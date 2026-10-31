#PROYECTO: EVOLUCIÓN DEL MERCADO DE LA VIVIENDA EN ESPAÑA (2020-2026)
#Preparación y unión de cinco fuentes de datos

library(dplyr)
library(readr)
library(tidyr)
library(stringr)
library(ggplot2)

#PASO 1. Importar los archivos
vivienda <- read_delim(
  "data/raw/precios_vivienda_m2.csv",
  delim = ";")

precios_ine <- read_delim(
  "data/raw/indice_precios_vivienda.csv",
  delim = "\t",
  locale = locale(encoding = "Latin1"))

hipotecas <- read_delim(
  "data/raw/hipotecas.csv",
  delim = "\t")

#Descomprimir el archivo de población
carpeta_poblacion <- tempfile("poblacion_")
dir.create(carpeta_poblacion)

unzip(
  "data/raw/poblacion_2020_2024.zip",
  exdir = carpeta_poblacion
)

#Importar el CSV descomprimido
poblacion_2020_2024 <- read_delim(
  file.path(carpeta_poblacion, "poblacion_2020_2024.csv"),
  delim = ";"
)

poblacion_2025_2026 <- read_delim(
  "data/raw/poblacion_2025_2026.csv",
  delim = ";")

#Unir los dos archivos de población
poblacion <- bind_rows(
  poblacion_2020_2024,
  poblacion_2025_2026)

intereses <- read_csv(
  "data/raw/tipos_interes.csv",
  locale = locale(encoding = "Latin1"),
  col_types = cols(.default = col_character()))

#PASO 2. Preparar los precios de vivienda por provincia y trimestre
vivienda_filtrada <- vivienda %>%
  filter(Año >= 2020, Año <= 2026, Régimen == "Libre") %>%
  mutate(codigo_provincia = if_else(CPRO %in% as.character(1:52),
                                    str_pad(CPRO, 2, pad = "0"), NA_character_))

#Añadir Madrid, Murcia, Navarra y Asturias, que aparecen como CCAA uniprovinciales
uniprovinciales <- vivienda_filtrada %>%
  filter(Provincia == "Total CCAA",
         Comunidad_Autónoma %in% c("Madrid, Comunidad de", "Murcia, Region de",
                                    "Navarra, Comunidad Foral de", "Asturias, Principado de")) %>%
  mutate(
    codigo_provincia = case_when(
      Comunidad_Autónoma == "Madrid, Comunidad de" ~ "28",
      Comunidad_Autónoma == "Murcia, Region de" ~ "30",
      Comunidad_Autónoma == "Navarra, Comunidad Foral de" ~ "31",
      Comunidad_Autónoma == "Asturias, Principado de" ~ "33"
    ),
    Provincia = case_when(
      codigo_provincia == "28" ~ "Madrid",
      codigo_provincia == "30" ~ "Murcia",
      codigo_provincia == "31" ~ "Navarra",
      codigo_provincia == "33" ~ "Asturias"
    )
  )

