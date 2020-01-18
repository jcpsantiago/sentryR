#' Parse a Sentry DSN into its components
#'
#' @param dsn the DSN of a Sentry project.
#'
#' @return a named list with parsed elements of the DSN
#' @export
#'
#' @examples
#' parse_dsn("https://1234@sentry.io/1")
parse_dsn <- function(dsn) {
  if (!is.character(dsn)) {
    stop(
      paste("dsn must be a character string, not", class(dsn))
    )
  }

  dsn_fields <- stats::setNames(
    as.list(stringr::str_match(dsn, stringr::regex("(.*)://(\\w*)(:(\\w*))?@(.*)/(.*)"))),
    c("dsn", "protocol", "public_key", "ignore", "secret_key", "host", "project_id")
  )

  if (is.na(dsn_fields$dsn)) {
    stop("Invalid DSN! Expected format is 'https://<public_key>@<host>/<project_id>' ",
         "but received '", dsn, "' instead.")
  }

  mandatory_fields_present <- sapply(
    c("public_key", "host", "project_id"),
    function(x) !is.na(dsn_fields[[x]]) & dsn_fields[[x]] != "")

  if (!all(mandatory_fields_present)) {
    stop("Expected fields 'https://<public_key>@<host>/<project_id>', but can't find ",
             paste(names(mandatory_fields_present)[!mandatory_fields_present],
                   collapse = ", "), " in '", dsn, "'. Please check your DSN.")
  }

  return(dsn_fields)
}


#' Configure Sentry
#'
#' @param dsn the DSN of a Sentry project.
#'
#' @return populates the .SentryEnv environment with character strings
#'
#' @export
#'
#' @examples
#' \dontrun{
#' configure_sentry("https://12345abcddbc45e49773bb1ca8d9c533@sentry.io/1234567")
#' .SentryEnv$host # sentry.io
#' }
configure_sentry <- function(dsn) {

  if (length(dsn) > 1) {
    stop("Expected one dsn, but received ", length(dsn), " instead.")
  }

  parsed <- parse_dsn(dsn)

  invisible(list2env(parsed, .SentryEnv))
}


#' Check if Sentry is configured
#'
#' @return boolean
#'
#' @export
#'
#' @examples
#' \dontrun{
#' configure_sentry("https://12345abcddbc45e49773bb1ca8d9c533@sentry.io/1234567")
#' is_sentry_configured() # TRUE
#' }
is_sentry_configured <- function() {

  mandatory_fields <- sapply(
    c("public_key", "host", "project_id"),
    function(x) exists(x, envir = .SentryEnv))

  all_fields_present <- all(mandatory_fields) && all(!is.na(c(
                          .SentryEnv$public_key,
                          .SentryEnv$host,
                          .SentryEnv$project_id
                        )))

  if (!all_fields_present) {
    message(
      paste0("Expected public_key, host and project_id to be present but can't find ",
             paste(names(mandatory_fields)[!mandatory_fields],
                   collapse = ", "), "."))

    return(FALSE)
  }

  return(all_fields_present)
}


#' Prepare JSON payload for Sentry
#'
#' @param ... named parameters
#'
#' @return
#' @export
#'
#' @examples
prepare_payload <- function(...) {
  # FIXME: don't allow unnamed lists e.g. prepare_paylaod(list(foo = 12, bar = 45))
  if (any(names(c(...)) == "")) {
    stop("All elements must be named!")
  }

  user_inputs <- list(...)

  # TODO: check that user_inputs contains only valid names
  # according to Sentry's documentation, and NULLify those not overwriteable

  # Hexadecimal string representing a uuid4 value.
  # The length is exactly 32 characters. Dashes are not allowed.
  uuid <- gsub(pattern = "-", replacement = "",
               x = uuid::UUIDgenerate(use.time = TRUE))

  defaults <- list(
    # Sentry will treat the timezone as UTC/GMT by default
    timestamp = strftime(as.POSIXlt(Sys.time(), tz = "GMT"), "%Y-%m-%dT%H:%M:%SZ"),
    logger = dplyr::if_else(is.null(user_inputs$logger), "R", user_inputs$logger),
    platform = "R",
    sdk = list(
      name = "SentryR",
      version = as.character(packageVersion("SentryR"))),
    event_id = uuid
  )

  if ("logger" %in% names(user_inputs)) {
    user_inputs$logger <- NULL
  }

  defaults_plus_userfields <- append(defaults, user_inputs)

  payload <- jsonlite::toJSON(defaults_plus_userfields,
                              auto_unbox = TRUE,
                              null = 'null')

  return(payload)
}


