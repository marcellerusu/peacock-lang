require "utils"
require "ast"
require "lexer"

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

class SimpleSchemaArgParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :identifier &&
      _self.peek_token.type == :open_paren &&
      _self.peek_token_twice.type == :identifier &&
      _self.peek_token_thrice.type == :close_paren
  end

  def parse!
    args = []
    schema_name_t = consume! :identifier
    consume! :open_paren
    var_t = consume! :identifier
    close_t = consume! :close_paren
    AST::SimpleSchemaArg.new(
      schema_name_t.value,
      var_t.value,
      schema_name_t.start_pos,
      close_t.end_pos
    )
  end
end

class SchemaIntParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :int_lit
  end

  def parse!
    consume_parser! IntParser
  end
end

class SimpleArgParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :identifier &&
      _self.peek_token.is_one_of?(:comma, :close_paren)
  end

  def parse!
    name_t = consume! :identifier
    AST::SimpleArg.new(name_t.value, name_t.start_pos, name_t.end_pos)
  end
end

class NullSchemaParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :null
  end

  def parse!
    null_t = consume! :null
    AST::NullSchema.new(null_t.start_pos, null_t.end_pos)
  end
end

class SchemaArgParser < Parser
  PARSERS = [
    SimpleSchemaArgParser,
    NullSchemaParser,
    SchemaIntParser,
    SimpleArgParser,
  ]

  def self.can_parse?(_self)
    PARSERS.any? { |klass| klass.can_parse? _self }
  end

  def parse!
    consume_first_valid_parser! PARSERS
  end
end

class SimpleFnArgsParser < Parser
  ARG_PARSERS = [
    SimpleArgParser,
    SchemaArgParser,
  ]

  def parse!
    open_t = consume! :open_paren

    if current_token.type == :close_paren
      close_t = consume! :close_paren
      return AST::SimpleFnArgs.new([], open_t.start_pos, close_t.end_pos)
    end

    args = []

    loop do
      args.push consume_first_valid_parser! ARG_PARSERS
      break if current_token.type == :close_paren
      consume! :comma
    end
    close_t = consume! :close_paren

    AST::SimpleFnArgs.new(args, open_t.start_pos, close_t.end_pos)
  end
end

class SingleLineDefWithArgsParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :function &&
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

    AST::SingleLineDefWithArgs.new(
      fn_name_t.value,
      args_n,
      return_value_n,
      function_t.start_pos,
      return_value_n.end_pos
    )
  end
end

class SingleLineDefWithoutArgsParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :function &&
      _self.peek_token.type == :identifier &&
      _self.rest_of_line.include?("=")
  end

  def parse!
    function_t = consume! :function
    fn_name_t = consume! :identifier
    consume! :"="
    return_value_n = consume_parser! ExprParser

    AST::SingleLineDefWithoutArgs.new(
      fn_name_t.value,
      return_value_n,
      function_t.start_pos,
      return_value_n.end_pos
    )
  end
end

class MultilineDefWithoutArgsParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :function &&
      _self.peek_token.type == :identifier
  end

  def parse!
    function_t = consume! :function
    fn_name_t = consume! :identifier
    body = consume_parser! FunctionBodyParser
    end_t = consume! :end
    AST::MultilineDefWithoutArgs.new(
      fn_name_t.value,
      body,
      function_t.start_pos,
      end_t.end_pos
    )
  end
end

class MultilineDefWithArgsParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :function &&
      _self.peek_token.type == :identifier &&
      _self.peek_token_twice.type == :open_paren
  end

  def parse!
    function_t = consume! :function
    fn_name_t = consume! :identifier
    args_n = consume_parser! SimpleFnArgsParser
    body = consume_parser! FunctionBodyParser
    end_t = consume! :end
    AST::MultilineDefWithArgs.new(
      fn_name_t.value,
      args_n,
      body,
      function_t.start_pos,
      end_t.end_pos
    )
  end
end

OPERATORS = [:+, :-, :*, :/, :"&&", :"||", :"===", :"!==", :>, :<, :">=", :"<=", :mod, :"==", :in]

class OperatorParser < Parser
  def self.can_parse?(_self, lhs_n)
    _self.current_token&.is_one_of?(*OPERATORS)
  end

  def parse!(lhs_n)
    operator_t = consume_any!
    rhs_n = consume_parser! ExprParser
    AST::Op.new(lhs_n, operator_t.type, rhs_n, lhs_n.start_pos, rhs_n.end_pos)
  end
end

# Complex primatives

class SimpleObjectEntryParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :identifier &&
      _self.peek_token.type == :colon
  end

  def parse!
    key_t = consume! :identifier
    consume! :colon
    value_n = consume_parser! ExprParser

    AST::SimpleObjectEntry.new(key_t.value, value_n, key_t.start_pos, value_n.end_pos)
  end
end

class ArrowMethodObjectEntryParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :identifier &&
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
        args_n.start_pos,
        return_expr_n.end_pos
      ),
      key_t.start_pos,
      return_expr_n.end_pos
    )
  end