vivienda_filtrada <- vivienda_filtrada %>%
  filter(!is.na(codigo_provincia)) %>%
  bind_rows(uniprovinciales) %>%
  distinct() %>%
  mutate(
    Mes = case_when(Trimestre == 1 ~ 1L, Trimestre == 2 ~ 4L,
                    Trimestre == 3 ~ 7L, Trimestre == 4 ~ 10L),
    codigo_ccaa = case_when(
      Comunidad_Autónoma == "Andalucía" ~ "01",
      Comunidad_Autónoma == "Aragón" ~ "02",
      Comunidad_Autónoma == "Asturias, Principado de" ~ "03",
      Comunidad_Autónoma == "Balears, Illes" ~ "04",
      Comunidad_Autónoma == "Canarias" ~ "05",
      Comunidad_Autónoma == "Cantabria" ~ "06",
      Comunidad_Autónoma == "Castilla y León" ~ "07",
      Comunidad_Autónoma == "Castilla-La Mancha" ~ "08",
      Comunidad_Autónoma == "Cataluña" ~ "09",
      Comunidad_Autónoma == "Comunitat Valenciana" ~ "10",
      Comunidad_Autónoma == "Extremadura" ~ "11",
      Comunidad_Autónoma == "Galicia" ~ "12",
      Comunidad_Autónoma == "Madrid, Comunidad de" ~ "13",
      Comunidad_Autónoma == "Murcia, Region de" ~ "14",
      Comunidad_Autónoma == "Navarra, Comunidad Foral de" ~ "15",
      Comunidad_Autónoma == "País Vasco" ~ "16",
      Comunidad_Autónoma == "Rioja, La" ~ "17",
      Comunidad_Autónoma == "Ceuta" ~ "18",
      Comunidad_Autónoma == "Melilla" ~ "19",
      TRUE ~ NA_character_
    )
  )

#PASO 3. Preparar el índice de precios de vivienda del INE por CCAA y trimestre
ipv_ccaa <- precios_ine %>%
  filter(`General, vivienda nueva y de segunda mano` == "General",
         `Índices y tasas` == "Índice",
         Periodo >= "2020T1", Periodo <= "2026T2") %>%
  transmute(
    codigo_ccaa = str_sub(`Comunidades y Ciudades Autónomas`, 1, 2),
    Año = as.integer(str_sub(Periodo, 1, 4)),
    Trimestre = as.integer(str_sub(Periodo, 6, 6)),
    Valor_IPV = as.numeric(str_replace(Total, ",", "."))
  )

#PASO 4. Preparar hipotecas mensuales y unirlas con los precios
hipotecas_ancha <- hipotecas %>%
  filter(`Naturaleza de la finca` == "Viviendas",
         `Número e importe` %in% c("Número de hipotecas", "Importe de hipotecas")) %>%
  mutate(Año = as.integer(str_sub(Periodo, 1, 4))) %>%
  filter(Año >= 2020, Año <= 2026) %>%
  pivot_wider(names_from = `Número e importe`, values_from = Total) %>%
  filter(Provincias != "Total Nacional") %>%
  mutate(
    codigo_provincia = str_sub(Provincias, 1, 2),
    Mes = as.integer(str_sub(Periodo, 6, 7)),
    `Número de hipotecas` = as.numeric(str_remove_all(`Número de hipotecas`, fixed("."))),
    `Importe de hipotecas` = as.numeric(str_remove_all(`Importe de hipotecas`, fixed(".")))
  )

#Tabla única de correspondencia provincia-CCAA
provincias_ccaa <- vivienda_filtrada %>%
  distinct(codigo_provincia, Provincia, Comunidad_Autónoma, codigo_ccaa) %>%
  distinct(codigo_provincia, .keep_all = TRUE)

base_vivienda_hipotecas <- hipotecas_ancha %>%
  left_join(provincias_ccaa %>% select(codigo_provincia, Comunidad_Autónoma, codigo_ccaa),
            by = "codigo_provincia") %>%
  left_join(vivienda_filtrada %>% select(codigo_provincia, Año, Mes, Valor, Trimestre),
            by = c("codigo_provincia", "Año", "Mes")) %>%
  left_join(ipv_ccaa, by = c("codigo_ccaa", "Año", "Trimestre"))

#PASO 5. Preparar y añadir los tipos de interés mensuales
intereses_vivienda <- intereses %>%
  slice(6:n()) %>%
  transmute(
    Periodo = `CóDIGO DE LA SERIE`,
    Tipo_interes = as.numeric(DN_1TI2T0002)
  ) %>%
  mutate(
    Mes = match(str_sub(Periodo, 1, 3),
                c("ENE", "FEB", "MAR", "ABR", "MAY", "JUN",
                  "JUL", "AGO", "SEP", "OCT", "NOV", "DIC")),
    Año = as.integer(str_sub(Periodo, 5, 8))
  ) %>%
  filter(Año >= 2020, Año <= 2026) %>%
  select(Año, Mes, Tipo_interes)

