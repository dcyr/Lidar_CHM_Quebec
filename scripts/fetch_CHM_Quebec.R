rm(list = ls())
setwd("D:/Lidar_CHM_Quebec/")
### setting working directory (named after current date)
wwd <- paste(getwd(), Sys.Date(), sep = "/")
dir.create(wwd)
setwd(wwd)


require(RCurl)  
require(XML)
require(raster)
require(sf)


##########################################################################
############### load a metadata csv file (if any) in case some files were previously downloaded
######################################################################
x <- list.files("../data") ### or another path if you want to use another list of previously downloaded files
meta <- x[grep("meta", x)] ### make sure it is the 
meta <-  meta[grep("CHM", meta)]

if(length(meta)==0) { ## if file doesn't exist, create a new one
  meta <- data.frame()
} else {
  meta <- read.csv(paste("../data", meta, sep = "/"))
}



################################
### fetch CHM files URLs
urlLIDAR <- read.csv("../data/CHM_URL-list.csv", sep = ";")

#### in case downloading all files is not necessary
n <- 105 # here I chose 100 of them, they're 1Gb in size on average !
####
n <- n-length(which(meta$status=="downloaded")) ### subtract number of already downloaded files to the targetted effective
####
## first remove URLs that have already been downloaded
urlSubset <- which(!urlLIDAR$lidar_url %in% paste0(dirname(meta$sourceURL), "/"))
urlSubset <- sample(1:nrow(urlLIDAR), n)



##########################################################################
############### downloading files
############### (first run this loop, which catch error messages - download sometimes fail)
############### (then, to recover failed downloades, run the following loop)
##########################################################################

for (i in urlSubset) {#1:nrow(urlLIDAR)
  #i <- 1
  url <- urlLIDAR[i,"lidar_url"]
  
    result <- getURL(url,verbose=F,
                   ftp.use.epsv=TRUE,
                   dirlistonly = TRUE)
  
  ### finding the CHM file (CHM = MHC in French)
  fName <- getHTMLLinks(result, xpQuery = "//a/@href[contains(., 'MHC')]")
  fName <- basename(fName[grep(".tif", fName)])
  fName <- fName[!grepl(".xml", fName)]
  url <- paste0(url, fName)
  
  if(url %in% meta$sourceURL) {
    print(paste("file", basename(url), "already downloaded"))
    print("trying to download next one")
    next
  }
  
  
  ### changing  MHC (French) for CHM (English)
  fName <- gsub("MHC", "CHM", fName)

  ### downloading file, bypassing error if any, 
  

  #################downloading with ERROR HANDLING
  possibleError <- tryCatch(
    download.file(url, destfile = fName,
                        mode="wb"),
    error=function(e) e
  )
  
  
  ### error handling, just taking note of errors
  if(inherits(possibleError, "error")) {
    df <- data.frame(fileName = NA,
                     projection = NA,
                     EPSG = NA,
                     xmin = NA,
                     xmax = NA,
                     ymin = NA,
                     ymax = NA,
                     sourceURL = url,
                     status = "error")
    
    
    
  } else { ### if downloaded successfully
    r <- raster(fName)
    ### storing metadata for later use
    bb <- as.numeric(bbox(r))
    df <- data.frame(fileName = fName,
                     projection = st_crs(r)$input,
                     EPSG = st_crs(r)$epsg,
                     xmin = bb[1],
                     xmax = bb[3],
                     ymin = bb[2],
                     ymax = bb[4],
                     sourceURL = url,
                     status = "downloaded")
  }
  
  if(nrow(meta)==0) {
    meta <- df
  } else {
    meta <- rbind(meta, df)
  }
  print(i)
    
}
############################################
write.csv(meta, file = "CHM_metadata.csv", row.names = F)
############################################



################
## error recovery (files for which attempts were already made)
### the use of a "while" loop is very risky here, should probably be changed
meta <- read.csv( "CHM_metadata.csv") ### or it could be 
remaining <- sum(meta$status == "error")
print(paste(remaining, "files remaining"))
while(remaining > 0) {
  for (i in 1:nrow(meta)) {#1:nrow(urlLIDAR)
    status <- meta[i, "status"]
    
    if(status == "downloaded") {
      next
    }
    #i <- 1
    
    url <- meta[i,"sourceURL"]
    fName <- basename(url)
    ### changing  MHC (French) for CHM (English)
    fName <- gsub("MHC", "CHM", fName)
    
    ### downloading file, bypassing error if any, 
    #downloading with ERROR HANDLING
    possibleError <- tryCatch(
      download.file(url, destfile = fName,
                    mode="wb"),
      error=function(e) e
    )
    
    
    ### error handling
    if(inherits(possibleError, "error")) {
      df <- data.frame(fileName = NA,
                       projection = NA,
                       EPSG = NA,
                       xmin = NA,
                       xmax = NA,
                       ymin = NA,
                       ymax = NA,
                       sourceURL = url,
                       status = "error")
      
      
      
    } else { ### if downloaded successfully
      r <- raster(fName)
      ### storing metadata for later use
      bb <- as.numeric(bbox(r))
      df <- data.frame(fileName = fName,
                       projection = st_crs(r)$input,
                       EPSG = st_crs(r)$epsg,
                       xmin = bb[1],
                       xmax = bb[3],
                       ymin = bb[2],
                       ymax = bb[4],
                       sourceURL = url,
                       status = "downloaded")
    }
    
    meta[i,] <- df
    remaining <- sum(meta$status == "error")
    print(paste(remaining, "files remaining"))
  } 
}
write.csv(meta, file = "CHM_metadata.csv", row.names = F)
##


# 
# ####parsing files for metadata
# x <- list.files()
# meta <- data.frame()
# for (i in seq_along(x)) {
#   
# }




