#' Title
#'
#' @param e
#'
#' @return
#' @export
#'
#' @examples
captureCalls <- function(e) {
  e$calls <- sys.calls()
  signalCondition(e)
}

#' Title
#'
#' @param z
#'
#' @return
#' @export
#'
#' @examples
withCapturedCalls <- function(z) {
  f <- function(...){
    return(withCallingHandlers(z(...), error = captureCalls))
  }
  return(f)
}

#' Title
#'
#' @param calls
#'
#' @return
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
