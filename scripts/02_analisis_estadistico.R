library(readr)
library(tidyr)
library(dplyr)
library(ggplot2)
library(mapSpain)
library(sf)

#Registrar Times New Roman
windowsFonts(TNR = windowsFont("Times New Roman"))

#1. Importación de las bases de datos
dataset_vivienda <- read_csv("data/processed/dataset_vivienda.csv")
dataset_renta <- read_csv("data/processed/dataset_renta.csv")

#2. Comprobación inicial de las bases
dim(dataset_vivienda)
dim(dataset_renta)

names(dataset_vivienda)
names(dataset_renta)

str(dataset_vivienda)
str(dataset_renta)

#3. Comprobación de valores ausentes
colSums(is.na(dataset_vivienda))
colSums(is.na(dataset_renta))

#4. Análisis descriptivo del valor tasado de la vivienda
#4.1. Valor tasado medio anual de cada provincia
vivienda_comparacion <- dataset_vivienda %>%
  filter(año %in% c(2020, 2025)) %>%
  group_by(provincia, año) %>%
  summarise(
    precio_medio_anual = mean(precio_m2)
  )

#4.2 Estadísticos de los valores medios anuales provinciales
tabla_precio <- vivienda_comparacion %>%
  group_by(año) %>%
  summarise(
    `Número de territorios` = n(),
    `Media (€/m²)` = mean(precio_medio_anual),
    `Mediana (€/m²)` = median(precio_medio_anual),
    `Desviación típica (€/m²)` = sd(precio_medio_anual),
    `Mínimo (€/m²)` = min(precio_medio_anual),
    `Primer cuartil (€/m²)` = quantile(precio_medio_anual, 0.25),
    `Tercer cuartil (€/m²)` = quantile(precio_medio_anual, 0.75),
    `Máximo (€/m²)` = max(precio_medio_anual),
    `Rango intercuartílico (€/m²)` = IQR(precio_medio_anual),
    `Coeficiente de variación (%)` =
      sd(precio_medio_anual) / mean(precio_medio_anual) * 100
  )
print(vivienda_comparacion, n = Inf, width = Inf)


#Transponer,redondear y nombrar las columnas
tabla_preciov <- round(t(as.matrix(tabla_precio[, -1])), 2)
colnames(tabla_preciov) <- as.character(tabla_precio$año)
View(tabla_preciov)

#4.3 Comparación del valor tasado medio anual
par(family = "TNR")
boxplot(precio_medio_anual ~ año,
        data = vivienda_comparacion,
        main = "Valor tasado medio anual de la vivienda libre",
        xlab = "Año",
        ylab = "Valor tasado (€/m²)",
        col = c("lightblue", "steelblue4"), 
        family="TNR")



#Calcular el valor tasado medio de cada año
medias_vivienda <- vivienda_comparacion %>%
  group_by(año) %>%
  summarise(media = mean(precio_medio_anual)) %>%
  arrange(año)

#Añadir las medias como cruces rojas
points(x = 1:2,
       y = medias_vivienda$media,
       pch = 4,
       col = "red",
       cex = 1,
       lwd = 3)

#Añadir una leyenda
legend("topleft",
       legend = "Media",
       pch = 4,
       col = "red",
       pt.cex = 1,
       pt.lwd = 3,
       cex = 1,
       bty = "n")

#Comprobar valores atípicos extremos 
extremos_vivienda <- vivienda_comparacion %>%
  group_by(año) %>%
  mutate(
    limite_inferior = quantile(precio_medio_anual, 0.25) -
      3 * IQR(precio_medio_anual),
    limite_superior = quantile(precio_medio_anual, 0.75) +
      3 * IQR(precio_medio_anual)
  ) %>%
  filter(
    precio_medio_anual < limite_inferior |
      precio_medio_anual > limite_superior
  ) %>%
  select(año, provincia, precio_medio_anual,
         limite_inferior, limite_superior)

print(extremos_vivienda, width = Inf)
#4.4 Variación del valor tasado medio anual por provincia 
#Seleccionar las medias anuales de 2020
precio_2020 <- vivienda_comparacion %>%
  filter(año == 2020) %>%
  select(provincia, precio_2020 = precio_medio_anual)

