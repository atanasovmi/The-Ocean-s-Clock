# Shared design choices; the analysis remains visible in each numbered script.
library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(patchwork)

ink <- "#15212B"
ocean <- "#007A87"
coral <- "#D55E00"
paper <- "#FFFFFF"
muted <- "#62707A"
grid_colour <- "#E8ECEF"
source_coral <- "Source: Baird et al. (2021), Coral Spawning Database v1."
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)

theme_clock <- function(base_size = 15) {
  theme_minimal(base_size = base_size, base_family = "Arial") +
    theme(plot.background = element_rect(fill = paper, colour = NA),
          panel.background = element_rect(fill = paper, colour = NA),
          text = element_text(colour = ink),
          plot.title = element_text(size = 24, face = "bold", margin = margin(b = 10)),
          plot.subtitle = element_text(size = 14, colour = muted, lineheight = 1.2,
                                       margin = margin(b = 20)),
          plot.caption = element_text(size = 10, colour = muted, hjust = 0,
                                      lineheight = 1.25, margin = margin(t = 18)),
          plot.title.position = "plot", plot.caption.position = "plot",
          plot.margin = margin(24, 28, 24, 24),
          panel.grid.minor = element_blank(), panel.grid.major = element_line(colour = grid_colour, linewidth = 0.3),
          axis.title = element_text(size = 13), axis.text = element_text(colour = ink),
          strip.text = element_text(face = "bold", size = 13, hjust = 0),
          strip.background = element_blank(), legend.position = "bottom",
          legend.title = element_text(size = 12), legend.text = element_text(size = 11))
}

# Every exported figure has a matching plot-data CSV in outputs/tables.
save_figure <- function(plot, name, width = 14, height = 8.5) {
  ggsave(file.path("outputs/figures", paste0(name, ".png")), plot = plot,
         width = width, height = height, units = "in", dpi = 300,
         device = ragg::agg_png, bg = paper)
  dir.create("outputs/vector", recursive = TRUE, showWarnings = FALSE)
  ggsave(file.path("outputs/vector", paste0(name, ".svg")), plot = plot,
         width = width, height = height, units = "in", device = svglite::svglite, bg = paper)
}
