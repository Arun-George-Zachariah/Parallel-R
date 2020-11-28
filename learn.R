#!/usr/bin/env Rscript

# Loading the "parallel" package to enable parallel computation.
library(parallel)

# Loading the "bnlearn" package to learn the structure of a Bayesian network.
library(bnlearn)

# Loading the input arguments.
args = commandArgs(trailingOnly=TRUE)

# Initializing the cluster.
cl = makeCluster(readLines(args[0]), type = "PSOCK")

# Loading the "bnlearn" package onto the cluster nodes.
invisible(clusterEvalQ(cl, library(bnlearn)))

# Learning the network structure on each split.
models = parLapply(cl, seq(length(cl)), function(...) {
  data = read.csv(args[1], header = TRUE)
  hc(data, score="k2")
})

# Averaging the networks
strength = custom.strength(models, c("A", "B", "C", "D", "E", "F"))
dag = averaged.network(strength)
dag = cextend(dag)

# Printing the learnt structure
dag