# FROM: https://github.com/rstudio/shiny/blob/master/R/conditions.R
# more info: https://github.com/rstudio/shiny/wiki/Stack-traces-in-R
# Given sys.parents() (which corresponds to sys.calls()), return a logical index
# that prunes each subtree so that only the final branch remains. The result,
# when applied to sys.calls(), is a linear list of calls without any "wrapper"
# functions like tryCatch, try, with, hybrid_chain, etc. While these are often
# part of the active call stack, they rarely are helpful when trying to identify
# a broken bit of code.
prune_stack_trace <- function(parents) {
  # Detect nodes that are not the last child. This is necessary, but not
  # sufficient; we also need to drop nodes that are the last child, but one of
  # their ancestors is not.
  is_dupe <- duplicated(parents, fromLast = TRUE)

  # The index of the most recently seen node that was actually kept instead of
  # dropped.
  current_node <- 0

  # Loop over the parent indices. Anything that is not parented by current_node
  # (a.k.a. last-known-good node), or is a dupe, can be discarded. Anything that
  # is kept becomes the new current_node.
  include <- vapply(seq_along(parents), function(i) {
    if (!is_dupe[[i]] && parents[[i]] == current_node) {
      current_node <<- i
      TRUE
    } else {
      FALSE
    }
  }, FUN.VALUE = logical(1))

  include
}
