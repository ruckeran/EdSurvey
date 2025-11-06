# --------------------------------------------------------------------------------------------------
# -------- Syntax for downloading and reading in OECD PISA data directly from their website --------
# --------------------------------------------------------------------------------------------------

# Packages needed ----------------------------------------------------------------------------------

library(readr)
library(eatGADS)
library(devtools)
devtools::load_all()

# Downloading data with adjusted EdSurvey function -------------------------------------------------

downloadPISA(root = "C:/Users/ruckeran/Downloads", years = c(2000, 2003, 2006, 2009, 2012), database = "INT")

# Reading data one by one because didn't work in one line of code ---------------------------------

# readPISA(path = c("C:/Users/ruckeran/Downloads/PISA/2000",
#                   "C:/Users/ruckeran/Downloads/PISA/2003",
#                   "C:/Users/ruckeran/Downloads/PISA/2006",
#                   "C:/Users/ruckeran/Downloads/PISA/2009",
#                   "C:/Users/ruckeran/Downloads/PISA/2012"), countries = "deu", cognitive = "score", forceReread = TRUE)

years <- c("2000","2003","2006","2009","2012")
base  <- "C:/Users/ruckeran/Downloads/PISA"

# reading individually, using forceReread to ensure that everything is freshly read in
pisa_list2 <- setNames(lapply(years, function(yr) {
  cat("\n--- Reading PISA", yr, "---\n")
  readPISA(path = file.path(base, yr),
           countries = "deu",
           cognitive = "score",
           forceReread = TRUE)
}), years)

pisa_list <- pisa_list2
