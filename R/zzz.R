# sentryR uses an environment to track state within the package
# pre-calculates a couple of re-used values
# plays well with the glue package too
# TODO: do we really need to use emptyenv() here?
.sentry_env <- new.env(parent = emptyenv())

pkg_version <- as.character(utils::packageVersion("SentryR"))

.onLoad <- function(libname, pkgname) {
  .sentry_env$pkg_version <- pkg_version
  .sentry_env$as.integer <- base::as.integer
  .sentry_env$Sys.time <- base::Sys.time
}
