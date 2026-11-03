# Run from the project root, ideally in a fresh R session.
# Some Windows terminals inherit an unsupported C.UTF-8 locale.
# Set a real Windows UTF-8 locale before reading chart labels.
if (.Platform$OS.type == "windows") Sys.setlocale("LC_CTYPE", "English_United States.utf8")
.libPaths(c(".Rlibrary", .libPaths()))
options(stringsAsFactors = FALSE)
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)
scripts <- c(
  "prepare_coral.R", "check_lunar_reference.R", "prepare_ocean.R",
  "analyse_heat_exposure.R", "fit_aquarium_models.R", "compare_field_studies.R",
  "export_spatial_data.R",
  "plots/01_lunar_timing.R", "plots/02_night_timing.R", "plots/03_heat_stress.R",
  "plots/04_spawning_exposure.R", "plots/05_model_comparison.R", "plots/06_field_comparison.R",
  "write_findings.R", "check_results.R"
)
for (script in scripts) {
  message("\nRunning ", script)
  source(file.path("R", script), encoding = "UTF-8")
}
session_details <- capture.output(sessionInfo())
writeLines(trimws(session_details, which = "right"), "outputs/session-info.txt")
message("Finished. See outputs/figures and outputs/RESULTS.md.")