#Seleccionar las medias anuales de 2025
precio_2025 <- vivienda_comparacion %>%
  filter(año == 2025) %>%
  select(provincia, precio_2025 = precio_medio_anual)

#Unir los valores de cada provincia y calcular el crecimiento
crecimiento_precio <- precio_2020 %>%
  left_join(precio_2025, by = "provincia") %>%
  mutate(
    variacion_porcentaje =
      (precio_2025 - precio_2020) / precio_2020 * 100
  )

#Mostrar las provincias de mayor a menor crecimiento
crecimiento_precio %>%
  arrange(desc(variacion_porcentaje))

#Resumen de los crecimientos provinciales
summary(crecimiento_precio$variacion_porcentaje)

#Número de territorios donde aumenta el valor tasado
sum(crecimiento_precio$variacion_porcentaje > 0)

#Número de territorios donde disminuye
sum(crecimiento_precio$variacion_porcentaje < 0)

#Número de territorios donde no cambia
sum(crecimiento_precio$variacion_porcentaje == 0)

#Histograma del análisis univariante del crecimiento provincial
par(family = "TNR")

hist(crecimiento_precio$variacion_porcentaje,
     main = "Distribución del crecimiento provincial: 2020–2025",
     xlab = "Variación acumulada del valor tasado (%)",
     ylab = "Número de territorios",
     col = "lightblue",
     border = "white")


#4.5 Mapa del crecimiento provincial entre 2020 y 2025

#Obtener los códigos y convertirlos a número
codigos <- dataset_vivienda %>%
  filter(año == 2020, trimestre == 1) %>%
  select(provincia, codigo_provincia) %>%
  mutate(codigo_provincia = as.numeric(codigo_provincia))

#Unir el mapa con los códigos y los crecimientos
mapa <- esp_get_prov() %>%
  mutate(codigo_provincia = as.numeric(cpro)) %>%
  left_join(codigos, by = "codigo_provincia") %>%
  left_join(crecimiento_precio, by = "provincia")

#Comprobar que no faltan datos
sum(is.na(mapa$variacion_porcentaje))


#Dibujar el mapa
ggplot(mapa) +
  geom_sf(aes(fill = variacion_porcentaje), colour = "white") +
  scale_fill_viridis_c(name = "Crecimiento (%)") +
  labs(
    title = "Crecimiento del valor tasado de la vivienda libre",
    subtitle = "Variación nominal de las medias anuales: 2020–2025"
  ) +
  theme_void(base_family = "TNR")

#4.6 Selección de los territorios con mayor y menor crecimiento

#Tres territorios con mayor crecimiento
mayor_crecimiento <- crecimiento_precio %>%
  ungroup() %>%
  arrange(desc(variacion_porcentaje)) %>%
  slice(1:3)

#Tres territorios con menor crecimiento
menor_crecimiento <- crecimiento_precio %>%
  ungroup() %>%
  arrange(variacion_porcentaje) %>%
  slice(1:3)

#Mostrar los resultados
print(mayor_crecimiento, width = Inf)
print(menor_crecimiento, width = Inf)

#4.7 Evolución trimestral de las provincias seleccionadas

#Seleccionar los datos trimestrales de las seis provincias
evolucion_seleccionadas <- dataset_vivienda %>%
  filter(provincia %in% c(mayor_crecimiento$provincia, menor_crecimiento$provincia)) %>%
  select(provincia, año, trimestre, precio_m2) %>%
  arrange(provincia, año, trimestre) %>%
  mutate(
    tiempo = año + (trimestre - 1) / 4
  )

#Mostrar la tabla
evolucion_seleccionadas

#Identificar el grupo de cada provincia
evolucion_seleccionadas <- evolucion_seleccionadas %>%
  mutate(
    grupo = ifelse(
      provincia %in% mayor_crecimiento$provincia,
      "Mayor crecimiento",
      "Menor crecimiento"
    )
  )

