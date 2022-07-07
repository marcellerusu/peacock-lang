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

  def consume_parser!(parser_klass, *parse_args)
    parser = parser_klass.from(self)
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

  def peek_token_thrice
    @tokens[@pos + 3]
  end

  def parser_not_implemented!(parser_klasses)
    puts "Not Implemented, only supporting the following parsers - "
    pp parser_klasses
    not_implemented!
  end

  def consume_first_valid_parser!(parser_klasses)
    parser_klass = parser_klasses.find { |klass| klass.can_parse? self }
    if !parser_klass
      parser_not_implemented! parser_klasses
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

class SimpleSchemaArgParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :identifier &&
      _self.peek_token.type == :open_paren &&
      _self.peek_token_twice.type == :identifier &&
      _self.peek_token_thrice.type == :close_paren
  end

  def parse!
    args = []
    schema_name_t = consume! :identifier
    consume! :open_paren
    var_t = consume! :identifier
    consume! :close_paren
    AST::SimpleSchemaArg.new(schema_name_t.value, var_t.value, schema_name_t.pos)
  end
end

class SimpleArgParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :identifier &&
      _self.peek_token.is_one_of?(:comma, :close_paren)
  end

  def parse!
    name_t = consume! :identifier
    AST::SimpleArg.new(name_t.value, name_t.pos)
  end
end

class SimpleFnArgsParser < Parser
  ARG_PARSERS = [
    SimpleArgParser,
    SimpleSchemaArgParser,
  ]

  def parse!
    open_t = consume! :open_paren

    if current_token.type == :close_paren
      consume! :close_paren
      return AST::SimpleFnArgs.new([], open_t.pos)
    end

    args = []

    loop do
      args.push consume_first_valid_parser! ARG_PARSERS
      break if current_token.type == :close_paren
      consume! :comma
    end
    consume! :close_paren

    AST::SimpleFnArgs.new(args, open_t.pos)
  end
end

class SingleLineDefWithArgsParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :function &&
      _self.peek_token.type == :identifier &&
      _self.peek_token_twice.type == :open_paren &&
      _self.rest_of_line.include?("=")
  end

  def parse!
    function_t = consume! :function
    fn_name_t = consume! :identifier
    args_n = consume_parser! SimpleFnArgsParser
    consume! :"="
    return_value_n = consume_parser! ExprParser

    AST::SingleLineDefWithArgs.new(fn_name_t.value, args_n, return_value_n, function_t.pos)
  end
end

class MultilineDefWithoutArgsParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :function &&
      _self.peek_token.type == :identifier
  end

  def parse!
    function_t = consume! :function
    fn_name_t = consume! :identifier
    body = consume_parser! FunctionBodyParser
    consume! :end
    AST::MultilineDefWithoutArgs.new(fn_name_t.value, body, function_t.pos)
  end
end

class MultilineDefWithArgsParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :function &&
      _self.peek_token.type == :identifier &&
      _self.peek_token_twice.type == :open_paren
  end

  def parse!
    function_t = consume! :function
    fn_name_t = consume! :identifier
    args_n = consume_parser! SimpleFnArgsParser
    body = consume_parser! FunctionBodyParser
    consume! :end
    AST::MultilineDefWithArgs.new(fn_name_t.value, args_n, body, function_t.pos)
  end
end

OPERATORS = [:+, :-, :*, :/, :in, :"&&", :"||", :"===", :"!==", :>, :<, :">=", :"<="]

class OperatorParser < Parser
  def self.can_parse?(_self, node)
    _self.current_token&.is_one_of?(*OPERATORS)
  end

  def parse!(lhs_n)
    operator_t = consume_any!
    rhs_n = consume_parser! ExprParser
    AST::Op.new(lhs_n, operator_t.type, rhs_n, lhs_n.pos)
  end
end

# Complex primatives

class SimpleObjectEntryParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :identifier &&
      _self.peek_token.type == :colon
  end

  def parse!
    key_t = consume! :identifier
    consume! :colon
    value_n = consume_parser! ExprParser

    AST::SimpleObjectEntry.new(key_t.value, value_n, key_t.pos)
  end
end

class ArrowMethodObjectEntryParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :identifier &&
      _self.peek_token.type == :open_paren &&
      _self.rest_of_line.include?("=>")
  end

  def parse!
    key_t = consume! :identifier
    args_n = consume_parser! SimpleFnArgsParser
    consume! :"=>"
    return_expr_n = consume_parser! ExprParser
    AST::ArrowMethodObjectEntry.new(
      key_t.value,
      AST::SingleLineArrowFnWithArgs.new(
        args_n,
        return_expr_n,
        # TODO: incorrect
        # this should be position of (
        key_t.pos
      ),
      key_t.pos
    )
  end
end

class FunctionObjectEntryParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :function
  end

  def parse!
    fn_n = consume_first_valid_parser! function_parsers
    AST::FunctionObjectEntry.new(fn_n.name, fn_n, fn_n.pos)
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

class SpreadObjectEntryParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :"..."
  end

  def parsers
    [
      IdentifierLookupParser,
      ObjectParser,
    ]
  end

  def parse!
    spread_t = consume! :"..."
    expr_n = consume_first_valid_parser! parsers
    AST::SpreadObjectEntry.new(expr_n, spread_t.pos)
  end
end

class ObjectParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :"{"
  end

  ENTRY_PARSERS = [
    SimpleObjectEntryParser,
    ArrowMethodObjectEntryParser,
    FunctionObjectEntryParser,
    SpreadObjectEntryParser,
  ]

  def parse!
    open_brace_t = consume! :"{"
    values = []
    loop do
      values.push consume_first_valid_parser! ENTRY_PARSERS
      consume_if_present! :comma
      break if current_token.type == :"}"
    end
    consume! :"}"
    AST::ObjectLiteral.new(values, open_brace_t.pos)
  end
end

class ArrayParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :"["
  end

  def parse!
    open_sq_b_t = consume! :"["
    elems = []
    loop do
      elems.push consume_parser! ExprParser
      consume_if_present! :comma
      break if current_token.type == :"]"
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

# Statements

class SimpleAssignmentParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :identifier &&
      _self.peek_token.type == :assign
  end

  def parse!
    id_t = consume! :identifier
    consume! :assign
    expr_n = consume_parser! ExprParser

    AST::SimpleAssignment.new(id_t.value, expr_n, id_t.pos)
  end
end

class FunctionCallWithoutArgs < Parser
  def self.can_parse?(_self, node)
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
  def self.can_parse?(_self, node)
    _self.current_token&.type == :open_paren
  end

  def parse!(lhs_n)
    open_p_t = consume! :open_paren
    args = []
    loop do
      args.push consume_parser! ExprParser
      consume_if_present! :comma
      break if current_token.type == :close_paren
    end
    consume! :close_paren

    AST::FnCall.new(args, lhs_n, open_p_t.pos)
  end
end

class FunctionCallWithArgsWithoutParens < Parser
  def self.can_parse?(_self, node)
    _self.current_token&.is_not_one_of?(:comma, :"]", :"#\{", :close_paren, :"}") &&
    !_self.new_line?
  end

  def end_of_expr?
    current_token&.is_one_of? :"}", :close_paren
  end

  def parse!(lhs_n)
    args = []

    loop do
      args.push consume_parser! ExprParser
      break if new_line? || end_of_expr?
      consume! :comma
    end

    AST::FnCall.new(args, lhs_n, args.first.pos)
  end
end

class DotParser < Parser
  def self.can_parse?(_self, node)
    _self.current_token&.type == :dot
  end

  def parse!(lhs_n)
    dot_t = consume! :dot
    rhs_n = consume_parser! IdentifierLookupParser
    AST::Dot.new(lhs_n, ".", rhs_n, dot_t.pos)
  end
end

class ReturnParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :return
  end

  def parse!
    return_t = consume! :return
    expr_n = consume_parser! ExprParser
    AST::Return.new(expr_n, return_t.pos)
  end
end

class ShortAnonFnParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :"#\{"
  end

  def parse!
    open_anon_t = consume! :"#\{"
    return_expr_n = consume_parser! ExprParser
    consume! :"}"
    AST::ShortFn.new(return_expr_n, open_anon_t.pos)
  end
end

class AnonIdLookupParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :it
  end

  def parse!
    id_t = consume! :it
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
    return_expr_n = consume_parser! ExprParser
    AST::SingleLineArrowFnWithoutArgs.new(return_expr_n, open_p_t.pos)
  end
end

class MultiLineArrowFnWithArgsParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :open_paren &&
      _self.rest_of_line&.include?("=>") &&
      _self.rest_of_line&.include?("{")
  end

  def parse!
    args_n = consume_parser! SimpleFnArgsParser
    consume! :"=>"
    consume! :"{"
    body_n = consume_parser! FunctionBodyParser
    consume! :"}"
    AST::MultiLineArrowFnWithArgs.new(args_n, body_n, args_n.pos)
  end
end

class SingleLineArrowFnWithArgsParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :open_paren &&
      _self.rest_of_line&.include?("=>")
  end

  def parse!
    args_n = consume_parser! SimpleFnArgsParser
    consume! :"=>"
    return_expr_n = consume_parser! ExprParser
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
    return_expr_n = consume_parser! ExprParser
    AST::SingleLineArrowFnWithOneArg.new(arg_t.value, return_expr_n, arg_t.pos)
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
    arr_expr_n = consume_parser! ExprParser
    body = consume_parser! ProgramParser
    consume! :end
    AST::SimpleForOfLoop.new(iter_var_t.value, arr_expr_n, body, for_t.pos)
  end
end

class AwaitParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :await
  end

  def parse!
    await_t = consume! :await
    expr_n = consume_parser! ExprParser
    AST::Await.new(expr_n, await_t.pos)
  end
end

class BoolParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :bool_lit
  end

  def parse!
    bool_t = consume! :bool_lit
    AST::Bool.new(bool_t.value, bool_t.pos)
  end
end