base_vivienda_hipotecas <- base_vivienda_hipotecas %>%
  left_join(intereses_vivienda, by = c("Año", "Mes"))

#PASO 6. Preparar y añadir la población total por provincia
poblacion_filtrada <- poblacion %>%
  filter(`Edad simple` == "Todas las edades", Sexo == "Total",
         Provincias != "Total Nacional") %>%
  mutate(
    codigo_provincia = str_sub(Provincias, 1, 2),
    Total = as.numeric(str_remove_all(Total, fixed("."))),
    Año = as.integer(str_extract(Periodo, "\\d{4}")),
    Mes = case_when(
      str_detect(Periodo, "enero") ~ 1L,
      str_detect(Periodo, "abril") ~ 4L,
      str_detect(Periodo, "julio") ~ 7L,
      str_detect(Periodo, "octubre") ~ 10L,
      TRUE ~ NA_integer_
    )
  ) %>%
  filter(Año >= 2020, Año <= 2026) %>%
  select(codigo_provincia, Año, Mes, Poblacion = Total)

base_vivienda_hipotecas <- base_vivienda_hipotecas %>%
  left_join(poblacion_filtrada, by = c("codigo_provincia", "Año", "Mes")) %>%
  filter(!(Año == 2026 & Mes == 7)) %>%
  mutate(Trimestre = ceiling(Mes / 3)) %>%
  group_by(Provincias, codigo_provincia, Comunidad_Autónoma, codigo_ccaa, Año, Trimestre) %>%
  summarise(
    `Número de hipotecas` = sum(`Número de hipotecas`),
    `Importe de hipotecas` = sum(`Importe de hipotecas`),
    Valor = first(Valor[!is.na(Valor)], default = NA_real_),
    Valor_IPV = first(Valor_IPV[!is.na(Valor_IPV)], default = NA_real_),
    Tipo_interes = mean(Tipo_interes, na.rm = TRUE),
    Poblacion = first(Poblacion[!is.na(Poblacion)], default = NA_real_),
    .groups = "drop"
  ) %>%
  arrange(codigo_provincia, Año, Trimestre)

sum(is.na(base_vivienda_hipotecas$Poblacion)) #para saber cuantos valores ausentes había antes de la interpolación

datos_antes_interpolacion <- base_vivienda_hipotecas %>%
  select(codigo_provincia, Año, Trimestre, Poblacion)

#PASO 7. Interpolar los valores ausentes de población
base_vivienda_hipotecas <- base_vivienda_hipotecas %>%
  mutate(periodo_trimestre = Año * 4 + Trimestre) %>%
  group_by(codigo_provincia) %>%
  arrange(periodo_trimestre, .by_group = TRUE) %>%
  mutate(
    Poblacion = approx(
      x = periodo_trimestre[!is.na(Poblacion)],
      y = Poblacion[!is.na(Poblacion)],
      xout = periodo_trimestre,
      method = "linear",
      rule = 1 
    )$y
  ) %>%
  ungroup() %>%
  select(-periodo_trimestre) %>%
  select(
    Provincias, codigo_provincia, Comunidad_Autónoma, codigo_ccaa,
    Año, Trimestre, `Número de hipotecas`, `Importe de hipotecas`,
    Valor, Valor_IPV, Tipo_interes, Poblacion
  )

datos_comparacion <- datos_antes_interpolacion %>%
  left_join(
    base_vivienda_hipotecas %>%
      select(codigo_provincia, Año, Trimestre,
             Poblacion_despues = Poblacion),
    by = c("codigo_provincia", "Año", "Trimestre")
  )


