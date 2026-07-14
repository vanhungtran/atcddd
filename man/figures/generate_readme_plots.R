# ── README Publication Plots — Rich Colour Edition ─────────────────
# Skills: r-beautiful-graphics (themes, colours, annotations)
#         getting-more-out-of-graphics (comparisons, layout, colour function)
#         r-graph-gallery (lollipop, heatmap, small multiples)
# ───────────────────────────────────────────────────────────────────

library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)
library(viridisLite)
devtools::load_all("c:/Users/tranh/OneDrive/Statistics/atcddd", quiet = TRUE)

# ── Load data ──────────────────────────────────────────────────────
ddd <- readr::read_csv(
  system.file("extdata", "WHO_ATC_DDD_2026-07-14.csv", package = "atcddd"),
  show_col_types = FALSE
)
cod <- readr::read_csv(
  system.file("extdata", "WHO_ATC_codes_2026-07-14.csv", package = "atcddd"),
  show_col_types = FALSE
)

# ── Rich colour palettes ───────────────────────────────────────────
# Inspired by Japanese colour harmony principles (saturated, balanced)
# and colour-blind safe sequential/discrete schemes

# Lollipop gradient: from deep indigo through teal to warm gold
lollipop_colors <- c(
  "#0D0887FF", "#47039FFF", "#7301A8FF",
  "#9C179EFF", "#BD3786FF", "#D8576BFF",
  "#ED7953FF", "#FA9E3BFF", "#FDC328FF", "#F0F921FF"
)

# Warm sequential for hierarchy pyramid (amber → ruby)
pyramid_colors <- c(
  "#FCCF6CFF", "#F9B45BFF", "#F5994BFF",
  "#EF7D3BFF", "#E8612CFF", "#DE441EFF", "#D22211FF"
)

# Categorical palette for administration routes (colour-blind safe)
route_palette <- c(
  "Oral"        = "#0077BB",  # cerulean
  "Parenteral"  = "#EE7733",  # orange
  "Rectal"      = "#CC3311",  # vermillion
  "Sublingual"  = "#33BBEE",  # cyan
  "Transdermal" = "#009988",  # teal
  "Inhalation"  = "#BBBBBB",  # grey
  "Nasal"       = "#EE3377",  # magenta
  "Vaginal"     = "#AA3377",  # purple
  "Implant"     = "#882255"   # wine
)

# ── Unified elegant theme ──────────────────────────────────────────
theme_readme <- function(base_size = 13) {
  theme_minimal(base_size = base_size) %+replace%
    theme(
      plot.title         = element_text(face = "bold", hjust = 0.5, size = rel(1.4), margin = margin(b = 4)),
      plot.subtitle      = element_text(hjust = 0.5, color = "grey45", size = rel(0.95), margin = margin(b = 12)),
      plot.caption       = element_text(color = "grey55", size = rel(0.7), hjust = 1, margin = margin(t = 8)),
      plot.background    = element_rect(fill = "white", color = NA),
      panel.grid.major.x = element_line(color = "grey92", linewidth = 0.4),
      panel.grid.major.y = element_blank(),
      panel.grid.minor   = element_blank(),
      axis.title         = element_text(size = rel(0.88), color = "grey35"),
      axis.text          = element_text(size = rel(0.82), color = "grey35"),
      axis.ticks         = element_blank(),
      legend.position    = "bottom",
      legend.text        = element_text(size = rel(0.78)),
      legend.title       = element_text(size = rel(0.82)),
      plot.margin        = margin(15, 18, 10, 14)
    )
}

grp_names <- c(
  A = "Alimentary tract", B = "Blood", C = "Cardiovascular",
  D = "Dermatologicals", G = "Genito-urinary", H = "Hormonal",
  J = "Anti-infectives", L = "Anti-neoplastic", M = "Musculo-skeletal",
  N = "Nervous system", P = "Anti-parasitic", R = "Respiratory",
  S = "Sensory organs", V = "Various"
)