end

class FunctionObjectEntryParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :function
  end

  def parse!
    fn_n = consume_parser! FunctionDefinitionParser
    AST::FunctionObjectEntry.new(fn_n.name, fn_n, fn_n.start_pos, fn_n.end_pos)
  end
end

class IdentifierLookupParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :identifier
  end

  def parse!
    id_t = consume! :identifier
    AST::IdLookup.new(id_t.value, id_t.start_pos, id_t.end_pos)
  end
end

class SpreadObjectEntryParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :"..."
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
    AST::SpreadObjectEntry.new(expr_n, spread_t.start_pos, spread_t.end_pos)
  end
end

class ObjectParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :"{"
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
      break if current_token.type == :"}"
      values.push consume_first_valid_parser! ENTRY_PARSERS
      consume_if_present! :comma
      break if current_token.type == :"}"
    end
    close_brace_t = consume! :"}"
    AST::ObjectLiteral.new(values, open_brace_t.start_pos, close_brace_t.end_pos)
  end
end

class ArrayComprehensionParser < Parser
  def parse!(expr_n, start_pos)
    consume! :for
    id_t = consume! :identifier
    consume! :in
    array_expr_n = consume_parser! ExprParser
    if_expr_n = nil
    if current_token.type == :if
      consume! :if
      if_expr_n = consume_parser! ExprParser
    end
    close_sq_b_t = consume! :"]"
    AST::ArrayComprehension.new(
      expr_n,
      id_t.value,
      array_expr_n,
      if_expr_n,
      start_pos,
      close_sq_b_t.end_pos
    )
  end
end

class ArrayParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :"["
  end

  def parse!
    open_sq_b_t = consume! :"["
    elems = []
    if current_token.type == :"]"
      close_sq_b_t = consume! :"]"
      return AST::ArrayLiteral.new(elems, open_sq_b_t.start_pos, close_sq_b_t.end_pos)
    end

    first_expr_n = consume_parser! ExprParser

    if current_token.type == :for
      return consume_parser! ArrayComprehensionParser, first_expr_n, open_sq_b_t.start_pos
    end
    elems.push first_expr_n
    loop do
      break if current_token.type == :"]"
      consume_if_present! :comma
      elems.push consume_parser! ExprParser
    end
    close_sq_b_t = consume! :"]"
    AST::ArrayLiteral.new(elems, open_sq_b_t.start_pos, close_sq_b_t.end_pos)
  end
end

# Simple Primatives

class IntParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :int_lit
  end

  def parse!
    int_t = consume! :int_lit
    AST::Int.new(int_t.value, int_t.start_pos, int_t.end_pos)
  end
end

class FloatParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :float_lit
  end

  def parse!
    float_t = consume! :float_lit
    AST::Float.new(float_t.value, float_t.start_pos, float_t.end_pos)
  end
end

class SimpleStringParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :str_lit
  end

  def parse!
    str_t = consume! :str_lit
    AST::SimpleString.new(str_t.value, str_t.start_pos, str_t.end_pos)
  end
end

# Statements

class SimpleReassignmentParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :identifier &&
      _self.peek_token&.type == :"="
  end

  def parse!
    id_t = consume! :identifier
    consume! :"="
    expr_n = consume_parser! ExprParser

    AST::SimpleReassignment.new(id_t.value, expr_n, id_t.start_pos, expr_n.end_pos)
  end
end

class SimpleAssignmentParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :identifier &&
      _self.peek_token&.type == :assign
  end

  def parse!
    id_t = consume! :identifier
    consume! :assign
    expr_n = consume_parser! ExprParser

    AST::SimpleAssignment.new(id_t.value, expr_n, id_t.start_pos, expr_n.end_pos)
  end
end

class DefaultAssignmentParser < Parser
  def self.can_parse?(_self, lhs)
    _self.current_token&.type == :"||="
  end

  def parse!(lhs_n)
    consume! :"||="
    expr_n = consume_parser! ExprParser
    AST::DefaultAssignment.new(lhs_n, expr_n, lhs_n.start_pos, expr_n.end_pos)
  end
end

class PlusAssignmentParser < Parser
  def self.can_parse?(_self, lhs)
    _self.current_token&.type == :"+="
  end

  def parse!(lhs_n)
    consume! :"+="
    expr_n = consume_parser! ExprParser
    AST::PlusAssignment.new(lhs_n, expr_n, lhs_n.start_pos, expr_n.end_pos)
  end
end

class FunctionCallWithoutArgs < Parser
  def self.can_parse?(_self, lhs)
    _self.current_token&.type == :open_paren &&
      _self.peek_token.type == :close_paren
  end

  def parse!(lhs_n)
    open_p_t = consume! :open_paren
    close_p_t = consume! :close_paren

    AST::FnCall.new([], lhs_n, open_p_t.start_pos, close_p_t.end_pos)
  end
end

