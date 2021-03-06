###########################################
#Mapas en R con datos abiertos
#1� encuentro de Ususaries de R en Rosario
#Lic. Julia Fern�ndez
#23 de octubre de 2018
###########################################


###Aplicaci�n: construcci�n de mapas de la Regi�n Sanitaria IV del Ministerio de Salud 
#de la Provincia de Buenos Aires

#Librer�as
library(dplyr)
library(sp)
library(ggplot2)
library(grDevices)
library(broom)
library(RColorBrewer)

col1 <- rgb(red=154,green=202,blue=60,maxColorValue = 255)

#Datos para construir el mapa: estos datos provienen del sitio www.gadm.org
#Los datos de Argentina s�lo se encuentran subdivididos hasta el nivel de departamento
#o partido

mapa <- readRDS('ARG_adm2.rds')

#Revisamos el formato del objeto. La estructura se puede ver en el Global Environment
class(mapa)

names(mapa) #Me da los nombres de las variables en el data.frame que acompa�a a los datos espaciales
mapa@polygons #Es una lista con los datos de los pol�gonos: en este caso, cada elemento de la lista contiene datos de un departamento/partido

#Podemos ir estudiando qu� informaci�n tiene el data.frame
head(mapa$NAME_0,20)
tail(mapa$NAME_0,20)
#Vemos que NAME_0 tiene el nombre del pa�s

head(mapa$NAME_1,20)
tail(mapa$NAME_1,20)
#Vemos que NAME_1 tiene el nombre de la provincia

head(mapa$NAME_2,20)
tail(mapa$NAME_2,20)
#Vemos que NAME_2 tiene el nombre del departamento o partido

###Construyo un vector que tiene los nombres de los 13 partidos que conforman la RSIV 
#del Ministerio de Salud de la Provincia de Buenos Aires
RSIV <- as.vector(c("Arrecifes","Baradero","Capit�n Sarmiento","Carmen de Areco",
                    "Col�n","Pergamino","Ramallo","Rojas","Salto",
                    "San Andr�s de Giles","San Antonio de Areco","San Nicol�s",
                    "San Pedro"))

#Chequeo que est�n los 13 partidos:
length(RSIV)

#Voy a tomar �nicamente los datos de los 13 partidos que me interesan:
head(mapa$OBJECTID,20)

posicion <- numeric(length(RSIV)) #vector vac�o
for (i in 1:length(RSIV)) {
  posicion[i] <- which(mapa$NAME_2==RSIV[i]) #Este vector me da el OBJECTID de los 13 partidos de la RSIV
}

posicion

#Chequeamos que est�n los 13 partidos que nos interesan: porque podemos cometer 
#errores de tipeo, o los nombres podr�an tener abreviaturas, etc.
mapa$NAME_2[posicion]

#En este caso las variables OBJECTID y ID_2 tienen la misma informaci�n
mapa$OBJECTID
mapa$ID_2

#Seleccionamos solamente la informaci�n que corresponde a los partidos de la RSIV:
mapaRSIV <- mapa[mapa$OBJECTID[posicion],]

#Con esta informaci�n ya podemos construir un mapa con los l�mites de los partidos de
#la RSIV:
plot(mapaRSIV)

#Ahora podemos empezar a agregar informaci�n y personalizar nuestro mapa
#La funci�n coordinates permite recuperar las coordenadas de un objeto Spatial, y 
#tambi�n definir las coordenadas para crear un objeto Spatial
plot(mapaRSIV,col=col1)
text(coordinates(mapaRSIV),mapaRSIV$NAME_2)
points(coordinates(mapaRSIV),col="black",pch=16) 

#El punto me tapa el nombre, as� que quiero ubicarlo un poco m�s arriba
head(coordinates(mapaRSIV))

#Corro los puntos de lugar
plot(mapaRSIV,col=col1)
text(coordinates(mapaRSIV),mapaRSIV$NAME_2) 
points(coordinates(mapaRSIV)[,1],coordinates(mapaRSIV)[,2]+0.05,col="black",pch=16)
#Agrego una constante a la latitud para que los puntos queden sobre los nombres de los
#partidos

#Ahora voy a agregar una escala de colores que indique la densidad de poblaci�n de los 
#partidos en 2010.
#Los datos de la poblaci�n por partido pueden obtenerse de la base REDATAM a la que 
#se puede acceder desde la p�gina del INDEC

#Densidad de poblaci�n 2010:
dens <- read.table("poblacion.txt",header=TRUE,sep = "\t",dec=",")

#Creo un nuevo SpatialPolygonsDataFrame con la informaci�n de la densidad de poblaci�n,
#usando la funci�n merge
densidad <- merge(mapaRSIV,dens,by.x="NAME_2",by.y="Partido")

#Una forma r�pida de representar con una escala de colores la densidad en el mapa es 
#usar la funci�n spplot del paquete sp. El mapa b�sico con spplot:
spplot(densidad,"Densidad")

#Los mapas con spplot se pueden guardar asign�ndoles un nombres, como los gr�ficos de
#ggplot2
mapa1 <- spplot(densidad,"Densidad")

