require(data.table)
require(RSQLite)

args <- commandArgs(trailingOnly = T)
db <- dbConnect(SQLite(), args[1])
res <- data.table(dbGetQuery(db, "SELECT * from parameters;"), key = c("serial", "realization"))
stopifnot(dbDisconnect(db))

saveRDS(
  res,
  pipe("cat","wb")
)