class FunctionCallWithArgs < Parser
  def self.can_parse?(_self, lhs)
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
    close_p_t = consume! :close_paren

    AST::FnCall.new(args, lhs_n, open_p_t.start_pos, close_p_t.end_pos)
  end
end

class SimpleWhenParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :when
  end

  def parse!
    when_t = consume! :when
    expr_n = consume_parser! ExprParser
    body = consume_parser! ProgramParser, end_tokens: [:when, :else]
    AST::SimpleWhen.new(expr_n, body, when_t.start_pos, body.last&.end_pos || expr_n.end_pos)
  end
end

class CaseElseParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :else
  end

  def parse!
    else_t = consume! :else
    body = consume_parser! ProgramParser
    AST::CaseElse.new(body, else_t.start_pos, body.last&.end_pos || else_t.end_pos)
  end
end

class WhenParser < Parser
  PARSERS = [SimpleWhenParser, CaseElseParser]

  def self.can_parse?(_self)
    PARSERS.any? { |klass| klass.can_parse? _self }
  end

  def parse!
    consume_first_valid_parser! PARSERS
  end
end

class EmptyCaseExprParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :case &&
      _self.new_line?(1)
  end

  def parse!
    case_t = consume! :case
    cases = []
    loop do
      break if current_token&.type == :end
      cases.push consume_parser! WhenParser
    end
    end_t = consume! :end

    AST::EmptyCaseExpr.new(cases, case_t.start_pos, end_t.end_pos)
  end
end

class FunctionCallWithArgsWithoutParens < Parser
  def self.can_parse?(_self, lhs)
    _self.current_token&.is_not_one_of?(:assign, :comma, :"]", :for, :if, :close_paren, :"}") &&
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

    AST::FnCall.new(args, lhs_n, lhs_n.end_pos, args.last.end_pos)
  end
end

class DotParser < Parser
  def self.can_parse?(_self, lhs)
    _self.current_token&.type == :dot
  end

  def parse!(lhs_n)
    dot_t = consume! :dot
    rhs_n = consume_parser! IdentifierLookupParser
    AST::Dot.new(lhs_n, ".", rhs_n, dot_t.start_pos, rhs_n.end_pos)
  end
end

class BindParser < Parser
  def self.can_parse?(_self, lhs)
    _self.current_token&.type == :"::"
  end

  def parse_args_without_parens!
    args = []

    start_line = current_line
    loop do
      break if current_token.nil?
      break if current_line != start_line
      args.push consume_parser! ExprParser
      break if current_token.nil?
      break if current_line != start_line
      consume! :comma
    end

    args
  end

  def parse_args!
    return [] if new_line?
    return parse_args_without_parens! if current_token.type != :open_paren

    consume! :open_paren
    args = []
    loop do
      args.push consume_parser! ExprParser
      break if current_token.type == :close_paren
      consume! :comma
    end
    consume! :close_paren

    args
  end

  def parse!(lhs_n)
    bind_t = consume! :"::"
    fn_name_n = consume_parser! IdentifierLookupParser
    args = parse_args!
    AST::Bind.new(lhs_n, fn_name_n, args)
  end
end

class OptionalChainParser < Parser
  def self.can_parse?(_self, lhs)
    _self.current_token&.type == :"?."
  end

  def parse!(lhs)
    q_t = consume! :"?."
    property_t = consume! :identifier
    AST::OptionalChain.new(
      lhs,
      property_t.value,
      q_t.start_pos,
      property_t.end_pos
    )
  end
end

class ReturnParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :return
  end

  def parse!
    return_t = consume! :return
    expr_n = consume_parser! ExprParser
    AST::Return.new(expr_n, return_t.start_pos, expr_n.end_pos)
  end
end

class ShortAnonFnWithNamedArgParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :"#\{" &&
      _self.peek_token&.type == :"|"
  end

  def parse_args!
    args = []

    consume! :"|"
    loop do
      args.push consume!(:identifier).value
      break if current_token.type == :"|"
      consume! :comma
    end
    consume! :"|"

    args
  end

  def parse!
    open_anon_t = consume! :"#\{"
    args = parse_args!
    return_expr_n = consume_parser! ExprParser
    return_expr_n ||= AST::Empty.new
    end_t = consume! :"}"
    AST::ShortFnWithArgs.new(args, return_expr_n, open_anon_t.start_pos, end_t.end_pos)
  end
end

class ShortAnonFnParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :"#\{"
  end

  def parse!
    open_anon_t = consume! :"#\{"
    return_expr_n = consume_parser! ExprParser
    return_expr_n ||= AST::Empty.new
    end_t = consume! :"}"
    AST::ShortFn.new(return_expr_n, open_anon_t.start_pos, end_t.end_pos)
  end
end

class AnonIdLookupParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :%
  end

  def parse!
    id_t = consume! :%
    AST::AnonIdLookup.new(id_t.start_pos, id_t.end_pos)
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
    AST::SingleLineArrowFnWithoutArgs.new(
      return_expr_n,
      open_p_t.start_pos,
      return_expr_n.end_pos
    )
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
    end_t = consume! :"}"
    AST::MultiLineArrowFnWithArgs.new(args_n, body_n, args_n.start_pos, end_t.end_pos)
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
    AST::SingleLineArrowFnWithArgs.new(args_n, return_expr_n, args_n.start_pos, return_expr_n.end_pos)
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
    AST::SingleLineArrowFnWithOneArg.new(arg_t.value, return_expr_n, arg_t.start_pos, return_expr_n.end_pos)
  end
end

class SimpleForOfLoopParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :for &&
      _self.peek_token.type == :identifier &&
      _self.peek_token_twice.type == :of
  end

  def parse!
    for_t = consume! :for
    iter_var_t = consume! :identifier
    consume! :of
    arr_expr_n = consume_parser! ExprParser
    body = consume_parser! ProgramParser
    end_t = consume! :end
    AST::SimpleForOfLoop.new(iter_var_t.value, arr_expr_n, body, for_t.start_pos, end_t.end_pos)
  end
end

class AwaitParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :await
  end

  def parse!
    await_t = consume! :await
    expr_n = consume_parser! ExprParser
    AST::Await.new(expr_n, await_t.start_pos, expr_n.end_pos)
  end
end

class BoolParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :bool_lit
  end

  def parse!
    bool_t = consume! :bool_lit
    AST::Bool.new(bool_t.value, bool_t.start_pos, bool_t.end_pos)
  end
end

class SimpleElementParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :< &&
      _self.peek_token&.type == :identifier &&
      _self.peek_token_twice&.type == :>
  end

  def parse!
    open_t = consume! :<
    name_t = consume! :identifier
    consume! :>
    children = []
    loop do
      break if !ElementParser.can_parse?(self)
      children.push consume_parser! ElementParser
    end
    consume! :"</"
    consume! :identifier
    close_t = consume! :>
    AST::SimpleElement.new(
      name_t.value,
      children,
      open_t.start_pos,
      close_t.end_pos
    )
  end
end

class EscapedElementExprParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :"{"
  end

  def parse!
    open_t = consume! :"{"
    expr_n = consume_parser! ExprParser
    close_t = consume! :"}"
    AST::EscapedElementExpr.new(
      expr_n,
      open_t.start_pos,
      close_t.end_pos
    )
  end
end

class ElementParser < Parser
  PARSERS = [
    SimpleElementParser,
    EscapedElementExprParser,
  ]

  def self.can_parse?(_self)
    PARSERS.any? { |klass| klass.can_parse? _self }
  end

  def parse!
    consume_first_valid_parser! PARSERS
  end
end

class DotAssignmentParser < Parser
  def self.can_parse?(_self, lhs)
    lhs.is_a?(AST::Dot) &&
      _self.current_token&.type == :assign
  end

  def parse!(lhs_n)
    assign_t = consume! :assign
    expr_n = consume_parser! ExprParser
    AST::DotAssignment.new(
      lhs_n,
      expr_n,
      assign_t.start_pos,
      expr_n.end_pos
    )
  end
end

class ThisParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :this
  end

  def parse!
    this_t = consume! :this
    AST::This.new(this_t.value, this_t.start_pos, this_t.end_pos)
  end
end

class ConstructableParser < Parser
  PARSERS = [
    IdentifierLookupParser,
    ThisParser,
  ]

  def self.can_parse?(_self)
    PARSERS.any? { |klass| klass.can_parse? _self }
  end

  def parse!
    consume_first_valid_parser! PARSERS
  end
end

class NewParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :new
  end

  def parse!
    new_t = consume! :new
    class_expr_n = consume_parser! ConstructableParser
    open_p_t = consume! :open_paren
    args = []
    loop do
      args.push consume_parser! ExprParser
      consume_if_present! :comma
      break if current_token.type == :close_paren
    end
    close_p_t = consume! :close_paren
    AST::New.new(
      class_expr_n,
      args,
      new_t.start_pos,
      close_p_t.end_pos
    )
  end
end

class DynamicLookupParser < Parser
  def self.can_parse?(_self, lhs)
    # a[1] is valid, but a [1]
    _self.current_token&.type == :"[" &&
      _self.current_token.start_pos == _self.prev_token.end_pos
  end

  def parse!(lhs)
    open_t = consume! :"["
    expr_n = consume_parser! ExprParser
    close_t = consume! :"]"
    AST::DynamicLookup.new(
      lhs,
      expr_n,
      open_t.start_pos,
      close_t.end_pos
    )
  end
end

class SchemaCaptureParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :capture
  end

  def parse!
    id_t = consume! :capture
    AST::SchemaCapture.new(id_t.value, id_t.start_pos, id_t.end_pos)
  end
end

class RangeOperandParser < Parser
  PARSERS = [
    IdentifierLookupParser,
    IntParser,
    FloatParser,
    SimpleStringParser,
  ]

  def self.can_parse?(_self)
    PARSERS.any? { |klass| klass.can_parse _self }
  end

  def parse!
    consume_first_valid_parser! PARSERS
  end
end

