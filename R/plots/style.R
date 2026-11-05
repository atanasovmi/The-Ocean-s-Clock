# The shared look of the plots: one night-time colour scheme, one typeface.
.libPaths(c(".Rlibrary", .libPaths()))
library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)

# Colour ----
# Every colour has one job, on every plot.
night <- "#0B1D2E"   # the page, and water or sky with nothing in it
moon  <- "#F1EAD7"   # main text, and anything that is the Moon
soft  <- "#B7C4CE"   # secondary text and axis labels
faint <- "#8598A7"   # sources and quiet notes
rule  <- "#31475A"   # hairlines
spawn <- "#FF7E8B"   # a spawning record. Gamete bundles really are this pink.
water <- "#4FA3DB"   # cooling water, or a model's forecast

# Heat stress climbs from the page colour to a bright ember, so a calm year
# disappears into the background and only heat catches the eye.
heat_steps <- c("#0B1D2E", "#4D4580", "#9A3A7A", "#D24C5F", "#F27F40", "#FDD78A")

# Type ----
# Bahnschrift is the DIN lettering of road signs and instruments, and it ships
# with Windows. It is one variable font file; the number picks a named cut from
# it (2 semilight, 4 semibold, 8 semi-condensed, 13 condensed, 14 condensed
# semibold). Other systems fall back to their default sans-serif.
bahnschrift <- "C:/Windows/Fonts/bahnschrift.ttf"
type_cut <- function(name, cut) {
  if (!file.exists(bahnschrift)) return("sans")
  if (!name %in% systemfonts::registry_fonts()$family) {
    systemfonts::register_font(name, plain = list(bahnschrift, bitwShiftL(cut, 16)))
  }
  name
}
font_title <- type_cut("Plot Title", 4)
font_text  <- type_cut("Plot Text", 2)
font_note  <- type_cut("Plot Note", 8)
font_tick  <- type_cut("Plot Tick", 13)
font_label <- type_cut("Plot Label", 14)

# ggplot sizes text in millimetres and theme() in points; this converts.
pts <- function(points) points / ggplot2::.pt

# Theme ----
theme_plot <- function() {
  theme_void(base_family = font_text) +
    theme(
      text = element_text(colour = moon),
      plot.background = element_rect(fill = night, colour = NA),
      plot.title.position = "plot", plot.caption.position = "plot",
      plot.title = element_text(family = font_title, size = 29, hjust = 0,
                                margin = margin(b = 7)),
      plot.subtitle = element_text(size = 16.5, colour = soft, hjust = 0, lineheight = 1.15,
                                   margin = margin(b = 20)),
      plot.caption = element_text(family = font_note, size = 11, colour = faint, hjust = 0,
                                  lineheight = 1.15, margin = margin(t = 16)),
      plot.margin = margin(28, 36, 20, 36),
      axis.text = element_text(family = font_tick, size = 14.5, colour = soft),
      axis.text.x = element_text(margin = margin(t = 5)),
      axis.text.y = element_text(margin = margin(r = 5), hjust = 1),
      axis.title = element_text(family = font_note, size = 14, colour = soft),
      axis.title.x = element_text(margin = margin(t = 9)),
      axis.title.y = element_text(angle = 90, margin = margin(r = 9)),
      axis.ticks = element_line(colour = faint, linewidth = 0.35),
      axis.ticks.length = unit(5, "pt"),
      legend.text = element_text(family = font_note, size = 13, colour = soft),
      legend.title = element_text(family = font_note, size = 13, colour = soft)
    )
}

# Moon phases ----
# A small drawn moon for marking lunar days on an axis. `phase` is the lunar day
# (0 = full, +-14.8 = new). width and height are the disc's size in data units,
# because a plot's two axes usually have different scales.
moon_icon <- function(x, y, phase, width, height, id = paste(x, phase)) {
  angle <- seq(-pi / 2, pi / 2, length.out = 40)
  lit_fraction <- (1 + cos(2 * pi * phase / 29.53)) / 2
  # Before full moon the right side is lit; after it, the left (northern view).
  side <- if_else(phase <= 0, 1, -1)
  limb <- side * cos(angle)
  terminator <- side * (1 - 2 * lit_fraction) * cos(angle)
  tibble(id = id,
         x = x + width / 2 * c(limb, rev(terminator)),
         y = y + height / 2 * c(sin(angle), rev(sin(angle))))
}

# A row of drawn moons across the top of a plot whose x axis is the lunar day.
moon_phase_row <- function(days, y, width, height) {
  circle <- seq(0, 2 * pi, length.out = 60)
  discs <- bind_rows(lapply(days, function(day) {
    tibble(id = day, x = day + width / 2 * cos(circle), y = y + height / 2 * sin(circle))
  }))
  lit_parts <- bind_rows(lapply(days, function(day) moon_icon(day, y, day, width, height, id = day)))
  list(geom_polygon(data = discs, aes(x, y, group = id), inherit.aes = FALSE, fill = "#1F3549"),
       geom_polygon(data = lit_parts, aes(x, y, group = id), inherit.aes = FALSE, fill = moon))
}

# Read a measure/value statistics table into a simple named vector.
read_statistics <- function(path) {
  statistics <- read_csv(path, show_col_types = FALSE)
  setNames(statistics$value, statistics$measure)
}

# Export ----
# The PNG is the presentation file. The SVG scales freely in Prezi.
save_plot <- function(plot, filename, width = 13 + 1/3, height = 7.5) {
  dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
  dir.create("outputs/vector", recursive = TRUE, showWarnings = FALSE)
  ggsave(file.path("outputs/figures", paste0(filename, ".png")), plot = plot,
         width = width, height = height, dpi = 300, device = ragg::agg_png, bg = night)
  ggsave(file.path("outputs/vector", paste0(filename, ".svg")), plot = plot,
         width = width, height = height, device = svglite::svglite, bg = night)
}
