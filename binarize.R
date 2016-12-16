require(data.table)

args <- commandArgs(trailingOnly = T)

res <- fread(args[1], verbose = F,
  key = c("serial","time"),
  col.names = c("serial", "time", "introductions", "transmissions", "total infections", "mild", "severe")
)

# do something with names here

saveRDS(res, pipe("cat","wb"))