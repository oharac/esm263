### Helper functions to check for and inspect differences between rasters

find_diffs <- function(test_rast, key_rast) {
  ### normalize both rasters to 1s. 
  ### Presumably, extents, CRS, and res should be identical, so 
  ### stack should work just fine:
  s_rast_norm <- test_rast / test_rast
  k_rast_norm <- key_rast / key_rast
  tmp_stack <- stack(s_rast_norm, -k_rast_norm)

  diff_rast <- calc(tmp_stack, fun = sum, na.rm = TRUE)
  diff_rast[values(diff_rast) == 0] <- NA
  return(diff_rast)
}

plot_diffs <- function(test_rast, key_rast, title = NULL) {
  tmp <- find_diffs(test_rast, key_rast)
  if(is.null(title)) title <- names(test_rast)
  mapview(tmp, layer.name = title,
          col.regions = c("purple", "darkgreen"))
}

check_rast <- function(test_rast, key_rast, tol = .002) {
  n_cells_key <- sum(!is.na(values(key_rast)))
  
  cellcount <- sum(!is.na(values(test_rast)) - n_cells_key)
  cellcount_check <- cellcount / n_cells_key %>%
    abs()
  
  ### find cells where the two rasters disagree 
  diff_rast <- find_diffs(test_rast, key_rast) %>%
    abs()
  
  celldiff <- sum(values(diff_rast), na.rm = TRUE)
  celldiff_check <- celldiff / n_cells_key
  
  check <- celldiff_check <= tol & cellcount_check <= tol
  
  return(data.frame(good      = check,
                    diff_tot  = celldiff,
                    celldiff  = celldiff_check, 
                    cellcount = cellcount_check))
}

plot_sf <- function(x_sf, title = NULL) {
  if(length(x_sf) > 1) {
    x_sf <- x_sf %>% select(1)   
  }
  plot(x_sf, main = title)
}
