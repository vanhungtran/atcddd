library(hexSticker)
library(ggplot2)
library(dplyr)
library(showtext)
library(viridisLite)

font_add_google("Righteous", "righteous")
showtext_auto()

# ── MODERN ATC HIERARCHY LOGO ────────────────────────────────────
# A radial branching tree representing the 5-level ATC hierarchy,
# with a pharmaceutical accent. Clean, professional, scientific.
# ─────────────────────────────────────────────────────────────────

set.seed(42)

# 5 levels of hierarchy
n_levels <- 5
level_y <- seq(0.8, -0.7, length.out = n_levels)
level_n <- c(1, 3, 6, 10, 16)
x_span  <- 0.75

# Pre-compute x positions for each level
x_positions <- list()
for (i in seq_len(n_levels)) {
  x_positions[[i]] <- if (i == 1) 0 else seq(-x_span, x_span, length.out = level_n[i])
}

# Build branches and nodes
segments_list <- list()
points_list <- list()

for (i in seq_len(n_levels)) {
  x_pos <- x_positions[[i]]
  y_pos <- level_y[i]
  sz    <- rev(seq(1.5, 4.0, length.out = n_levels))[i]
  col   <- viridis(n_levels, option = "mako", begin = 0.15, end = 0.85)[i]

  points_list[[i]] <- data.frame(x = x_pos, y = y_pos, size = sz, colour = col)

  if (i > 1) {
    prev_x <- x_positions[[i - 1]]
    # Distribute children evenly across parents
    for (p in seq_along(prev_x)) {
      # Each parent gets floor(n_children / n_parents) or 1 more for early ones
      base <- floor(level_n[i] / length(prev_x))
      extra <- if (p <= level_n[i] %% length(prev_x)) 1 else 0
      start_idx <- (p - 1) * base + min(p - 1, level_n[i] %% length(prev_x)) + 1
      end_idx <- start_idx + base + extra - 1
      children <- start_idx:min(end_idx, level_n[i])
      for (c in children) {
        segments_list <- append(segments_list, list(data.frame(
          x = prev_x[p], y = level_y[i - 1],
          xend = x_pos[c], yend = y_pos,
          alpha = 0.3 * (i / n_levels)
        )))
      }
    }
  }
}

segments_df <- bind_rows(segments_list)
points_df   <- bind_rows(points_list)

p <- ggplot() +
  # Connection lines
  geom_segment(data = segments_df,
               aes(x = x, y = y, xend = xend, yend = yend, alpha = alpha),
               color = "#0B525B", linewidth = 0.35) +
  # Nodes
  geom_point(data = points_df,
             aes(x = x, y = y, size = size, color = colour),
             alpha = 0.9) +
  # Central root emphasis
  geom_point(data = points_df %>% slice(1),
             aes(x = x, y = y), size = 5, color = "#0B525B", alpha = 1) +
  # ATC label inside root
  annotate("text", x = 0, y = level_y[1], label = "ATC",
           color = "white", size = 2.8, fontface = "bold", family = "righteous") +
  scale_alpha_identity() +
  scale_size_identity() +
  scale_color_identity() +
  coord_fixed(xlim = c(-0.9, 0.9), ylim = c(-0.9, 0.9)) +
  theme_void() +
  theme(
    legend.position = "none",
    plot.background = element_rect(fill = "transparent", color = NA),
    panel.background = element_rect(fill = "transparent", color = NA)
  )

sticker(p,
        package        = "atcddd",
        p_size          = 20,
        p_color         = "#0B525B",
        p_family        = "righteous",
        p_y            = 1.45,
        s_x            = 1,
        s_y            = 0.72,
        s_width        = 1.2,
        s_height       = 1.0,
        h_fill         = "#F8F9FA",
        h_color        = "#0B525B",
        h_size         = 1.8,
        filename       = "man/figures/logo.png",
        dpi            = 300,
        white_around_sticker = FALSE
)

cat("✓ Created man/figures/logo.png\n")
cat("Design: Radial ATC hierarchy tree (5 levels)\n")
cat("        Deep teal + viridis mako gradient\n")
cat("        White hex background, Righteous font\n")
