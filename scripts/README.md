# Scripts de R

Esta carpeta contiene el código utilizado para preparar los datos y realizar el análisis estadístico del proyecto.

## Archivos y orden de ejecución

1. **`01_preparacion_datos.R`**: importa las fuentes originales de `data/raw/`, revisa la calidad de los datos y realiza su limpieza, transformación e integración. Las bases resultantes se guardan en `data/processed/`.

2. **`02_analisis_estadistico.R`**: utiliza las bases procesadas para calcular los estadísticos descriptivos, elaborar tablas y gráficos y analizar las relaciones entre las variables.

## Cómo ejecutar los scripts

Los scripts deben ejecutarse en el orden indicado y desde la raíz del repositorio, para que funcionen las rutas relativas a las carpetas de datos.

Es necesario instalar previamente los paquetes utilizados, indicados al inicio de cada script. Los gráficos emplean Times New Roman mediante una configuración específica de Windows, que debe adaptarse si se utiliza otro sistema operativo.