#Para personalizar la paleta de colores se pueden usar las paletas del paquete RColorBrewer:
display.brewer.all()
paleta1 <- brewer.pal(n = 9, name = "OrRd") 
#Hay que recordar que la paleta no admite m�s de 9 colores

spplot(densidad,"Densidad",col.regions=paleta1,cuts=8) #En cuts: cantidad de colores menos 1

#Para agregar etiquetas y puntos al gr�fico es necesario definir listas donde est�n 
#las coordenadas y lo que se quiere graficar.
#creamos un data.frame con las coordenadas de los puntos
coords <- data.frame(x=coordinates(densidad)[,1],y=coordinates(densidad)[,2]+0.05)
coordinates(coords) <- ~ x + y #Este es un paso previo para poder representar las coordenadas con spplot

#Se define la lista con los puntos, donde "sp.point" indica que en esas coordenadas 
#deben representarse puntos
l1 <- list("sp.points",coords,pch=19,cex=1,col="black")

#Se define la lista con los nombres de los partidos, donde "sp.text" indica que en 
#esas coordenadas debe representarse texto
l2 <- list("sp.text",coordinates(densidad),RSIV)

#En la opci�n sp.layout se especifica una lista de uno o varios elementos que se 
#quieran agregar al mapa
spplot(densidad,"Densidad",col.regions=paleta1,cuts=8,sp.layout=list(l1,l2)) 

#Podemos agregar, por ejemplo, puntos en los partidos que cuentan con hospitales 
#provinciales:
hosp <- c("Carmen de Areco","Pergamino","San Nicol�s")

coords1 <- data.frame(x=coordinates(densidad[densidad$NAME_2 %in% hosp,])[,1]-0.01,
                      y=coordinates(densidad[densidad$NAME_2 %in% hosp,])[,2]-0.05)
coordinates(coords1) <- ~ x + y 
l3 <- list("sp.points",coords1,pch=17,col=col1,cex=2)

spplot(densidad,"Densidad",col.regions=paleta1,cuts=8,sp.layout=list(l1,l2,l3),
       main=list(label="Mapa de la RSIV")) 

#Por �ltimo, tambi�n pueden construirse mapas en ggplot2. Es importante en primer 
#lugar convertir el objeto Spatial al formato data.frame, esto puede hacerse 
#directamente con la librer�a broom
#Usamos la funci�n tidy:
dens_gg <- tidy(densidad)

#Vemos que este nuevo objeto tiene una columna con longitud y otra con latitud, pero 
#no tiene, por ejemplo, los nombres de los partidos
head(dens_gg)

#A continuaci�n se agregan al data.frame los pol�gonos necesarios para poder 
#representar el mapa
densidad$OBJECTID <- sapply(slot(densidad, "polygons"), function(x) slot(x, "ID"))
dens_gg <- merge(dens_gg, densidad, by.x = "id", by.y="OBJECTID")
head(dens_gg)

#A partir de este data.frame, una representaci�n b�sica de la RSIV es:
mapa2 <- ggplot(data = dens_gg) +
        geom_polygon(data = dens_gg,aes(x = long, y = lat, group = group),colour="black", fill=col1)+
        theme(axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank(),
          axis.title.y=element_blank(),
          axis.text.y=element_blank(),
          axis.ticks.y=element_blank(),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          panel.background = element_blank())

#Creamos un data.frame con los nombres de los partidos y sus respectivas coordenadas:
nombres <- data.frame(long=coordinates(densidad)[,1],lat=coordinates(densidad)[,2],
                      partido=densidad$NAME_2)

rsiv <- mapa2 +
        geom_text(data=nombres, aes(long, lat, label = partido), size=5)+
        geom_point(data=nombres, aes(long, lat+0.05),size=3)

#Con la funci�n ggsave se pueden guardar gr�ficos en distintos formatos
ggsave("rsiv.pdf", plot=rsiv)
ggsave("rsiv.png", plot=rsiv)

#Obtenemos un gr�fico en ggplot con los nombres de las localidades:
mapa3 <- ggplot(data = dens_gg) +
         geom_polygon(data = dens_gg,aes(x = long, y = lat, group = group, fill=Densidad),colour="black")+
         geom_text(data=nombres, aes(long, lat, label = partido), size=5)+
         geom_point(data=nombres, aes(long, lat+0.05))+
         scale_fill_gradient( low = "#FFF7EC", high = "#7F0000")+
         theme(axis.title.x=element_blank(),
               axis.text.x=element_blank(),
               axis.ticks.x=element_blank(),
               axis.title.y=element_blank(),
               axis.text.y=element_blank(),
               axis.ticks.y=element_blank(),
               panel.grid.major = element_blank(), 
               panel.grid.minor = element_blank(),
               panel.background = element_blank())
  

#Tambi�n podemos agrehar las ubicaciones de los hospitales provinciales. Hay que volver a obtener las coordenadas porque el formato que tienen no se puede usar en ggplot
coords2 <- data.frame(x=coordinates(densidad[densidad$NAME_2 %in% hosp,])[,1]-0.01,
                      y=coordinates(densidad[densidad$NAME_2 %in% hosp,])[,2]-0.05)

mapa3 + geom_point(data=coords2, aes(x, y),color=col1,shape=17,size=5)
  

