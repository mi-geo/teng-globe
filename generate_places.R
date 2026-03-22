# =============================================================================
# generate_places.R
#
# Downloads three boundary databases, filters to your visited places,
# and writes visited_places.json for globe.html.
#
# Assumed packages (install once before running):
#   install.packages(c("sf", "dplyr", "readr", "stringr",
#                      "jsonlite", "rmapshaper", "geojsonsf",
#                      "tigris", "rnaturalearth", "rnaturalearthdata"))
#   remotes::install_github("xmc811/cnmap")   # China county-level data
#
# Usage:
#   Rscript generate_places.R
#   (run from the folder that contains visited_regions.csv)
# =============================================================================

library(sf)
library(dplyr)
library(readr)
library(stringr)
library(jsonlite)
library(rmapshaper)
library(geojsonsf)
library(tigris)
library(rnaturalearth)
library(rnaturalearthdata)
library(cnmap)

options(tigris_use_cache = TRUE)   # cache tigris downloads locally

# ── Config ────────────────────────────────────────────────────────────────────
SIMPLIFY    <- 0.05    # 0 = full detail, 1 = maximum simplification
us_places <- st_read( "C:/Users/zhang/Data_Research/globe/usa.geojson" )
cn_places <- st_read( "C:/Users/zhang/Data_Research/globe/china.geojson" )
ad_places <- st_read( "C:/Users/zhang/Data_Research/globe/world_prov.geojson" )
wd_places <- st_read( "C:/Users/zhang/Data_Research/globe/world_sovn.geojson" )


# read management.xlsx , 
# and select and merge the data where 'travelled' == 1
# ── Read management file ──────────────────────────────────────────────────────
cn_manage <- read_xlsx("data_entry.xlsx", sheet = "CN")
us_manage <- read_xlsx("data_entry.xlsx", sheet = "US")
ad_manage <- read_xlsx("data_entry.xlsx", sheet = "Adm1")
wd_manage <- read_xlsx("data_entry.xlsx", sheet = "World")



# ── Filter to visited only ────────────────────────────────────────────────────
cn_visited <- cn_manage |> filter(travelled == 1)
us_visited <- us_manage |> filter(travelled == 1)
ad_visited <- ad_manage |> filter(travelled == 1)
wd_visited <- wd_manage |> filter(travelled == 1)



cn_places$coun_label <- NULL
cn_out <- cn_places |>
  inner_join(
    cn_visited |> select(coun_code, coun_label, batch ),
    by = "coun_code"
  )
us_out <- us_places |>
  inner_join(
    us_visited |> select(fips5, coun_label,batch ),
    by = "fips5"
  )
ad_out <- ad_places |>
  inner_join(
    ad_visited |> select(iso_3166_2 , name, type, batch ),
    by = c("iso_3166_2","name",'type')
  )
wd_out <- wd_places |>
  inner_join(
    wd_visited |> select(GEOUNIT, batch ),
    by = "GEOUNIT"
  )


st_write(
  cn_out,
  "C:/Users/zhang/GitHub/teng-globe/china.json",
  driver = "GeoJSON",
  delete_dsn = TRUE
)
st_write(
  us_out,
  "C:/Users/zhang/GitHub/teng-globe/usa.json",
  driver = "GeoJSON",
  delete_dsn = TRUE
)
ad_out <- ms_simplify(sf_geojson(ad_out), keep = 0.2) 
# Saving the JSON file
writeLines(ad_out, "C:/Users/zhang/GitHub/teng-globe/adm1.json")

wd_out <- ms_simplify(sf_geojson(wd_out), keep = 0.05) 
# Saving the JSON file
writeLines(wd_out, "C:/Users/zhang/GitHub/teng-globe/world.json")

plot(st_read(wd_out)[1][3,])
plot(st_read(ad_out)[1][3,])
plot(gdf_prov$name[1])
