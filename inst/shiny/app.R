library(shiny)
library(slitherlinkshiny)

# ---------------------------------------------------------------------------
# Grid rendering
# ---------------------------------------------------------------------------

draw_grid <- function(grid) {
  n <- grid$n
  m <- grid$m

  par(mar = c(1, 1, 2, 1), bg = "#f8f8f8")
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
    body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; }
    #status_box {
      font-size: 16px; font-weight: bold; padding: 10px;
      border-radius: 6px; text-align: center; margin-top: 10px;
    }
    .status-progress  { background: #e8f0fe; color: #1a56cc; }
    .status-violation { background: #fde8e8; color: #cc1a1a; }
    .status-solved    { background: #e8fde8; color: #1a7a1a; }
  "))),

  titlePanel("Slitherlink"),

  sidebarLayout(
    sidebarPanel(
      width = 3,
      selectInput("puzzle_name", "Select puzzle", choices = puzzle_choices),
      actionButton("new_game", "New Game",  class = "btn-primary btn-block"),
      br(),
      actionButton("reset",    "Reset",     class = "btn-warning btn-block"),
      br(),
      actionButton("solve",    "Solve",     class = "btn-info    btn-block"),
      br(),
      actionButton("hint",     "Hint",      class = "btn-default btn-block"),
      hr(),
      tags$strong("Random Puzzle"),
      fluidRow(
        column(6, numericInput("rand_n", "Rows", value = 5L,
                               min = 2L, max = 10L, step = 1L)),
        column(6, numericInput("rand_m", "Cols", value = 5L,
                               min = 2L, max = 10L, step = 1L))
      ),
      actionButton("random_puzzle", "Generate Random",
                   class = "btn-success btn-block"),
      hr(),
      uiOutput("status_box"),
      hr(),
      helpText(
        "Click near a segment to cycle it:",
        tags$ul(
          tags$li("Empty → drawn (black)"),
          tags$li("Drawn → crossed (red ×)"),
          tags$li("Crossed → empty")
        )
      )
    ),

    mainPanel(
      width = 9,
      plotOutput(
        "grid_plot",
        click  = "grid_click",
        width  = "520px",
        height = "520px"
      )
    )
  )
)

# ---------------------------------------------------------------------------
# Server
# ---------------------------------------------------------------------------

server <- function(input, output, session) {
  grid <- reactiveVal(get_puzzle("easy_3x3"))

  observeEvent(input$new_game, {
    grid(get_puzzle(input$puzzle_name))
  })

  observeEvent(input$reset, {
    grid(get_puzzle(input$puzzle_name))
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
      grid(g)
    }
  })

  observeEvent(input$solve, {
    solution <- solve_grid(grid())
    if (is.null(solution)) {
      showNotification("No solution found for this puzzle.", type = "error")
    } else {
      grid(solution)
    }
  })

  observeEvent(input$grid_click, {
    g <- grid()
    seg <- find_nearest_segment(g, input$grid_click$x, input$grid_click$y)
    if (!is.null(seg))
      grid(toggle_segment(g, seg$type, seg$i, seg$j))
  })

  output$grid_plot <- renderPlot({
    draw_grid(grid())
  }, bg = "#f8f8f8")

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