#Representar los dos paneles juntos
ggplot(evolucion_seleccionadas,
       aes(x = tiempo, y = precio_m2, colour = provincia)) +
  geom_line() +
  facet_wrap(~ grupo, ncol = 2,
             axes = "all", axis.labels = "all") +
  scale_x_continuous(breaks = 2020:2026) +
  scale_y_continuous(breaks = seq(0, 5000, by = 250)) +
  labs(
    title = "Evolución trimestral del valor tasado de la vivienda libre",
    subtitle = "Selección según la variación de las medias anuales de 2020 a 2025",
    x = "Año",
    y = "Valor tasado (€/m²)",
    colour = "Provincia"
  ) +
  theme_minimal(base_family = "TNR") +
  theme(
    axis.line = element_line(colour = "black"),
    axis.ticks = element_line(colour = "black")
  )

#5. Análisis descriptivo de la renta media por hogar
#5.1. Selección de los años de comparación
renta_comparacion <- dataset_renta %>%
  filter(año %in% c(2020, 2024))

#5.2. Estadísticos de la renta media por hogar provincial
tabla_renta <- renta_comparacion %>%
  group_by(año) %>%
  summarise(
    `Número de territorios` = n(),
    `Media (€)` = mean(renta_media_hogar),
    `Mediana (€)` = median(renta_media_hogar),
    `Desviación típica (€)` = sd(renta_media_hogar),
    `Mínimo (€)` = min(renta_media_hogar),
    `Primer cuartil (€)` = quantile(renta_media_hogar, 0.25),
    `Tercer cuartil (€)` = quantile(renta_media_hogar, 0.75),
    `Máximo (€)` = max(renta_media_hogar),
    `Rango intercuartílico (€)` = IQR(renta_media_hogar),
    `Coeficiente de variación (%)` =
      sd(renta_media_hogar) / mean(renta_media_hogar) * 100
  )

#Transponer, redondear y nombrar las columnas
tabla_rentav <- round(t(as.matrix(tabla_renta[, -1])), 2)
colnames(tabla_rentav) <- as.character(tabla_renta$año)
View(tabla_rentav)

#5.3. Comparación de la distribución de la renta media por hogar
par(family = "TNR")

boxplot(renta_media_hogar ~ año,
        data = renta_comparacion,
        main = "Distribución provincial de la renta media por hogar",
        xlab = "Año",
        ylab = "Renta media por hogar (€)",
        col = c("lightblue", "steelblue4"))

#Calcular la renta media de cada año
medias_renta <- renta_comparacion %>%
  group_by(año) %>%
  summarise(media = mean(renta_media_hogar)) %>%
  arrange(año)

#Añadir las medias
points(x = 1:2,
       y = medias_renta$media,
       pch = 4,
       col = "red",
       cex = 1,
       lwd = 3)

#Añadir una leyenda
legend("topleft",
       legend = "Media",
       pch = 4,
       col = "red",
       pt.cex = 1,
       pt.lwd = 3,
       cex = 1,
       bty = "n")

#5.4. Distribución territorial de la renta media por hogar en 2024

#Seleccionar la renta de 2024
renta_2024 <- dataset_renta %>%
  filter(año == 2024) %>%
  select(provincia, renta_media_hogar)

#Unir la renta al mapa provincial
mapa_renta <- esp_get_prov() %>%
  mutate(codigo_provincia = as.numeric(cpro)) %>%
  left_join(codigos, by = "codigo_provincia") %>%
  left_join(renta_2024, by = "provincia")

#Comprobar que no faltan datos
sum(is.na(mapa_renta$renta_media_hogar))

#Dibujar el mapa
ggplot(mapa_renta) +
  geom_sf(aes(fill = renta_media_hogar), colour = "white") +
  scale_fill_gradient(name = "Renta media\npor hogar (€)",low = "#EDF8E9",high = "#006D2C"
  ) +
  labs(
    title = "Renta media por hogar por provincia",
    subtitle = "Año 2024"
  ) +
  theme_void(base_family = "TNR")

#6.Análisis univariante de la población
#6.1.Comprobación de los datos

#Comprobar que la base contiene las variables necesarias
names(dataset_vivienda)

