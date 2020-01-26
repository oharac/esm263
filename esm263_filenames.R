library(tidyverse)

f <- list.files(file.path('~/Desktop/esm263_asst1'),
                recursive = TRUE)
df <- data.frame(asst_file = f, stringsAsFactors = FALSE) %>%
  mutate(student = str_replace_all(asst_file, '_[0-9].+', ''),
         fname = basename(asst_file))
