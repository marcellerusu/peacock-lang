$LOAD_PATH.push "./lib"

require "lexer"
require "parser"
require "type_checker"
require "compiler"

content = File.read(ARGV[0])

tokens = Lexer::tokenize(content)
# # puts ast
# # begin
parser = Parser.new(tokens, content)

case ARGV[1]
when "-t"
  puts "["
  puts "  #{tokens.map(&:to_s).join ",\n  "}"
  puts "]"
when /-a+/
  ast = parser.parse!
  pp ast.map(&:to_h)
when "-n"
  ast = parser.parse!
when "-c"
  ast = parser.parse!
  ast = TypeChecker.new(ast, content).step!
  js = Compiler.new(ast).eval
  puts js
when "-h"
  ast = parser.parse!
  js = Compiler.new(ast).eval
  puts "
  <!DOCTYPE html>
  <html>
    <script>
      #{js}
    </script>
  </html>
  "
else
  ast = parser.parse!
  js = Compiler.new(ast).eval
  puts js
end
# rescue Exception => e
#   puts e.stack
#   puts "---- FAILED ----"
# end
