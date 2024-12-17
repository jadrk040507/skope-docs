rm(list=ls())

library("siebanxicor")
library(dplyr)
library(purrr)
library(tidyr)

# Define your BANXICO API key
setToken(Sys.getenv("BANXICO_API"))

# Fetch the data using the specified series IDs
idSeries <- c("SF29656", "SF29654", "SF63528") 

# Get the data
series <- getSeriesData(idSeries, '2010-01-01')
reserves <- getSerieDataFrame(series, "SF29656")
asset <- getSerieDataFrame(series, "SF29654")
fx <-  getSerieDataFrame(series, "SF63528")

series.df <- reduce(list(reserves, asset, fx), full_join, by = "date")

colnames(series.df)[2:4] <- c("Reserva Internacional", "Activos Internacionales Totales", "Tipo de cambio")

# Ordena por fecha
series.df <- series.df %>%
  arrange(date)

# Rellena hacia abajo con el valor previo y hacia arriba con el siguiente (nearest neighbor)
series.df <- series.df %>%
  complete(date = seq(min(date), max(date), by = "1 day")) %>% # Asegura una secuencia completa de fechas
  fill(`Reserva Internacional`, `Activos Internacionales Totales`, `Tipo de cambio`, .direction = "downup") # Usa valores previos y siguientes para rellenar

# Filtra las fechas deseadas
series.df <- series.df %>%
  filter(date >= Sys.Date() - years(5))


# Specify the output directory and file name
write.csv(series.df, "scripts/data/mc_internationalreserves.csv", row.names = FALSE)
