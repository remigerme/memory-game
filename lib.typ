#import "@preview/colorful-boxes:1.4.0": outline-colorbox
#import "@preview/suiji:0.3.0": integers, gen-rng, shuffle

#let PAGE-MARGIN = 30pt

#let PAGE-WIDTH = 800pt * 200 * 140 / (190 * 140)
#let PAGE-HEIGHT = 800pt * 200 * 190 / (190 * 140)

#let ASSETS-FOLDER = "assets/"
#let BACK-CARD-PATH = ASSETS-FOLDER + "card-back.png"
#let MAX-NB-CARDS = 21
#let CARD-WIDTH = 40pt


/*********/
/* UTILS */
/*********/

// Extend an array with another array
#let extend(a, b) = {
  let c = a
  for e in b {
    c.push(e)
  }
  c
}

// Get file path of card n
#let get-file(n) = {
  ASSETS-FOLDER + "card" + str(n) + ".png"
}


/***********/
/* PARSING */
/***********/

// Read the number of pairs of cards used
#let get-nb-cards(doc) = {
  // Skipping until cards identifier
  let i = doc.children.position(x => x == [Cards])
  if (i == none) {
    panic("Couldn't find the cards identifier. Make sure there is a `Cards` somewhere.")
  }

  // Skipping whitespace and column
  i += 1
  while doc.children.at(i) == [ ] or doc.children.at(i) == [:] { i += 1 }

  // Parsing the number
  if doc.children.at(i).func() != text {
    panic("Please enter a number of cards")
  }
  let nb-cards = int(doc.children.at(i).text)

  // Checking if the number is valid
  if nb-cards < 1 or nb-cards > MAX-NB-CARDS {
    panic("Maximum number of cards is " + str(MAX-NB-CARDS))
  }

  nb-cards
}

// Read the number of players from the document and also
// read the (optional) names of the players if provided,
// else fill with "Player x" where x is an integer geq than 1
#let get-players(doc) = {
  // Skipping until players identifier
  let i = doc.children.position(x => x == [Players])
  if (i == none) {
    panic("Couldn't find the players identifier. Make sure there is a `Players` somewhere.")
  }

  // Skipping whitespace and column
  i += 1
  while doc.children.at(i) == [ ] or doc.children.at(i) == [:] { i += 1 }

  // Parsing the number
  if doc.children.at(i).func() != text {
    panic("Please enter a number of players")
  }
  let nb-players = int(doc.children.at(i).text)
  if nb-players < 1 {
    panic("There must be at least one player.")
  }

  // Skip whitespace
  i += 1
  while doc.children.at(i) == [ ] { i += 1 }

  // Then trying to read optional names of players
  let players = ()
  if doc.children.at(i).func() != text {
    // First case : the names were not provided
    for p in range(nb-players) {
      players.push("Player " + str(p + 1))
    }
  } else {
    // Second case : names were provided (in theory)
    let s = doc.children.at(i).text
    if not s.starts-with("(") or not s.ends-with(")") {
      panic("Please provide the names within parentheses")
    }

    players = s.slice(1, -1).split(",").map(p => p.trim(" "))
    if players.len() != nb-players {
      panic(
        "If you provide optional names, please provide "
          + str(nb-players)
          + " of them",
      )
    }
  }

  (nb-players, players)
}

// Parse actions from the document
// Returns an array containing fully completed locations and validations
// One entry out of three is a validation (turning cards back / removing them)
// Also checks all locations are within bounds
// But doesn't check that location isn't empty (card might have been found)
#let get-actions(doc, height, width) = { () }


/*****************/
/* INITIAL STATE */
/*****************/

// Returns a pair (height, width)
// We want the more balanced rectangle as possible
// Note that the rectangle is wider than it is high
#let get-grid-size(n) = {
  let sn = calc.floor(calc.sqrt(n))
  let res = 1
  for i in range(1, sn + 1) {
    if calc.rem(n, i) == 0 {
      res = i
    }
  }
  (res, calc.quo(n, res))
}

// Randomly choose n cards
#let choose-cards(rng, n) = {
  // Checking it is possible to choose n cards
  assert(
    n <= MAX-NB-CARDS,
    message: "Maximum number of cards is " + str(MAX-NB-CARDS),
  )

  let available = range(MAX-NB-CARDS)
  let cards = ()
  while (cards.len() < n) {
    let (rng, r) = integers(rng, low: 0, high: available.len())
    cards.push(available.remove(r))
  }
  (rng, cards)
}

// Generate initial state of the game
// Returns an array cards such as used in display-grid
#let get-initial-cards(rng, n, height, width) = {
  // Checking values are consistent
  assert.eq(
    height * width,
    2 * n,
    message: "The grid size isn't consistent with the number of pairs of cards.",
  )

  let (rng, cards) = choose-cards(rng, n) // Returns an array of n cards
  cards = cards.map(x => (x, true)) // Add visibility information
  cards = extend(cards, cards) // Each card should appear twice
  (rng, cards) = shuffle(rng, cards) // Shuffle the cards
  // Now, time to un-flatten the cards and create the grid
  let cards-grid = ()
  for (i, card) in cards.enumerate() {
    if calc.rem(i, width) == 0 {
      cards-grid.push(())
    }
    let h = calc.quo(i, width)
    cards-grid.at(h).push(card)
  }
  (rng, cards-grid)
}