outdir <- "man/figures"

# ═══════════════════════════════════════════════════════════════════
# PLOT 1: Lollipop — DDD Coverage by Anatomical Group
# ═══════════════════════════════════════════════════════════════════
ddd_group <- ddd %>%
  mutate(group = substr(atc_code, 1, 1)) %>%
  group_by(group) %>%
  summarise(
    total    = n_distinct(atc_code),
    with_ddd = n_distinct(atc_code[!is.na(ddd) & ddd != "NA"]),
    .groups  = "drop"
  ) %>%
  mutate(
    pct        = round(100 * with_ddd / total, 1),
    group_name = grp_names[group]
  )

# Colour by pct value using a rich gradient
p1 <- ddd_group %>%
  mutate(pct_rank = rank(pct)) %>%
  ggplot(aes(x = reorder(group_name, pct), y = pct)) +
  geom_segment(aes(xend = reorder(group_name, pct), yend = 0, colour = pct),
               linewidth = 1.6, alpha = 0.75) +
  geom_point(aes(colour = pct), size = 5) +
  geom_text(aes(label = paste0(pct, "%")),
            hjust = -0.5, size = 3.8, fontface = "bold", color = "grey25") +
  scale_colour_gradientn(colours = rev(lollipop_colors), guide = "none") +
  scale_y_continuous(limits = c(0, 110), expand = c(0, 0),
                     breaks = seq(0, 100, 20)) +
  coord_flip() +
  labs(
    title    = "How many drugs have a Defined Daily Dose?",
    subtitle = "Percentage of Level-5 substances with an assigned DDD, by anatomical group",
    x = NULL, y = "Drugs with DDD (%)",
    caption = "Data: WHO ATC/DDD Index 2025"
  ) +
  theme_readme() +
  theme(
    legend.position    = "none",
    panel.grid.major.y = element_line(color = "grey90", linewidth = 0.3),
    panel.grid.major.x = element_line(color = "grey92", linewidth = 0.3)
  )

ggsave(file.path(outdir, "readme-ddd-coverage.png"), p1, width = 10, height = 7, dpi = 200, bg = "white")
cat("1/4: readme-ddd-coverage.png\n")

# ═══════════════════════════════════════════════════════════════════
# PLOT 2: ATC Hierarchy Horizontal Bars — Gradient focal bars
# ═══════════════════════════════════════════════════════════════════
level_names <- c(
  "1" = "Level 1\nAnatomical main groups",
  "2" = "Level 2\nTherapeutic subgroups",
  "3" = "Level 3\nPharmacological subgroups",
  "4" = "Level 4\nChemical subgroups",
  "5" = "Level 5\nChemical substances"
)

code_dist <- cod %>%
  mutate(level = atc_level(atc_code)) %>%
  filter(!is.na(level)) %>%
  count(level) %>%
  mutate(
    level_label = level_names[as.character(level)],
    pct = round(100 * n / sum(n), 1),
    pct_label = paste0(pct, "%")
  ) %>%
  mutate(level_label = factor(level_label, levels = rev(level_names)))

p2 <- code_dist %>%
  ggplot(aes(x = level_label, y = n)) +
  geom_col(aes(fill = n), width = 0.7) +
  geom_text(aes(label = paste0(comma(n), " (", pct_label, ")")),
            hjust = -0.08, size = 4, fontface = "bold", color = "grey20") +
  scale_fill_gradientn(colours = pyramid_colors, guide = "none") +
  scale_y_continuous(limits = c(0, max(code_dist$n) * 1.3), labels = comma) +
  coord_flip() +
  labs(
    title    = "How the ATC tree fans out",
    subtitle = paste0(comma(nrow(cod)), " codes across 5 hierarchy levels"),
    x = NULL, y = "Number of ATC Codes",
    caption = "Data: WHO ATC/DDD Index 2025"
  ) +
  theme_readme() +
  theme(
    panel.grid.major.y = element_line(color = "grey90", linewidth = 0.3),
    panel.grid.major.x = element_blank()
  )