class RangeParser < Parser
  def self.can_parse?(_self, lhs_n)
    _self.current_token&.type == :".."
  end

  def parse!(lhs_n)
    consume! :".."
    rhs_n = consume_parser! RangeOperandParser
    AST::Range.new(lhs_n, rhs_n, lhs_n.start_pos, rhs_n.end_pos)
  end
end

class NullParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :null
  end

  def parse!
    null_t = consume! :null
    AST::Null.new(null_t.start_pos, null_t.end_pos)
  end
end

class SpreadExprParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :"..."
  end

  def parse!
    spread_t = consume! :"..."
    expr_n = consume_parser! ExprParser

    AST::SpreadExpr.new(expr_n, spread_t.start_pos, expr_n.end_pos)
  end
end

class ExprParser < Parser
  # order matters
  PRIMARY_PARSERS = [
    NullParser,
    IntParser,
    FloatParser,
    ThisParser,
    BoolParser,
    SimpleStringParser,
    AnonIdLookupParser,
    NewParser,
    ArrayParser,
    ObjectParser,
    MultiLineArrowFnWithArgsParser,
    SingleLineArrowFnWithOneArgParser,
    IdentifierLookupParser,
    ShortAnonFnWithNamedArgParser,
    ShortAnonFnParser,
    SingleLineArrowFnWithoutArgsParser,
    SingleLineArrowFnWithArgsParser,
    AwaitParser,
    SpreadExprParser,
    ElementParser,
    SchemaCaptureParser,
    EmptyCaseExprParser,
  ]

  SECONDARY_PARSERS = [
    RangeParser,
    OperatorParser,
    DotAssignmentParser,
    DotParser,
    BindParser,
    OptionalChainParser,
    DynamicLookupParser,
    DefaultAssignmentParser,
    PlusAssignmentParser,
    FunctionCallWithoutArgs,
    FunctionCallWithArgs,
    FunctionCallWithArgsWithoutParens,
  ]

  def parse!
    expr_n = consume_first_valid_parser! PRIMARY_PARSERS do
      binding.pry
    end
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
    _self.current_token&.type == :for &&
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
    end_t = consume! :end
    AST::ForOfObjDeconstructLoop.new(properties, arr_expr_n, body, for_t.start_pos, end_t.end_pos)
  end
end

class SchemaObjectParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :"{"
  end

  VALUE_PARSERS = [
    IntParser,
    FloatParser,
    SimpleStringParser,
    ShortAnonFnParser,
    SchemaCaptureParser,
    BoolParser,
  ]

  def parse_value!(key_name, start_pos, end_pos)
    return AST::SchemaCapture.new(key_name, start_pos, end_pos) if current_token.type != :colon
    consume! :colon
    consume_first_valid_parser! VALUE_PARSERS
  end

  def parse!
    open_b_t = consume! :"{"
    properties = []
    loop do
      property_t = consume! :identifier
      properties.push [property_t.value, parse_value!(property_t.value, property_t.start_pos, property_t.end_pos)]
      break if current_token.type == :"}"
      consume! :comma
    end
    end_b_t = consume! :"}"
    AST::SchemaObjectLiteral.new(properties, open_b_t.start_pos, end_b_t.end_pos)
  end
end

class SchemaExprParser < Parser
  SCHEMA_PARSERS = [
    SchemaObjectParser,
    IntParser,
    SimpleStringParser,
    IdentifierLookupParser,
    BoolParser,
    ShortAnonFnParser,
    NullSchemaParser,
  ]

  def parse!
    consume_first_valid_parser! SCHEMA_PARSERS
  end
end

class SchemaUnionParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :"|"
  end

  def parse!(first_schema_expr_n)
    schema_exprs = [first_schema_expr_n]
    loop do
      break if !self.class.can_parse?(self)
      consume! :"|"
      schema_exprs.push consume_parser! SchemaExprParser
    end

    AST::SchemaUnion.new(schema_exprs, first_schema_expr_n.start_pos, schema_exprs[-1].end_pos)
  end
end

class SchemaIntersectParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :"&"
  end

  def parse!(first_schema_expr_n)
    schema_exprs = [first_schema_expr_n]

    loop do
      break if !self.class.can_parse?(self)
      consume! :"&"
      schema_exprs.push consume_parser! SchemaExprParser
    end

    AST::SchemaIntersect.new(schema_exprs, first_schema_expr_n.start_pos, schema_exprs[-1].end_pos)
  end
end

class SchemaDefinitionParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :schema
  end

  OP_PARSERS = [
    SchemaUnionParser,
    SchemaIntersectParser,
  ]

  def parse!
    schema_t = consume! :schema
    name_t = consume! :identifier
    consume! :"="
    expr_n = consume_parser! SchemaExprParser

    loop do
      op_parser_klass = OP_PARSERS.find do |parser_klass|
        parser_klass.can_parse?(self)
      end
      break if !op_parser_klass
      expr_n = consume_parser! op_parser_klass, expr_n
    end

    AST::SchemaDefinition.new(name_t.value, expr_n, schema_t.start_pos, expr_n.end_pos)
  end
