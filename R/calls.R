#' Convert function call to a stack trace
#'
#' @param calls function calls, e.g. from sys.calls()
#'
#' @return a data.frame
#' @examples
#' \dontrun{
#' f <- function() stop("cabin pressure lost")
#' f()
#' sentryR:::calls_to_stacktrace(sys.calls())
#' }
calls_to_stacktrace <- function(calls) {
  # note, attr(NULL, ...) is NULL
  srcrefs <- lapply(calls, function(call) attr(call, "srcref", exact = TRUE))
  srcfiles <- lapply(srcrefs, function(ref) attr(ref, "srcfile", exact = TRUE))

  # TODO: Offset the lines to the function definition, not the function call
  df <- tibble::tibble(
    `function` = sapply(calls, function(call) {
      # https://github.com/rstudio/shiny/blob/master/R/conditions.R#L64
      if (is.function(call[[1]])) {
        "<Anonymous>"
      } else if (inherits(call[[1]], "call")) {
        paste0(format(call[[1]]), collapse = " ")
      } else if (typeof(call[[1]]) == "promise") {
        "<Promise>"
      } else {
        paste0(as.character(call[[1]]), collapse = " ")
      }
    }),
    raw_function = as.character(calls),
    module = vapply(srcfiles, function(file) {
      if (!is.null(file$original)) {
        return(basename(file$original$filename))
      }
      return(NA_character_)
    }, character(1)),
    abs_path = vapply(srcfiles, function(file) {
      if (!is.null(file)) {
        return(file$filename)
      }
      return(NA_character_)
    }, character(1)),
    filename = vapply(abs_path, function(path) basename(path), character(1)),
    lineno = vapply(srcrefs, function(ref) {
      if (!is.null(ref)) {
        return(ref[[1L]])
      }
      return(NA_integer_)
    }, integer(1)),
    context_line = unlist(mapply(function(file, line) {
      if (!is.null(file)) {
        if (!is.null(file$original)) {
          return(file$original$lines[[line]])
        }
        return(file$lines[[line]])
      }
      return(NA_character_)
    }, srcfiles, lineno, SIMPLIFY = FALSE)),
    pre_context = mapply(function(file, line) {
      if (!is.null(file)) {
        # 5 line window is recommended by Sentry
        start_line <- line - 5
        start_line <- ifelse(start_line < 0, 1, start_line)

        if (!is.null(file$original)) {
          return(file$original$lines[start_line:(line - 1)])
        }

        return(file$lines[start_line:(line - 1)])
      }
      return(NA_character_)
    }, srcfiles, lineno, SIMPLIFY = FALSE),
    post_context = mapply(function(file, line) {
      if (!is.null(file)) {
        if (!is.null(file$original)) {
          return(file$original$lines[(line + 1):(line + 5)])
        }

        return(file$lines[(line + 1):(line + 5)])
      }
      return(NA_character_)
    }, srcfiles, lineno, SIMPLIFY = FALSE)
  )

  # Remove "boring" calls within internal error handling functions,
  # as in https://github.com/rstudio/shiny/blob/master/R/conditions.R#L399
  do_keep <- !(df$`function` %in% c(
    "stop", ".handleSimpleError", "h",
    "doTryCatch", "tryCatchList", "tryCatchOne"
  ))
  df <- df[do_keep, ]

  # Name the vector elements of each column by the bare function name
  for (col in colnames(df)) {
    if (col != "function") {
      names(df[[col]]) <- df$`function`
    }
  }

  df
}