class ExprParser < Parser
  # order matters
  PRIMARY_PARSERS = [
    IntParser,
    FloatParser,
    BoolParser,
    SimpleStringParser,
    ArrayParser,
    ObjectParser,
    AnonIdLookupParser,
    MultiLineArrowFnWithArgsParser,
    SingleLineArrowFnWithOneArgParser,
    IdentifierLookupParser,
    ShortAnonFnParser,
    SingleLineArrowFnWithoutArgsParser,
    SingleLineArrowFnWithArgsParser,
    AwaitParser,
  ]

  SECONDARY_PARSERS = [
    OperatorParser,
    DotParser,
    FunctionCallWithoutArgs,
    FunctionCallWithArgs,
    FunctionCallWithArgsWithoutParens,
  ]

  def parse!
    expr_n = consume_first_valid_parser! PRIMARY_PARSERS
    loop do
      secondary_klass = SECONDARY_PARSERS.find { |parser_klass| parser_klass.can_parse?(self, expr_n) }
      break if !secondary_klass
      expr_n = consume_parser! secondary_klass, expr_n
    end
    expr_n
  end
end

class ForOfObjDeconstructLoopParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :for &&
      _self.peek_token.type == :"{"
  end

  def parse!
    for_t = consume! :for
    properties = []
    consume! :"{"
    loop do
      properties.push consume!(:identifier).value
      break if current_token.type == :"}"
      consume! :comma
    end
    consume! :"}"
    consume! :of
    arr_expr_n = consume_parser! ExprParser
    body = consume_parser! ProgramParser
    consume! :end
    AST::ForOfObjDeconstructLoop.new(properties, arr_expr_n, body, for_t.pos)
  end
end

class SchemaCaptureParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :capture
  end

  def parse!
    id_t = consume! :capture
    AST::SchemaCapture.new(id_t.value, id_t.pos)
  end
end

class SchemaObjectParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :"{"
  end

  VALUE_PARSERS = [
    IntParser,
    FloatParser,
    SimpleStringParser,
    ShortAnonFnParser,
    SchemaCaptureParser,
  ]

  def parse_value!(key_name, pos)
    return AST::SchemaCapture.new(key_name, pos) if current_token.type != :colon
    consume! :colon
    consume_first_valid_parser! VALUE_PARSERS
  end

  def parse!
    open_b_t = consume! :"{"
    properties = []
    loop do
      property_t = consume! :identifier
      properties.push [property_t.value, parse_value!(property_t.value, property_t.pos)]
      break if current_token.type == :"}"
      consume! :comma
    end
    consume! :"}"
    AST::SchemaObjectLiteral.new(properties, open_b_t.pos)
  end
end

class SchemaDefinitionParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :schema
  end

  SCHEMA_PARSERS = [
    SchemaObjectParser,
    IntParser,
    SimpleStringParser,
  ]

  def parse!
    schema_t = consume! :schema
    name_t = consume! :identifier
    consume! :"="
    expr_n = consume_first_valid_parser! SCHEMA_PARSERS
    AST::SchemaDefinition.new(name_t.value, expr_n, schema_t.pos)
  end
end

class SimpleSchemaAssignmentParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :identifier &&
      _self.peek_token.type == :open_paren &&
      _self.peek_token_twice.type == :identifier &&
      _self.peek_token_thrice.type == :close_paren
  end

  def parse!
    schema_name_t = consume! :identifier
    consume! :open_paren
    var_t = consume! :identifier
    consume! :close_paren
    consume! :assign
    expr_n = consume_parser! ExprParser
    AST::SimpleSchemaAssignment.new(schema_name_t.value, var_t.value, expr_n, schema_name_t.pos)
  end
end

def function_parsers
  [
    SingleLineDefWithArgsParser,
    MultilineDefWithArgsParser,
    MultilineDefWithoutArgsParser,
  ]
end

class ProgramParser < Parser
  def initialize(*args)
    super(*args)
    @body = []
  end

  ALLOWED_PARSERS = function_parsers + [
    SimpleAssignmentParser,
    ForOfObjDeconstructLoopParser,
    SimpleForOfLoopParser,
    SchemaDefinitionParser,
    SimpleSchemaAssignmentParser,
  ]

  def consume_parser!(parser_klass)
    expr_n = super parser_klass
    @body.push expr_n
  end

  def parse!(additional_parsers = [])
    while current_token && current_token.is_not_one_of?(:end, :"}")
      klass = (ALLOWED_PARSERS + additional_parsers).find { |klass| klass.can_parse?(self) }

      if !klass
        klass = ExprParser
      end

      consume_parser! klass
    end

    @body
  end
end

class FunctionBodyParser < ProgramParser
  ALLOWED_PARSERS = [
    ReturnParser,
  ]

  def parse!
    super ALLOWED_PARSERS

    last_n = @body[-1]
    if last_n.is_a? AST::SimpleAssignment
      @body.push AST::Return.new(AST::IdLookup.new(last_n.name, last_n.pos), last_n.pos)
    elsif last_n.is_not_a? AST::Return
      @body[-1] = AST::Return.new(last_n, last_n.pos)
    end

    @body
  end
end
