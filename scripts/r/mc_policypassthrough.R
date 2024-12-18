# Este código replicará el modelo de traspaso de la tasa objetivo de Banxico a las tasas bancarias.
# Asumimos que el usuario tiene acceso a paquetes R como 'siebanxicor' e 'inegiR'.

# Librerías necesarias
library(siebanxicor)  # Para datos de Banxico
library(inegiR)       # Para indicadores de INEGI
library(tidyverse)    # Para manipulación y visualización de datos
library(lmtest)       # Para tests de modelo
library(sandwich)     # Para errores robustos

# Autenticación para API de INEGI y Banxico
inegi_token <- "446548c3-7b55-4b22-8430-ac8f251ea555"
setToken("86d02771fd6b64ce29912469f70d872cf666627201a5d7e819a82c452ae61289")

# Descargar datos de la tasa objetivo de Banxico
serie = getSeriesData("SF43783")
tasa_objetivo <- getSerieDataFrame(serie, "SF43783") %>%
  rename(fecha = date, tasa_objetivo = value)

# Descargar datos de tasas bancarias
# Tasas activas (crédito a empresas, consumo y vivienda)
# Nota: Se deben usar las series adecuadas según el código de Banxico
idSeries <- c("SF309747", "SF309944", "SF310078")  # Reemplazar con códigos correctos
series_bancarias  <- getSeriesData(idSeries)
tasas_bancarias_raw <- map_dfr(idSeries, ~{
  data <- getSerieDataFrame(series_bancarias, .x)
  data$serie <- .x  # Add the series identifier to the data
  return(data)
})
tasas_bancarias <- tasas_bancarias_raw %>%
  pivot_wider(
    names_from = serie,      # Use the "serie" column to create new columns
    values_from = value      # Use the "value" column for the data
  ) %>%
  rename(
    fecha = date,                   # Rename "date" to "fecha"
    credito_empresas = SF309747,    # Rename based on series identifiers
    credito_consumo = SF309944,
    credito_vivienda = SF310078
  )

# Descargar variables de control (actividad económica e inflación)
igae <- inegi_series(series = "737219", token = inegi_token) %>% #737221 anual
  rename(fecha = date, igae = values)  %>% 
  select(fecha, igae)

inflacion <- inegi_series(series = "910406", token = inegi_token) %>%
  rename(fecha = date, inflacion = values)  %>% 
  select(fecha, inflacion)

# Unir todas las variables en un solo dataframe
data <- tasa_objetivo %>%
  left_join(tasas_bancarias, by = "fecha") %>%
  left_join(igae, by = "fecha") %>%
  left_join(inflacion, by = "fecha") %>%
  drop_na()

# Crear variables de diferencias mensuales
data <- data %>%
  mutate(
    d_tasa_objetivo = tasa_objetivo - lag(tasa_objetivo),
    d_credito_empresas = credito_empresas - lag(credito_empresas),
    d_credito_consumo = credito_consumo - lag(credito_consumo),
    d_credito_vivienda = credito_vivienda - lag(credito_vivienda),
    d_igae = igae - lag(igae),
    d_inflacion = inflacion - lag(inflacion)
  ) %>%
  drop_na()

# Regresiones para cada segmento
# Modelo: d_tasa_bancaria ~ d_tasa_objetivo + controles
modelos <- list(
  empresas = lm(d_credito_empresas ~ d_tasa_objetivo + d_igae + d_inflacion, data = data),
  consumo = lm(d_credito_consumo ~ d_tasa_objetivo + d_igae + d_inflacion, data = data),
  vivienda = lm(d_credito_vivienda ~ d_tasa_objetivo + d_igae + d_inflacion, data = data)
)

# Resultados
resultados <- map(modelos, ~coeftest(.x, vcov. = vcovHC(.x, type = "HC1")))

# Imprimir resultados
resultados




# Load required libraries
library(tidyverse)      # For data manipulation
library(lmtest)         # For robust standard errors
library(sandwich)       # For heteroskedasticity-robust covariance matrices
library(fixest)         # For distributed lag models with fixed effects
library(car)            # For testing assumptions (e.g., Durbin-Watson)
library(data.table)     # For efficient data handling

# Step 1: Download and Prepare Data
# Assuming you have already downloaded the data as shown in your initial code

# Note: Replace `idSeries` with the correct series IDs for credit rates
# tasa_objetivo, tasas_bancarias, igae, inflacion already downloaded and prepared
# Combining all datasets into a single data frame

