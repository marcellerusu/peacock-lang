require "utils"
require "ast"
require "lexer"

class Parser
  attr_reader :tokens, :program_string, :pos

  def self.can_parse?(_self)
    not_implemented!
  end

  def self.from(_self)
    self.new(_self.tokens, _self.program_string, _self.pos)
  end

  def initialize(tokens, program_string, pos = 0)
    @tokens = tokens
    @program_string = program_string
    @pos = pos
  end

  def consume_parser!(parser, *parse_args)
    expr_n = parser.parse! *parse_args
    @pos = parser.pos
    expr_n
  end

  def current_token
    @tokens[@pos]
  end

  def rest_of_line
    rest_of_program = @program_string[current_token.pos..]
    rest_of_program[0..rest_of_program.index("\n")]
  end

  def new_line?
    return true if !prev_token || !current_token
    @program_string[prev_token.pos..current_token.pos].include? "\n"
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

  def consume!(token_type = nil)
    # puts "#{token_type} #{current_token.type}"
    # binding.pry if token_type && token_type != current_token.type
    assert { token_type == current_token.type } unless token_type.nil?
    @pos += 1
    return prev_token
  end

  def parse!
    ProgramParser.from(self).parse!
  end
end

class SingleLineDefWithNoArgsParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :def &&
      _self.peek_token.type == :identifier &&
      _self.peek_token_twice.type == :"="
  end

  def parse!
    def_t = consume! :def
    fn_name_t = consume! :identifier
    consume! :"="
    return_value_n = consume_parser! ExprParser.from(self)
    AST::SingleLineDefWithNoArgs.new(fn_name_t.value, return_value_n, def_t.pos)
  end
end

class SimpleFnArgsParser < Parser
  def parse!
    open_t = consume! :open_paren
    args = []
    while current_token.type != :close_paren
      arg_t = consume! :identifier
      args.push arg_t.value
      consume! :comma unless current_token.type == :close_paren
    end
    consume! :close_paren

    AST::SimpleFnArgs.new(args, open_t.pos)
  end
end

class SingleLineDefWithArgsParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :def &&
      _self.peek_token.type == :identifier &&
      _self.peek_token_twice.type == :open_paren &&
      _self.rest_of_line.include?("=")
  end

  def parse!
    def_t = consume! :def
    fn_name_t = consume! :identifier
    args_n = consume_parser! SimpleFnArgsParser.from(self)
    consume! :"="
    return_value_n = consume_parser! ExprParser.from(self)

    AST::SingleLineDefWithArgs.new(fn_name_t.value, args_n, return_value_n, def_t.pos)
  end
end

class MultilineDefWithoutArgsParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :def &&
      _self.peek_token.type == :identifier
  end

  def parse!
    def_t = consume! :def
    fn_name_t = consume! :identifier
    body = consume_parser! FunctionBodyParser.from(self)
    consume! :end
    AST::MultilineDefWithoutArgs.new(fn_name_t.value, body, def_t.pos)
  end
end

class MultilineDefWithArgsParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :def &&
      _self.peek_token.type == :identifier &&
      _self.peek_token_twice.type == :open_paren
  end

  def parse!
    def_t = consume! :def
    fn_name_t = consume! :identifier
    args_n = consume_parser! SimpleFnArgsParser.from(self)
    body = consume_parser! FunctionBodyParser.from(self)
    consume! :end
    AST::MultilineDefWithArgs.new(fn_name_t.value, args_n, body, def_t.pos)
  end
end

OPERATORS = [:+, :-, :*, :/, :in, :"&&", :"||", :"==", :"!=", :>, :<, :">=", :"<="]

class OperatorParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.is_one_of? *OPERATORS
  end

  def parse!(lhs_n)
    operator_t = consume!
    rhs_n = consume_parser! ExprParser.from(self)
    AST::Op.new(lhs_n, operator_t.type, rhs_n, lhs_n.pos)
  end
end

# Complex primatives

class SimpleObjectParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :"{"
  end

  def parse!
    open_brace_t = consume! :"{"
    values = []
    while current_token.type != :"}"
      key_t = consume! :identifier
      consume! :colon
      value = consume_parser! ExprParser.from(self)
      consume! :comma unless current_token.type == :"}"
      values.push [key_t.value, value]
    end
    consume! :"}"
    AST::SimpleObjectLiteral.new(values, open_brace_t.pos)
  end
end

class ArrayParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :"["
  end

  def parse!
    open_sq_b_t = consume! :"["
    elems = []
    while current_token.type != :"]"
      elems.push consume_parser! ExprParser.from(self)
      consume! :comma unless current_token.type == :"]"
    end
    consume! :"]"
    AST::ArrayLiteral.new(elems, open_sq_b_t.pos)
  end
end

# Simple Primatives

class IntParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :int_lit
  end

  def parse!
    int_t = consume! :int_lit
    AST::Int.new(int_t.value, int_t.pos)
  end
end

class FloatParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :float_lit
  end

  def parse!
    int_t = consume! :float_lit
    AST::Float.new(int_t.value, int_t.pos)
  end
end

class SimpleStringParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :str_lit
  end

  def parse!
    int_t = consume! :str_lit
    AST::SimpleString.new(int_t.value, int_t.pos)
  end
end

class IdentifierLookupParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :identifier
  end

  def parse!
    id_t = consume! :identifier
    AST::IdLookup.new(id_t.value, id_t.pos)
  end
end

# Statements

class SimpleAssignmentParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :identifier &&
      _self.peek_token.type == :assign
  end

  def parse!
    id_t = consume! :identifier
    consume! :assign
    expr_n = consume_parser! ExprParser.from(self)

    AST::SimpleAssignment.new(id_t.value, expr_n, id_t.pos)
  end
end

class FunctionCallWithoutArgs < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :open_paren &&
    _self.peek_token.type == :close_paren
  end

  def parse!(lhs_n)
    open_p_t = consume! :open_paren
    consume! :close_paren

    AST::FnCall.new([], lhs_n, open_p_t.pos)
  end
end

class FunctionCallWithArgs < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :open_paren
  end

  def parse!(lhs_n)
    open_p_t = consume! :open_paren
    args = []
    while current_token.type != :close_paren
      args.push consume_parser! ExprParser.from(self)
      consume! :comma unless current_token.type == :close_paren
    end
    consume! :close_paren

    AST::FnCall.new(args, lhs_n, open_p_t.pos)
  end
end

class FunctionCallWithArgsWithoutParens < Parser
  def self.can_parse?(_self)
    _self.current_token&.is_not_one_of?(:comma, :"]", :close_paren, :"}") &&
      _self.peek_token&.type != :dot &&
      !_self.new_line?
  end

  def parse!(lhs_n)
    args = []
    until new_line?
      args.push consume_parser! ExprParser.from(self)
      consume! :comma unless new_line?
    end

    AST::FnCall.new(args, lhs_n, lhs_n.pos)
  end
end

class DotParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :dot
  end

  def parse!(lhs_n)
    dot_t = consume! :dot
    rhs_n = consume_parser! IdentifierLookupParser.from(self)
    AST::Dot.new(lhs_n, ".", rhs_n, dot_t.pos)
  end
end

class ReturnParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :return
  end

  def parse!
    return_t = consume! :return
    expr_n = consume_parser! ExprParser.from(self)
    AST::Return.new(expr_n, return_t.pos)
  end
end

class ShortAnonFnParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :"#\{"
  end

  def parse!
    open_anon_t = consume! :"#\{"
    return_expr_n = consume_parser! ExprParser.from(self)
    consume! :"}"
    AST::ShortFn.new(return_expr_n, open_anon_t.pos)
  end
end

class AnonIdLookupParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :%
  end

  def parse!
    id_t = consume! :%
    AST::AnonIdLookup.new(id_t.pos)
  end
end

class SingleLineArrowFnWithoutArgsParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :open_paren &&
      _self.peek_token&.type == :close_paren &&
      _self.peek_token_twice&.type == :"=>"
  end

  def parse!
    open_p_t = consume! :open_paren
    consume! :close_paren
    consume! :"=>"
    return_expr_n = consume_parser! ExprParser.from(self)
    AST::SingleLineArrowFnWithoutArgs.new(return_expr_n, open_p_t.pos)
  end
end

class SingleLineArrowFnWithArgsParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :open_paren &&
      _self.rest_of_line&.include?("=>")
  end

  def parse!
    args_n = consume_parser! SimpleFnArgsParser.from(self)
    consume! :"=>"
    return_expr_n = consume_parser! ExprParser.from(self)
    AST::SingleLineArrowFnWithArgs.new(args_n, return_expr_n, args_n.pos)
  end
end

class SingleLineArrowFnWithOneArgParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :identifier &&
      _self.peek_token&.type == :"=>"
  end

  def parse!
    arg_t = consume! :identifier
    consume! :"=>"
    return_expr_n = consume_parser! ExprParser.from(self)
    AST::SingleLineArrowFnWithOneArg.new(arg_t.value, return_expr_n, arg_t.pos)
  end
end

class ExprParser < Parser
  # order matters
  PRIMARY_PARSERS = [
    IntParser,
    FloatParser,
    SimpleStringParser,
    ArrayParser,
    SimpleObjectParser,
    AnonIdLookupParser,
    SingleLineArrowFnWithOneArgParser,
    IdentifierLookupParser,
    ShortAnonFnParser,
    SingleLineArrowFnWithoutArgsParser,
    SingleLineArrowFnWithArgsParser,
  ]

  SECONDARY_PARSERS = [
    OperatorParser,
    DotParser,
    FunctionCallWithoutArgs,
    FunctionCallWithArgs,
    FunctionCallWithArgsWithoutParens,
  ]

  def parse!
    parser_klass = PRIMARY_PARSERS.find { |parser_klass| parser_klass.can_parse?(self) }

    if !parser_klass
      not_implemented! do
        puts "Not Implemented, only supporting the following parsers - "
        pp PRIMARY_PARSERS
      end
    end

    expr_n = consume_parser! parser_klass.from(self)

    loop do
      secondary_klass = SECONDARY_PARSERS.find { |parser_klass| parser_klass.can_parse?(self) }
      break if !secondary_klass
      expr_n = consume_parser! secondary_klass.from(self), expr_n
    end

    expr_n
  end
end

class SimpleForOfLoopParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :for &&
      _self.peek_token.type == :identifier &&
      _self.peek_token_twice.type == :of
  end

  def parse!
    for_t = consume! :for
    iter_var_t = consume! :identifier
    consume! :of
    arr_expr_n = consume_parser! ExprParser.from(self)
    body = consume_parser! ProgramParser.from(self)
    consume! :end
    AST::SimpleForOfLoop.new(iter_var_t.value, arr_expr_n, body, for_t.pos)
  end
end

class ProgramParser < Parser
  def initialize(*args)
    super(*args)
    @body = []
  end

  ALLOWED_PARSERS = [
    ReturnParser,
    SimpleAssignmentParser,
    SingleLineDefWithNoArgsParser,
    SingleLineDefWithArgsParser,
    MultilineDefWithArgsParser,
    MultilineDefWithoutArgsParser,
    SimpleForOfLoopParser,
  ]

  def consume_parser!(parser)
    expr_n = parser.parse!
    @pos = parser.pos
    @body.push expr_n
  end

  def parse!
    while current_token && current_token.type != :end
      klass = ALLOWED_PARSERS.find { |klass| klass.can_parse?(self) }

      if !klass
        klass = ExprParser
      end

      consume_parser! klass.from(self)
    end

    @body
  end
end

class FunctionBodyParser < ProgramParser
  def parse!
    super

    last_n = @body[-1]
    if last_n.is_a? AST::SimpleAssignment
      @body.push AST::Return.new(AST::IdLookup.new(last_n.name, last_n.pos), last_n.pos)
    elsif last_n.is_not_a? AST::Return
      @body[-1] = AST::Return.new(last_n, last_n.pos)
    end

    @body
  end
end
