# sentryR uses an environment to track state within the package
# pre-calculates a couple of re-used values
# plays well with the glue package too
sentry_env <- new.env(parent = emptyenv())
sentry_env$pkg_version <- utils::packageVersion("sentryR")
sentry_env$as.integer <- base::as.integer
sentry_env$Sys.time <- base::Sys.time

installed_pkgs_df <- as.data.frame(installed.packages(),
  stringsAsFactors = FALSE
)
versions <- installed_pkgs_df$Version
names(versions) <- installed_pkgs_df$Package
modules <- as.list(versions)
sentry_env$modules <- modules

sys_info <- Sys.info()

sentry_env$payload_skeleton <- list(
  # Sentry will treat the timezone as UTC/GMT by default
  timestamp = NULL,
  logger = "R",
  platform = "R", # Sentry will ignore this for now
  sdk = list(
    name = "SentryR",
    version = as.character(utils::packageVersion("SentryR"))
  ),
  event_id = NULL,
  modules = modules,
  environment = NULL,
  contexts = list(
    os = list(
      name = sys_info[["sysname"]],
      version = sys_info[["release"]],
      kernel_version = sys_info[["version"]]
    ),
    runtime = list(
      version = glue::glue("{R.version$major}.{R.version$minor}"),
      type = "runtime",
      name = "R",
      build = R.version$version.string
    ),
    app = list(
      app_name = NULL,
      app_version = NULL
    )
  )
)

# shut up R CMD check
globalVariables(".")
