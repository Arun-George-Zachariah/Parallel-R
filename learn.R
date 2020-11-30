#!/usr/bin/env Rscript

# Loading the input arguments.
args = commandArgs(trailingOnly=TRUE)

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

# Obtaining the nodes from the header.
nodes = unlist(strsplit(gsub("[\r\n]", "", args[4]), split=","))

# Creating an empty drag.
currentDAG = empty.graph(nodes)

# Expectation–maximization loop.
while (TRUE) {

  # Learning the network structure on each split.
  models = parLapply(cl, seq(length(cl)), function(...) {
    data = read.csv(data_file, header = TRUE)
    hc(data, score="k2")
  })

  # Averaging the networks
  strength = custom.strength(models, nodes)
  newDAG = averaged.network(strength)
  newDAG = cextend(newDAG)

  # Printing the learnt structure
  print(newDAG)

  # Checking there was a change, in the network from the previous iteration.
  if (isTRUE(all.equal(currentDAG, newDAG)))
    break

  # Setting the new DAG to the current DAG for the next iteration
  currentDAG = newDAG
}

# Printing the final DAG.
currentDAG
