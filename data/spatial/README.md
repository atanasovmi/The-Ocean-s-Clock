# Geographic layers

The source polygons are NOAA Coral Reef Watch's published regional boundaries, preserved in `data/raw/crw/station_polygons.geojson`. The actual analysis uses these source polygons with `sf::st_join()` and the recorded reef coordinates. It does not choose regions by whichever marker happens to be nearest.

`R/export_spatial_data.R` writes two Shapefiles for inspection:

| Layer | Contents | Useful fields |
| --- | --- | --- |
| `noaa_regions.shp` | 214 NOAA region polygons | `region_id`, `name` |
| `reef_sites.shp` | 102 natural-reef subsite coordinates | `subsite_id`, `site`, `country`, `region_id` |

Both layers use WGS84 (EPSG:4326). A Shapefile consists of several companion files: keep the `.shp`, `.shx`, `.dbf`, `.prj` and `.cpg` files together. Short field names avoid the format's ten-character field-name limit.

```r
library(sf)
reefs <- st_read("data/spatial/reef_sites.shp")
regions <- st_read("data/spatial/noaa_regions.shp")
```

Five subsites fall outside the published polygons and retain a missing `region_id`. The full spatial lookup is `data/derived/reef_region_lookup.csv`. Once dates are also matched, 751 of the 1,026 recorded reef-nights have NOAA environmental context. Regional satellite statistics describe broad ocean conditions, not a thermometer reading at coral depth.
