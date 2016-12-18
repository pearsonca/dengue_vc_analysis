require(data.table)
require(ggplot2)
require(quantreg)

args <- commandArgs(trailingOnly = TRUE)
src <- args[1]
tar <- args[2]

dt <- readRDS(src)
reducedkey <- setdiff(key(dt),"intervention")
measures <- setdiff(names(dt), c(reducedkey,"intervention"))
nonkey <- setdiff(reducedkey, c("duration","start_time","coverage","efficacy"))

newkey <- c("particle", "realization", "time")

slice <- function(srcdt, q) {
  res <- srcdt[eval(q), .SD, keyby=nonkey, .SDcols=measures]
  res[, particle := .GRP, by=scenario ]
  res
}

crucible <- function(widedt, intname, lvls) melt.data.table(
  widedt[, .SD, keyby=newkey, .SDcols=measures],
  id.vars = newkey, variable.name = "measure"
)[,
  `:=`(
    intervention = factor(intname, lvls),
    year = floor(time/365),
    doy = time %% 365
  )
]

lvls <- c(non="none",off="vector control at DOY 14",ins="vector control at DOY 154")

reforge <- function(dt, q, name) crucible(slice(dt, q), name, lvls)

reference <- reforge(dt, quote(intervention==FALSE), lvls["non"])
offseason <- reforge(dt, quote(intervention==TRUE & start_time == 14), lvls["off"])
inseason <- reforge(dt, quote(intervention==TRUE & start_time == 154), lvls["ins"])

# day of year [6/1,11/1]

combo <- rbind(reference, offseason, inseason)
qs <- (0:4)/4
stats_combo <- combo[,{
    q <- quantile(value, probs = qs)
    list(min=q[1],low=q[2],med=q[3],hi=q[4],max=q[5])
  },
  by=list(measure, intervention, time)
]

stats_combo[, time := time - min(time) + 1]

intervention_dates <- melt.data.table(data.table(
    off=(0:11)*365 + 14 - 100,
    ins=(0:11)*365 + 154 - 100
  ), measure.vars = c("off","ins"),
  variable.name = "intervention", value.name = "time"
)
intervention_dates[, intervention := factor(lvls[as.character(intervention)],lvls) ]
intervention_dates <- intervention_dates[time > 0]
intervention_dates[, note := "control period" ]

ggsave(tar, ggplot(stats_combo[measure == "transmissions" & time < 365*4]) + aes(x=time) +
  geom_ribbon(aes(ymax=hi, ymin=low, fill=intervention), alpha=0.5) + geom_line(aes(color=intervention, y=med)) +
  geom_rect(aes(xmin=time, xmax=time+90, ymin=0, ymax=1000, fill=intervention), data=intervention_dates[time < 365*4], alpha=0.2) +
  geom_text(aes(x = time+45, y=500, label=note, angle=90, color=intervention), intervention_dates[time < 365*4], show.legend = FALSE) +
  facet_grid(measure ~ ., scales="free_y") +
  theme_minimal(), height = 150, width = 300, units = "mm")