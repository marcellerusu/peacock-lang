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
when /-a*/
  ast = parser.parse!
  pp AST::remove_numbers(ast) unless ARGV[1].include? "n"
when "-n"
else
  ast = parser.parse!
  js = Compiler.new(ast).eval
  puts js
end
# rescue Exception => e
#   puts e.stack
#   puts "---- FAILED ----"
# end
