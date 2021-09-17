require "token"

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

  def reset_current_token!
    @current_token = Token.new("", @col + 2)
  end

  def end_of_line?
    @col == @line.size - 1
  end

  def peek
    @line[@col + 1]
  end

  def peek_empty_or_end_of_line?
    peek == " " || @col == @line.size - 1
  end

  def tokenize_line
    tokens = []
    @col = 0
    @current_token = Token.new("", @col)
    while @col < @line.size
      break if @line[@col] == "#"
      @current_token.consume @line[@col] if @line[@col] != " "
      if keyword = @current_token.as_keyword(peek)
        tokens.push keyword
        reset_current_token!
      elsif peek_empty_or_end_of_line?
        if @current_token.is_literal?
          tokens.push @current_token.as_literal
        else
          tokens.push @current_token.as_symbol if @current_token[:str].size > 0
        end
        reset_current_token!
      end

      @col += 1
    end

    return tokens
  end
end