#Seleccionar el primer trimestre de 2020 y 2024
poblacion_comparacion <- dataset_vivienda %>%
  filter(año %in% c(2020, 2024), trimestre == 1) %>%
  select(codigo_provincia, provincia, año, trimestre, poblacion)

#Comprobar el número de observaciones
dim(poblacion_comparacion)

#Comprobar valores ausentes
colSums(is.na(poblacion_comparacion))

#Comprobar si hay registros duplicados por territorio y año
poblacion_comparacion %>%
  count(codigo_provincia, año) %>%
  filter(n > 1)

#Consultar los datos seleccionados
print(poblacion_comparacion, n = Inf, width = Inf)

#6.2.Calcular la variación (%) de la población
crecimiento_poblacion <- poblacion_comparacion %>%
  select(codigo_provincia, provincia, año, poblacion) %>%
  pivot_wider(
    names_from = año,
    values_from = poblacion,
    names_prefix = "poblacion_"
  ) %>%
  mutate(
    variacion_poblacion =
      (poblacion_2024 - poblacion_2020) / poblacion_2020 * 100
  ) %>%
  arrange(desc(variacion_poblacion))

#Mostrar el crecimiento de cada territorio
print(crecimiento_poblacion, n = Inf, width = Inf)

#Resumen estadístico de las variaciones
summary(crecimiento_poblacion$variacion_poblacion)

#Identificar los cinco territorios con mayor crecimiento
head(crecimiento_poblacion, 5)

#Identificar los cinco territorios con menor crecimiento
tail(crecimiento_poblacion, 5)

#6.3.Gráfico de la variación (%) de la población
grafico_poblacion <- ggplot(
  crecimiento_poblacion,
  aes(
    x = reorder(provincia, variacion_poblacion),
    y = variacion_poblacion
  )
) +
  geom_col(aes(fill = variacion_poblacion >= 0)) +
  geom_hline(yintercept = 0, colour = "black", linewidth = 0.4) +
  coord_flip() +
  scale_fill_manual(
    values = c("TRUE" = "steelblue4", "FALSE" = "indianred3"),
    labels = c("TRUE" = "Aumento", "FALSE" = "Disminución"),
    name = "Evolución"
  ) +
  labs(
    title = NULL,
    x = "Territorio",
    y = "Variación de la población (%)"
  ) +
  theme_minimal(base_family = "TNR") +
  theme(
    axis.title.x = element_text(face = "bold"),
    axis.title.y = element_text(face = "bold"),
    axis.text.y = element_text(size = 7),
    legend.position = "bottom"
  )

print(grafico_poblacion)

#Desviación típica de las variaciones de población
sd(crecimiento_poblacion$variacion_poblacion, na.rm = TRUE)


#7. Análisis bivariante de la renta y valor tasado de la vivienda
#7.1. Preparación de los datos de 2020 y 2024

#Calcular el valor tasado medio anual por provincia
vivienda_relacion <- dataset_vivienda %>%
  filter(año %in% c(2020, 2024)) %>%
  group_by(provincia, año) %>%
  summarise(
    precio_medio_anual = mean(precio_m2),
    .groups = "drop"
  )

#Seleccionar la renta de los mismos años
renta_relacion <- dataset_renta %>%
  filter(año %in% c(2020, 2024))

#Unir por provincia y año
relacion_renta_vivienda <- vivienda_relacion %>%
  left_join(renta_relacion, by = c("provincia", "año"))

#Separar los años
relacion_2020 <- relacion_renta_vivienda %>%
  filter(año == 2020)

relacion_2024 <- relacion_renta_vivienda %>%
  filter(año == 2024)

#7.2 Modelos de regresión lineal
modelo_2020 <- lm(
  precio_medio_anual ~ renta_media_hogar,
  data = relacion_2020
)

modelo_2024 <- lm(
  precio_medio_anual ~ renta_media_hogar,
  data = relacion_2024
)

#7.3. Diagramas de dispersión con rectas de regresión

#Límites comunes para ambos gráficos
limites_x <- range(relacion_renta_vivienda$renta_media_hogar)
limites_y <- range(relacion_renta_vivienda$precio_medio_anual)

#Dividir la ventana gráfica en dos paneles
par(mfrow = c(1, 2), family = "TNR")

