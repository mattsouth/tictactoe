# $ coffee analysis.coffee > moves.json
# Creates a JSON file that defines all the unique states in a tictacboard.
# Each key of the JSON object represents a state and has the following structure
# board: see Board below
# result: {1,2,3} if state is an end state, 1 = player 1 win, 2 = player 2 win, 3 = draw
# children: array of keys of child states
# paths: summary of number of paths that lead to different results.

# A tic-tac-toe board whose core datastructure is a nine element integer array
# with values {0,1,2} which indicate 0 = empty, 1 = player 1, 2 = player 2
# And whose array maps to the following 2D arrangement:
# 0 1 2
# 3 4 5
# 6 7 8
class Board
  @transforms = [0,1,2,3,4,5,6]

  constructor: (@board=[0,0,0,0,0,0,0,0,0]) ->

  # return unused slots - array of integers {0...8}
  moves: () -> (parseInt idx for idx, val of @board when @board[idx] is 0)

  # compare boards - returns true or false
  equals: (board) ->
    @board.every (elem, idx) -> elem is board.board[idx]

  # return transformed Board
  transform: (t) ->
    switch t
      when 0 # x=-y reflection
        new Board [@board[0],@board[3],@board[6],@board[1],@board[4],@board[7],@board[2],@board[5],@board[8]]
      when 1 # y=0 reflection
        new Board [@board[6],@board[7],@board[8],@board[3],@board[4],@board[5],@board[0],@board[1],@board[2]]
      when 2 # x=0 reflection
        new Board [@board[2],@board[1],@board[0],@board[5],@board[4],@board[3],@board[8],@board[7],@board[6]]
      when 3 # x=y reflection
        new Board [@board[8],@board[5],@board[2],@board[7],@board[4],@board[1],@board[6],@board[3],@board[0]]
      when 4 # 90deg rotation
        new Board [@board[6],@board[3],@board[0],@board[7],@board[4],@board[1],@board[8],@board[5],@board[2]]
      when 5 # 180deg rotation
        new Board [@board[8],@board[7],@board[6],@board[5],@board[4],@board[3],@board[2],@board[1],@board[0]]
      when 6 # 270deg rotation
        new Board [@board[2],@board[5],@board[8],@board[1],@board[4],@board[7],@board[0],@board[3],@board[6]]

  # flag that indicates state of board:
  # * 0 - in progress
  # * 1 - player 1 win
  # * 2 - player 2 win
  # * 3 - draw (all slots used, no winner found)
  # TODO: return -1 if the number of 1s vs 2s isnt balanced
  state: () ->
    _checkWins = (val) =>
      return true if @board[0] is val and @board[1] is val and @board[2] is val
      return true if @board[3] is val and @board[4] is val and @board[5] is val
      return true if @board[6] is val and @board[7] is val and @board[8] is val
      return true if @board[0] is val and @board[3] is val and @board[6] is val
      return true if @board[1] is val and @board[4] is val and @board[7] is val
      return true if @board[2] is val and @board[5] is val and @board[8] is val
      return true if @board[0] is val and @board[4] is val and @board[8] is val
      return true if @board[2] is val and @board[4] is val and @board[6] is val
    false
    return 2 if _checkWins(2)
    return 1 if _checkWins(1)
    return 3 if @moves().length is 0
    0

# test whether board already exists in a list of boards
is_known = (board, list) ->
  for test in list
    return true if board.equals test
  false

# try all transforms of board and compare to list
is_novel = (board, list) ->
  return false if is_known board, list
  for transform in Board.transforms
    transformed = board.transform(transform)
    return false if is_known transformed, list
  true

# returns all novel boards that can be generated from this one
play = (state, move) ->
  result = []
  for idx in state.moves()
    next = new Board state.board.slice()
    next.board[idx] = move
    result.push next if is_novel(next, result)
  result

# try all transforms of board and compare to list
# if found return the matching board from the list, else null
match = (board, list) ->
  return board if is_known board, list
  for transform in Board.transforms
    transformed = board.transform(transform)
    return transformed if is_known transformed, list
  return null

# Evolves a states object and moves object with an efficient representation
# of tictactoe board transitions. The keys in the states object are indices for
# board states (values) where the length of the key indicates the number of
# generations.  The moves object keys match the states keys and have values that
# consist of an array of reducible next moves.
# Once started this will continue until its finihsed, but, as it's tic tac toe
# this wont take very long.
#
# keysize = keysize of previous generation
# move = {1,2}
# states = all derived unique boards
# moves = all state transitions
evolve = (keysize, move, states, moves) ->
  cohort = []
  for key, parent of states when key.length is keysize and parent.state() is 0
    if not moves[key]?
      moves[key]=[]
    children = play parent, move
    for board, idx in children
      existing_board = match board, cohort
      if existing_board?
        for existing_key, value of states when key.length is keysize
          if existing_board.equals(value)
            moves[key].push existing_key
      else
        states["#{key}#{idx}"] = board
        moves[key].push "#{key}#{idx}"
        cohort.push board
  if cohort.length>0
    newmove = if move is 1 then 2 else 1
    evolve keysize+1, newmove, states, moves

backtrack = (step, rmap, winstate, result) ->
  for parent in rmap[step] when (parent isnt 's')
    result[parent].paths[winstate]++
    backtrack parent, rmap, winstate, result

# map unique states and transitions that a tic-tac-toe board can have
map = () ->
  result = {}
  states = s: new Board()
  moves = {}
  evolve 1, 1, states, moves
  rmap = {}

  for key, state of states
    result[key] =
      board: state.board
      children: moves[key]
    if moves[key]?
      for move in moves[key]
        if !rmap[move]
          rmap[move]=[]
        rmap[move].push key
    if state.state() isnt 0
      result[key].result=state.state()
    else
      if key isnt 's'
        result[key].paths =
          1: 0
          2: 0
          3: 0
  # work back from the end states to count the number of wins, draws and loss states that can be derived from a particular state
  for key, state of states when state.state() isnt 0
    backtrack key, rmap, state.state(), result
  result

console.log JSON.stringify(map())
