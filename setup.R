# Run once after opening The-Oceans-Clock.Rproj.
# Packages stay in an ignored project library; no global R settings are changed.
dir.create(".Rlibrary", showWarnings = FALSE)
.libPaths(c(".Rlibrary", .libPaths()))
packages <- c("ggplot2", "dplyr", "tidyr", "readr", "readxl", "jsonlite",
              "ragg", "zip", "sf", "svglite")
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing, lib = ".Rlibrary", repos = "https://cloud.r-project.org")
message("Ready. Run source('run.R') to reproduce the project from cached data.")
