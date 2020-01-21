# mock request
req <- list(
  PATH_INFO = "/launch_eva01",
  REQUEST_METHOD = "angel_attack",
  postBody = '[{"battery_level": "5 min"}]',
  HTTP_CONTENT_TYPE = "emergency launch",
  HTTP_HOST = "central dogma"
)

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
