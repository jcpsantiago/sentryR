message("🌱 sentryR/.Rprofile: activating `renv`")
source("renv/activate.R")
message()

.home_rprofile <- path.expand("~/.Rprofile")
if (file.exists(.home_rprofile)) {
  message("🏠 sentryR/.Rprofile: loading ", .home_rprofile)
  source(.home_rprofile)
  message()
}

message("▶️ sentryR/.Rprofile: all set")
message("- use `devtools::load_all()` to load library")
message("- use `devtools::test()` to run tests")

invisible()
