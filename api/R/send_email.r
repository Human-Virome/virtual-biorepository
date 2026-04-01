
#______________________________________________________________________________
#' Send an email for email verifications, password resets, etc.
#' 

footer <- 'sent by the <a href="https://hvp.jplab.net">HVP Virtual Biorepository</a>'

send_email <- function (to, subject, message) {
  
  tryCatch(
    error = function (e) stop("Unable to send email.\n", e$message),
    expr  = {
      
      odir <- getwd()
      on.exit(setwd(dir = odir))
      
      dir.create(tdir <- tempfile())
      on.exit(unlink(tdir, recursive = TRUE), add = TRUE)
      setwd(tdir)
      
      cat(file = 'destination.json', jsonlite::toJSON(list(ToAddresses = to)))
      
      cat(file = 'message.json', jsonlite::toJSON(list(
        Subject = list(Data = subject, Charset = 'UTF-8'),
        Body    = list(Html = list(
            Data = paste0(message, '<br><br>', footer),
            Charset = 'UTF-8' )))))
      
      system2(
        command = '/snap/bin/aws', 
        args    = c(
          'ses', 'send-email', 
          '--from',        shQuote("HVP Virtual Biorepository <hvp-no-reply@jplab.net>"),
          '--destination', 'file://destination.json', 
          '--message',     'file://message.json' ))
    })
}