#' Send a message to a Sentry server
#'
#' @param ... named parameters
#'
#' @return sends message to Sentry
#' @export
#'
#' @examples
capture <- function(...) {

  if (!is_sentry_configured()) {
    stop("Sentry is not configured!")
  }

  payload <- prepare_payload(...)

  resp <- httr::POST(
    url = sentry_url(),
    body = payload, encode = "json",
    httr::add_headers(.headers = sentry_headers())
  )

  resp_status_code <- httr::status_code(resp)

  if (resp_status_code == 201 || resp_status_code == 200) {
    resp_body <- httr::content(resp)
    message("Your event was recorder in Sentry with ID ", resp_body$id)
  } else {
    warning(
      "Error connecting to Sentry:",
      httr::content(resp, "text", encoding = "UTF-8")
    )
  }
}


#' Report a message
#'
#' @param .message message text
#' @param ... optional additional named paramters
#' @param .level the level of the message. Default: "info"
#'
#' @return nothing; sends message to Sentry
#' @export
#'
#' @examples
#' \dontrun{
#' capture_message("this is an important message", logger = "my.logger")
#' }
capture_message <- function(.message, ..., .level = "info") {
  # TODO: hello? happy path?
  capture(message = .message, ..., level = .level)
}


#' Report an error or exception object
#'
#' @param error an error object
#' @param ... optional additional named paramters
#' @param .level the level of the message. Default: "error"
#'
#' @return nothing; sends error to Sentry
#' @export
#'
#' @examples
#' \dontrun{
#' capture_exception(simpleError("foo"), tags = list(version = "1.0"))
#' }
capture_exception <- function(error, ..., .level = "error") {
  # TODO: hello? happy path?
  # TODO: wrangling the error should be a pure function prepare_error()

  if (!is.null(error$calls)) {
    stacktrace <- calls2stacktrace(error$calls)
  } else {
    stacktrace <- data.frame()
  }

  error_type <- paste(class(error), collapse = ",")
  error_message <- gsub('(\\n|\\")', "", as.character(error))

  exception_payload <- list(
    exception = tibble::tibble(
      type = error_type,
      message = error_message,
      stacktrace = list(
        frames = stacktrace
      )
    )
  )

  capture(exception = exception_payload, ..., level = .level)
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
  if (!is_sentry_configured()) {
    warning("An error occured but Sentry is not configured.")
    return()
  }

  if (!is.null(error$calls)) {
    stacktrace <- calls2stacktrace(error$calls)
  } else {
    stacktrace <- list()
  }

  # Ensure a non-empty body for jsonlite::fromJSON(req$postBody)
  if (identical(req$postBody, character(0))) {
    req$postBody <- "[]"
  }

  # Ensure that req$HTTP_CONTENT_TYPE is exists
  if (is.null(req$HTTP_CONTENT_TYPE)) {
    req$HTTP_CONTENT_TYPE <- NA
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

  stacktrace_json <- jsonlite::toJSON(stacktrace, auto_unbox = TRUE)

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
    warning(
      "Error connecting to Sentry:",
      httr::content(resp, "text", encoding = "UTF-8"), "\n"
    )
  }
}


#' Build the response URL
#'
#' @export
#'
#' @return a character string
sentry_url <- function() {
  glue::glue("{protocol}://{host}/api/{project_id}/store/", .envir = .SentryEnv)
}


#' Set the response header
#'
#' @export
#'
#' @return a character vector
sentry_headers <- function() {
  if (!is.na(.SentryEnv$secret_key)) {
    # looks nicer, but the \n could create some issues, so we remove them
    # just in case
    c("X-Sentry-Auth" = glue::glue("Sentry sentry_version=7,
                                   sentry_client=sentryR/{packageVersion('sentryR')},
                                   sentry_timestamp={as.integer(Sys.time())},
                                   sentry_key={public_key},
                                   sentry_secret={secret_key}",
      .envir = .SentryEnv
    ) %>%
      gsub("[\r\n]", "", .))
  } else {
    c("X-Sentry-Auth" = glue::glue("Sentry sentry_version=7,
                                   sentry_client=sentryR/{packageVersion('sentryR')},
                                   sentry_timestamp={as.integer(Sys.time())},
                                   sentry_key={public_key}",
      .envir = .SentryEnv
    ) %>%
      gsub("[\r\n]", "", .))
  }
}
