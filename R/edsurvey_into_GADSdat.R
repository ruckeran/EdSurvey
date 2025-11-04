# --------------------------------------------------------------------------------------------------
# -------------------------- Converting EdSurvey.DataFrame into GADSdat ----------------------------
# --------------------------------------------------------------------------------------------------

# Packages needed ----------------------------------------------------------------------------------

library(tidyr)
library(dplyr)


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

# Renaming the columns for GADSdat
dat_long <- dat_long %>%
  rename(varName = variableName,
         varLabel = Labels,
         value   = code,
         valLabel = label)

# Creating new missing tags (with the help of the variables dat_long$value and dat_long$missing)
dat_long$missings <- mapply(function(val, miss_str) {
  val_chr <- as.character(val) # Ensuring the incoming value is treated as a character string
  if (is.na(val)) return(NA_character_) # If the value itself is missing -> NA
  miss_vals <- unlist(strsplit(as.character(miss_str), ";")) # If semicolon exists, splitting into individual codes
  if (val_chr %in% miss_vals || val_chr %in% c("n", "r")) "miss" else "valid"
}, dat_long$value, dat_long$missing, USE.NAMES = FALSE)

# Keeping only necessary columns for GADSdat
dat_long2 <- dat_long %>%
  select(c("varName", "varLabel", "value", "valLabel", "missings"))


# Preparing meta data and data for GADSdat ---------------------------------------------------------

varLabels <- data.frame(varName = dat$variableName,
                        varLabel = dat$Labels,
                        stringsAsFactors = FALSE)
valLabels <- data.frame(varName = dat_long2$varName,
                        value = dat_long2$value,
                        valLabel = dat_long2$valLabel,
                        missings = dat_long2$missings,
                        stringsAsFactors = FALSE)

vars <- pisa_list2$`2000`$dataList$Student$fileFormat$variableName # Saving variable names out of fileFormat
n <- length(vars_unique) # How many elements do we need for the data frame
df <- as.data.frame(
  setNames(replicate(n, character(0), simplify = FALSE), vars_unique),
  stringsAsFactors = FALSE
)

# > df2 <- as.data.frame(lapply(vars_unique, function(x) character(0)))
# > names(df2) <- vars_unique
# > all.equal(df, df2)


valLabels2 <- valLabels
valLabels2$value <- as.numeric(valLabels2$value)
## error hunt following
table(valLabels$value[is.na(valLabels2$value)], valLabels2$value[is.na(valLabels2$value)],
      useNA = "if")

gads <- import_raw(df = df, varLabels = varLabels, valLabels = valLabels,
                   checkVarNames = FALSE)  # Creating GADSdat
