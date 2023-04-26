require "utils"

class ParserError
  attr_reader :msg, :start_pos, :end_pos

  def initialize(msg, start_pos, end_pos)
    @msg = msg
    @start_pos
    @end_pos = end_pos
  end
end

class SimpleAssignmentError < ParserError
end

class Parser
  attr_reader :tokens, :program_string, :pos, :errors

  def self.can_parse?(_self)
    not_implemented!
  end

  def self.from(_self)
    self.new(_self.tokens, _self.program_string, _self.pos, _self.errors)
  end

  def initialize(tokens, program_string, pos = 0, errors = [])
    @tokens = tokens
    @program_string = program_string
    @pos = pos
    @errors = errors
  end

  def consume_parser!(parser_klass, *parse_args, **parse_opts)
    parser = parser_klass.from(self)
    expr_n = parser.parse! *parse_args, **parse_opts
    @pos = parser.pos
    expr_n
  end

  def current_token
    @tokens[@pos]
  end

  def prev_token
    @tokens[@pos - 1]
  end

  def peek_token
    @tokens[@pos + 1]
  end

  def peek_token_twice
    @tokens[@pos + 2]
  end

  def peek_token_thrice
    @tokens[@pos + 3]
  end

  def rest_of_line
    rest_of_program = @program_string[current_token.start_pos..]
    rest_of_program[0..rest_of_program.index("\n")]
  end

  def current_line
    @program_string[0..current_token&.start_pos]
      .split("\n")
      .count
  end

  def new_line?(offset = 0)
    return true if !prev_token || !current_token
    prev = @tokens[@pos + offset - 1]
    curr = @tokens[@pos + offset]
    @program_string[prev.start_pos..curr.start_pos].include? "\n"
  end

  def parser_not_implemented!(parser_klasses)
    puts "Not Implemented, only supporting the following parsers - "
    pp parser_klasses
    not_implemented!
  end

  def consume_first_valid_parser!(parser_klasses, &catch_block)
    parser_klass = parser_klasses.find { |klass| klass.can_parse? self }
    if !parser_klass
      if catch_block
        catch_block.call
      else
        parser_not_implemented! parser_klasses
      end
    end
    consume_parser! parser_klass
  end

  def consume!(token_type)
    assert { token_type == current_token.type }
    @pos += 1
    return prev_token
  end

  def consume_any!
    @pos += 1
    return prev_token
  end

  def consume_if_present!(token_type)
    consume! token_type if current_token.type == token_type
  end

  def parse!
    ProgramParser.from(self).parse!
  end
end