#Año 2020
plot(
  relacion_2020$renta_media_hogar,
  relacion_2020$precio_medio_anual,
  main = "Renta y vivienda (2020)",
  xlab = "Renta media por hogar (€)",
  ylab = "Valor tasado medio anual (€/m²)",
  xlim = limites_x,
  ylim = limites_y,
  pch = 19,
  col = "steelblue4"
)

#Dibujar la recta dentro del intervalo observado
limites_2020 <- data.frame(
  renta_media_hogar = range(relacion_2020$renta_media_hogar)
)

lines(
  limites_2020$renta_media_hogar,
  predict(modelo_2020, newdata = limites_2020),
  col = "red",
  lwd = 2
)

#Año 2024
plot(
  relacion_2024$renta_media_hogar,
  relacion_2024$precio_medio_anual,
  main = "Renta y vivienda (2024)",
  xlab = "Renta media por hogar (€)",
  ylab = "Valor tasado medio anual (€/m²)",
  xlim = limites_x,
  ylim = limites_y,
  pch = 19,
  col = "steelblue4"
)

limites_2024 <- data.frame(
  renta_media_hogar = range(relacion_2024$renta_media_hogar)
)

lines(
  limites_2024$renta_media_hogar,
  predict(modelo_2024, newdata = limites_2024),
  col = "red",
  lwd = 2
)

#Volver a mostrar un solo gráfico por ventana
par(mfrow = c(1, 1))

#Detectar valores atípicos extremos de renta
extremos_renta <- renta_comparacion %>%
  group_by(año) %>%
  mutate(
    limite_inferior = quantile(renta_media_hogar, 0.25) -
      3 * IQR(renta_media_hogar),
    limite_superior = quantile(renta_media_hogar, 0.75) +
      3 * IQR(renta_media_hogar)
  ) %>%
  filter(
    renta_media_hogar < limite_inferior |
      renta_media_hogar > limite_superior
  ) %>%
  select(año, provincia, renta_media_hogar,
         limite_inferior, limite_superior)

print(extremos_renta, width = Inf)

#7.4. Comparación de las correlaciones de Pearson
tabla_correlaciones <- relacion_renta_vivienda %>%
  group_by(año) %>%
  summarise(
    correlacion = cor(
      renta_media_hogar,
      precio_medio_anual,
      method = "pearson")
  )

View(tabla_correlaciones)

#8. Comparación del crecimiento de la vivienda y de la renta
#Seleccionar los valores iniciales
datos_2020 <- relacion_2020 %>%
  select(
    provincia,
    precio_2020 = precio_medio_anual,
    renta_2020 = renta_media_hogar
  )

#Seleccionar los valores finales
datos_2024 <- relacion_2024 %>%
  select(
    provincia,
    precio_2024 = precio_medio_anual,
    renta_2024 = renta_media_hogar
  )

#Calcular las variaciones y su diferencia
comparacion_crecimientos <- datos_2020 %>%
  left_join(datos_2024, by = "provincia") %>%
  mutate(
    crecimiento_vivienda =
      (precio_2024 - precio_2020) / precio_2020 * 100,
    crecimiento_renta =
      (renta_2024 - renta_2020) / renta_2020 * 100,
    diferencia_pp = crecimiento_vivienda - crecimiento_renta
  )

#Resumen de las diferencias
summary(comparacion_crecimientos$diferencia_pp)

#Número de territorios donde crece más la vivienda
sum(comparacion_crecimientos$diferencia_pp > 0)

#Número de territorios donde crece más la renta
sum(comparacion_crecimientos$diferencia_pp < 0)

#Mostrar los resultados ordenados
comparacion_crecimientos %>%
  arrange(desc(diferencia_pp))

#8.1 Representar la diferencia entre ambos crecimientos
#Seleccionar las diez diferencias más altas
diferencias_altas <- comparacion_crecimientos %>%
  ungroup() %>%
  arrange(desc(diferencia_pp)) %>%
  slice(1:10)

#Seleccionar las diez diferencias más bajas
diferencias_bajas <- comparacion_crecimientos %>%
  ungroup() %>%
  arrange(diferencia_pp) %>%
  slice(1:10)

