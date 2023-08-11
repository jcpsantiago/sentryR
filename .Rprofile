.maybe_message <- if (interactive()) message else function(...) {invisible()}

.home_rprofile <- path.expand("~/.Rprofile")
if (file.exists(.home_rprofile)) {
  .maybe_message("🏠 sentryR/.Rprofile: loading ~/.Rprofile")
  source(.home_rprofile)
  .maybe_message()
}

if (!isNamespaceLoaded("renv")) {
  .maybe_message("🌱 sentryR/.Rprofile: activating `renv`")
  source("renv/activate.R")
  .maybe_message()
}

invisible()
