#!/usr/bin/env Rscript

# Loading the input arguments.
args = commandArgs(TRUE)

# Loading the "parallel" package to enable parallel computation.
library(parallel)

# Obtaining the paths from the input.
lib_dir = args[1]
data_file = args[3]

# Loading the "bnlearn" package to learn the structure of a Bayesian network.
library(bnlearn, lib.loc = lib_dir)

# Initializing the cluster.
cl = makeCluster(readLines(args[2]), type = "PSOCK")

# Exporting the paths.
clusterExport(cl, "lib_dir")
clusterExport(cl, "data_file")

#Loading the "bnlearn" package onto the cluster nodes.
invisible(clusterEvalQ(cl, library(bnlearn, lib.loc = lib_dir)))

# Learning the network structure on each split.
models = parLapply(cl, seq(length(cl)), function(...) {
  data = read.csv(data_file, header = TRUE)
  hc(data, score="k2")
})

# Obtaining the nodes from the header.
nodes = unlist(strsplit(gsub("[\r\n]", "", args[4]), split=","))

# # Averaging the networks
strength = custom.strength(models, nodes)
dag = averaged.network(strength)
dag = cextend(dag)

# Printing the learnt structure
dag