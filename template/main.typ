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

/**************/
/* PLAY BELOW */
/**************/