/****************************/
/* INFO ABOUT CURRENT STATE */
/****************************/

// Counting the number of non-empty pairs of cards
#let get-nb-left-cards(cards) = {
  calc.quo(
    cards
      .map(row => row.fold(
        0,
        (acc, card) => if card == none { acc } else { acc + 1 },
      ))
      .sum(),
    2,
  )
}

// Errors if card is empty
#let check-card-not-empty(cards, h, w) = {
  if cards.at(h).at(w) == none {
    panic("This card has already been found.")
  }
}


/*************/
/* MAIN LOOP */
/*************/
#let simulate-game(doc, nb-cards, nb-players, initial-cards) = {
  // Initial state
  let cards = initial-cards
  let player = 0
  let scores = ()
  for _ in range(nb-players) {
    scores.push(0)
  }

  // Simulate each action
  let actions = get-actions(doc, ..get-grid-size(nb-cards))
  actions = actions.rev()
  while actions.len() > 0 {
    // First action is a cell location
    let (h1, w1) = actions.pop()
    check-card-not-empty(cards, h1, w1)
    cards.at(h1).at(w1).at(1) = true // set visibility to true

    // Second action - if it exists, should be a different cell location
    if actions.len() == 0 { break }
    let (h2, w2) = actions.pop()
    check-card-not-empty(cards, h2, w2)
    if (h2, w2) == (h1, w1) {
      panic("You must play two different cells.")
    }
    cards.at(h2).at(w2).at(1) = true // set visibility to true

    // If linebreak, validate action
    if actions.len() == 0 { break }
    let _ = actions.pop()
    if cards.at(h1).at(w1).at(0) == cards.at(h2).at(w2).at(0) {
      // If the cards were the same : win turn
      // Removing found cards
      cards.at(h1).at(w1) = none
      cards.at(h2).at(w2) = none
      scores.at(player) += 1
      // Note that value of player remains unchanged
    } else {
      // Else cards were different
      // Setting back visibility to false
      cards.at(h1).at(w1).at(1) = false
      cards.at(h2).at(w2).at(1) = false
      player = calc.rem(player + 1, nb-players) // turn of next player
    }
  }

  // Return final state
  (cards, player, scores)
}


/****************/
/* GAME DISPLAY */
/****************/

// Display users, pairs of cards left, scoreboard...
#let display-info(
  nb-players,
  nb-cards,
  cards,
  player,
  players-names,
  scores,
) = {
  outline-colorbox(
    title: "Info",
    width: auto,
    radius: 2pt,
    centering: true,
  )[#nb-players PLAYERS

    #get-nb-left-cards(cards) PAIRS OF CARDS LEFT (#nb-cards TOTAL)

    CURRENT TURN : #players-names.at(player)

    SCOREBOARD
    #{
      for (i, score) in scores.enumerate() {
        [#players-names.at(i) - #score]
      }
    }]
}

// Display the game grid filled with left cards
#let display-grid(height, width, cards) = {
  // Checking the cards lists are of the expected sizes
  assert.eq(
    height,
    cards.len(),
    message: "Cards list height is wrong."
      + str(height)
      + " "
      + str(cards.len()),
  ) // Checking height
  assert(
    cards.all(x => x.len() == width),
    message: "Cards list width is wrong.",
  ) // Checking widths

  // Everything is rendered as cells inside a table
  let cells = ()

  // First, the header row
  let cell-row = ([],)
  for j in range(width) {
    cell-row.push(str.from-unicode(j + "A".to-unicode()))
  }
  cells.push(cell-row)

  // Now, displaying each card (if needed)
  for i in range(height) {
    let cell-row = ([#(i + 1)],)
    for j in range(width) {
      // Skip if card has already been removed
      if cards.at(i).at(j) == none {
        cell-row.push([])
        continue
      }

      let (card, visible) = cards.at(i).at(j)
      let src = if visible { get-file(card) } else { BACK-CARD-PATH }
      cell-row.push(image(src))
    }
    cells.push(cell-row)
  }
  table(align: center + horizon, columns: width + 1, ..cells.flatten())
}


/*****************/
/* MAIN FUNCTION */
/*****************/
#let game(doc, seed: 10) = {
  // Page size and margin
  set page(
    width: PAGE-WIDTH,
    height: PAGE-HEIGHT,
    margin: PAGE-MARGIN,
  )

  // Inputs from doc
  let nb-cards = get-nb-cards(doc)
  let (nb-players, players-names) = get-players(doc)

  // Get initial state
  let rng = gen-rng(seed)
  let (grid-height, grid-width) = get-grid-size(2 * nb-cards)
  let (rng, initial-cards) = get-initial-cards(
    rng,
    nb-cards,
    grid-height,
    grid-width,
  )

  // Simulate all played rounds to get current state
  let (cards, player, scores) = simulate-game(
    doc,
    nb-cards,
    nb-players,
    initial-cards,
  )

  // First displaying the game info panel
  display-info(nb-players, nb-cards, cards, player, players-names, scores)

  // Finally displaying the current state
  display-grid(
    grid-height,
    grid-width,
    cards,
  )
}
