%.rds: binarize.R %.out
	$(R) $^ > $@

%-overview.png: overview-plot.R %.rda
	$(R) $^ $@