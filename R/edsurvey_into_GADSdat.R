# --------------------------------------------------------------------------------------------------
# -------------------------- Converting EdSurvey.DataFrame into GADSdat ----------------------------
# --------------------------------------------------------------------------------------------------

# Packages needed ----------------------------------------------------------------------------------

library(tidyr)
library(dplyr)
library(eatGADS)

# Splitting labelValues at "^" ---------------------------------------------------------------------

dat <- pisa_list2$`2000`$dataList$Student$fileFormat
max_parts <- max(sapply(strsplit(dat$labelValues, "\\^"), length), na.rm = TRUE) # Determine the number of parts per line
into <- paste0("val", seq_len(max_parts)) # Generate and separate column names
dat_wide <- tidyr::separate(dat, labelValues, into = into, sep = "\\^", fill = "right") %>%
  select(!(Start:multiplier) & !(labelled) & !(Type:Width2))


# Converting dat into long format (and splitting values and value labels) --------------------------

dat_long <- dat_wide |>
  pivot_longer(cols = starts_with("val"),
               names_to = "valnum",
               values_to = "pair",
               values_drop_na = TRUE) |>
  separate(pair, into = c("code", "label"),
           sep = "=", fill = "right")

# GADSdats expect specific variable names
dat_long <- dat_long %>%
  rename(varName = variableName,
         varLabel = Labels,
         value   = code,
         valLabel = label)

# Creating new missing tags
setMissingtags <- function(val, miss_str) {
  val_chr <- as.character(val)
  if (is.na(val)) return(NA_character_) # if the value itself is missing -> NA
  miss_vals <- unlist(strsplit(as.character(miss_str), ";")) # split semicolon-separated codes
  if (val_chr %in% miss_vals || val_chr %in% c("n", "r")) "miss" else "valid"
}

dat_long$missings <- mapply(setMissingtags, dat_long$value, dat_long$missing, USE.NAMES = FALSE)


# Preparing meta data and data for GADSdat ---------------------------------------------------------

n <- length(dat$variableName)
varLabels <- data.frame(varName = dat$variableName,
                        varLabel = dat$Labels,
                        format = rep(NA, n),
                        display_width = rep(NA, n),
                        labeled = rep(NA, n),
                        stringsAsFactors = FALSE)
valLabels <- data.frame(varName = dat_long$varName,
                        value = dat_long$value,
                        valLabel = dat_long$valLabel,
                        missings = dat_long$missings,
                        stringsAsFactors = FALSE)
labels <- merge(varLabels, valLabels, by = "varName", all.x = FALSE, sort = FALSE)

vars <- pisa_list2$`2000`$dataList$Student$fileFormat$variableName
df <- as.data.frame(lapply(vars, function(x) character(0)))
names(df) <- vars

gads <- eatGADS:::new_GADSdat(df, labels)
