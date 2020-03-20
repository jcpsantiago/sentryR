# sentryR uses an environment to track state within the package
# pre-calculates a couple of re-used values
# plays well with the glue package too
.sentry_env <- new.env()
# FIXME: should use utils::packageVersion() instead, but that's not working
# with CRAN because the package is checked before being installed, thus there is
# no sentryR package to get the version from
.sentry_env$pkg_version <- "1.1.0.9000"