end

class SimpleSchemaAssignmentParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :identifier &&
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
    AST::SimpleSchemaAssignment.new(
      schema_name_t.value,
      var_t.value,
      expr_n,
      schema_name_t.start_pos,
      expr_n.end_pos
    )
  end
end

class ThisSchemaArgParser < Parser
  def self.can_parse?(_self)
    _self.rest_of_line.include?("::")
  end

  def parse!
    schema = consume_parser! SchemaExprParser
    bind_t = consume! :"::"
    AST::ThisSchemaArg.new(schema, schema.start_pos, bind_t.end_pos)
  end
end

class CaseFunctionParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :case &&
      _self.peek_token.type == :function
  end

  def parse_case!
    when_t = consume! :when
    this_schema_arg = consume_parser! ThisSchemaArgParser if ThisSchemaArgParser.can_parse? self
    has_open_paren = !!consume!(:open_paren) if current_token.type == :open_paren
    arg_patterns = []
    loop do
      break if current_token.type == :close_paren
      arg_patterns.push consume_parser! SchemaArgParser
      break if current_token.type == :close_paren
      break if !has_open_paren
      consume! :comma
    end
    consume! :close_paren if has_open_paren
    body_n = consume_parser! FunctionBodyParser, end_tokens: [:when]
    AST::CaseFnPattern.new(this_schema_arg, arg_patterns, body_n, when_t.start_pos, body_n[-1].end_pos)
  end

  def parse!
    case_t = consume! :case
    consume! :function
    name_t = consume! :identifier
    patterns = []
    while current_token.type != :end
      patterns.push parse_case!
    end
    end_t = consume! :end
    AST::CaseFunctionDefinition.new(
      name_t.value,
      patterns,
      case_t.start_pos,
      end_t.end_pos
    )
  end
end

class SingleLineBindFunctionDefinitionParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :function &&
      _self.peek_token&.type == :identifier &&
      _self.peek_token_twice&.type == :"::" &&
      _self.rest_of_line.include?("=")
  end

  def parse!
    fn_t = consume! :function
    obj_name_t = consume! :identifier
    consume! :"::"
    fn_name_t = consume! :identifier
    args = consume_parser! SimpleFnArgsParser
    consume! :"="
    return_expr_n = consume_parser! ExprParser
    AST::SingleLineBindFunctionDefinition.new(
      obj_name_t.value,
      fn_name_t.value,
      args,
      return_expr_n,
      fn_t.start_pos,
      return_expr_n.end_pos
    )
  end
end

class MultiLineBindFunctionDefinitionParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :function &&
      _self.peek_token&.type == :identifier &&
      _self.peek_token_twice&.type == :"::" &&
      !_self.rest_of_line.include?("=")
  end

  def parse!
    fn_t = consume! :function
    obj_name_t = consume! :identifier
    consume! :"::"
    fn_name_t = consume! :identifier
    args = consume_parser! SimpleFnArgsParser
    body = consume_parser! FunctionBodyParser
    end_t = consume! :end
    AST::MultiLineBindFunctionDefinition.new(
      obj_name_t.value,
      fn_name_t.value,
      args,
      body,
      fn_t.start_pos,
      end_t.end_pos
    )
  end
end

class FunctionDefinitionParser < Parser
  PARSERS = [
    SingleLineDefWithArgsParser,
    SingleLineBindFunctionDefinitionParser,
    MultiLineBindFunctionDefinitionParser,
    SingleLineDefWithoutArgsParser,
    MultilineDefWithArgsParser,
    MultilineDefWithoutArgsParser,
    CaseFunctionParser,
  ]

  def self.can_parse?(_self)
    PARSERS.find { |klass| klass.can_parse? _self }
  end

  def parse!
    consume_first_valid_parser! PARSERS
  end
end

class BodyComponentWithoutAttrsParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :component
  end

  def parse!
    component_t = consume! :component
    name_t = consume! :identifier
    constructor_body = consume_parser! ComponentConstructorParser
    assert { constructor_body.all? { |node| node.is_a? AST::SimpleAssignment } }
    consume! :in
    expr_n = consume_parser! ExprParser
    end_t = consume! :end
    AST::BodyComponentWithoutAttrs.new(
      name_t.value,
      constructor_body,
      expr_n,
      component_t.start_pos,
      end_t.end_pos
    )
  end
end

class SimpleComponentWithAttrsParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :component &&
      _self.peek_token_twice.type == :"{" &&
      _self.rest_of_line.include?("in")
  end

  def parse!
    component_t = consume! :component
    name_t = consume! :identifier
    attributes = consume_parser! SchemaObjectParser
    consume! :in
    expr_n = consume_parser! ExprParser
    end_t = consume! :end
    AST::ExprComponentWithAttributes.new(
      name_t.value,
      attributes,
      expr_n,
      component_t.start_pos,
      end_t.end_pos
    )
  end
end

class SimpleComponentParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :component &&
      _self.peek_token_twice.type == :in
  end

  def parse!
    component_t = consume! :component
    name_t = consume! :identifier
    consume! :in
    expr_n = consume_parser! ExprParser
    end_t = consume! :end
    AST::ExprComponent.new(
      name_t.value,
      expr_n,
      component_t.start_pos,
      end_t.end_pos
    )
  end
end

class ConstructorWithoutArgsParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :function &&
      _self.peek_token&.value == "constructor"
  end

  def parse!
    function_t = consume! :function
    fn_name_t = consume! :identifier
    body = consume_parser! ConstructorBodyParser
    end_t = consume! :end
    AST::ConstructorWithoutArgs.new(
      fn_name_t.value,
      body,
      function_t.start_pos,
      end_t.end_pos
    )
  end
end

class ConstructorWithArgsParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :function &&
      _self.peek_token&.value == "constructor" &&
      _self.peek_token_twice.type == :open_paren
  end

  def parse!
    function_t = consume! :function
    fn_name_t = consume! :identifier
    args_n = consume_parser! SimpleFnArgsParser
    body = consume_parser! ConstructorBodyParser
    end_t = consume! :end
    AST::ConstructorWithArgs.new(
      fn_name_t.value,
      args_n,
      body,
      function_t.start_pos,
      end_t.end_pos
    )
  end
end

class StaticMethodWithArgsParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :static &&
      _self.peek_token.type == :function
  end

  def parse!
    static_t = consume! :static
    consume! :function
    name_t = consume! :identifier
    args_n = consume_parser! SimpleFnArgsParser
    body = consume_parser! FunctionBodyParser
    end_t = consume! :end
    AST::StaticMethod.new(
      name_t.value,
      args_n,
      body,
      static_t.start_pos,
      end_t.end_pos
    )
  end
end

class DefaultConstructorArgParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :"@" &&
      _self.peek_token&.type == :identifier &&
      _self.peek_token_twice&.type == :"="
  end

  def parse!
    at_t = consume! :"@"
    name_t = consume! :identifier
    consume! :"="
    expr_n = consume_parser! ExprParser

    AST::DefaultConstructorArg.new(name_t.value, expr_n, at_t.start_pos, expr_n.end_pos)
  end
end

class SimpleConstructorArgParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :"@" &&
      _self.peek_token&.type == :identifier
  end

  def parse!
    at_t = consume! :"@"
    name_t = consume! :identifier

    AST::SimpleConstructorArg.new(name_t.value, at_t.start_pos, name_t.end_pos)
  end
end

class ConstructorArgParser < Parser
  PARSERS = [
    DefaultConstructorArgParser,
    SimpleConstructorArgParser,
  ]

  def self.can_parse?(_self)
    PARSERS.any? { |klass| klass.can_parse? _self }
  end

  def parse!
    consume_first_valid_parser! PARSERS
  end
end

class ShortHandConstructorParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :function &&
      _self.peek_token.value == "constructor" &&
      _self.peek_token_thrice.type == :"@"
  end

  def parse!
    function_t = consume! :function
    consume! :identifier
    consume! :open_paren
    args = []
    loop do
      args.push consume_parser! ConstructorArgParser
      break if current_token.type == :close_paren
      consume! :comma
    end
    close_t = consume! :close_paren
    AST::ShortHandConstructor.new(
      args,
      function_t.start_pos,
      close_t.end_pos
    )
  end
end

class OneLineGetterParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :get &&
      _self.peek_token.type == :identifier &&
      _self.peek_token_twice.type == :"="
  end

  def parse!
    get_t = consume! :get
    name_t = consume! :identifier
    consume! :"="
    expr_n = consume_parser! ExprParser
    AST::OneLineGetter.new(
      name_t.value,
      expr_n,
      get_t.start_pos,
      expr_n.end_pos
    )
  end
end

class InstancePropertyParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :identifier &&
      _self.peek_token.type == :assign
  end

  def parse!
    id_t = consume! :identifier
    consume! :assign
    expr_n = consume_parser! ExprParser
    AST::InstanceProperty.new(
      id_t.value,
      expr_n,
      id_t.start_pos,
      expr_n.end_pos
    )
  end
end

class ClassParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :class
  end

  PARSERS = [
    InstancePropertyParser,
    ShortHandConstructorParser,
    ConstructorWithArgsParser,
    ConstructorWithoutArgsParser,
    StaticMethodWithArgsParser,
    OneLineGetterParser,
    FunctionDefinitionParser,
  ]

  def parse_parent_class!
    return nil if current_token.type != :<
    consume! :<
    parent_class_t = consume! :identifier
    return parent_class_t.value
  end

  def parse!
    class_t = consume! :class
    class_name_t = consume! :identifier
    parent_class = parse_parent_class!
    entries = []
    loop do
      break if !PARSERS.any? { |klass| klass.can_parse? self }
      entries.push consume_first_valid_parser! PARSERS
    end
    end_t = consume! :end
    AST::Class.new(
      class_name_t.value,
      parent_class,
      entries,
      class_t.start_pos,
      end_t.end_pos
    )
  end
