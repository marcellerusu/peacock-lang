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

  def consume_token!
    return if @current_token.nil?
    @tokens.push @current_token.as_token if @current_token.valid?
    @current_token = nil
  end

  def tokenize_line
    @tokens = []
    @current_token = nil
    for i in 0..(@line.size - 1)
      char = @line[i]
      if char == "#"
        consume_token!
        break
      end
      if char == " " && !@current_token&.token&.start_with?('"')
        consume_token!
        next
      end
      @current_token.consume! char unless @current_token.nil?
      @current_token = Token.new(char, @line, i) if @current_token.nil?
      next unless @current_token.full_token?
      consume_token!
    end

    return @tokens
  end
end
