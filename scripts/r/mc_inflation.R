rm(list = ls())

# Load the necessary libraries
library(inegiR)
library(dplyr)
library(tidyr)

# Define your INEGI API key
inegi.api = Sys.getenv("INEGI_API")

# Fetch the data using the specified series IDs
idSeries <- c("910406", "910407", "910410")  # Your INEGI series IDs

# Get the data
series <- inegi_series_multiple(series = idSeries, token = inegi.api)

# Transform the data
series.wide <- series %>%
  select(date, values, meta_indicatorid) %>%  
  pivot_wider(names_from = meta_indicatorid, values_from = values) %>%
  rename(
    date = date,
    'Inflación general' = '910406',
    'Subyacente' = '910407',
    'No subyacente' = '910410') %>% 
  filter(date >= '2012-01-01')

# Specify the output directory and file name
write.csv(series.wide, "scripts/data/mc_inflation.csv", row.names = FALSE)


# Create plots
library(ggplot2)
library(ggthemes)
library(showtext)
library(scales)
library(plotly)

series.long <- series.wide %>% 
  pivot_longer(cols = -date, names_to = "Index", values_to = "Value")

font_add_google("Rubik", "Rubik")
showtext_auto()
showtext_opts(dpi = 600)


ggplot(series.long, aes(date, Value, color = Index)) +
  geom_line(linewidth = 1) +
  labs(
    title = "Tasa de inflación anual en México por sus componentes",
    subtitle = "Tasas en %",
    x = "",
    y = "",
    color = ""
  ) +
  scale_x_date(
    date_breaks = "2 years",
    date_labels = "%Y",
    expand = c(0, 0)
  ) +
  scale_y_continuous(
    labels = scales::percent_format(scale = 1),
    expand = c(0, 0)
  ) +
  theme_fivethirtyeight() +
  theme(
    text = element_text(family = "Rubik"),
    legend.title = element_blank(),
    # plot.title = element_text(size = 16),        # Tamaño del título
    # plot.subtitle = element_text(size = 14),    # Tamaño del subtítulo
    # axis.title.x = element_text(size = 12),     # Tamaño del título del eje X
    # axis.title.y = element_text(size = 12),     # Tamaño del título del eje Y
    # axis.text.x = element_text(size = 10),      # Tamaño de las etiquetas del eje X
    # axis.text.y = element_text(size = 10),      # Tamaño de las etiquetas del eje Y
    legend.background = element_blank(),           # Removes the background color of the entire plot
    panel.background = element_blank(),           # Removes the background color of the entire plot
    plot.background = element_blank()           # Removes the background color of the entire plot
      ) +
  scale_color_economist()

ggsave("scripts/plots/mc_inflation.png", width = 6, height = 6, dpi = 600)


  