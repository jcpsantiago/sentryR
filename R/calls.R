#' Convert function call to a stack trace
#'
#' @param calls function calls, e.g. from sys.calls()
#'
#' @return a data.frame
#' @examples
#' \dontrun{
#' f <- function() stop("cabin pressure lost")
#' f()
#' calls_to_stacktrace(sys.calls())
#' }
calls_to_stacktrace <- function(calls) {

  srcrefs <- lapply(calls, function(call) attr(call, "srcref", exact = TRUE))
  srcfiles <- lapply(srcrefs, function(ref) {
    if (!is.null(ref)) {
      attr(ref, "srcfile", exact = TRUE)
    }
  })

  df <- tibble::tibble(
    `function` = sapply(calls, function(call) {
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
        print(file)
        return(basename(file$original$filename))
      }
      return(NA_character_)
    }, character(1)),
    abs_path = vapply(srcfiles, function(file) {
      if (!is.null(file)) {
        print(file)
        return(file$filename)
      }
      return(NA_character_)
    }, character(1)),
    filename = vapply(abs_path, function(path) basename(path), character(1)),
    lineno = vapply(srcrefs, function(ref) {
      if (!is.null(ref)) {
        print(ref)
        return(ref[[1L]])
      }
      return(NA_integer_)
    }, integer(1)),
    context_line = unlist(mapply(function(file, line) {
      if (!is.null(file)) {
        if (!is.null(file$original)) {
          return(file$original$lines[[line]])
        }
        print(file$lines[[line]])
        return(file$lines[[line]])
      }
      return(NA_character_)
    }, srcfiles, lineno)),
    pre_context = mapply(function(file, line) {
      if (!is.null(file)) {
        print(file)
        # 5 line window is recommended by Sentry
        start_line <- line - 5
        start_line <- ifelse(start_line < 0, 1, start_line)

        # TODO: skip empty lines?
        return(file$lines[start_line:line])
      }
      return(NA_character_)
    }, srcfiles, lineno),
    post_context = mapply(function(file, line) {
      if (!is.null(file)) {
        print(file)

        # TODO: skip empty lines?
        return(file$lines[(line + 1):(line + 5)])
      }
      return(NA_character_)
    }, srcfiles, lineno)
  )

  df
}
