# https://stackoverflow.com/questions/26539441/remove-null-elements-from-list-of-lists
# remove NULL nodes from a list
# helper function for rm_null_obs
is_null_obs <- function(x) {
  is.null(x) | all(sapply(x, is.null))
}

rm_null_obs <- function(x) {
  x <- Filter(Negate(is_null_obs), x)
  lapply(x, function(x) if (is.list(x)) rm_null_obs(x) else x)
}
