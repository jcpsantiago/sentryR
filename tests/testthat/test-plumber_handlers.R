context("test handlers")

test_that("default_error_handler works", {
  mock_req <- make_req("angel_attack", "/launch_eva01",
    body = '[{"battery_level": "5 min"}]'
  )
  mock_res <- plumber:::PlumberResponse$new()
  handled <- default_error_handler(mock_req, mock_res, simpleError("NO! NO! NO!"))

  expect_true(
    is.list(handled)
  )
  expect_equal(
    names(handled), c("error")
  )
  expect_equal(
    handled$error, "500 - Internal server error"
  )
  expect_equal(
    mock_res$status, 500
  )

  options(plumber.debug = TRUE)
  mock_res$status <- 200
  handled <- default_error_handler(mock_req, mock_res, simpleError("NO! NO! NO!"))

  expect_equal(
    names(handled), c("error", "message")
  )
  expect_equal(
    handled$error, "500 - Internal server error"
  )
  expect_equal(
    handled$message, "Error: NO! NO! NO!\n"
  )

  # Now with status already set to 500
  handled <- default_error_handler(mock_req, mock_res, simpleError("NO! NO! NO!"))
  expect_equal(
    handled$error, "Internal error"
  )
})

test_that("we can wrap error handlers with sentry", {
  wrapped <- wrap_error_handler_with_sentry()

  expect_true(is.function(wrapped))
})
