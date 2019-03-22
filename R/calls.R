#' Capture calls
#'
#' @param error error object
captureCalls <- function(error) {
  error$calls <- sys.calls()
  signalCondition(error)
}


#' Create safe function
#'
#' @param z the function whose errors we want to track
#'
#' @return a function
#' @export
withCapturedCalls <- function(z) {
  f <- function(...){
    return(withCallingHandlers(z(...), error = captureCalls))
  }
  return(f)
}


#' Convert function call to stacktrace
#'
#' @param calls function call
#'
#' @return a data.frame
calls2stacktrace <- function(calls) {
  srcrefs <- sapply(calls, function(v) {
    srcref <- attr(v, "srcref")

    if (!is.null(srcref)) {
      srcfile <- attr(srcref, "srcfile")
      c(basename(srcfile$filename), srcref[1L])
    } else {
      c(NA, NA)
    }
  })

  calls <- lapply(as.character(calls), function(x) strsplit(x, "\n")[[1]][1])
  df <- data.frame(t(rbind(srcrefs, calls)))
  colnames(df) <- c("filename", "lineno", "function")
  df
}