ggsave(file.path(outdir, "readme-atc-pyramid.png"), p2, width = 10, height = 6, dpi = 200, bg = "white")
cat("2/4: readme-atc-pyramid.png\n")


# ═══════════════════════════════════════════════════════════════════
# PLOT 3: Small Multiples — DDD by Route for Multi-Route Drugs
# ═══════════════════════════════════════════════════════════════════
multi_route_drugs <- ddd %>%
  filter(!is.na(ddd) & ddd != "NA", !is.na(adm_r), adm_r != "NA", adm_r != "") %>%
  count(atc_code, sort = TRUE) %>%
  filter(n >= 3) %>%
  slice_head(n = 8)

ddroutes <- ddd %>%
  semi_join(multi_route_drugs, by = "atc_code") %>%
  filter(!is.na(ddd) & ddd != "NA", !is.na(adm_r)) %>%
  mutate(
    ddd_num     = as.numeric(ddd),
    route_label = case_when(
      adm_r == "O"      ~ "Oral",
      adm_r == "P"      ~ "Parenteral",
      adm_r == "R"      ~ "Rectal",
      adm_r == "SL"     ~ "Sublingual",
      adm_r == "TD"     ~ "Transdermal",
      adm_r == "Inhal"  ~ "Inhalation",
      adm_r == "N"      ~ "Nasal",
      adm_r == "V"      ~ "Vaginal",
      adm_r == "Implant" ~ "Implant",
      TRUE ~ adm_r
    ),
    drug_label = paste0(atc_code, "\n", tolower(atc_name))
  ) %>%
  group_by(atc_code) %>%
  mutate(ddd_rank = dense_rank(desc(ddd_num))) %>%
  ungroup()

p3 <- ddroutes %>%
  ggplot(aes(x = reorder(route_label, ddd_num), y = ddd_num)) +
  geom_col(aes(fill = route_label), width = 0.7, alpha = 0.92) +
  geom_text(aes(label = paste0(ddd_num, " ", uom)),
            vjust = -0.35, size = 2.4, fontface = "bold", color = "grey30") +
  scale_fill_manual(values = route_palette, guide = "none") +
  facet_wrap(~ drug_label, scales = "free_y", ncol = 4) +
  labs(
    title    = "DDD values differ by administration route",
    subtitle = "Same drug, different routes — different Defined Daily Doses",
    x = NULL, y = "DDD value",
    caption = "Data: WHO ATC/DDD Index 2025"
  ) +
  theme_readme(11) +
  theme(
    axis.text.x  = element_text(angle = 35, hjust = 1, size = rel(0.65), color = "grey30"),
    axis.text.y  = element_text(size = rel(0.65), color = "grey40"),
    axis.title.y = element_text(size = rel(0.75)),
    strip.text   = element_text(face = "bold", size = rel(0.7), color = "grey15",
                                margin = margin(4, 2, 3, 2)),
    panel.spacing = unit(0.5, "lines"),
    panel.grid.major.y = element_line(color = "grey90", linewidth = 0.3)
  )

ggsave(file.path(outdir, "readme-ddd-routes.png"), p3, width = 12, height = 7.5, dpi = 200, bg = "white")
cat("3/4: readme-ddd-routes.png\n")


