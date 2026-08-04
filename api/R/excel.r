export_excel <- function () {
  
  dict <- local({
    fp <- 'html/app/dictionary.js'
    js <- readChar(con = fp, nchars = file.size(fp))
    js <- sub('const vbrDictionary = ', '', js)
    js <- sub('};', '}', js)
    jsonlite::parse_json(js)
  })

  # 1. Initialize Workbook
  wb <- openxlsx2::wb_workbook()

  # Create hidden worksheet for controlled vocabularies and cell styles.
  wb <- openxlsx2::wb_add_worksheet(wb, 'cv')
  wb <- openxlsx2::wb_add_numfmt(wb, 'cv', "A1", numfmt = 49)
  text_style     <- openxlsx2::wb_get_cell_style(wb, 'cv', "A1")
  next_cv_col    <- 2L
  cv_error_title <- "Not in Controlled Vocabulary"
  cv_error_msg   <- paste(
    "The value you entered is not in the controlled vocabulary.",
    "Contact the HVPCC if additional CV terms are needed." )

  for (sheet in names(dict)) {
    
    stopifnot(nchar(sheet) < 32)

    wb <- openxlsx2::wb_add_worksheet(wb, sheet = sheet)

    fields <- names(dict[[sheet]])

    # Write field names to header row
    header_row <- paste0("A1:", openxlsx2::int2col(length(fields)), "1")
    wb <- openxlsx2::wb_add_data(wb, sheet, fields, header_row)
    wb <- openxlsx2::wb_set_row_heights(wb, sheet, rows = 1, heights = 20)
    wb <- openxlsx2::wb_freeze_pane(wb, sheet, first_row = TRUE)
    wb <- openxlsx2::wb_add_font(      wb, sheet, header_row, bold = TRUE, size = "12")
    wb <- openxlsx2::wb_add_cell_style(wb, sheet, header_row, vertical = "center" )
    wb <- openxlsx2::wb_add_border(    wb, sheet, header_row, 
      bottom_border = "thick",
      inner_vgrid   = "thin",
      bottom_color  = openxlsx2::wb_color(hex = "00333333"),
      inner_vcolor  = openxlsx2::wb_color(hex = "00888888"),
      left_color    = openxlsx2::wb_color(hex = "00888888"),
      right_color   = openxlsx2::wb_color(hex = "00888888") )

    # Compute widths using strwidth()
    widths <- local({
      pdf(NULL)
      name_widths <- strwidth(fields, units = "inches", font = 2, cex = 1)
      zero_width  <- strwidth("0",    units = "inches", font = 1, cex = 1)
      dev.off()
      return ((name_widths / zero_width) + 3)
    })
    wb <- openxlsx2::wb_set_col_widths(wb, sheet, cols = seq_along(fields), widths = widths)

    for (i in seq_along(fields)) {

      field        <- as.character(fields[i])
      col_letter   <- openxlsx2::int2col(i)
      header_cell  <- sprintf("%s1", col_letter)
      column_cells <- sprintf("%s2:%s1048576", col_letter, col_letter)

      # --- Safe Extraction from JSON ---
      x  <- dict[[sheet]][[i]]

      # Gather information for an Excel dropdown option list.
      cv_terms <- any(utils::hasName(x, c('cv', 'suggestions')))
      cv_force <- utils::hasName(x, 'cv')
      if      (cv_force) { cv_terms <- unlist(x[['cv']]);          }
      else if (cv_terms) { cv_terms <- unlist(x[['suggestions']]); }
      else               { cv_terms <- NULL                        }
      cv_yesno <- (length(cv_terms) == 2 && all(c('yes', 'no') %in% cv_terms))
      
      # Coerce to character and provide safe fallbacks for missing JSON fields
      def <- if (is.null(x[['def']])) ""           else as.character(x[['def']][1])
      fmt <- if (is.null(x[['fmt']])) character(0) else as.character(unlist(x[['fmt']]))

      # Freeze up to this column in addition to the first row.
      if ('primary' %in% fmt)
        wb <- openxlsx2::wb_freeze_pane(wb, sheet, first_active_row = 2L, first_active_col = i + 1L)

      # --- 2. Header Prompt's Title and Message ---
      if ('required' %in% fmt) {
        prompt_title <- "Required"
        header_color <- openxlsx2::wb_color(hex = "#F7B4AE")
        prompt_msg   <- def
      } else if ('condition' %in% fmt) {
        prompt_title <- "Conditional"
        header_color <- openxlsx2::wb_color(hex = "#FDE49B")
        prompt_msg   <- paste0(x[['condition']][['description']], "\n\n", def)
      } else {
        prompt_title <- "Optional"
        header_color <- openxlsx2::wb_color(hex = "#A6E3B7")
        prompt_msg   <- def
      }
      if      ('uid'      %in% fmt) prompt_title <- paste(prompt_title, '[uid]')
      else if ('ontology' %in% fmt) prompt_title <- paste(prompt_title, '[ontology]')
      else if ('number'   %in% fmt) prompt_title <- paste(prompt_title, '[number]')
      else if ('integer'  %in% fmt) prompt_title <- paste(prompt_title, '[integer]')
      else if ('cv'       %in% fmt) prompt_title <- paste(prompt_title, ifelse(cv_yesno,'[yes/no]', '[cv]'))
      if ("multiple" %in% fmt) {
        prompt_title <- sub("]", ", list]", prompt_title)
        cv_force     <- FALSE
      }
      prompt_title <- substr(prompt_title, 1, 32) 

      stopifnot(isTRUE(nzchar(prompt_msg)))
      prompt_msg <- sub("See below for UID format.", "See VBR website for UID format.", prompt_msg)
      if (nchar(prompt_msg) > 255) prompt_msg <- paste0(substr(prompt_msg, 1, 254), "&#8230;")
      prompt_msg <- gsub('"',   "&quot;", prompt_msg)
      prompt_msg <- gsub("\\n", "&#10;",  prompt_msg)
      
      # --- 3. Header Validation (Read-only popup) ---
      wb <- openxlsx2::wb_add_fill(wb, sheet, header_cell, color = header_color)
      wb <- openxlsx2::wb_add_data_validation(
        wb             = wb,
        sheet          = sheet,
        dims           = header_cell,
        type           = "textLength",
        operator       = "greaterThan",
        value          = "0",
        allow_blank    = FALSE,
        show_input_msg = TRUE,
        prompt_title   = prompt_title,
        prompt         = prompt_msg )

      # --- 4. Dropdown Validation ---
      if (!is.null(cv_terms)) {
        
        if (cv_yesno) {
          dropdown_ref <- '"yes,no"'
        } else {
          cv_col_letter <- openxlsx2::int2col(next_cv_col)
          cv_header     <- sprintf("%s1", cv_col_letter)
          cv_cells      <- sprintf("%s2:%s%d", cv_col_letter, cv_col_letter, length(cv_terms) + 1)
          dropdown_ref  <- sprintf("'cv'!$%s$2:$%s$%d", cv_col_letter, cv_col_letter, length(cv_terms) + 1)
          wb <- openxlsx2::wb_set_cell_style_across(wb, 'cv', style = text_style, cols = next_cv_col)
          wb <- openxlsx2::wb_add_data(  wb, 'cv', dims = cv_header, x = field)
          wb <- openxlsx2::wb_add_data(  wb, 'cv', dims = cv_cells,  x = cv_terms)
          next_cv_col <- next_cv_col + 1L
        }

        wb <- openxlsx2::wb_add_data_validation(
          wb             = wb,
          sheet          = sheet,
          dims           = column_cells,
          type           = "list",
          value          = dropdown_ref,
          show_input_msg = FALSE,
          show_error_msg = cv_force,
          error_title    = cv_error_title,
          error          = cv_error_msg )
      }

      # --- 5. Numeric Validation ---
      num_type <- NULL
      if      ('number'  %in% fmt) { num_type <- "decimal" }
      else if ('integer' %in% fmt) { num_type <- "whole"   }

      if (!is.null(num_type)) {

        value <- unlist(x[['range']])
        stopifnot(isTRUE(length(value) == 2))
        title <- "Out of bounds"
        msg   <- "Please enter a %s number between %s and %s."
        msg   <- sprintf(msg, num_type, value[1], value[2])

        wb <- openxlsx2::wb_add_data_validation(
          wb             = wb,
          sheet          = sheet,
          dims           = column_cells,
          type           = num_type,
          operator       = "between",
          value          = value,
          show_input_msg = FALSE,
          show_error_msg = TRUE,
          error_title    = title,
          error          = msg )
      }
      else {
        # Force Column to Display as Text
        wb <- openxlsx2::wb_set_cell_style_across(wb, sheet, style = text_style, cols = i)
      }

    }
  }

  # 6. Finalize and Save
  wb <- openxlsx2::wb_set_active_sheet(wb, sheet = 2)
  wb <- openxlsx2::wb_set_sheet_visibility(wb, "cv", value = "hidden")
  
  openxlsx2::wb_save(wb, "html/app/vbr_metadata_template.xlsx", overwrite = TRUE)
  message("Success!")
}


# export_excel()