#Unir los territorios seleccionados
diferencias_seleccionadas <- bind_rows(
  diferencias_altas,
  diferencias_bajas
) %>%
  mutate(
    mayor_crecimiento = ifelse(
      diferencia_pp > 0,
      "Valor tasado",
      "Renta"
    )
  )

#Gráfico de barras horizontales
ggplot(
  diferencias_seleccionadas,
  aes(x = diferencia_pp,
      y = reorder(provincia, diferencia_pp),
      fill = mayor_crecimiento)
) +
  geom_col(width = 0.7) +
  geom_vline(xintercept = 0, colour = "black") +
  scale_fill_manual(
    name = "Mayor crecimiento",
    values = c(
      "Valor tasado" = "steelblue4",
      "Renta" = "#39856B"
    )
  ) +
  labs(
    title = "Diferencias entre el crecimiento de la vivienda y de la renta",
    subtitle = "2020-2024 · Diez diferencias más altas y diez más bajas",
    x = "Crecimiento del valor tasado - crecimiento de la renta (p. p.)",
    y = NULL
  ) +
  theme_minimal(base_family = "TNR") +
  theme(
    panel.grid.major.y = element_line(colour = "grey80", linewidth = 0.4),
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

#Recuento de los resultados de los 52 territorios
sum(comparacion_crecimientos$diferencia_pp > 0)
sum(comparacion_crecimientos$diferencia_pp < 0)
sum(comparacion_crecimientos$diferencia_pp == 0)

#Detalle de los 52 territorios
comparacion_crecimientos <- comparacion_crecimientos %>%
  arrange(desc(diferencia_pp))

print(comparacion_crecimientos, n = Inf, width = Inf)

#9.Análisis bivariante de la variación de población y del precio de la vivienda
#9.1.Calcular la variación del precio tasado entre 2020 y 2024
precio_poblacion <- dataset_vivienda %>%
  filter(año %in% c(2020, 2024), trimestre == 1) %>%
  select(codigo_provincia, provincia, año, precio_m2) %>%
  pivot_wider(
    names_from = año,
    values_from = precio_m2,
    names_prefix = "precio_"
  ) %>%
  mutate(
    variacion_precio =
      (precio_2024 - precio_2020) / precio_2020 * 100
  )

#9.2.Unir la variación de población y la del precio
datos_bivariantes <- crecimiento_poblacion %>%
  select(codigo_provincia, provincia, variacion_poblacion) %>%
  inner_join(
    precio_poblacion %>% select(codigo_provincia, provincia, variacion_precio),
    by = c("codigo_provincia", "provincia")
  )

#Comprobar los datos unidos
dim(datos_bivariantes)
colSums(is.na(datos_bivariantes))
print(datos_bivariantes, n = Inf, width = Inf)

#9.3.Calcular la correlación de Pearson
correlacion_poblacion_precio <- cor.test(
  datos_bivariantes$variacion_poblacion,
  datos_bivariantes$variacion_precio,
  method = "pearson"
)

print(correlacion_poblacion_precio)

#9.4.Gráfico de dispersión con recta de regresión
windowsFonts(TNR = windowsFont("Times New Roman"))

grafico_poblacion_precio <- ggplot(
  datos_bivariantes,
  aes(x = variacion_poblacion, y = variacion_precio)
) +
  geom_point(color = "steelblue4", size = 2.5) +
  geom_smooth(method = "lm", se = FALSE,
              color = "darkred", linewidth = 0.8) +
  labs(
    x = "Variación de la población (%)",
    y = "Variación del precio tasado (%)"
  ) +
  theme_minimal(base_family = "TNR") +
  theme(
    text = element_text(family = "TNR"),
    axis.title = element_text(family = "TNR", face = "bold", size = 10),
    axis.text = element_text(family = "TNR", face = "plain", size = 9),
    panel.border = element_rect(colour = "black", fill = NA, linewidth = 0.6),
    panel.grid.minor = element_blank(),
    plot.margin = margin(10, 20, 10, 20)
  )

print(grafico_poblacion_precio)
