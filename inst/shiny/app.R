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
      font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
      background-color: #f0f2f5;
    }
    .well {
      background-color: #ffffff;
      border: 1px solid #dde1e7;
      border-radius: 8px;
      box-shadow: 0 1px 4px rgba(0,0,0,0.07);
    }
    .section-label {
      font-size: 10px; font-weight: 700;
      letter-spacing: 1px; color: #aaa;
      text-transform: uppercase;
      margin: 14px 0 6px 0;
      padding-bottom: 5px;
      border-bottom: 1px solid #f0f0f0;
    }
    .btn { border-radius: 5px; font-size: 13px; }
    .btn-block + .btn-block { margin-top: 5px; }
    #status_box {
      font-size: 14px; font-weight: 600;
      padding: 8px 16px; border-radius: 6px;
      text-align: center; margin-top: 10px;
      display: inline-block;
    }
    .status-progress  { background: #e8f0fe; color: #1a56cc; }
    .status-violation { background: #fde8e8; color: #cc1a1a; }
    .status-solved    { background: #e8fde8; color: #1a7a1a; }
    #timer_display {
      font-size: 30px; font-weight: 700;
      letter-spacing: 4px; margin-bottom: 6px;
      font-family: 'Courier New', monospace;
    }
    .grid-wrap {
      display: flex; flex-direction: column;
      align-items: center; padding-top: 6px;
    }
    .grid-box {
      background: #ffffff; border-radius: 8px;
      box-shadow: 0 1px 6px rgba(0,0,0,0.09);
      padding: 6px;
    }
    .help-text {
      font-size: 11px; color: #aaa; margin-top: 14px;
      line-height: 1.6;
    }
  "))),

  titlePanel(
    div(
      tags$span("Slitherlink",
        style = "font-size:22px; font-weight:700; color:#222;"),
      tags$span(" \u2014 Draw a single closed loop",
        style = "font-size:13px; color:#999; margin-left:6px;")
    )
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
        div(class = "grid-box",
          plotOutput(
            "grid_plot",
            click  = "grid_click",
            width  = "520px",
            height = "520px"
          )
        ),
        uiOutput("status_box")
      )
    )
  )
)

# ---------------------------------------------------------------------------
# Server
# ---------------------------------------------------------------------------

server <- function(input, output, session) {
  grid    <- reactiveVal(get_puzzle("easy_3x3"))
  history <- reactiveVal(list())   # stack of previous grid states

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

  push_history <- function() {
    history(c(history(), list(grid())))
  }

  clear_history <- function() history(list())

  observeEvent(input$new_game, {
    clear_history()
    reset_timer()
    grid(get_puzzle(input$puzzle_name))
  })

  observeEvent(input$reset, {
    clear_history()
    reset_timer()
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
    push_history()
    g <- grid()
    # Find the first segment that should be drawn (1) but is currently empty (0)
    for (i in seq_len(nrow(solution$seg_h))) {
      for (j in seq_len(ncol(solution$seg_h))) {
        if (solution$seg_h[i, j] == 1L && g$seg_h[i, j] == 0L) {
          g$seg_h[i, j] <- 1L
          grid(g)
          return()
        }
      }
    }
    for (i in seq_len(nrow(solution$seg_v))) {
      for (j in seq_len(ncol(solution$seg_v))) {
        if (solution$seg_v[i, j] == 1L && g$seg_v[i, j] == 0L) {
          g$seg_v[i, j] <- 1L
          grid(g)
          return()
        }
      }
    }
    showNotification("No hint available.", type = "message")
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
    }
  })

  observeEvent(input$grid_click, {
    g <- grid()
    seg <- find_nearest_segment(g, input$grid_click$x, input$grid_click$y)
    if (!is.null(seg)) {
      start_timer()
      push_history()
      new_g <- toggle_segment(g, seg$type, seg$i, seg$j)
      if (is_solved(new_g)) stop_timer()
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
