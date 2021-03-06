#!/usr/bin/env ruby

$LOAD_PATH.push "./lib"

require "lexer"
require "parser"

content = File.read(ARGV[0])
tokens = Lexer::tokenize(content)
ast = Parser.new(tokens, content).parse!
ast = ast.map(&:to_h)
spec = <<-EOS
  it "#{Time::now}" do
    ast = parse('#{content}')
    expect(ast).to eq(#{ast})
  end
EOS

SNAPSHOT_SPEC_FILENAME = "spec/snapshot_spec.rb"

*file, end_line = File.read(SNAPSHOT_SPEC_FILENAME)
  .split("\n")

throw "wtf" if end_line != "end"

new_file = (file + spec.split("\n") + [end_line]).join("\n")

File.write(SNAPSHOT_SPEC_FILENAME, new_file)
