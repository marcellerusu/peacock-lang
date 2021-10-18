# require "pry"

TOKENS = {
  "=" => :declare,
  ":=" => :assign,
  "(" => :open_parenthesis,
  ")" => :close_parenthesis,
  "{" => :open_brace,
  "}" => :close_brace,
  "[" => :open_square_bracket,
  "]" => :close_square_bracket,
  "=>" => :arrow,
  "." => :dot,
  ":" => :colon,
  "," => :comma,
  # Operators
  "==" => :eq,
  "!=" => :not_eq,
  "*" => :mult,
  "/" => :div,
  "+" => :plus,
  "-" => :minus,
  # values
  "true" => :true,
  "false" => :false,
  "self" => :self,
  # Constructs
  "fn" => :fn,
  "if" => :if,
  "unless" => :unless,
  "else" => :else,
  "then" => :then,
  "end" => :end,
  "reduce" => :reduce, # TODO
  "next" => :next, # TODO
  "break" => :break, # TODO
  "module" => :module, # TODO
  "class" => :class, # TODO
  "return" => :return,
}

class Token
  attr_reader :token, :line, :current_index, :start_index

  def initialize(token, line, index)
    @token = token
    @start_index = index
    @current_index = index
    @line = line
  end

  def clone
    Token.new(@token, @line, @start_index)
  end

  def undo!
    @current_index -= 1
    @token = @token.chop
    self
  end

  def consume!(char)
    @current_index += 1
    @token += char
  end

  def full_token?
    @token == peek_rest_of_token.token
  end

  def invalid?
    !valid?
  end

  def valid?
    keyword? || literal? || symbol? || identifier? || instance_identifier?
  end

  # Parsing

  def as_token
    return as_literal if literal?
    return as_keyword if keyword?
    return as_identifier if identifier?
    return as_symbol if symbol?
    return as_instance_identifier if instance_identifier?
  end

  def as_keyword
    [@start_index, TOKENS[@token]]
  end

  def as_identifier
    [@start_index, :identifier, @token]
  end

  def as_instance_identifier
    [@start_index, :instance_identifier, @token]
  end

  def as_symbol
    [@start_index, :symbol, @token]
  end

  def as_literal
    return [@start_index, :str_lit, as_str] if str?
    return [@start_index, :regex_lit, as_regex] if regex?
    return [@start_index, :int_lit, as_int] if int?
    return [@start_index, :float_lit, as_float] if float?
  end

  def symbol?
    return false if @token.chr != ":"
    return Token.new(@token.delete_prefix(":"), nil, nil).identifier?
  end

  def identifier?
    return false if TOKENS.include?(@token)
    return false if @token =~ /[\s]/
    return false unless @token =~ /^[a-zA-Z][a-zA-Z1-9\-!?]*$/
    return true
  end

  def instance_identifier?
    return false if @token.chr != "@"
    return Token.new(@token.delete_prefix(":"), nil, nil).identifier?
  end

  def keyword?
    TOKENS.include?(token)
  end

  def literal?
    int? || float? || str?
  end

  def empty?
    @token.empty?
  end

  def str?
    !!(@token =~ /^".*"$/)
  end

  def regex?
    !!(@token =~ /^\/.*\/[gim]?$/)
  end

  def as_str
    @token[1..-2]
  end

  def int?
    as_int.to_s == @token
  end

  def as_int
    @token.to_i
  end

  def float?
    return clone.undo!.int? if @token[-1] == "."
    as_float.to_s == @token
  end

  def as_float
    @token.to_f
  end

  # Peeking

  def peek_string
    i = @line[@current_index + 1..].index '"'
    Token.new(@line[@start_index..i + 1], @line, @start_index) unless i.nil?
  end

  def peek_rest_of_token
    return self if @current_index >= @line.size
    return peek_string || self if @token[0] == '"'

    peek_token = Token.new(@token, @line, @start_index)
    for char in @line.slice(@current_index + 1, @line.size - 1).split("")
      if peek_token.invalid?
        peek_token.undo!
        break
      end
      peek_token.consume! char
    end
    if peek_token.valid?
      return peek_token
    else
      return peek_token.undo!
    end
  end
end
