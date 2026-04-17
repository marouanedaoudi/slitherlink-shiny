library(shiny)
library(slitherlinkshiny)

# ---------------------------------------------------------------------------
# Grid rendering
# ---------------------------------------------------------------------------

draw_grid <- function(grid) {
  n <- grid$n
  m <- grid$m

  par(mar = c(1, 1, 1, 1), bg = "#ffffff")
  plot(
    NULL,
    xlim = c(0.5, m + 1.5), ylim = c(0.5, n + 1.5),
    asp = 1, axes = FALSE, xlab = "", ylab = ""
  )

  # Helper: plot y for grid row i (row 1 at top)
  py <- function(i) n + 2 - i

  # Empty segment placeholders (light gray dashed)
  for (i in seq_len(n + 1)) {
    for (j in seq_len(m)) {
      if (grid$seg_h[i, j] == 0)
        segments(j, py(i), j + 1, py(i), col = "#cccccc", lty = 2, lwd = 1)
    }
  }
  for (i in seq_len(n)) {
    for (j in seq_len(m + 1)) {
      if (grid$seg_v[i, j] == 0)
        segments(j, py(i), j, py(i + 1), col = "#cccccc", lty = 2, lwd = 1)
    }
  }

  # Clue numbers — color reflects constraint status
  for (i in seq_len(n)) {
    for (j in seq_len(m)) {
      clue <- grid$clues[i, j]
      if (is.na(clue)) next

      count <- (grid$seg_h[i,     j] == 1) +
               (grid$seg_h[i + 1, j] == 1) +
               (grid$seg_v[i,     j] == 1) +
               (grid$seg_v[i, j + 1] == 1)

      clue_col <- if (count > clue)   "#cc0000"        # violated
             else if (count == clue)  "#2a7a2a"        # satisfied
             else                     "#333333"        # in progress

      text(j + 0.5, py(i) - 0.5, as.character(clue),
           cex = 1.6, col = clue_col, font = 2)
    }
  }

  # Drawn segments (black, thick)
  for (i in seq_len(n + 1)) {
    for (j in seq_len(m)) {
      if (grid$seg_h[i, j] == 1) {
        segments(j, py(i), j + 1, py(i), col = "#111111", lwd = 5)
      } else if (grid$seg_h[i, j] == -1) {
        cx <- j + 0.5
        segments(cx - 0.12, py(i) - 0.12, cx + 0.12, py(i) + 0.12, col = "#cc0000", lwd = 2)
        segments(cx - 0.12, py(i) + 0.12, cx + 0.12, py(i) - 0.12, col = "#cc0000", lwd = 2)
      }
    }
  }
  for (i in seq_len(n)) {
    for (j in seq_len(m + 1)) {
      if (grid$seg_v[i, j] == 1) {
        segments(j, py(i), j, py(i + 1), col = "#111111", lwd = 5)
      } else if (grid$seg_v[i, j] == -1) {
        cy <- py(i) - 0.5
        segments(j - 0.12, cy - 0.12, j + 0.12, cy + 0.12, col = "#cc0000", lwd = 2)
        segments(j - 0.12, cy + 0.12, j + 0.12, cy - 0.12, col = "#cc0000", lwd = 2)
      }
    }
  }

  # Intersection dots (drawn last so they sit on top)
  for (i in seq_len(n + 1)) {
    for (j in seq_len(m + 1)) {
      points(j, py(i), pch = 20, cex = 1.0, col = "#111111")
    }
  }
}

# ---------------------------------------------------------------------------
# Click → nearest segment
# ---------------------------------------------------------------------------

find_nearest_segment <- function(grid, cx, cy) {
  n <- grid$n
  m <- grid$m

  # Convert click to continuous grid coordinates
  # Node (i, j) is at plot position (j, n+2-i)
  ni <- n + 2 - cy   # continuous row index  (1 = top node row)
  nj <- cx           # continuous col index  (1 = left node col)

  # Reject clicks outside the grid area (with a small tolerance)
  tol <- 0.5
  if (ni < 1 - tol || ni > n + 1 + tol) return(NULL)
  if (nj < 1 - tol || nj > m + 1 + tol) return(NULL)

  dist_h <- abs(ni - round(ni))   # proximity to a horizontal line
  dist_v <- abs(nj - round(nj))   # proximity to a vertical line

  if (dist_h <= dist_v) {
    # Horizontal segment candidate
    i_h <- as.integer(round(ni))
    j_h <- as.integer(floor(nj))
    if (i_h >= 1L && i_h <= n + 1L && j_h >= 1L && j_h <= m)
      return(list(type = "h", i = i_h, j = j_h))
  } else {
    # Vertical segment candidate
    j_v <- as.integer(round(nj))
    i_v <- as.integer(floor(ni))
    if (i_v >= 1L && i_v <= n && j_v >= 1L && j_v <= m + 1L)
      return(list(type = "v", i = i_v, j = j_v))
  }

  NULL
}

