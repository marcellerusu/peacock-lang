require "ast"
require "parser"
require "compiler"

def compile(str)
  tokens = Lexer::tokenize(str.strip)
  ast = Parser.new(tokens, str).parse!
  Compiler.new(ast).eval
end

def entries(dir)
  Dir.entries(dir).select { |file| ![".", ".."].include? file }
end

entries("spec/codegen").each do |category|
  context category do
    entries("spec/codegen/#{category}").each do |name|
      contents = File.read("spec/codegen/#{category}/#{name}")
      f = false
      i = false
      case contents[0..1]
      when ":f"
        f = true
        contents.slice! ":f"
      when ":i"
        i = true
        contents.slice! ":i"
      end
      begin
        it name, f: f, i: i do
          output = compile(contents)
          expected_output = contents.split("\n")
            .select { |line| line.start_with? "#" }
            .map { |line| line[2..].rstrip }.join "\n"

          expect(output).to eq(expected_output)
        end
      rescue
        binding.pry
      end
    end
  end
end
