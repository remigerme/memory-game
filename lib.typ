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

// Read the number of pairs of cards used
#let get-nb-cards(doc) = { 2 }

// Read the number of players from the document
#let get-nb-players(doc) = { 2 }

// Read the (optional) names of the players if provided
// Else fill with "Player x" where x is an integer geq than 1
#let get-players-names(doc, nb-players) = { ("Yo", "Le reuf") }

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

// Get file path of card n
#let get-file(n) = {
  ASSETS-FOLDER + "card" + str(n) + ".png"
}

// Counting the number of empty (none) cards
#let get-nb-left-cards(cards) = {
  cards
    .map(row => row.fold(
      0,
      (acc, card) => if card == none { acc } else { acc + 1 },
    ))
    .sum()
}

// Main loop
#let simulate-game(doc, rng, nb-cards, nb-players, initial-cards) = {
  let player = 0
  let scores
  (initial-cards, player, (0, 2))
}

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

// Main function
#let game(doc, seed: 10) = {
  // Page size and margin
  set page(
    width: PAGE-WIDTH,
    height: PAGE-HEIGHT,
    margin: PAGE-MARGIN,
  )

  // Inputs from doc
  let nb-cards = get-nb-cards(doc)
  let nb-players = get-nb-players(doc)
  let players-names = get-players-names(doc, nb-players) // Optional names

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
    rng,
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
