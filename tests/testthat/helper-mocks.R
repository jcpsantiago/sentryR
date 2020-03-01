# mock request
# From the plumber tests
# https://github.com/rstudio/plumber/blob/master/tests/testthat/helper-mock-request.R
make_req <- function(verb, path, qs = "", body = "") {
  req <- new.env()
  req$REQUEST_METHOD <- toupper(verb)
  req$PATH_INFO <- path
  req$QUERY_STRING <- qs
  req$rook.input <- list(read_lines = function() {
    body
  })
  req
}

# mock error
error_nocalls <- simpleError("Reverse polarisation!!",
  call = function() "He's dead Jim."
)

error_wcalls <- simpleError("Reverse polarisation!!",
  call = function() "He's dead Jim."
)

# mock sentry DSN
.sentry_env <- new.env()
.sentry_env$public_key <- "1234"
.sentry_env$host <- "sentry.io"
.sentry_env$project_id <- "1"

# mock response for sentry.configured
not_configured <- mockery::mock(FALSE)
configured <- mockery::mock(TRUE)
