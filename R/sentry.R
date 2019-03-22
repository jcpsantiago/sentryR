# sentryR uses an environment to track state within the package
# plays well with the glue package too
.SentryEnv <- new.env()


#' Parse Sentry DSN
#'
#' @param dsn the DSN of a Sentry project as a character string.
#'
#' @return populates the .SentryEnv environment with character strings
sentry.config <- function(dsn) {
  stopifnot(is.character(dsn) && dsn != "")

  l <- setNames(
    as.list(stringr::str_match(dsn, stringr::regex("(.*)://(\\w*)(:(\\w*))?@(.*)/(.*)"))),
    c("dsn", "protocol", "public_key", "ignore", "secret_key", "host", "project_id")
  )

  stopifnot(dsn == "" || !is.na(l$dsn))

  invisible(list2env(l, .SentryEnv))
}


#' Check if Sentry is configured
#'
#' @return boolean
sentry.configured <- function() {

  mandatory_fields <- purrr::map_lgl(c("public_key", "host", "project_id"),
                                     ~exists(., envir = .SentryEnv))

  all(mandatory_fields) && all(!is.na(c(.SentryEnv$public_key,
                                    .SentryEnv$host,
                                    .SentryEnv$project_id)))
}


#' Send a notification on error
#'
#' @param error
#' @param req
#'
#' @return
#' @example
#' tryCatch(stop("error"), error = sentry.captureException)
sentry.captureException <- function(error, req, tz = "GMT", rows_per_field = 10) {
  if (!sentry.configured()) {
    message("Connection to Sentry is not configured.")
    return()
  }

  if (!is.null(error$calls)) {
    stacktrace <- calls2stacktrace(error$calls)
  } else {
    stacktrace <- list()
  }

  err.type <- paste(class(error), collapse = ",")
  err.message <- gsub('(\\n|\\")', "", as.character(error))

  timestamp <- strftime(as.POSIXlt(Sys.time(), tz = tz), "%Y-%m-%dT%H:%M:%S")

  ## we shouldn't send the whole body to sentry, because some requests
  ## are really really big. The default is set to 10 rows for now.
  ## The as.character is needed otherwise sentry will complain
  ## about malformed JSON
  request_body <- jsonlite::fromJSON(req$postBody) %>%
    purrr::map(., ~ head(., rows_per_field)) %>%
    jsonlite::toJSON(null = "null", auto_unbox = TRUE) %>%
    as.character(.)

  stacktrace_json <- jsonlite::toJSON(stacktrace, auto_unbox = T)

  payload <- glue::glue('{
    "timestamp": "<<timestamp>>",
    "logger": "none",
    "platform": "other",
    "sdk": {
      "name": "sentryR",
      "version": "packageVersion("sentryR")"
    },
    "exception": [{
      "type": "<<err.type>>",
      "value": "<<error$message>>"
    }],
    "stacktrace": {"frames": <<stacktrace_json>>},
    "request": {
      "url": "<<req$PATH_INFO>>",
      "method": "<<req$REQUEST_METHOD>>",
      "data": {
        "Post body": <<request_body>>
      },
      "headers": {
        "Content-Type": "<<req$HTTP_CONTENT_TYPE>>",
        "Host": "<<req$HTTP_HOST>>"
      }
    }
  }', .open = "<<", .close = ">>")

  resp <- httr::POST(
    url = .sentry.url(),
    body = payload, encode = "json",
    httr::add_headers(.headers = .sentry.header())
  )

  if (httr::status_code(resp) == 201 || httr::status_code(resp) == 200) {
    cat("OK.\n")
  } else {
    cat("Error connecting to Sentry:", httr::content(resp, "text"), "\n")
  }
}


.sentry.url <- function() {
  glue::glue("{protocol}://{host}/api/{project_id}/store/", .envir = .SentryEnv)
}


#' Set the response header
#'
#' @return a character vector
.sentry.header <- function() {
  if (!is.na(.SentryEnv$secret_key)) {
    c("X-Sentry-Auth" = glue::glue("Sentry sentry_version=7,
                                   sentry_client=sentryR/{packageVersion('sentryR')},
                                   sentry_timestamp={as.integer(Sys.time())},
                                   sentry_key={public_key},
                                   sentry_secret={secret_key}",
                                   .envir = .SentryEnv))
  } else {
    c("X-Sentry-Auth" = glue::glue("Sentry sentry_version=7,
                                   sentry_client=sentryR/{packageVersion('sentryR')},
                                   sentry_timestamp={as.integer(Sys.time())},
                                   sentry_key={public_key}",
                                   .envir = .SentryEnv))
  }
}
