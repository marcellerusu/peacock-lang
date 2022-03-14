$LOAD_PATH.push "./lib"

require "lexer"
require "parser"
require "compiler"

content = File.read(ARGV[0])

tokens = Lexer::tokenize(content)
# # puts ast
# # begin
parser = Parser.new(tokens, content)
case ARGV[1]
when "-t"
  pp tokens
when /-a+/
  ast = parser.parse!
  pp ast.map(&:to_h)
when "-n"
  ast = parser.parse!
else
  ast = parser.parse!
  js = Compiler.new(ast).eval
  puts js
end
# rescue Exception => e
#   puts e.stack
#   puts "---- FAILED ----"
# end
