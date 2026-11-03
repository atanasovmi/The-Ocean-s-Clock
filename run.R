# Run from the project root, ideally in a fresh R session.
# Some Windows terminals inherit an unsupported C.UTF-8 locale.
# Set a real Windows UTF-8 locale before reading chart labels.
if (.Platform$OS.type == "windows") Sys.setlocale("LC_CTYPE", "English_United States.utf8")
.libPaths(c(".Rlibrary", .libPaths()))
options(stringsAsFactors = FALSE)
scripts <- c("01_prepare.R", "02_enrich.R", "03_geography_seasons.R",
             "04_moon_sunset.R", "05_temperature.R", "06_robustness.R", "07_results.R")
for (script in scripts) {
  message("\nRunning ", script)
  source(file.path("R", script), encoding = "UTF-8")
}
capture.output(sessionInfo(), file = "outputs/session-info.txt")
message("Finished. See outputs/figures and outputs/RESULTS.md.")
