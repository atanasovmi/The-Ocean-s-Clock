# White, slide-sized charts. A serif headline and restrained axes leave room for the data.
.libPaths(c(".Rlibrary", .libPaths()))
library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)

ink <- "#183139"
blue <- "#086879"
orange <- "#AC4A20"
muted <- "#53686D"
grid <- "#DCE4E4"

theme_presentation <- function() {
  theme_minimal(base_size = 16, base_family = "sans") +
    theme(text = element_text(colour = ink),
          plot.title.position = "plot", plot.caption.position = "plot",
          plot.title = element_text(family = "serif", size = 32, face = "bold", margin = margin(b = 6)),
          plot.subtitle = element_text(size = 15, colour = muted, margin = margin(b = 18), lineheight = 1.13),
          axis.text = element_text(size = 13, colour = ink),
          axis.title = element_text(size = 14, colour = ink),
          axis.title.x = element_text(margin = margin(t = 8)),
          axis.title.y = element_text(margin = margin(r = 9)),
          panel.grid.minor = element_blank(),
          panel.grid.major = element_line(colour = grid, linewidth = 0.34),
          strip.text = element_text(face = "bold", hjust = 0, size = 14),
          legend.position = "top", legend.title = element_blank(),
          legend.justification = "left", legend.text = element_text(size = 13),
          plot.background = element_rect(fill = "white", colour = NA),
          plot.caption = element_text(size = 11, colour = muted, hjust = 0, margin = margin(t = 14), lineheight = 1.1),
          plot.margin = margin(20, 25, 16, 23))
}

save_plot <- function(plot, filename, width = 13 + 1/3, height = 7.5) {
  dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
  dir.create("outputs/vector", recursive = TRUE, showWarnings = FALSE)
  ggsave(file.path("outputs/figures", paste0(filename, ".png")), plot = plot,
         width = width, height = height, dpi = 300, device = ragg::agg_png, bg = "white")
  ggsave(file.path("outputs/vector", paste0(filename, ".svg")), plot = plot,
         width = width, height = height, device = svglite::svglite, bg = "white")
}
