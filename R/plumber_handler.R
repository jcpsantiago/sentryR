#' Capture function calls
#'
#' @param error error object
capture_function_calls <- function(error) {
  error$function_calls <- sys.calls()
  signalCondition(error)
}


#' Create safe function
#'
#' @param z the function whose errors we want to track
#'
#' @return a function
#' @export
with_captured_calls <- function(z) {
  f <- function(...) {
    return(withCallingHandlers(z(...), error = capture_function_calls))
  }
  return(f)
}


#' Default error handler for Plumber
#'
#' @param req a Plumber request object
#' @param res a Plumber response object
#' @param error an error object
#'
#' @return a list
#' @export
default_error_handler <- function(req, res, error) {
  li <- list()

  if (res$status == 200L) {
    # The default is a 200. If that's still set, then we should probably override with a 500.
    # It's possible, however, than a handler set a 40x and then wants to use this function to
    # render an error, though.
    res$status <- 500
    li$error <- "500 - Internal server error"
  } else {
    li$error <- "Internal error"
  }

  # Don't overly leak data unless the user opts-in
  if (getOption("plumber.debug", FALSE)) {
    li["message"] <- gsub("\\n", "", as.character(error))
  }

  li
}


#' Wrap a plumber error handler such that it reports errors to Sentry
#'
#' @param error_handler a function to handle plumber errors
#'
#' @return a function
#' @export
wrap_error_handler_with_sentry <- function(error_handler = default_error_handler) {
  function(req, res, error, ...) {
    http_content_type <- ifelse(is.null(req$HTTP_CONTENT_TYPE), "", req$HTTP_CONTENT_TYPE)
    if (!is.null(req$postBody) && length(req$postBody) > 0 && grepl(pattern = "application/json", x = http_content_type, fixed = T) ) {
      req_body <- list(
        data = lapply(jsonlite::fromJSON(req$postBody), function(x) utils::head(x, 10))
      )
    } else {
      req_body <- NULL
    }

    request_payload <- list(
      url = req$PATH_INFO,
      query_string = req$QUERY_STRING,
      method = req$REQUEST_METHOD,
      headers = list(
        `content-type` = http_content_type
      ),
      env = list(
        REMOTE_ADDR = ifelse(
          is.null(req$HTTP_HOST),
          req$SERVER_NAME,
          req$HTTP_HOST
        )
      )
    )

    if (!is.null(req_body)) {
      request_payload <- append(request_payload, req_body)
    }

    capture_exception(error,
      request = request_payload,
      transaction = req$PATH_INFO, ...
    )

    error_handler(req, res, error)
  }
}


#' Error handler with Sentry reporting
#'
#' @param req a plumber request object
#' @param res a plumber response object
#' @param error an error object
#' @param ... extra named variables for Sentry
#'
#' @return a list with response payload
#' @export
#'
#' @examples
#' \dontrun{
#' sentryR::configure_sentry(Sys.getenv("SENTRY_DSN"))
#' pr <- plumber::plumb("example_plumber.R")
#' pr$setErrorHandler(sentryR::sentry_error_handler)
#' pr$run()
#' }
sentry_error_handler <- wrap_error_handler_with_sentry()
