# Generate impressive hex logo for atcddd package
# Install required packages if needed
if (!require("hexSticker")) install.packages("hexSticker")
if (!require("ggplot2")) install.packages("ggplot2")
if (!require("dplyr")) install.packages("dplyr")
if (!require("showtext")) install.packages("showtext")

library(hexSticker)
library(ggplot2)
library(dplyr)
library(showtext)

# Option 1: Medical/Pharmaceutical Theme with ATC Hierarchy
# =========================================================

# Add custom font (optional)
font_add_google("Righteous", "righteous")
font_add_google("Roboto", "roboto")
showtext_auto()

# Create a visualization of the ATC hierarchy
set.seed(42)
hierarchy_data <- data.frame(
  level = factor(c("1", "2", "3", "4", "5"), 
                 levels = c("1", "2", "3", "4", "5")),
  count = c(1, 8, 15, 25, 50),
  color = c("#264653", "#2a9d8f", "#e9c46a", "#f4a261", "#e76f51")
)

p1 <- ggplot(hierarchy_data, aes(x = level, y = count, fill = level)) +
  geom_col(width = 0.8, alpha = 0.95) +
  scale_fill_manual(values = hierarchy_data$color) +
  theme_void() +
  theme(
    legend.position = "none",
    plot.background = element_rect(fill = "transparent", color = NA),
    panel.background = element_rect(fill = "transparent", color = NA)
  )

sticker(p1,
        package = "atcddd",
        p_size = 24,
        p_color = "#264653",
        p_family = "righteous",
        p_y = 1.5,
        s_x = 1,
        s_y = 0.75,
        s_width = 1.3,
        s_height = 1,
        h_fill = "transparent",
        h_color = "#2a9d8f",
        h_size = 1.5,
        filename = "man/figures/logo_option1.png",
        dpi = 300,
        white_around_sticker = FALSE
)

cat("✓ Created logo_option1.png - Hierarchy bar chart theme\n\n")


# Option 2: DNA/Chemical Structure Theme
# =========================================

# Create a molecule/network structure
set.seed(123)
n_nodes <- 30
nodes <- data.frame(
  x = runif(n_nodes, -1, 1),
  y = runif(n_nodes, -1, 1),
  size = runif(n_nodes, 2, 8)
)

# Create connections
edges <- data.frame(
  x1 = numeric(),
  y1 = numeric(),
  x2 = numeric(),
  y2 = numeric()
)

for (i in 1:(n_nodes-1)) {
  for (j in (i+1):n_nodes) {
    dist <- sqrt((nodes$x[i] - nodes$x[j])^2 + (nodes$y[i] - nodes$y[j])^2)
    if (dist < 0.5) {
      edges <- rbind(edges, data.frame(
        x1 = nodes$x[i],
        y1 = nodes$y[i],
        x2 = nodes$x[j],
        y2 = nodes$y[j]
      ))
    }
  }
}

p2 <- ggplot() +
  geom_segment(data = edges, 
               aes(x = x1, y = y1, xend = x2, yend = y2),
               color = "#2a9d8f", alpha = 0.4, size = 0.5) +
  geom_point(data = nodes, 
             aes(x = x, y = y, size = size),
             color = "#264653", alpha = 0.8) +
  scale_size_continuous(range = c(2, 8)) +
  theme_void() +
  theme(
    legend.position = "none",
    plot.background = element_rect(fill = "transparent", color = NA),
    panel.background = element_rect(fill = "transparent", color = NA)
  )

sticker(p2,
        package = "atcddd",
        p_size = 24,
        p_color = "#264653",
        p_family = "righteous",
        p_y = 1.5,
        s_x = 1,
        s_y = 0.75,
        s_width = 1.4,
        s_height = 1.2,
        h_fill = "transparent",
        h_color = "#2a9d8f",
        h_size = 1.5,
        filename = "man/figures/logo_option2.png",
        dpi = 300,
        white_around_sticker = FALSE
)

cat("✓ Created logo_option2.png - Molecular network theme\n\n")


# Option 3: Medical Cross + Data Theme
# ======================================

# Create a stylized medical cross with data elements
cross_data <- data.frame(
  x = c(-0.2, 0.2, 0.2, 0.6, 0.6, 0.2, 0.2, -0.2, -0.2, -0.6, -0.6, -0.2),
  y = c(0.6, 0.6, 0.2, 0.2, -0.2, -0.2, -0.6, -0.6, -0.2, -0.2, 0.2, 0.2)
)

# Add data points around the cross
set.seed(789)
data_points <- data.frame(
  x = c(runif(15, -0.9, -0.3), runif(15, 0.3, 0.9)),
  y = runif(30, -0.9, 0.9),
  alpha = runif(30, 0.3, 0.9)
)

p3 <- ggplot() +
  geom_polygon(data = cross_data, aes(x = x, y = y),
               fill = "#2a9d8f", alpha = 0.9) +
  geom_point(data = data_points, aes(x = x, y = y, alpha = alpha),
             color = "#e76f51", size = 2) +
  scale_alpha_continuous(range = c(0.3, 0.9)) +
  coord_fixed() +
  theme_void() +
  theme(
    legend.position = "none",
    plot.background = element_rect(fill = "transparent", color = NA),
    panel.background = element_rect(fill = "transparent", color = NA)
  )

sticker(p3,
        package = "atcddd",
        p_size = 24,
        p_color = "#264653",
        p_family = "righteous",
        p_y = 1.5,
        s_x = 1,
        s_y = 0.75,
        s_width = 1.2,
        s_height = 1.2,
        h_fill = "transparent",
        h_color = "#2a9d8f",
        h_size = 1.5,
        filename = "man/figures/logo_option3.png",
        dpi = 300,
        white_around_sticker = FALSE
)

