R=$(shell which Rscript)

ref.rds: translate.R *.sqlite
	$(R) $^ > $@

%.rds: binarize.R %.out ref.rds
	$(R) $^ > $@

%-overview.png: overview-plot.R %.rda
	$(R) $^ $@