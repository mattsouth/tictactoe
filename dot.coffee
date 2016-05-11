# take moves.json and create a graphviz dot graph from it
data = require process.argv[2]

class Board
  constructor: (options) ->
    {@board, @result} = options

  get: (x,y) ->
    switch @board[x*3+y]
      when 0
        return " "
      when 1
        return "X"
      when 2
        return "O"

  # return string for associated graphviz record
  draw: (board) ->
    result = "[label=\""
    for x in [0,1,2]
      result+="\{"
      for y in [0,1,2]
        result+=@get(x,y)
        result+="|" if y<2
      result+="\}"
      result+="|" if x<2
    result+="\""
    result+=",color=\"green\",fontcolor=\"green\"" if @result is 1
    result+=",color=\"red\",fontcolor=\"red\"" if @result is 2
    result+=",color=\"lightgray\",fontcolor=\"lightgray\"" if @result is 3
    result+"]"

summary = win: 0, draw: 0, lose: 0
for key, state of data when state.result?
  summary.win++ if state.result is 1
  summary.lose++ if state.result is 2
  summary.draw++ if state.result is 3
  
# draw result
result = "digraph tictactoe {\n\tnode [shape=record];\n\tlabel = \"Analysis of tic-tac-toe, ignoring moves that can be considered symmetric. #{Object.keys(data).length} moves. #{summary.win} won.  #{summary.lose} lost. #{summary.draw} drawn.\";\n"
for key, val of data
  painter = new Board(val)
  result+="\t#{key} #{painter.draw()};\n"
for key, val of data
  if val.children?
    for move in val.children
      result+="\t#{key} -> #{move};\n"
console.log result + "}"
