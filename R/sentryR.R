#' \code{sentryR} package
#'
#' SDK for 'sentry.io', a cross-platform application monitoring service
#'
#' @docType package
#' @name sentryR
NULL

## quiets concerns of R CMD check re: the .'s that appear in pipelines
if (getRversion() >= "2.15.1") {
  utils::globalVariables(c(".", "abs_path", "lineno", ".sentry_env"))
}
