require "token"
require "pry"

class Lexer
  def initialize(program)
    @program = program
  end

  def tokenize
    lines = @program.split("\n")
    lines.map do |line|
      @line = line
      tokenize_line
    end
  end

  private

  def tokenize_line
    tokens = []
    current_token = Token.new("", @line, 0)
    for i in 0..(@line.size - 1)
      char = @line[i]
      break if char == "#" # ignore comments
      if char == " "
        current_token = Token.new("", @line, i + 1)
        next
      end

      current_token.consume char
      # binding.pry
      next unless current_token.full_token?
      if current_token.keyword?
        tokens.push current_token.as_keyword
      elsif current_token.literal?
        tokens.push current_token.as_literal
      elsif current_token.symbol?
        tokens.push current_token.as_symbol
      end
      # TODO: why + 2?
      current_token = Token.new("", @line, i + 2)
    end

    return tokens
  end
end
