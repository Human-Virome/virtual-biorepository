df <- read.table(file = "html/ontologies/ncit.tsv", sep = "\t", header = TRUE, quote = "")

keep <- integer(0)
mark <- function (id) {
  keep    <<- c(keep, which(df$id == id))
  children <- df[df[['parent']] == id, 'id']
  sapply(children, mark)
}

invisible(mark("NCIT:C70700")) # Biospecimen Collection Method
invisible(mark("NCIT:C15189")) # Biopsy Procedure
invisible(mark("NCIT:C51692")) # Skin Biopsy
invisible(mark("NCIT:C64979")) # Diagnostic Surgical Procedure

writeLines(
  text = sprintf("%s\t[%s]", df[keep,'label'], df[keep,'id']),
  con  = "html/cv/collection_method.tsv")

