##########################################
#### EdSurvey Data Frame into GADSdat ####

library(tidyr)
library(dplyr)

### 1. Splitting labelValues at "^"
dat <- pisa_list2$`2000`$dataList$Student$fileFormat
max_parts <- max(sapply(strsplit(dat$labelValues, "\\^"), length), na.rm = TRUE) # Determine the number of parts per line
into <- paste0("val", seq_len(max_parts)) # Generate and separate column names
dat_wide <- tidyr::separate(dat, labelValues, into = into, sep = "\\^", fill = "right", extra = "merge")

### 2. Converting dat into long format (and splitting values and value labels)
dat_long <- dat_wide |>
  pivot_longer(cols = starts_with("val"),
               names_to = "valnum",
               values_to = "pair",
               values_drop_na = TRUE) |>
  separate(pair, into = c("code", "label"),
           sep = "=", fill = "right", extra = "merge")

# Renaming the columns for GADSdat
dat_long <- dat_long %>%
  rename(varName = variableName,
         varLabel = Labels,
         value   = code,
         valLabel = label)

# Creating new missing tags
dat_long$missings <- mapply(function(val, miss_str) {
  val_chr <- as.character(val)
  if (is.na(val) || trimws(val_chr) == "") return(NA_character_) # If the value itself is missing or only contains spaces -> NA
  if (is.na(miss_str) || trimws(as.character(miss_str)) == "") return("valid") # If no missing definition -> “valid”
  miss_vals <- unlist(strsplit(as.character(miss_str), "[;,\\s]+")) # Parsing and comparing missing codes
  miss_vals <- trimws(gsub("^['\"]|['\"]$", "", miss_vals))
  if (val_chr %in% miss_vals) "miss" else "valid"
}, dat_long$value, dat_long$missing, USE.NAMES = FALSE)

# Keeping only necessary columns for GADSdat
dat_long2 <- dat_long %>%
  select(any_of(c("varName", "varLabel", "value", "valLabel", "missings")))

### 3. Preparing meta data and data for GADSdat
varLabels <- data.frame(varName = dat$variableName,
                        varLabel = dat$Labels,
                        stringsAsFactors = FALSE)
valLabels <- data.frame(varName = dat_long2$varName,
                        value = dat_long2$value,
                        valLabel = dat_long2$valLabel,
                        missings = dat_long2$missings,
                        stringsAsFactors = FALSE)

vars <- pisa_list2$`2000`$dataList$Student$fileFormat$variableName # Saving variable names out of fileFormat
vars_unique <- unique(vars) # make varnames unique
n <- length(vars_unique) # how many elements do we need for the data frame
df <- as.data.frame(
  setNames(replicate(n, character(0), simplify = FALSE), vars_unique),
  stringsAsFactors = FALSE
)

gads <- import_raw(df = df, varLabels = varLabels, valLabels = valLabels)  # Creating GADSdat


