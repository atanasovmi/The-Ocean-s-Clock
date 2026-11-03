# Optional final packaging, after both students agree on real graphic ownership.
# Fill authors.csv with actual names; this script never invents participation.
library(readr)
library(zip)
authors <- read_csv("authors.csv", show_col_types = FALSE)
stopifnot(all(c("figure", "main_author") %in% names(authors)))
if (anyNA(authors$main_author) || any(!nzchar(trimws(authors$main_author)))) {
  stop("Fill the main_author column in authors.csv before exporting the submission.")
}
dir.create("submission/graphics", recursive = TRUE, showWarnings = FALSE)
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
                   "The-Oceans-Clock.Rproj", "AGENTS.md", ".gitattributes", ".gitignore")
zip::zipr("submission/The-Oceans-Clock_R-project.zip", project_files,
          include_directories = FALSE, mode = "mirror")
message("Exported named PNGs and the complete R-project ZIP to submission/.")
