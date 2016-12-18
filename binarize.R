require(data.table)

args <- commandArgs(trailingOnly = T)

res <- fread(
  args[1], showProgress = F, key = c("serial","time"),
  col.names = c("serial", "time", "introductions", "transmissions", "infections", "cases", "severe")
)[, asymptomatic := infections - cases - severe]

ref <- readRDS(args[2])

res <- res[ref[,list(realization, vector_control, campaign_duration, timing, vc_coverage, vc_efficacy), keyby=serial], on="serial"]
res[, scenario := serial - realization ]
res[, mild := cases - severe ]

saveRDS(
  res[,
    list(introductions, transmissions, asymptomatic, mild, severe), # outputs
    keyby=list( # inputs
      scenario, realization, time, intervention=as.logical(vector_control),
      duration=campaign_duration, start_time = timing, coverage=vc_coverage,
      efficacy = vc_efficacy
    )
  ],
  pipe("cat","wb")
)