$LOAD_PATH.push "./lib"

require "lexer"
require "parser"
require "compiler"

content = File.read(ARGV[0])

tokens = Lexer::tokenize(content)
# # puts ast
# # begin

case ARGV[1]
when "-t"
  pp tokens
when /-a*/
  ast = Parser.new_top(tokens).parse!
  pp AST::remove_numbers(ast) unless ARGV[1].include? "n"
when "-n"
else
  ast = Parser.new_top(tokens).parse!
  js = Compiler.new(ast).eval
  puts js
end
# rescue Exception => e
#   puts e.stack
#   puts "---- FAILED ----"
# end
