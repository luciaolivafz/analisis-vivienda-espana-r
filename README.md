# Análisis del mercado de la vivienda en España con R

Proyecto académico de la asignatura **Análisis Estadístico Avanzado** del Grado en Gestión de la Información y Contenidos Digitales de la **Universidad Carlos III de Madrid**.

El estudio analiza la evolución del valor tasado de la vivienda y sus diferencias territoriales, e incorpora información sobre la renta de los hogares, la actividad hipotecaria, los tipos de interés y la población.

**Autoras:** Lucía Oliva Fernández y Eva Pérez García.  
**Curso académico:** 2026-2027.  
**Estado:** en desarrollo.

## 1. Objetivos

El objetivo general es estudiar la evolución del mercado de la vivienda en España entre 2020 y 2026 y explorar su relación con factores económicos y demográficos.

Los objetivos específicos son:

- Integrar información de distintas fuentes oficiales en bases de datos comparables.
- Revisar y documentar la calidad de los datos.
- Describir la evolución del valor tasado y sus diferencias entre territorios.
- Analizar la distribución de la renta media por hogar.
- Examinar la asociación entre renta y valor tasado.
- Incorporar el estudio de la actividad hipotecaria y las condiciones de financiación.

El trabajo tiene un enfoque descriptivo y exploratorio. Las asociaciones observadas no se interpretan como relaciones causales.

## 2. Fuentes de información

| Información | Organismo |
|---|---|
| Valor tasado de la vivienda libre | Ministerio de Vivienda y Agenda Urbana |
| Índice de Precios de Vivienda | Instituto Nacional de Estadística |
| Número e importe de hipotecas | Instituto Nacional de Estadística |
| Población | Instituto Nacional de Estadística |
| Renta neta media por hogar | Instituto Nacional de Estadística |
| Renta de Navarra en 2020 | Instituto de Estadística de Navarra — Nastat |
| Tipos de interés | Banco de España |

Fuentes principales:

