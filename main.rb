$LOAD_PATH.push "/Users/marcelrusu/Documents/Projects/peacock/lib"

require "lexer"
require "parser"
require "compiler"

content = File.read(ARGV[0])

tokens = Lexer.new(content).tokenize
ast = Parser.new(tokens).parse!
puts Compiler.new(ast).eval
