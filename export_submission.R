# Optional final packaging, after both students agree on real graphic ownership.
# Fill authors.csv with actual names; this script never invents participation.
library(readr)
library(zip)
authors <- read_csv("authors.csv", show_col_types = FALSE)
stopifnot(file.exists("The-Oceans-Clock.Rproj"),
          all(c("figure", "main_author") %in% names(authors)),
          !anyDuplicated(authors$figure))
if (anyNA(authors$main_author) || any(!nzchar(trimws(authors$main_author)))) {
  stop("Fill the main_author column in authors.csv before exporting the submission.")
}
dir.create("submission/graphics", recursive = TRUE, showWarnings = FALSE)
# This folder contains generated submission copies. Remove obsolete PNG copies
# when the figure selection or author assignment changes; source figures stay intact.
old_exports <- list.files("submission/graphics", pattern = "\\.png$", full.names = TRUE)
if (length(old_exports)) unlink(old_exports)
for (i in seq_len(nrow(authors))) {
  source_file <- file.path("outputs/figures", authors$figure[i])
  stopifnot(file.exists(source_file))
  author_name <- gsub("[^[:alnum:]_-]+", "_", trimws(authors$main_author[i]))
  stopifnot(file.copy(source_file, file.path("submission/graphics", paste0(author_name, "_", authors$figure[i])), overwrite = TRUE))
}
project_files <- c(list.files("R", recursive = TRUE, full.names = TRUE),
                   list.files(".agents", recursive = TRUE, full.names = TRUE),
                   list.files("data", recursive = TRUE, full.names = TRUE),
                   list.files("docs", recursive = TRUE, full.names = TRUE),
                   list.files("outputs", recursive = TRUE, full.names = TRUE),
                   "README.md", "run.R", "setup.R", "export_submission.R", "authors.csv",
                   list.files("tools", recursive = TRUE, full.names = TRUE),
                   "The-Oceans-Clock.Rproj", "AGENTS.md", ".gitattributes", ".gitignore")
# The large parsed regional cache is reproducible from the included source gzip
# archives. The optional native snapshot contains selected analysis/model objects.
project_files <- setdiff(project_files, "data/derived/regional_daily.rds")
project_files <- project_files[!grepl("__pycache__|\\.pyc$", project_files)]
native_files <- c(".RData", ".Rhistory")
project_files <- c(project_files, native_files[file.exists(native_files)])
zip::zipr("submission/The-Oceans-Clock_R-project.zip", project_files,
          include_directories = FALSE, mode = "mirror")
message("Exported named PNGs and the complete R-project ZIP to submission/.")
