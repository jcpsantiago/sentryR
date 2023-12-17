#' Convert function call to a stack trace
#'
#' @param calls function calls, e.g. from sys.calls()
#'
#' @return a data.frame
calls_to_stacktrace <- function(calls) {
  srcrefs <- lapply(calls, function(call) attr(call, "srcref", exact = TRUE))
  srcfiles <- lapply(srcrefs, function(ref) {
    if (!is.null(ref)) {
      attr(ref, "srcfile", exact = TRUE)
    }
  })

  # https://github.com/rstudio/shiny/blob/master/R/conditions.R#L64
  funs <- sapply(calls, function(call) {
    if (is.function(call[[1]])) {
      "<Anonymous>"
    } else if (inherits(call[[1]], "call")) {
      paste0(format(call[[1]]), collapse = " ")
    } else if (typeof(call[[1]]) == "promise") {
      "<Promise>"
    } else {
      paste0(as.character(call[[1]]), collapse = " ")
    }
  })

  # drop calls to uninformative error handling internals, as in
  # https://github.com/rstudio/shiny/blob/master/R/conditions.R#L399
  to_keep <- !(funs %in%
    c(".handleSimpleError", "h", "doTryCatch", "tryCatchList", "tryCatchOne")
  )

  funs_to_keep <- funs[to_keep]

  names(srcrefs) <- funs_to_keep
  names(srcfiles) <- funs_to_keep

  srcrefs <- srcrefs[to_keep]

  srcfiles <- srcfiles[to_keep]

  full_function_call <- as.character(calls)
  names(full_function_call) <- funs_to_keep
  full_function_call <- full_function_call[to_keep]

  # TODO: Offset the lines to the function definition, not the function call
  df <- tibble::tibble(
    `function` = funs_to_keep,
    raw_function = full_function_call,
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
    }, srcfiles, lineno)),
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
    }, srcfiles, lineno),
    post_context = mapply(function(file, line) {
      if (!is.null(file)) {
        if (!is.null(file$original)) {
          return(file$original$lines[(line + 1):(line + 5)])
        }

        return(file$lines[(line + 1):(line + 5)])
      }
      return(NA_character_)
    }, srcfiles, lineno)
  )

  df
}
