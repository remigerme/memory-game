#import "../lib.typ": game

// Change seed for a different random game
#show: game.with(seed: 10)

/************/
/* SETTINGS */
/************/

// Number of pairs of cards (max TODO) - default : TODO
Cards : 15

// Number of players (at least 1)
// The players can be given optional names within parentheses and separated by
// commas, WITHOUT SPACES before the commas.
// If a name is provided, all players must be given a name
// For example : 4 (Sofia, King Arthur, Rémi, Marilie)
Players : 2 (Sofia, King Arthur)

// Play below the start (and do not erase it)
// Specify two locations on a line
// Each card will be revealed as soon as typed
// Make sure you are typing on the LAST line of the editor to be able to see both of your played cards visible
// When you are ready to turn them back, create a new line
// Make sure to stay within bounds of the grid :)
// Example game
// Start
// a5 b2
// b3 c    -- here the row is not specified yet
Start
