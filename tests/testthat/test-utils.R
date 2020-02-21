test_that("removing NULLs from lists work", {
  expect_equal(
    rm_null_obs(list(foo = 123)),
    list(foo = 123)
  )

  expect_equal(
    rm_null_obs(list(foo = 123, bar = NULL)),
    list(foo = 123)
  )

  expect_equal(
    rm_null_obs(list(foo = 123, bar = list(off = "meh", rab = NULL))),
    list(foo = 123, bar = list(off = "meh"))
  )

  expect_equal(
    rm_null_obs(list(foo = NULL, bar = list(off = "meh", rab = NULL))),
    list(bar = list(off = "meh"))
  )

  expect_equal(
    rm_null_obs(list(foo = 123, bar = list(off = "meh", rab = NULL, rib = NULL))),
    list(foo = 123, bar = list(off = "meh"))
  )
})

test_that("detects if an observation or all elements are NULL", {
  expect_true(is_null_obs(NULL))
  expect_true(is_null_obs(list(foo = NULL)))
  expect_false(is_null_obs(list(foo = 123, bar = list(mee = NULL))))
  expect_false(is_null_obs(c(123, NULL)))
})
