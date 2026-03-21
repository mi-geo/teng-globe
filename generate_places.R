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

# save the files to management.xlsx
# ── China ─────────────────────────────────────────────────────────────────────
cn_df <- cn_places |>
  st_drop_geometry() |>                          # remove geometry
  arrange(prov_name, pref_name) |>               # sort by province then prefecture
  mutate( section = NA, travelled = NA)            # add two empty columns

# ── US ────────────────────────────────────────────────────────────────────────
us_df <- us_places |>
  st_drop_geometry() |>
  arrange(state_name, county_name) |>            # sort by state then county
  mutate(section = NA, travelled = NA)
state_map <- c(
  AL = "Alabama", AK = "Alaska", AZ = "Arizona", AR = "Arkansas",
  CA = "California", CO = "Colorado", CT = "Connecticut",
  DE = "Delaware", FL = "Florida", GA = "Georgia",
  HI = "Hawaii", ID = "Idaho", IL = "Illinois", IN = "Indiana",
  IA = "Iowa", KS = "Kansas", KY = "Kentucky", LA = "Louisiana",
  ME = "Maine", MD = "Maryland", MA = "Massachusetts",
  MI = "Michigan", MN = "Minnesota", MS = "Mississippi",
  MO = "Missouri", MT = "Montana", NE = "Nebraska",
  NV = "Nevada", NH = "New Hampshire", NJ = "New Jersey",
  NM = "New Mexico", NY = "New York", NC = "North Carolina",
  ND = "North Dakota", OH = "Ohio", OK = "Oklahoma",
  OR = "Oregon", PA = "Pennsylvania", RI = "Rhode Island",
  SC = "South Carolina", SD = "South Dakota", TN = "Tennessee",
  TX = "Texas", UT = "Utah", VT = "Vermont",
  VA = "Virginia", WA = "Washington", WV = "West Virginia",
  WI = "Wisconsin", WY = "Wyoming", DC = "District of Columbia"
)
state_map_rev <- setNames(names(state_map), state_map)
us_df$state_sn <- state_map_rev[us_df$state_name]

# ── Write to manage.xlsx ──────────────────────────────────────────────────────
library(writexl)
write_xlsx(
  list(CN = cn_df, US = us_df),
  "C:/Users/zhang/GitHub/teng-globe/data_entry.xlsx"
)
message("Saved manage.xlsx with ", nrow(cn_df), " China rows and ", nrow(us_df), " US rows")


# read management.xlsx , 
# and select and merge the data where 'travelled' == 1
# ── Read management file ──────────────────────────────────────────────────────
cn_manage <- read_xlsx("data_entry.xlsx", sheet = "CN")
us_manage <- read_xlsx("data_entry.xlsx", sheet = "US")

# ── Filter to visited only ────────────────────────────────────────────────────
cn_visited <- cn_manage |> filter(travelled == 1)
us_visited <- us_manage |> filter(travelled == 1)

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