#Tabla con las interpolaciones
tabla_interpolacion <- datos_comparacion %>%
  filter(
    is.na(Poblacion) &
      !is.na(Poblacion_despues)
  ) %>%
  mutate(
    trimestre = if_else(Trimestre == 2, "T2 2020", "T4 2020")
  ) %>%
  left_join(
    base_vivienda_hipotecas %>%
      select(codigo_provincia, Provincias) %>%
      distinct(),
    by = "codigo_provincia"
  ) %>%
  select(
    provincia = Provincias,
    trimestre,
    Poblacion_despues
  ) %>%
  pivot_wider(
    names_from = trimestre,
    values_from = Poblacion_despues,
    names_prefix = "Población estimada "
  ) %>%
  arrange(provincia)

print(tabla_interpolacion, n = Inf)

tabla_interpolacion <- tabla_interpolacion %>%
  mutate(
    `Población estimada T2 2020` =
      round(`Población estimada T2 2020`),
    `Población estimada T4 2020` =
      round(`Población estimada T4 2020`)
  )

#EJEMPLO MADRID
#Gráfico de interpolación de la población 
datos_madrid <- datos_comparacion %>%
  filter(codigo_provincia == "28") %>%
  mutate(
    periodo = Año + (Trimestre - 1) / 4,
    interpolado = is.na(Poblacion)
  )

ggplot(datos_madrid, aes(x = periodo, y = Poblacion_despues)) +
  geom_line() +
  geom_point(aes(color = interpolado), size = 3) +
  scale_color_manual(
    values = c("FALSE" = "grey50", "TRUE" = "skyblue2"),
    labels = c("FALSE" = "Dato original", "TRUE" = "Interpolado")
  ) +
  scale_x_continuous(
    breaks = 2020:2026,
    labels = 2020:2026
  ) +
  labs(
    title = "Evolución de la población de Madrid (2020-2026)",
    x = "Año",
    y = "Población (habitantes)",
    color = "Tipo de dato"
  ) +
  theme_minimal(base_family = "Times New Roman") +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    axis.title = element_text(face = "bold"),
    axis.title.x = element_text(margin = margin(t = 12)),
    axis.title.y = element_text(margin = margin(r = 12)),
    legend.title = element_text(face = "bold")
  )


# Tabla de población de Madrid antes y después de la interpolación
tabla_madrid <- datos_comparacion %>%
  filter(codigo_provincia == "28") %>%
  arrange(Año, Trimestre) %>%
  transmute(
    Año,
    Trimestre,
    `Población original` = round(Poblacion),
    `Población tras interpolación` = round(Poblacion_despues)
  )

print(tabla_madrid, n = Inf)


#PASO 8. Limpiar y unificar
#Nombres de las provincias
base_vivienda_hipotecas <- base_vivienda_hipotecas %>%
  mutate(
    Provincias = str_remove(Provincias, "^\\d+\\s+"),
    Provincias = recode(
      Provincias,
      "Araba/Álava" = "Álava",
      "Alicante/Alacant" = "Alicante",
      "Balears, Illes" = "Islas Baleares",
      "Castellón/Castelló" = "Castellón",
      "Coruña, A" = "A Coruña",
      "Girona" = "Gerona",
      "Gipuzkoa" = "Guipúzcoa",
      "Lleida" = "Lérida",
      "Rioja, La" = "La Rioja",
      "Ourense" = "Orense",
      "Palmas, Las" = "Las Palmas",
      "Valencia/València" = "Valencia",
      "Bizkaia" = "Vizcaya"
    )
  )

#Nombres de las CCAA
base_vivienda_hipotecas <- base_vivienda_hipotecas %>%
  mutate(
    Comunidad_Autónoma = recode(
      Comunidad_Autónoma,
      "Balears, Illes" = "Islas Baleares",
      "Comunitat Valenciana" = "Comunidad Valenciana",
      "Madrid, Comunidad de" = "Comunidad de Madrid",
      "Murcia, Region de" = "Región de Murcia",
      "Navarra, Comunidad Foral de" = "Comunidad Foral de Navarra",
      "Asturias, Principado de" = "Principado de Asturias",
      "Rioja, La" = "La Rioja"
    )
  )

