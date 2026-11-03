# A conventional ggplot theme shared by the six presentation figures.
.libPaths(c(".Rlibrary", .libPaths()))
library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)

blue <- "#356A8A"
orange <- "#C57932"

theme_presentation <- function() {
  theme_bw(base_size = 17, base_family = "sans") +
    theme(plot.title = element_text(size = 20, face = "plain", margin = margin(b = 8)),
          plot.subtitle = element_text(size = 13, margin = margin(b = 12)),
          axis.text = element_text(size = 15, colour = "black"),
          axis.title = element_text(size = 16),
          panel.grid.minor = element_blank(),
          panel.grid.major = element_line(colour = "grey92", linewidth = 0.25),
          panel.border = element_rect(colour = "grey35", linewidth = 0.5),
          legend.position = "top", legend.title = element_blank(),
          legend.text = element_text(size = 13),
          plot.caption = element_text(size = 10, hjust = 0, margin = margin(t = 12)),
          plot.margin = margin(12, 18, 12, 12))
}

save_plot <- function(plot, filename, width = 10.5, height = 6.5) {
  dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
  dir.create("outputs/vector", recursive = TRUE, showWarnings = FALSE)
  ggsave(file.path("outputs/figures", paste0(filename, ".png")), plot = plot,
         width = width, height = height, dpi = 300, device = ragg::agg_png, bg = "white")
  ggsave(file.path("outputs/vector", paste0(filename, ".svg")), plot = plot,
         width = width, height = height, device = svglite::svglite, bg = "white")
}
