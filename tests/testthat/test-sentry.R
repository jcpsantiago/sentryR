context("test-sentry")

test_that("parsing the dsn works", {
  expect_error(parse_dsn(888))

  test_dsn <- "https://1234@sentry.io"
  expect_error(
    parse_dsn(test_dsn),
    paste0(
      "Invalid DSN! Expected format is 'https://<public_key>@<host>/<project_id>' but received ",
      "'https://1234@sentry\\.io' instead\\."
    )
  )

  test_dsn <- "https://1234@sentry.io/"
  expect_error(
    parse_dsn(test_dsn),
    paste0(
      "Expected fields 'https://<public_key>@<host>/<project_id>', ",
      "but can't find project_id in 'https://1234@sentry\\.io/'",
      "\\. Please check your DSN\\."
    )
  )

  test_dsn <- "https://1234@sentry.io/1"
  expect_equal(
    names(parse_dsn(test_dsn)),
    c("dsn", "protocol", "public_key", "ignore", "secret_key", "host", "project_id")
  )
  expect_equal(
    parse_dsn(test_dsn),
    list(
      dsn = test_dsn, protocol = "https", public_key = "1234",
      ignore = NA_character_, secret_key = NA_character_,
      host = "sentry.io", project_id = "1"
    )
  )
})

test_that("setting configuration works", {
  expect_error(configure_sentry(42))
  expect_error(configure_sentry(c("https://1234@sentry.io/1", "https://1234@sentry.io/2")))

  configure_sentry(dsn = "https://1234@sentry.io/1",
                   app_name = "el appo", app_version = "8.8.8",
                   environment = "production",
                   contexts = list(app = list(app_identifier = "APPO")))

  expect_equal(.sentry_env$payload_skeleton$contexts$app$app_name, "el appo")
  expect_equal(.sentry_env$payload_skeleton$contexts$app$app_version, "8.8.8")
  expect_equal(.sentry_env$payload_skeleton$contexts$app$app_identifier, "APPO")
  expect_equal(.sentry_env$payload_skeleton$environment, "production")
  expect_equal(.sentry_env$dsn, "https://1234@sentry.io/1")
  expect_equal(.sentry_env$protocol, "https")
  expect_equal(.sentry_env$public_key, "1234")
  expect_equal(.sentry_env$ignore, NA_character_)
  expect_equal(.sentry_env$secret_key, NA_character_)
  expect_equal(.sentry_env$host, "sentry.io")
  expect_equal(.sentry_env$project_id, "1")

  rm(list = ls(envir = .sentry_env), envir = .sentry_env)

})

test_that("builds payload correctly", {
  expect_error(prepare_payload(message = "foo", "bar"))

  expect_match(
    prepare_payload(message = "foo", level = "info"),
    '\\{.*,"message":"foo","level":"info"\\}'
  )
})

test_that("configuration is properly set", {
  expect_message(
    is_sentry_configured(),
    "Expected public_key, host and project_id to be present but can't find public_key, host, project_id\\."
  )
  expect_false(is_sentry_configured())

  .sentry_env$public_key <- "1234"
  .sentry_env$host <- "sentry.io"

  expect_message(
    is_sentry_configured(),
    "Expected public_key, host and project_id to be present but can't find project_id\\."
  )
  expect_false(is_sentry_configured())


  .sentry_env$project_id <- "1"

  expect_true(is_sentry_configured())

  rm(list = ls(envir = .sentry_env), envir = .sentry_env)


  configure_sentry("https://1234@sentry.io/1")

  fields <- sapply(
    c(
      "dsn", "protocol", "public_key", "ignore",
      "secret_key", "host", "project_id"
    ),
    function(x) exists(x, envir = .sentry_env)
  )

  expect_true(all(fields))

  rm(list = ls(envir = .sentry_env), envir = .sentry_env)
})