sort(unique(base_vivienda_hipotecas$Comunidad_Autónoma))

#PASO 9. Ordenar y renombrar las columnas
base_vivienda_hipotecas <- base_vivienda_hipotecas %>%
  mutate(
    Año = as.integer(Año),
    Trimestre = as.integer(Trimestre)
  ) %>%
  select(
    codigo_provincia,
    provincia = Provincias,
    comunidad_autonoma = Comunidad_Autónoma,
    año = Año,
    trimestre = Trimestre,
    precio_m2 = Valor,
    indice_precios_vivienda = Valor_IPV,
    numero_hipotecas = `Número de hipotecas`,
    importe_hipotecas = `Importe de hipotecas`,
    tipo_interes = Tipo_interes,
    poblacion = Poblacion
  )


#PASO 10. COMPROBACIONES DE CALIDAD

#10.1. Dimensiones y valores ausentes
print(dim(base_vivienda_hipotecas))
print(colSums(is.na(base_vivienda_hipotecas)))

#10.2. Comprobar duplicados completos
cat("Filas duplicadas completas:",
    sum(duplicated(base_vivienda_hipotecas)), "\n")

#10.3. Comprobar duplicados por provincia y periodo
duplicados_periodo <- base_vivienda_hipotecas %>%
  count(codigo_provincia, año, trimestre) %>%
  filter(n > 1)

print(duplicados_periodo)

#10.4. Comprobar que hay una observación por provincia y trimestre
stopifnot(nrow(duplicados_periodo) == 0)


#PASO 11. IDENTIFICACIÓN DE POSIBLES VALORES ATÍPICOS
variables <- c(
  "precio_m2",
  "indice_precios_vivienda",
  "numero_hipotecas",
  "importe_hipotecas",
  "tipo_interes",
  "poblacion"
)

#11.1. Calcular límites IQR y recuento de valores atípicos
resumen_atipicos <- lapply(variables, function(variable) {
  
  x <- base_vivienda_hipotecas[[variable]]
  x <- x[!is.na(x)]
  
  q1 <- quantile(x, 0.25)
  q3 <- quantile(x, 0.75)
  iqr <- IQR(x)
  
  limite_inferior <- q1 - 1.5 * iqr
  limite_superior <- q3 + 1.5 * iqr
  
  data.frame(
    variable = variable,
    limite_inferior = as.numeric(limite_inferior),
    limite_superior = as.numeric(limite_superior),
    numero_atipicos = sum(
      x < limite_inferior | x > limite_superior
    )
  )
}) %>%
  bind_rows()

print(resumen_atipicos, row.names = FALSE)


#11.2. Revisar los valores detectados en cada variable
observaciones_atipicas <- lapply(variables, function(variable) {
  
  limites <- resumen_atipicos %>%
    filter(.data$variable == variable)
  
  base_vivienda_hipotecas %>%
    filter(
      .data[[variable]] < limites$limite_inferior |
        .data[[variable]] > limites$limite_superior
    ) %>%
    select(
      provincia, año, trimestre,
      all_of(variable)
    ) %>%
    mutate(variable_analizada = variable) %>%
    relocate(variable_analizada)
}) %>%
  bind_rows()

#Resumen de las observaciones detectadas
observaciones_atipicas %>%
  count(variable_analizada, name = "numero_atipicos") %>%
  print(n = Inf)

#Consultar los diez valores más altos de cada variable
for (variable in variables) {
  
  cat("\nVariable:", variable, "\n")
  
  print(
    observaciones_atipicas %>%
      filter(variable_analizada == variable) %>%
      arrange(desc(.data[[variable]])) %>%
      slice_head(n = 10),
    n = Inf
  )
}


