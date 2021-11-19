$LOAD_PATH.push "./lib"

require "lexer"
require "parser"
require "compiler"

content = File.read(ARGV[0])

tokens = Lexer::tokenize(content)
ast = Parser.new(tokens).parse!
# # puts ast
# # begin

case ARGV[1]
when "-T"
  puts tokens
when "-A"
  puts ast
when "-N"
else
  js = Compiler.new(ast).eval
  puts js
end
# rescue Exception => e
#   puts e.stack
#   puts "---- FAILED ----"
# end
