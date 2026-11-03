# Export inspectable copies of the geographic layers actually used in the join.
library(sf)
library(dplyr)
library(readr)
features <- st_read("data/raw/crw/station_polygons.geojson", quiet = TRUE)
catalogue <- read_csv("data/derived/region_catalogue.csv", show_col_types = FALSE)
regions <- features |>
  filter(st_geometry_type(geometry) %in% c("POLYGON", "MULTIPOLYGON")) |>
  mutate(region_id = sub("\\.php.*$", "", gauge_page)) |>
  select(region_id) |>
  left_join(catalogue |> select(region_id = station_id, name = station_name),
            by = "region_id", relationship = "one-to-one") |>
  st_cast("MULTIPOLYGON")
lookup <- read_csv("data/derived/reef_region_lookup.csv", show_col_types = FALSE)
reefs <- lookup |>
  select(subsite_id, site, country, region_id = station_id, longitude, latitude) |>
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)
# Short, explicit field names avoid the Shapefile ten-character field-name limit.
dir.create("data/spatial", recursive = TRUE, showWarnings = FALSE)
st_write(regions, "data/spatial/noaa_regions.shp", delete_layer = TRUE, quiet = TRUE,
         layer_options = "ENCODING=UTF-8")
st_write(reefs, "data/spatial/reef_sites.shp", delete_layer = TRUE, quiet = TRUE,
         layer_options = "ENCODING=UTF-8")
read_regions <- st_read("data/spatial/noaa_regions.shp", quiet = TRUE)
read_reefs <- st_read("data/spatial/reef_sites.shp", quiet = TRUE)
stopifnot(nrow(read_regions) == 214, nrow(read_reefs) == 102,
          setequal(read_regions$region_id, regions$region_id),
          setequal(read_reefs$subsite_id, reefs$subsite_id),
          st_crs(read_regions)$epsg == 4326, st_crs(read_reefs)$epsg == 4326,
          identical(read_regions$region_id, regions$region_id),
          identical(read_reefs$region_id, reefs$region_id),
          max(abs(st_coordinates(read_reefs) - st_coordinates(reefs))) < 1e-10)
message("Exported and read back 214 NOAA region polygons and 102 reef coordinates.")