- [Valor tasado de la vivienda](https://datos.gob.es/es/catalogo/e05233601-valor-tasado-de-la-vivienda)
- [Índice de Precios de Vivienda](https://www.ine.es/jaxiT3/Tabla.htm?t=79563)
- [Estadística de Hipotecas](https://www.ine.es/jaxiT3/Tabla.htm?t=76317)
- [Estadística Continua de Población (datos definitivos hasta 2024)](https://www.ine.es/jaxiT3/Tabla.htm?t=56945)
- [Estadística Continua de Población (datos provisionales de 2025 y 2026)](https://www.ine.es/jaxiT3/Tabla.htm?t=59589&L=0)
- [Indicadores de renta media y mediana](https://www.ine.es/jaxiT3/Tabla.htm?t=53689&L=0)
- [Tipos de interés aplicados por las entidades de crédito](https://datos.bde.es/datos/es/datasets/000/007.html)

Las referencias completas y las particularidades de cada fuente se documentan en el informe académico.

## 3. Bases de datos

### Base trimestral: `dataset_vivienda.csv`

Contiene **1.352 observaciones y 11 variables**, correspondientes a las 50 provincias y las ciudades autónomas de Ceuta y Melilla durante 26 trimestres.

**Cobertura:** primer trimestre de 2020 a segundo trimestre de 2026.

| Variable | Contenido |
|---|---|
| `codigo_provincia` | Identificador territorial |
| `provincia` | Nombre del territorio |
| `comunidad_autonoma` | Comunidad autónoma |
| `año` | Año de referencia |
| `trimestre` | Trimestre de referencia |
| `precio_m2` | Valor tasado de la vivienda libre, en €/m² |
| `indice_precios_vivienda` | Índice de Precios de Vivienda |
| `numero_hipotecas` | Número de hipotecas constituidas sobre viviendas |
| `importe_hipotecas` | Importe agregado de las hipotecas, en la unidad de la fuente |
| `tipo_interes` | Tipo de interés de la serie seleccionada |
| `poblacion` | Población del territorio |

Aunque la estructura de la base es provincial, algunos indicadores tienen otra escala geográfica. El IPV procede de información autonómica y el tipo de interés presenta un mismo valor para todos los territorios de cada trimestre. Estas repeticiones deben tenerse en cuenta al analizar los datos.

### Base anual: `dataset_renta.csv`

Contiene **260 observaciones y 3 variables**, correspondientes a los mismos 52 territorios durante cinco años.

**Cobertura:** 2020–2024.

| Variable | Contenido |
|---|---|
| `provincia` | Nombre del territorio |
| `año` | Año de referencia |
| `renta_media_hogar` | Renta neta media anual por hogar, en euros |

## 4. Preparación y calidad de los datos

El proceso de preparación incluye:

- Adaptación de formatos, delimitadores y codificaciones.
- Conversión de las variables numéricas.
- Homogeneización de identificadores territoriales y temporales.
- Integración de las fuentes.
- Revisión de valores ausentes y duplicados.
- Identificación de observaciones potencialmente atípicas.

### Valores ausentes

Para completar la cobertura de población, se incorporó un archivo complementario con información de 2025 y 2026.

Posteriormente, se aplicó interpolación lineal a los valores ausentes de población, ordenando las observaciones por territorio y fecha. No se realizó extrapolación. Se estimaron 104 valores correspondientes al segundo y cuarto trimestre de 2020 en los 52 territorios.

El dato de renta de Navarra en 2020 se completó con información de Nastat. Su procedencia diferente se documenta como una limitación de comparabilidad.

### Duplicados

Se revisaron tanto las filas completamente duplicadas como las claves que identifican cada observación:

- Base trimestral: provincia, año y trimestre.
- Base anual: provincia y año.

Las comprobaciones documentadas no detectaron duplicados.

### Valores atípicos

Se utilizaron límites basados en el rango intercuartílico:

- **Posibles valores atípicos:** por debajo de Q1 − 1,5 × IQR o por encima de Q3 + 1,5 × IQR.
- **Posibles valores atípicos extremos:** por debajo de Q1 − 3 × IQR o por encima de Q3 + 3 × IQR.

La detección estadística no se consideró motivo suficiente para eliminar una observación.

En las comparaciones anuales de vivienda (2020 y 2025) y renta (2020 y 2024) no se detectaron valores extremos según el criterio de 3 × IQR, aplicado por separado a cada año.

## 5. Análisis realizados

### Valor tasado de la vivienda

- Cálculo de medias anuales por territorio.
- Comparación descriptiva entre 2020 y 2025 mediante medidas de posición y dispersión.
- Diagramas de caja con la media señalada.
- Cálculo de la variación porcentual acumulada por territorio.
- Histograma de las variaciones porcentuales.
- Mapa de la distribución territorial del crecimiento.
- Identificación de los tres territorios con mayor y menor crecimiento.
- Análisis de la evolución trimestral de los seis territorios seleccionados.

Se utiliza 2025 como último año completo para la comparación anual. Las series trimestrales incluyen los datos disponibles hasta 2026-T2.

### Renta neta media por hogar

- Comparación descriptiva entre 2020 y 2024.
- Cálculo de medidas de posición y dispersión.
- Diagramas de caja.
- Detección y revisión de valores potencialmente atípicos y extremos.
- Mapa de la distribución territorial de la renta en 2024.

### Relación entre renta y vivienda

- Integración de ambas variables por territorio y año.
- Comparación de la renta media por hogar y el valor tasado de la vivienda en 2020 y 2024.
- Diagramas de dispersión con escalas comunes.
- Ajuste y representación de rectas de regresión lineal.
- Cálculo y comparación de las correlaciones de Pearson.

Las rectas de regresión se representan dentro del intervalo de renta observado en cada año. Los resultados permiten estudiar la asociación entre ambas variables, sin establecer relaciones causales.

## 6. Principales resultados

### Crecimiento del valor tasado

El valor tasado de la vivienda aumenta en los **52 territorios** entre 2020 y 2025. La variación media es del **24,45%**, con un mínimo del 5,09% y un máximo del 53,13%.

Los mayores crecimientos corresponden a Málaga, Islas Baleares y Valencia, mientras que los menores se registran en Palencia, Zamora y Ciudad Real.

### Renta media por hogar

La renta media territorial pasa de **30.707,56€ en 2020** a **37.939,33€ en 2024**, un aumento del 23,55%. La dispersión relativa entre territorios se mantiene prácticamente estable.

### Relación entre renta y vivienda

La correlación de Pearson pasa de **0,752 en 2020** a **0,819 en 2024**, lo que refleja una asociación positiva entre la renta media por hogar y el valor tasado de la vivienda. Esta relación no implica causalidad.

## 7. Herramientas utilizadas

El tratamiento y análisis se desarrolla en **R**, utilizando RStudio como entorno de trabajo.

Paquetes empleados en el script de análisis:

- `readr`: importación de archivos.
- `dplyr`: transformación, agrupación y unión de datos.
- `tidyr`: organización y transformación de datos.
- `stringr`: tratamiento de cadenas de texto.
- `ggplot2`: elaboración de gráficos.
- `mapSpain`: obtención de cartografía provincial.
- `sf`: tratamiento de información espacial.

También se utilizan funciones de R base para estadísticos, diagramas de caja, histogramas, correlaciones y regresión lineal.

## 8. Ejecución del análisis

1. Descargar o clonar el repositorio.
2. Abrir el script de análisis en RStudio.
3. Establecer como directorio de trabajo la carpeta que contiene las bases de datos.
4. Comprobar que los archivos se denominan:
   - `dataset_vivienda.csv`
   - `dataset_renta.csv`
5. Instalar los paquetes necesarios si todavía no están disponibles:

```r
install.packages(c("readr", "dplyr", "tidyr", "stringr", "ggplot2", "mapSpain", "sf"))
```

6. Ejecutar el script en orden, desde el principio.

### Tipografía y sistema operativo

Los gráficos utilizan Times New Roman. El script incluye:

```r
windowsFonts(TNR = windowsFont("Times New Roman"))
```

Esta configuración es específica de Windows. En otros sistemas debe adaptarse el registro de la fuente y las referencias a `"TNR"`.

La obtención de cartografía mediante `mapSpain` puede requerir conexión a internet en la primera ejecución.

## 9. Consideraciones para interpretar los resultados

- Los importes monetarios son nominales y no están ajustados por inflación.
- El valor tasado no equivale necesariamente al precio de compraventa.
- Los estadísticos territoriales asignan el mismo peso a cada provincia o ciudad autónoma.
- Las medias territoriales no describen las desigualdades entre hogares de un mismo territorio.
- Los resultados provinciales no permiten extraer conclusiones sobre hogares individuales.
- La selección de los seis territorios extremos no representa al conjunto del país.
- Los datos de 2026 corresponden únicamente a los dos primeros trimestres.
- Las observaciones de población interpoladas son estimaciones.
- El dato complementario de Navarra en 2020 requiere considerar su comparabilidad.
- Las correlaciones y regresiones utilizadas tienen finalidad exploratoria y no demuestran causalidad.

## 10. Documentación y uso de IA

El informe académico documenta las fuentes, las decisiones metodológicas, los resultados y las limitaciones del estudio.

La declaración de uso de inteligencia artificial generativa se incluye en el anexo correspondiente del informe.

## 11. Atribución de los datos

Los datos proceden de los organismos indicados y su reutilización está sujeta a las condiciones de cada fuente. La publicación de este repositorio no modifica dichas condiciones.

La elaboración de las bases integradas, el código de análisis y la interpretación de los resultados forman parte del trabajo académico de las autoras.

## Copyright y condiciones de uso

© 2026 Lucía Oliva Fernández y Eva Pérez García. Todos los derechos reservados sobre las aportaciones originales del proyecto.

Salvo autorización expresa de las autoras o los usos permitidos por la legislación aplicable, no se permite reproducir, modificar ni redistribuir el código, el informe y las visualizaciones originales.

Los datos de terceros conservan sus propias licencias y condiciones de reutilización. Este aviso no atribuye a las autoras derechos sobre los datos ni sobre la cartografía utilizados.

La disponibilidad pública del repositorio no implica la concesión de una licencia de código abierto.
