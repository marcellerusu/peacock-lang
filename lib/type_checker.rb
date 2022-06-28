require "ast"
require "utils"

module Types
  class Type
    def to_s
      self.class.name.split("::")[1]
    end
  end

  class Number < Type
  end

  class String < Type
  end

  class Boolean < Type
  end

  class Object < Type
  end

  class Any < Type
  end

  class Array < Type
    attr_reader :type

    def initialize(type = Any)
      @type = type
    end
  end

  class Undefined < Type
  end

  class Function < Type
    attr_reader :args_type, :return_type

    def initialize(args_type, return_type)
      @args_type = args_type
      @return_type = return_type
    end
  end

  class Tuple < Type
    attr_reader :types

    def initialize(types)
      @types = types
    end
  end
end

class TypeChecker
  attr_reader :ast, :program_string, :pos, :stack

  def self.can_parse?(_self)
    not_implemented!
  end

  def self.from(_self)
    self.new(_self.ast, _self.program_string, _self.pos, _self.stack)
  end

  def consume_steper!(checker_klass, *step_args)
    checker = checker_klass.from(self)
    expr_n = checker.step! *step_args
    @pos = checker.pos
    expr_n
  end

  def initialize(ast, program_string, pos = 0, stack = {})
    @ast = ast
    @program_string = program_string
    @pos = pos
    @stack = stack
    @errors = []
  end

  def step!
    for i in 0...@ast.size
      @ast[i] = consume_steper! StatementChecker, @ast[i]
    end
    assert_not_reached! if @has_errors
    @ast
  end

  def ignore!
    assert_not_reached!
  end

  def pos_to_line_and_col(pos)
    line, col, i = 1, 0, 0
    @program_string.each_char do |char|
      break if i == pos
      if char == "\n"
        col = 0
        line += 1
      else
        col += 1
      end
      i += 1
    end

    return line, col
  end

  def print_error(node, expected, got)
    previous_line = (@program_string[0..node.pos].rindex("\n") || -1) + 1
    previous_line = (@program_string[0..previous_line].rindex("\n") || -1) + 1
    next_line = (@program_string[node.pos..].index("\n") || @program_string.size) + 1
    line, col = pos_to_line_and_col node.pos
    puts "Type mismatch! [line:#{line},col:#{col}]"
    puts "> #{@program_string[previous_line..next_line]}"
    puts "  ^ Expected #{expected}, got #{got}"
    @has_errors = true
  end

  def print_failed_id_lookup(node)
    previous_line = (@program_string[0..node.pos].rindex("\n") || -1) + 1
    previous_line = (@program_string[0..previous_line].rindex("\n") || -1) + 1
    next_line = (@program_string[node.pos..].index("\n") || @program_string.size) + 1
    line, col = pos_to_line_and_col node.pos
    puts "Variable `#{node.value}` not found! [line:#{line},col:#{col}]"
    puts "> #{@program_string[previous_line..next_line]}"
    @has_errors = true
  end

  def type_of(node)
    case node
    when AST::Int
      Types::Number.new
    when AST::Float
      Types::Number.new
    when AST::SimpleString
      Types::String.new
    when AST::IdLookup
      if !@stack[node.value]
        print_failed_id_lookup node
        assert_not_reached!
      end
      @stack[node.value]
    else
      assert_not_reached!
    end
  end

  GLOBAL_CONSTRUCTORS = {
    "String" => Types::String.new,
    "Number" => Types::Number.new,
    "Boolean" => Types::Boolean.new,
    "Object" => Types::Object.new,
    "Array" => Types::Array.new,
  }

  CONSOLE_TYPES = {
    "log" => Types::Function.new(
      Types::Any.new,
      Types::Undefined.new
    ),
  }
end

class StatementChecker < TypeChecker
  def step!(node)
    case node
    when AST::SimpleSchemaAssignment
      step_simple_schema_assignment node
    when AST::FnCall
      step_function_call node
    when AST::SimpleAssignment
      step_simple_assignment node
    else
      assert_not_reached!
    end
  end

  def fn_type_from_native_object(dot_node)
    assert { dot_node.lhs.value.is_a? String }
    case dot_node.lhs.value
    when "console"
      CONSOLE_TYPES[dot_node.rhs.value]
    end
  end

  def function_type(node)
    case node
    when AST::Dot
      fn_type_from_native_object(node)
    end
  end

  def args_type(args)
    arg_types = []
    for arg in args
      arg_types.push type_of arg
    end
    Types::Tuple.new arg_types
  end

  def step_function_call(node)
    fn_type = function_type node.expr
    call_args_type = args_type node.args

    if !types_match?(fn_type.args_type, call_args_type)
      print_error node, fn_type.args_type, call_args_type
      assert_not_reached!
    end

    node
  end

  def types_match?(into, from)
    case into
    when Types::Any
      true
    when Types::Number
      from.is_a? Types::Number
    when Types::String
      from.is_a? Types::String
    else
      assert_not_reached!
    end
  end

  def step_simple_assignment(node)
    rhs_type = type_of node.expr

    assert { rhs_type }

    @stack[node.name] = rhs_type

    node
  end

  def step_simple_schema_assignment(node)
    schema_type = GLOBAL_CONSTRUCTORS[node.schema_name]
    ignore! if !schema_type
    rhs_type = type_of node.expr
    if !types_match?(rhs_type, schema_type)
      print_error node, schema_type, rhs_type
      assert_not_reached!
    end

    @stack[node.name] = rhs_type

    AST::SimpleAssignment.new(node.name, node.expr)
  end
end
