#!/usr/bin/env ruby

$LOAD_PATH.push "./lib"

require "lexer"
require "parser"
require "compiler"

def eval(src)
  tokens = Lexer::tokenize src
  ast = Parser.new_top(tokens).parse!
  Compiler.new(ast).eval
end

while true
  print "(pea)> "
  input = gets.chomp
  js = eval(input)
  begin
    result = %x{ echo '#{js}' | node }
    puts result
  rescue
    puts "wtf"
  end
end