end

class SimpleForInLoopParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :for &&
      _self.peek_token.type == :identifier &&
      _self.peek_token_twice.type == :in
  end

  def parse!
    for_t = consume! :for
    variable_t = consume! :identifier
    consume! :in
    object_n = consume_parser! ExprParser
    body = consume_parser! ProgramParser
    end_t = consume! :end
    AST::SimpleForInLoop.new(
      variable_t.value,
      object_n,
      body,
      for_t.start_pos,
      end_t.end_pos
    )
  end
end

class ArrayAssignmentParser < Parser
  def self.can_parse?(_self)
    _self.current_token.type == :"[" &&
      _self.rest_of_line.include?(":=")
  end

  def parse!
    open_t = consume! :"["
    variables = []
    loop do
      variables.push consume!(:identifier).value
      break if current_token.type == :"]"
      consume! :comma
    end
    close_t = consume! :"]"
    consume! :assign
    expr_n = consume_parser! ExprParser
    AST::ArrayAssignment.new(
      variables,
      expr_n,
      open_t.start_pos,
      expr_n.end_pos
    )
  end
end

class ElseIfParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :else &&
      _self.peek_token&.type == :if
  end

  def parse!
    else_t = consume! :else
    consume! :if
    cond_n = consume_parser! ExprParser
    body_n = consume_parser! ProgramParser, end_tokens: [:else]
    AST::ElseIf.new(cond_n, body_n, else_t.start_pos, body_n.last&.end_pos)
  end
end

class ElseParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :else
  end

  def parse!
    else_t = consume! :else
    body_n = consume_parser! ProgramParser
    AST::Else.new(body_n, else_t.start_pos, body_n.last&.end_pos)
  end
end

class ElseBranchParser < Parser
  PARSERS = [
    ElseIfParser,
    ElseParser,
  ]

  def self.can_parse?(_self)
    PARSERS.any? { |klass| klass.can_parse? _self }
  end

  def parse!
    consume_first_valid_parser! PARSERS
  end
end

class IfParser < Parser
  def self.can_parse?(_self)
    _self.current_token&.type == :if
  end

  def parse!
    if_t = consume! :if
    cond_n = consume_parser! ExprParser
    pass_n = consume_parser! ProgramParser, end_tokens: [:else]
    branches = []
    loop do
      break if !ElseBranchParser.can_parse?(self)
      branches.push consume_parser! ElseBranchParser
    end
    end_t = consume! :end
    AST::If.new(cond_n, pass_n, branches, if_t.start_pos, end_t.end_pos)
  end
end

class ProgramParser < Parser
  def initialize(*args)
    super(*args)
    @body = []
  end

  ALLOWED_PARSERS = [
    IfParser,
    FunctionDefinitionParser,
    SimpleAssignmentParser,
    SimpleReassignmentParser,
    ArrayAssignmentParser,
    ForOfObjDeconstructLoopParser,
    SimpleForInLoopParser,
    SimpleForOfLoopParser,
    SchemaDefinitionParser,
    SimpleSchemaAssignmentParser,
    SimpleComponentWithAttrsParser,
    SimpleComponentParser,
    BodyComponentWithoutAttrsParser,
    ClassParser,
    ReturnParser,
  ]

  def consume_parser!(parser_klass)
    expr_n = super parser_klass
    @body.push expr_n
  end

  def parse!(additional_parsers: [], end_tokens: [])
    while current_token&.is_not_one_of?(*end_tokens, :end, :"}")
      klass = (ALLOWED_PARSERS + additional_parsers).find { |klass| klass.can_parse?(self) }

      if !klass
        klass = ExprParser
      end

      expr_n = consume_parser! klass
      break if !expr_n
    end

    @body
  end
end

class ComponentConstructorParser < ProgramParser
  def parse!
    super end_tokens: [:in]
  end
end

class ConstructorBodyParser < ProgramParser
end

class FunctionBodyParser < ProgramParser
  def parse!(end_tokens: [])
    super additional_parsers: ALLOWED_PARSERS, end_tokens: end_tokens
    return [] if @body.size == 0

    last_n = @body[-1]
    if last_n.is_a? AST::SimpleAssignment
      @body.push AST::Return.new(
        AST::IdLookup.new(last_n.name, last_n.start_pos, last_n.end_pos),
        last_n.start_pos,
        last_n.end_pos
      )
    elsif last_n.is_a? AST::EmptyCaseExpr
      last_n.cases.each do |case_|
        next if case_.body.size == 0
        case_.body[-1] = AST::Return.new(case_.body[-1], case_.body[-1].start_pos, case_.body[-1].end_pos)
      end
    elsif last_n.is_not_one_of? AST::Return, AST::SimpleForOfLoop, AST::SimpleForInLoop, AST::ForOfObjDeconstructLoop
      @body[-1] = AST::Return.new(last_n, last_n.start_pos, last_n.end_pos)
    end

    @body
  end
end
