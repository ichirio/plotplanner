withr_tempdir <- function(env = parent.frame()) {
  d <- tempfile("tflspec-test")
  dir.create(d)
  withr_defer <- function() unlink(d, recursive = TRUE)
  do.call(on.exit, list(substitute(withr_defer()), add = TRUE), envir = env)
  d
}
