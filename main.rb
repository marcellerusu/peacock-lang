$LOAD_PATH.push "/Users/marcellerusu/repos/m-lang/lib"

require "lexer"
require "parser"
require "compiler"

content = File.read(ARGV[0])

tokens = Lexer.new(content).tokenize
ast = Parser.new(tokens).parse!
puts Compiler.new(ast).eval
