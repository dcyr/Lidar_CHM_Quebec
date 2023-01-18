rm(list = ls())
setwd("C:/Users/dcyr-z840/Desktop/Lidar_CHM_Quebec/")
### setting working directory (named after current date)
wwd <- paste(getwd(), Sys.Date(), sep = "/")
dir.create(wwd)
setwd(wwd)


require(RCurl)  
require(XML)
require(raster)
require(sf)


################################
### downloading Qc LIDAR data
urlBuildings <- read.csv("../sourceInfo/Index_Bati.csv")

for (i in 1:nrow(urlBuildings)) {
  #i <- 1
  url <- urlBuildings[i,"SHP"]
  fName <-  paste0(urlBuildings[i,"Nom"], ".zip")
  download.file(url, destfile = "temp.zip",
                mode="wb")
  unzip("temp.zip")
  
}
