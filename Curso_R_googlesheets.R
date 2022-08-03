
# Packages -----------------
install.packages("tidyverse")
install.packages("readxl")
install.packages("openxlsx")
install.packages('questionr')
install.packages('readr')
install.packages('googlesheets4')
install.packages('googledrive')

rm(list=ls())
gc()

# Open packages
library(tidyverse)
library(readxl)
library(openxlsx)
library(questionr)
library(readr)
library(googlesheets4)
library(googledrive)


gs4_auth() #Conección a la cuenta google. Hay que darle el permiso a tidyverse de modificar archivos en el drive

setwd("C:/Users/Ministerio/Documents/R_googledrive_SEPOT/") #Acá nos ponemos en un directorio de trabajo. Es opcional, pueden poner el 
      #camino entero para llegar al archivo si quieren. 


#En este ejercicio, supongamos que tenemos un excel con la inflación hasta mayo de 2022. La queremos subir a un drive. 

# 1- Importación de la base -----
#Lo más simple y rápido es pasar por la pestaña "import" arriba a la derecha.

setwd("Bases_externas") 
df_inflacion_mayo_22<-read_excel("Inflacion_mayo_22.xlsx")
head(df_inflacion_mayo_22)

#Una vez cargada la base en R, empezamos definiendo la carpeta objetivo (creada prealablemente en R)
id_carpeta<-drive_get("Curso_R_SEPOT")  #Se guarda el vínculo a la carpeta del drive. Es importante que no tenga homónimos

#Luego, creamos un archivo "sheet" en google drive
gs4_create(name="inflacion_base_dic_16",sheets=df_inflacion_mayo_22)
#Verán que les aparece en la ventana de inicio de drive. Hay que luego moverlo a la carpeta que indicamos
drive_mv(file="inflacion_base_dic_16",path=id_carpeta)

#Entre tiempo, salió la inflación de junio, y dio un índice de 793,0278 (base diciembre 2016=100). Quiero modificar el sheet con R 
    #para agregarle sólo el dato que falta, de junio 2022. 
df_inflacion_junio_22<-read_excel("Inflacion_junio_22.xlsx")
head(df_inflacion_junio_22)

#No quiero modificar el resto de la base, sólo agregar la última línea. 
df_indice_junio_22<-df_inflacion_junio_22%>%
  subset(mes=="junio" & anio=="2022")
head(df_indice_junio_22)

#Puedo luego agregarle al sheet una última línea, que es esta observación de junio 2022

id_inflacion<-drive_get("inflacion_base_dic_16") #Le asigno a esta variable el camino para llegar al sheet con la inflación

sheet_append(df_indice_junio_22,ss=id_inflacion)


#Vino un tal Guillermo y me dijo que hay que cambiar el índice de inflación para abril de 2022: debería ser 700, no 717. 
df_correccion<-df_inflacion_junio_22%>%
  mutate(inflacion=ifelse(anio=="2022" & mes=="abril",700, #Le cambio, sólo para el mes de abril del año 2022, la inflación por 700
                          inflacion)
         )%>%
  subset(mes=="abril" & anio=="2022")
head(df_correccion)

#Ahora quiero subir ese cambio al drive, no ya a la última línea, sino corregir el valor de unas células que ya estaban. 

range_write(df_correccion,ss=id_inflacion,range="A66:C66",col_names =FALSE) #Son las 3 células que hay que cambiar en el drive
#También funciona si ponen "A66" en vez del range total. 

#Me quedó mal el nombre de la pestaña. Lo puedo cambiar acá 
sheet_rename(ss=id_inflacion,sheet="df_inflacion_mayo_22","IPC total nacional")

#Ahora quiero también tener en el mismo excel, pero en otra pestaña, el índice de inflación para Cuyo. 

df_inflacion_cuyo_junio_22<-read_excel("Inflacion_cuyo_junio_22.xlsx")
head(df_inflacion_cuyo_junio_22)
sheet_write(df_inflacion_cuyo_junio_22,ss=id_inflacion,sheet="IPC Cuyo")

#Me acordé que tenía armado en mi drive el índice de inflación de Patagonia, y lo quiero agregar al mismo sheet que estuvimos armando
id_patagonia<-drive_get("inflacion_patagonia_junio_2022") #Encuentro el sheet que quiero leer: tiene que estar guardado como hoja de cálculo 
    #google, y no tener homónimos
df_inflacion_patagonia_junio_22<-read_sheet(ss=id_patagonia) #Guardo el contenido de la primera pestaña del archivo en R. 
    #Se puede guardar otra pestaña agregando la opción sheet="nombre_de_la_pestaña"
sheet_write(df_inflacion_patagonia_junio_22,ss=id_inflacion,sheet="IPC Patagonia")

#Me aburrí y quiero borrar el archivo 
drive_trash(id_inflacion)