test_that("we build the correct sentry.io call url", {
  .sentry_env$protocol <- "https"
  .sentry_env$host <- "sentry.io"
  .sentry_env$project_id <- "1"

  expect_equal(sentry_url(), "https://sentry.io/api/1/store/")

  rm(list = ls(envir = .sentry_env), envir = .sentry_env)
})

test_that("we build the correct headers", {
  # without deprecated secret key
  .sentry_env$public_key <- "1234"
  .sentry_env$secret_key <- NA
  .sentry_env$pkg_version <- "8.8.8"

  expect_match(
    sentry_headers()[[1]],
    "Sentry sentry_version=7,sentry_client=sentryR/.*,sentry_timestamp=.*sentry_key=1234"
  )

  # with the deprecated secret key
  .sentry_env$secret_key <- "5678"
  expect_match(
    sentry_headers()[[1]],
    "Sentry sentry_version=7,sentry_client=sentryR/.*,sentry_timestamp=.*sentry_key=1234,sentry_secret=5678"
  )

  rm(list = ls(envir = .sentry_env), envir = .sentry_env)
})

test_that("we build the call stack correctly", {
  # Get a call list with a "boring" .handleSimpleError in it
  get_calls <- function() sys.calls()
  .handleSimpleError <- function() get_calls()
  get_calls_with_boring <- function(n) .handleSimpleError()
  calls_with_boring <- get_calls_with_boring(123)

  # For testing, only process the calls within this function
  final_calls_with_boring <- tail(calls_with_boring, 3)
  stacktrace <- calls_to_stacktrace(final_calls_with_boring)
  expect_equal(
    colnames(stacktrace), c(
      "function", "raw_function", "module", "abs_path",
      "filename", "lineno", "context_line", "pre_context", "post_context"
    )
  )

  # The calls on the stack should be
  # - get_calls_with_boring()
  # [.handleSimpleError() should be skipped]
  # - get_calls()

  expect_equal(
    stacktrace$`function`,
    c("get_calls_with_boring", "get_calls")
  )

  expect_equal(stacktrace$raw_function, c(
    get_calls_with_boring = "get_calls_with_boring(123)",
    get_calls = "get_calls()"
  ))

  # TODO: How to check 'module'?

  expect_equal(
    stacktrace$filename,
    c(get_calls_with_boring = "test-sentry.R", get_calls = "test-sentry.R")
  )

  first_line = stacktrace$lineno[[1]]
  expect_equal(
    stacktrace$lineno,
    c(get_calls_with_boring = first_line, get_calls = first_line - 2)
  )

  expect_equal(stacktrace$context_line, c(
    get_calls_with_boring =
      "  calls_with_boring <- get_calls_with_boring(123)",
    get_calls =
      "  .handleSimpleError <- function() get_calls()"
  ))

  expect_equal(stacktrace$pre_context, list(
    get_calls_with_boring = c(
      "test_that(\"we build the call stack correctly\", {",
      "  # Get a call list with a \"boring\" .handleSimpleError in it",
      "  get_calls <- function() sys.calls()",
      "  .handleSimpleError <- function() get_calls()",
      "  get_calls_with_boring <- function(n) .handleSimpleError()"
    ),
    get_calls = c(
      "})",
      "",
      "test_that(\"we build the call stack correctly\", {",
      "  # Get a call list with a \"boring\" .handleSimpleError in it",
      "  get_calls <- function() sys.calls()"
    )
  ))

  expect_equal(stacktrace$post_context, list(
    get_calls_with_boring = c(
      "",
      "  # For testing, only process the calls within this function",
      "  final_calls_with_boring <- tail(calls_with_boring, 3)",
      "  stacktrace <- calls_to_stacktrace(final_calls_with_boring)",
      "  expect_equal("
    ),
    get_calls = c(
      "  get_calls_with_boring <- function(n) .handleSimpleError()",
      "  calls_with_boring <- get_calls_with_boring(123)",
      "",
      "  # For testing, only process the calls within this function",
      "  final_calls_with_boring <- tail(calls_with_boring, 3)"
    )
  ))

  rm(list = ls(envir = .sentry_env), envir = .sentry_env)
})
