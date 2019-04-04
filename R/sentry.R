#' Parse Sentry DSN
#'
#' @param dsn the DSN of a Sentry project as a character string.
#'
#' @return populates the .SentryEnv environment with character strings
#'
#' @importFrom stringr str_match regex
#' @importFrom stats setNames
#'
#' @export
sentry.config <- function(dsn) {
  l <- stats::setNames(
    as.list(stringr::str_match(dsn, stringr::regex("(.*)://(\\w*)(:(\\w*))?@(.*)/(.*)"))),
    c("dsn", "protocol", "public_key", "ignore", "secret_key", "host", "project_id")
  )

  # Was sentry correctly configured? Abort if a dsn is passed (dsn != "") AND no dsn could be parsed
  # by the regex (is.na(l$dsn)) – the following line is the inverse statement as per de Morgan's law
  stopifnot(dsn == "" || !is.na(l$dsn))

  invisible(list2env(l, .SentryEnv))
}


#' Check if Sentry is configured
#'
#' @return boolean
#' @importFrom purrr map_lgl
sentry.configured <- function() {

  mandatory_fields <- purrr::map_lgl(c("public_key", "host", "project_id"),
                                     ~exists(., envir = .SentryEnv))

  all(mandatory_fields) && all(!is.na(c(.SentryEnv$public_key,
                                    .SentryEnv$host,
                                    .SentryEnv$project_id)))
}


#' Send a notification on error
#'
#' @param error error object
#' @param req request object from Plumber
#' @param rows_per_field limit the number of rows sent to Sentry, Default: 10
#'
#' @return message
#' @importFrom magrittr %>%
#' @importFrom jsonlite fromJSON toJSON
#' @importFrom purrr map
#' @importFrom glue glue
#' @importFrom httr POST add_headers status_code
#' @export
sentry.captureException <- function(error, req, rows_per_field = 10) {
  if (!sentry.configured()) {
    message("Connection to Sentry is not configured.")
    return()
  }

  if (!is.null(error$calls)) {
    stacktrace <- calls2stacktrace(error$calls)
  } else {
    stacktrace <- list()
  }

  error_type <- paste(class(error), collapse = ",")
  error_message <- gsub('(\\n|\\")', "", as.character(error))

  # Sentry will treat the timezone as UTC/GMT by default
  timestamp <- strftime(as.POSIXlt(Sys.time(), tz = "GMT"), "%Y-%m-%dT%H:%M:%S")

  # we shouldn't send the whole body to sentry, because some requests
  # are really really big. The default is set to 10 rows for now.
  # The as.character is needed otherwise sentry will complain
  # about malformed JSON
  request_body <- jsonlite::fromJSON(req$postBody) %>%
    purrr::map(., ~ head(., rows_per_field)) %>%
    jsonlite::toJSON(null = "null", auto_unbox = TRUE) %>%
    as.character(.)

  stacktrace_json <- jsonlite::toJSON(stacktrace, auto_unbox = T)

  payload <- glue::glue('{
    "timestamp": "<<timestamp>>",
    "logger": "R",
    "platform": "other",
    "sdk": {
      "name": "<<.packageName>>",
      "version": "<<as.character(packageVersion(.packageName))>>"
    },
    "exception": [{
      "type": "<<error_type>>",
      "value": "<<error_message>>",
      "stacktrace": {"frames": <<stacktrace_json>>}
    }],
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
    message("Error successfully sent to Sentry, check your project for more details.\n")
  } else {
    message("Error connecting to Sentry:", httr::content(resp, "text"), "\n")
  }
}


#' Build the response URL
#'
#' @return a character string
#' @importFrom glue glue
.sentry.url <- function() {
  glue::glue("{protocol}://{host}/api/{project_id}/store/", .envir = .SentryEnv)
}


#' Set the response header
#'
#' @return a character vector
#' @importFrom glue glue
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