data <- tasa_objetivo %>%
  left_join(tasas_bancarias, by = "fecha") %>%
  left_join(igae, by = "fecha") %>%
  left_join(inflacion, by = "fecha") %>%
  drop_na() %>%
  mutate(
    d_tasa_objetivo = tasa_objetivo - lag(tasa_objetivo),
    d_credito_empresas = credito_empresas - lag(credito_empresas),
    d_credito_consumo = credito_consumo - lag(credito_consumo),
    d_credito_vivienda = credito_vivienda - lag(credito_vivienda),
    d_igae = igae - lag(igae),
    d_inflacion = inflacion - lag(inflacion)
  ) %>%
  drop_na()

# Step 2: Create Distributed Lag Terms
# Define the number of lags for the monetary policy variable
max_lag <- 12
for (k in 0:max_lag) {
  data[[paste0("lag_", k)]] <- lag(data$d_tasa_objetivo, k)
}

# Step 3: Define Regression Formulas for Distributed Lag Models
# Using dynamic terms for d_tasa_objetivo and control variables (d_igae, d_inflacion)
formula_lags_empresas <- as.formula(
  paste("d_credito_empresas ~ ", 
        paste(paste0("lag_", 0:max_lag), collapse = " + "), 
        "+ d_igae + d_inflacion")
)

formula_lags_consumo <- as.formula(
  paste("d_credito_consumo ~ ", 
        paste(paste0("lag_", 0:max_lag), collapse = " + "), 
        "+ d_igae + d_inflacion")
)

formula_lags_vivienda <- as.formula(
  paste("d_credito_vivienda ~ ", 
        paste(paste0("lag_", 0:max_lag), collapse = " + "), 
        "+ d_igae + d_inflacion")
)

# Step 4: Estimate Distributed Lag Models
# Using fixest for efficient regression with robust standard errors
dl_model_empresas <- feols(formula_lags_empresas, data = data)
dl_model_consumo <- feols(formula_lags_consumo, data = data)
dl_model_vivienda <- feols(formula_lags_vivienda, data = data)

# Step 5: Robust Standard Errors
# Cluster standard errors by time variable (e.g., monthly data)
summary_empresas <- summary(dl_model_empresas, cluster = "fecha")
summary_consumo <- summary(dl_model_consumo, cluster = "fecha")
summary_vivienda <- summary(dl_model_vivienda, cluster = "fecha")

# Step 6: Output Results
# Create a table with results for all models
etable(dl_model_empresas, dl_model_consumo, dl_model_vivienda, cluster = "fecha", tex = FALSE)

# Step 7: Diagnostic Tests
# Check for autocorrelation in residuals using Durbin-Watson test
dw_test_empresas <- durbinWatsonTest(residuals(dl_model_empresas))
dw_test_consumo <- durbinWatsonTest(residuals(dl_model_consumo))
dw_test_vivienda <- durbinWatsonTest(residuals(dl_model_vivienda))

# Print diagnostics
print(dw_test_empresas)
print(dw_test_consumo)
print(dw_test_vivienda)

# Step 8: Plotting Results (Optional)
# Visualize cumulative passthrough over lags
coefficients_empresas <- coef(dl_model_empresas)[1:(max_lag + 1)]
coefficients_consumo <- coef(dl_model_consumo)[1:(max_lag + 1)]
coefficients_vivienda <- coef(dl_model_vivienda)[1:(max_lag + 1)]

cumulative_effect_empresas <- cumsum(coefficients_empresas)
cumulative_effect_consumo <- cumsum(coefficients_consumo)
cumulative_effect_vivienda <- cumsum(coefficients_vivienda)

# Create a data frame for plotting
effects_df <- data.frame(
  Lag = 0:max_lag,
  Empresas = cumulative_effect_empresas,
  Consumo = cumulative_effect_consumo,
  Vivienda = cumulative_effect_vivienda
)

# Plot
effects_df %>%
  pivot_longer(cols = -Lag, names_to = "Credit_Type", values_to = "Effect") %>%
  ggplot(aes(x = Lag, y = Effect, color = Credit_Type)) +
  geom_line(size = 1) +
  labs(
    title = "Cumulative Passthrough Effects of Monetary Policy",
    x = "Lag (Months)",
    y = "Cumulative Effect",
    color = "Credit Type"
  ) +
  theme_minimal()