# ═══════════════════════════════════════════════════════════════════
# PLOT 4: Heatmap — DDD Coverage × Route Across Groups
# ═══════════════════════════════════════════════════════════════════
route_groups <- ddd %>%
  filter(!is.na(adm_r), adm_r != "NA", adm_r != "") %>%
  mutate(
    group   = substr(atc_code, 1, 1),
    has_ddd = !is.na(ddd) & ddd != "NA"
  ) %>%
  group_by(group, adm_r) %>%
  summarise(
    n_total = n(),
    n_with  = sum(has_ddd),
    pct     = round(100 * sum(has_ddd) / n(), 1),
    .groups = "drop"
  ) %>%
  filter(n_total >= 5) %>%
  mutate(
    group_name  = grp_names[group],
    route_label = case_when(
      adm_r == "O"     ~ "Oral",
      adm_r == "P"     ~ "Parenteral",
      adm_r == "R"     ~ "Rectal",
      adm_r == "SL"    ~ "Sublingual",
      adm_r == "TD"    ~ "Transdermal",
      adm_r == "Inhal" ~ "Inhalation",
      adm_r == "N"     ~ "Nasal",
      adm_r == "V"     ~ "Vaginal",
      TRUE ~ adm_r
    )
  ) %>%
  mutate(
    route_label = factor(route_label, levels = c(
      "Oral", "Parenteral", "Rectal", "Inhalation",
      "Nasal", "Transdermal", "Sublingual", "Vaginal"
    )),
    # Text colour: white on dark tiles, dark on light tiles
    txt_col = ifelse(pct > 50, "white", "grey20"),
    pct_label = ifelse(pct >= 1, paste0(pct, "%"), "<1%")
  )

# Rich divergent heatmap palette: dark teal → gold → rust
heatmap_colors <- c(
  "#0C2D48FF", "#113B5EFF", "#1A4B72FF",
  "#2B6A96FF", "#4086B3FF", "#5CA2C2FF",
  "#7DB9CFFF", "#A1CFDAFF", "#C5E3E5FF",
  "#E8F2EFFF", "#FAD980FF", "#F4A85BFF",
  "#E67C3DFF", "#CE582EFF", "#B13D26FF"
)

p4 <- route_groups %>%
  filter(!is.na(route_label)) %>%
  ggplot(aes(x = route_label, y = reorder(group_name, desc(group_name)))) +
  geom_tile(aes(fill = pct), color = "white", linewidth = 1.4) +
  geom_text(aes(label = pct_label, colour = txt_col),
            size = 3.5, fontface = "bold") +
  scale_fill_gradientn(colours = heatmap_colors,
                       na.value = "grey95",
                       name = "% with DDD",
                       guide = guide_colorbar(
                         barwidth = 14, barheight = 0.6,
                         title.position = "top", title.hjust = 0.5,
                         frame.colour = "grey50", ticks.colour = "grey50"
                       )) +
  scale_colour_identity(guide = "none") +
  labs(
    title    = "Which drug classes have DDDs — and by which route?",
    subtitle = "DDD coverage (%) by anatomical group and administration route",
    x = NULL, y = NULL,
    caption = "Data: WHO ATC/DDD Index 2025"
  ) +
  theme_readme(12) +
  theme(
    legend.position  = "bottom",
    panel.grid       = element_blank(),
    axis.text.x      = element_text(angle = 30, hjust = 1, size = rel(0.9),
                                    color = "grey25", face = "bold"),
    axis.text.y      = element_text(size = rel(0.88), color = "grey25"),
    plot.background  = element_rect(fill = "white", color = NA)
  )

ggsave(file.path(outdir, "readme-ddd-heatmap.png"), p4, width = 11, height = 7, dpi = 200, bg = "white")
cat("4/4: readme-ddd-heatmap.png\n")

cat("\n═══════════════════════════════════════════\n")
cat("All 4 README plots regenerated with rich colour palettes:\n")
cat("  1. readme-ddd-coverage.png  — Viridis gradient lollipop\n")
cat("  2. readme-atc-pyramid.png   — Amber→ruby sequential bars\n")
cat("  3. readme-ddd-routes.png    — Tol colour-blind categorical routes\n")
cat("  4. readme-ddd-heatmap.png   — Teal→gold→rust divergent tiles\n")
cat("═══════════════════════════════════════════\n")