# ---------------------------------------------------------------------------
# Puzzle choices
# ---------------------------------------------------------------------------

puzzle_choices <- setNames(
  list_puzzles()$name,
  paste0(
    list_puzzles()$name, " (",
    list_puzzles()$difficulty, " — ",
    list_puzzles()$size, ")"
  )
)

# ---------------------------------------------------------------------------
# UI
# ---------------------------------------------------------------------------

ui <- fluidPage(
  tags$head(tags$style(HTML("
    body {
      font-family: Georgia, 'Times New Roman', serif;
      background-color: #fafaf8;
      color: #1c1c1c;
    }

    /* Sidebar */
    .well {
      background: #ffffff;
      border: 1px solid #d8d4cc;
      border-radius: 3px;
      box-shadow: none;
      padding: 18px 16px;
    }
    .section-label {
      font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
      font-size: 9px; font-weight: 700;
      letter-spacing: 1.4px; color: #888;
      text-transform: uppercase;
      margin: 20px 0 8px 0;
      padding-bottom: 5px;
      border-bottom: 1px solid #e8e4dc;
    }
    .section-label:first-child { margin-top: 0; }

    /* Inputs */
    .selectize-input {
      border: 1px solid #c8c4bc; border-radius: 2px;
      box-shadow: none; font-size: 13px;
      font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
    }
    .selectize-input.focus { border-color: #666; box-shadow: none; }
    .selectize-dropdown { border: 1px solid #c8c4bc; border-radius: 2px; font-size: 13px; }
    .form-control {
      border: 1px solid #c8c4bc; border-radius: 2px;
      box-shadow: none; font-size: 13px;
    }
    .form-control:focus { border-color: #666; box-shadow: none; }
    label {
      font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
      font-size: 11px; color: #555; font-weight: 400;
    }

    /* Buttons — all unified, no color circus */
    .btn {
      font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
      font-size: 12px; font-weight: 500;
      border-radius: 2px;
      border: 1px solid #b0aca4;
      background: #f4f2ee; color: #2c2c2c;
      box-shadow: none;
      transition: background 0.12s;
    }
    .btn:hover  { background: #e8e4dc; color: #1c1c1c; }
    .btn:active { background: #dedad2; }
    .btn-primary { background: #2c2c2c; color: #fafaf8; border-color: #2c2c2c; }
    .btn-primary:hover { background: #444; color: #fff; border-color: #444; }
    .btn-block + .btn-block { margin-top: 5px; }

    /* Status line */
    #status_box {
      font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
      font-size: 12px; font-weight: 500;
      padding: 5px 14px; border-radius: 2px;
      text-align: center; margin-top: 12px;
      display: inline-block;
      border: 1px solid;
    }
    .status-progress  { background: #f4f2ee; color: #555; border-color: #c8c4bc; }
    .status-violation { background: #fdf4f4; color: #8b0000; border-color: #d4b0b0; }
    .status-solved    { background: #f4faf4; color: #1a5c1a; border-color: #a8c8a8; }

    /* Timer */
    #timer_display {
      font-size: 34px; font-weight: 400;
      letter-spacing: 5px; margin-bottom: 2px;
      font-family: 'Courier New', monospace;
      color: #2c2c2c;
    }
    #puzzle_label {
      font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
      font-size: 10px; color: #888; letter-spacing: 1px;
      text-transform: uppercase; margin-bottom: 10px;
    }
    #best_time {
      font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
      font-size: 11px; color: #888; margin-top: 4px;
    }
    #best_time span { color: #1a5c1a; font-weight: 600; }

    /* Grid */
    .grid-wrap {
      display: flex; flex-direction: column;
      align-items: center; padding-top: 6px;
      width: 100%;
    }
    .grid-box {
      background: #ffffff;
      border: 1px solid #d8d4cc;
      border-radius: 2px;
      padding: 6px;
      width: 100%; max-width: 534px;
      box-sizing: border-box;
    }
    #grid_plot img { width: 100% !important; height: auto !important; }

    /* Help text */
    .help-text {
      font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
      font-size: 11px; color: #888; margin-top: 18px;
      line-height: 1.7;
    }
    .help-text ul { padding-left: 14px; margin: 3px 0 0 0; }
  "))),

  tags$div(
    style = "padding: 14px 20px 10px 20px; border-bottom: 1px solid #d8d4cc; margin-bottom: 18px; background: #fafaf8;",
    tags$span("Slitherlink",
      style = "font-size: 18px; font-weight: 700; color: #1c1c1c; font-family: Georgia, serif; letter-spacing: 0.2px;"),
    tags$span(" \u2014 draw a single closed loop",
      style = "font-size: 12px; color: #888; margin-left: 8px; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;")
  ),

  sidebarLayout(
    sidebarPanel(
      width = 3,

      div(class = "section-label", "Puzzle"),
      selectInput("puzzle_name", NULL, choices = puzzle_choices),
      fluidRow(
        column(6, actionButton("new_game", "New Game",
                               class = "btn-primary btn-block")),
        column(6, actionButton("reset",    "Reset",
                               class = "btn-warning btn-block"))
      ),

      div(class = "section-label", "Assist"),
      actionButton("solve", "Solve", class = "btn-info btn-block"),
      fluidRow(
        column(6, actionButton("hint", "Hint",
                               class = "btn-default btn-block")),
        column(6, actionButton("undo", "Undo",
                               class = "btn-default btn-block"))
      ),

      div(class = "section-label", "Random"),
      fluidRow(
        column(6, numericInput("rand_n", "Rows", value = 5L,
                               min = 2L, max = 10L, step = 1L)),
        column(6, numericInput("rand_m", "Cols", value = 5L,
                               min = 2L, max = 10L, step = 1L))
      ),
      actionButton("random_puzzle", "Generate",
                   class = "btn-success btn-block"),

      div(class = "help-text",
        "Click a segment to cycle:",
        tags$ul(
          style = "padding-left:14px; margin:3px 0 0 0;",
          tags$li("Empty \u2192 drawn"),
          tags$li("Drawn \u2192 crossed \u00d7"),
          tags$li("Crossed \u2192 empty")
        )
      )
    ),

    mainPanel(
      width = 9,
      div(class = "grid-wrap",
        uiOutput("timer_display"),
        uiOutput("puzzle_label"),
        div(class = "grid-box",
          plotOutput(
            "grid_plot",
            click  = "grid_click",
            width  = "100%",
            height = "520px"
          )
        ),
        uiOutput("status_box"),
        uiOutput("best_time")
      )
    )
  )
)

# ---------------------------------------------------------------------------
# Server
# ---------------------------------------------------------------------------

server <- function(input, output, session) {
  grid               <- reactiveVal(get_puzzle("easy_3x3"))
  history            <- reactiveVal(list())   # stack of previous grid states
  current_puzzle_key <- reactiveVal("easy_3x3")
  best_times         <- reactiveVal(list())   # named list: key -> best seconds

  # Timer: NULL = idle, POSIXct = start time, NA = stopped
  timer_start   <- reactiveVal(NULL)
  timer_elapsed <- reactiveVal(0L)   # seconds at stop time

  reset_timer <- function() {
    timer_start(NULL)
    timer_elapsed(0L)
  }

  start_timer <- function() {
    if (is.null(timer_start()))
      timer_start(Sys.time())
  }

  stop_timer <- function() {
    s <- timer_start()
    if (!is.null(s) && !is.na(s)) {
      timer_elapsed(as.integer(difftime(Sys.time(), s, units = "secs")))
      timer_start(NA)   # sentinel: timer frozen
    }
  }

  record_best_time <- function() {
    secs <- timer_elapsed()
    if (secs == 0L) return()
    key <- current_puzzle_key()
    bt  <- best_times()
    if (is.null(bt[[key]]) || secs < bt[[key]]) {
      bt[[key]] <- secs
      best_times(bt)
    }
  }

  push_history <- function() {
    history(c(history(), list(grid())))
  }

  clear_history <- function() history(list())

  observeEvent(input$new_game, {
    clear_history()
    reset_timer()
    current_puzzle_key(input$puzzle_name)
    grid(get_puzzle(input$puzzle_name))
  })

  observeEvent(input$reset, {
    clear_history()
    reset_timer()
    current_puzzle_key(input$puzzle_name)
    grid(get_puzzle(input$puzzle_name))
  })

  observeEvent(input$undo, {
    h <- history()
    if (length(h) == 0L) {
      showNotification("Nothing to undo.", type = "message")
      return()
    }
    grid(h[[length(h)]])
    history(h[-length(h)])
  })

  observeEvent(input$hint, {
    if (is_solved(grid())) return()
    solution <- solve_grid(grid())
    if (is.null(solution)) {
      showNotification("No solution found — cannot give a hint.",
                       type = "error")
      return()
    }
    g <- grid()
    candidates <- list()
    for (i in seq_len(nrow(solution$seg_h))) {
      for (j in seq_len(ncol(solution$seg_h))) {
        if (solution$seg_h[i, j] == 1L && g$seg_h[i, j] == 0L)
          candidates <- c(candidates, list(list(mat = "h", i = i, j = j)))
      }
    }
    for (i in seq_len(nrow(solution$seg_v))) {
      for (j in seq_len(ncol(solution$seg_v))) {
        if (solution$seg_v[i, j] == 1L && g$seg_v[i, j] == 0L)
          candidates <- c(candidates, list(list(mat = "v", i = i, j = j)))
      }
    }
    if (length(candidates) == 0L) {
      showNotification("No hint available.", type = "message")
      return()
    }
    push_history()
    pick <- candidates[[sample(length(candidates), 1L)]]
    if (pick$mat == "h") g$seg_h[pick$i, pick$j] <- 1L
    else                 g$seg_v[pick$i, pick$j] <- 1L
    grid(g)
  })

  observeEvent(input$random_puzzle, {
    n <- as.integer(input$rand_n)
    m <- as.integer(input$rand_m)
    withProgress(message = "Generating puzzle\u2026", value = 0.5, {
      g <- tryCatch(
        random_puzzle(n = n, m = m),
        error = function(e) NULL
      )
    })
    if (is.null(g)) {
      showNotification(
        "Could not generate a puzzle. Try a different size.",
        type = "error"
      )
    } else {
      clear_history()
      reset_timer()
      current_puzzle_key(paste0("random_", n, "x", m))
      grid(g)
    }
  })

  observeEvent(input$solve, {
    solution <- solve_grid(grid())
    if (is.null(solution)) {
      showNotification("No solution found for this puzzle.", type = "error")
    } else {
      push_history()
      grid(solution)
      stop_timer()
      record_best_time()
    }
  })

  observeEvent(input$grid_click, {
    g <- grid()
    seg <- find_nearest_segment(g, input$grid_click$x, input$grid_click$y)
    if (!is.null(seg)) {
      start_timer()
      push_history()
      new_g <- toggle_segment(g, seg$type, seg$i, seg$j)
      if (is_solved(new_g)) {
        stop_timer()
        record_best_time()
      }
      grid(new_g)
    }
  })

  output$grid_plot <- renderPlot({
    draw_grid(grid())
  }, bg = "#ffffff")

  output$timer_display <- renderUI({
    s <- timer_start()

    if (is.null(s)) {
      secs <- 0L
    } else if (is.na(s)) {
      secs <- timer_elapsed()
    } else {
      invalidateLater(1000, session)
      secs <- as.integer(difftime(Sys.time(), s, units = "secs"))
    }

    mm  <- secs %/% 60L
    ss  <- secs %%  60L
    lbl <- sprintf("%02d:%02d", mm, ss)
    col <- if (!is.null(s) && is.na(s)) "#1a7a1a" else "#555555"
    div(id = "timer_display", style = paste0("color:", col, ";"), lbl)
  })

  output$best_time <- renderUI({
    key  <- current_puzzle_key()
    best <- best_times()[[key]]
    if (is.null(best)) return(NULL)
    mm  <- best %/% 60L
    ss  <- best %%  60L
    div(id = "best_time",
      "Best: ", tags$span(sprintf("%02d:%02d", mm, ss))
    )
  })

  output$puzzle_label <- renderUI({
    key <- current_puzzle_key()
    if (grepl("^random_", key)) {
      size <- sub("^random_", "", key)
      lbl  <- paste0("Random \u2014 ", size)
    } else {
      info <- list_puzzles()
      row  <- info[info$name == key, ]
      lbl  <- if (nrow(row) == 1L)
        paste0(tools::toTitleCase(row$difficulty), " \u2014 ", row$size)
      else key
    }
    div(id = "puzzle_label", lbl)
  })

  output$status_box <- renderUI({
    g <- grid()
    if (is_solved(g)) {
      div(id = "status_box", class = "status-solved",   "Puzzle solved!")
    } else if (!check_clues(g, strict = FALSE)) {
      div(id = "status_box", class = "status-violation", "Constraint violated")
    } else {
      div(id = "status_box", class = "status-progress",  "In progress...")
    }
  })
}

shinyApp(ui, server)
