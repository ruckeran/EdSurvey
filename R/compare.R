library(eatFDZ)


pisa2000 <- eatGADS::import_spss("https://fdz.iqb.hu-berlin.de/media/study_files/61/PISA2000_15J_SC.sav", checkVarNames = FALSE)

gads2 <- gads
gads2$labels$value <- as.numeric(gads2$labels$value)

test <- compare_data(gads2, pisa2000, name_data1 = "OECD", name_data2 = "FDZ",
                     metaExceptions = c("display_width", "labeled", "format"))
eatAnalysis::write_xlsx(test, "C:/Users/ruckeran/Downloads/PISA.xlsx")