#PASO 12. EXPORTACIÓN DE LA BASE FINAL
dir.create(
  "data/processed",
  recursive = TRUE,
  showWarnings = FALSE)

write_csv(
  base_vivienda_hipotecas,
  "data/processed/dataset_vivienda.csv")

#Comprobar que el archivo se ha guardado
file.exists("data/processed/dataset_vivienda.csv")

#DATASET ANUAL DE RENTA MEDIA POR PROVINCIA
renta_original <- read_delim(
  "data/raw/renta_anual_media.csv",
  delim = ";",
  locale = locale(
    encoding = "UTF-8",
    grouping_mark = ".",
    decimal_mark = ","
  ),
  na = c("", "NA", ".."),
  trim_ws = TRUE,
  show_col_types = FALSE
)

#Seleccionar datos
renta_provincia <- renta_original %>%
  filter(
    `Indicadores de renta media` == "Renta neta media por hogar",
    !is.na(Provincias),
    is.na(Islas),
    Periodo %in% as.character(2020:2024)
  ) %>%
  transmute(
    provincia = str_squish(Provincias),
    año = as.integer(Periodo),
    renta_media_hogar = as.numeric(Total)
  ) %>%
  arrange(provincia, año)

#Unificar nombres de provincias
renta_provincia <- renta_provincia %>%
  mutate(
    provincia = recode(
      provincia,
      "Araba/Álava" = "Álava",
      "Alicante/Alacant" = "Alicante",
      "Balears, Illes" = "Islas Baleares",
      "Castellón/Castelló" = "Castellón",
      "Coruña, A" = "A Coruña",
      "Girona" = "Gerona",
      "Gipuzkoa" = "Guipúzcoa",
      "Lleida" = "Lérida",
      "Rioja, La" = "La Rioja",
      "Ourense" = "Orense",
      "Palmas, Las" = "Las Palmas",
      "Valencia/València" = "Valencia",
      "Bizkaia" = "Vizcaya"
    )
  )

#Comprobar valores ausentes
colSums(is.na(renta_provincia))

#Completar Navarra en 2020 con el dato de Nastat
renta_provincia <- renta_provincia %>%
  mutate(
    renta_media_hogar = if_else(
      provincia == "Navarra" & año == 2020 & is.na(renta_media_hogar),
      35430,
      renta_media_hogar
    )
  )

#Comprobar la base
glimpse(renta_provincia)
dim(renta_provincia)
n_distinct(renta_provincia$provincia)
sort(unique(renta_provincia$año))
renta_provincia %>% count(año)

#Comprobar duplicados
renta_provincia %>%
  count(provincia, año) %>%
  filter(n > 1)

#Comprobar valores ausentes finales
colSums(is.na(renta_provincia))

#Guardar la base limpia de renta
write_csv(
  renta_provincia,
  "data/processed/dataset_renta.csv"
)

#Comprobar que se ha guardado
file.exists("data/processed/dataset_renta.csv")

#Detectar valores atípicos
q1 <- quantile(renta_provincia$renta_media_hogar, 0.25, na.rm = TRUE)
q3 <- quantile(renta_provincia$renta_media_hogar, 0.75, na.rm = TRUE)
iqr <- IQR(renta_provincia$renta_media_hogar, na.rm = TRUE)

limite_inferior <- q1 - 1.5 * iqr
limite_superior <- q3 + 1.5 * iqr

atipicos_renta <- renta_provincia %>%
  filter(
    renta_media_hogar < limite_inferior |
      renta_media_hogar > limite_superior
  ) %>%
  select(provincia, año, renta_media_hogar)

atipicos_renta

#Comprobar evolución de las rentas
renta_provincia %>%
  filter(
    provincia %in% c("Islas Baleares", "Ceuta", "Guipúzcoa", "Madrid", "Melilla"),
    año %in% 2022:2024
  ) %>%
  arrange(provincia, año)