cat("✓ Created logo_option3.png - Medical cross + data theme\n\n")


# Option 4: Pills/Capsules Theme (RECOMMENDED)
# =============================================

# Create stylized pills arranged in a pattern
pills <- data.frame(
  x = c(-0.4, 0, 0.4, -0.2, 0.2),
  y = c(0.3, 0.5, 0.3, -0.2, -0.2),
  width = c(0.3, 0.35, 0.3, 0.28, 0.28),
  height = c(0.6, 0.7, 0.6, 0.55, 0.55),
  color = c("#264653", "#2a9d8f", "#e9c46a", "#f4a261", "#e76f51")
)

p4 <- ggplot() +
  # Draw pill capsules
  lapply(1:nrow(pills), function(i) {
    list(
      # Top half
      geom_rect(aes(xmin = pills$x[i] - pills$width[i]/2,
                    xmax = pills$x[i] + pills$width[i]/2,
                    ymin = pills$y[i],
                    ymax = pills$y[i] + pills$height[i]/2),
                fill = pills$color[i], alpha = 0.9),
      # Bottom half (lighter)
      geom_rect(aes(xmin = pills$x[i] - pills$width[i]/2,
                    xmax = pills$x[i] + pills$width[i]/2,
                    ymin = pills$y[i] - pills$height[i]/2,
                    ymax = pills$y[i]),
                fill = pills$color[i], alpha = 0.5),
      # Middle line
      geom_segment(aes(x = pills$x[i] - pills$width[i]/2,
                       xend = pills$x[i] + pills$width[i]/2,
                       y = pills$y[i],
                       yend = pills$y[i]),
                   color = "white", size = 1.5, alpha = 0.8)
    )
  }) +
  coord_fixed() +
  theme_void() +
  theme(
    legend.position = "none",
    plot.background = element_rect(fill = "transparent", color = NA),
    panel.background = element_rect(fill = "transparent", color = NA)
  )

sticker(p4,
        package = "atcddd",
        p_size = 24,
        p_color = "#264653",
        p_family = "righteous",
        p_y = 1.5,
        s_x = 1,
        s_y = 0.75,
        s_width = 1.3,
        s_height = 1.1,
        h_fill = "transparent",
        h_color = "#2a9d8f",
        h_size = 1.5,
        filename = "man/figures/logo_option4.png",
        dpi = 300,
        white_around_sticker = FALSE
)

cat("✓ Created logo_option4.png - Pills/capsules theme (RECOMMENDED)\n\n")


# Option 5: Minimalist ATC Code Theme
# ====================================

# Create a clean, minimalist design with ATC code pattern
atc_text <- data.frame(
  label = c("A", "T", "C"),
  x = c(-0.5, 0, 0.5),
  y = c(0.2, 0.2, 0.2),
  size = c(20, 20, 20)
)

# Add DDD elements
ddd_bars <- data.frame(
  x = c(-0.6, -0.3, 0, 0.3, 0.6),
  height = c(0.3, 0.5, 0.4, 0.6, 0.35),
  fill = rep(c("#2a9d8f", "#264653"), length.out = 5)
)

p5 <- ggplot() +
  geom_col(data = ddd_bars, 
           aes(x = x, y = height, fill = fill),
           width = 0.15, alpha = 0.8) +
  geom_text(data = atc_text,
            aes(x = x, y = y - 0.4, label = label),
            size = 25, color = "#264653", fontface = "bold") +
  scale_fill_identity() +
  coord_fixed() +
  theme_void() +
  theme(
    legend.position = "none",
    plot.background = element_rect(fill = "transparent", color = NA),
    panel.background = element_rect(fill = "transparent", color = NA)
  )

sticker(p5,
        package = "atcddd",
        p_size = 20,
        p_color = "#264653",
        p_family = "roboto",
        p_y = 1.5,
        s_x = 1,
        s_y = 0.75,
        s_width = 1.4,
        s_height = 1.1,
        h_fill = "transparent",
        h_color = "#2a9d8f",
        h_size = 1.5,
        filename = "man/figures/logo_option5.png",
        dpi = 300,
        white_around_sticker = FALSE
)

cat("✓ Created logo_option5.png - Minimalist ATC text theme\n\n")


# Create a comparison HTML file
cat("\n===========================================\n")
cat("✓ ALL 5 LOGO OPTIONS CREATED WITH TRANSPARENT BACKGROUNDS!\n")
cat("===========================================\n\n")
cat("Files saved in: man/figures/\n\n")
cat("Logo options:\n")
cat("  1. logo_option1.png - Hierarchy bar chart (clean, data-focused)\n")
cat("  2. logo_option2.png - Molecular network (scientific, connected)\n")
cat("  3. logo_option3.png - Medical cross + data (healthcare focus)\n")
cat("  4. logo_option4.png - Pills/capsules (RECOMMENDED - clear pharma theme)\n")
cat("  5. logo_option5.png - Minimalist ATC text (simple, modern)\n\n")
cat("All logos now have TRANSPARENT backgrounds!\n")
cat("Perfect for use on any background color (white, dark, colored).\n\n")
cat("To use a logo, rename it to 'logo.png':\n")
cat("  Example: file.copy('man/figures/logo_option4.png', 'man/figures/logo.png', overwrite=TRUE)\n\n")
cat("Or update README.md to reference your chosen option.\n")
