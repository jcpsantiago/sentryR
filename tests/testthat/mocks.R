# mock request
req <- new.env()
req$postBody <- '{"a": 123}'
req$PATH_INFO <- "/endpoint"
req$REQUEST_METHOD <- "POST"
req$HTTP_CONTENT_TYPE <- "application/json"
req$HTTP_HOST <- "127.0.0.1"

# mock error
error_nocalls <- simpleError("Reverse polarisation!!",
                             call = function() "He's dead Jim.")

error_wcalls <- simpleError("Reverse polarisation!!",
                            call = function() "He's dead Jim.")

# mock sentry DSN
.SentryEnv <- new.env()
.SentryEnv$public_key <- "1234"
.SentryEnv$host <- "sentry.io"
.SentryEnv$project_id <- "1"

# mock response for sentry.configured
not_configured <- mockery::mock(FALSE)
configured <- mockery::mock(TRUE)
