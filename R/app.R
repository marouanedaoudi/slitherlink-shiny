#' Launch the Slitherlink Shiny application
#'
#' @return Does not return; starts the Shiny app in the default browser.
#' @export
run_app <- function() {
  app_dir <- system.file("shiny", package = "slitherlinkshiny")
  if (app_dir == "") {
    stop("Could not find Shiny app directory. Try re-installing the package.")
  }
  shiny::runApp(app_dir, display.mode = "normal")
}
