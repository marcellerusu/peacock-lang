require "ast"
require "utils"

class Object
  def do
    yield self
  end
end

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

    def to_s
      "Array<#{type}>"
    end

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

    def to_s
      "Tuple<#{types.map(&:to_s).join ", "}>"
    end

    def initialize(types)
      @types = types
    end
  end

  class Union < Type
    attr_reader :types

    def initialize(types)
      @types = types
    end
  end
end

class TypeChecker
  attr_reader :ast, :program_string, :pos, :stack

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

  def get_line_positions_to_print(node)
    previous_line = (@program_string[0..node.pos].rindex("\n") || -1) + 1
    previous_line = (@program_string[0...previous_line - 1].rindex("\n")) + 1

    next_line = @program_string[node.pos..].do { |s|
      i = s.index("\n")
      if i
        i + node.pos
      else
        @program_string.size
      end
    }

    return previous_line, next_line
  end

  def print_error(node, expected, got)
    previous_line, next_line = get_line_positions_to_print node
    line, col = pos_to_line_and_col node.pos
    puts "Type mismatch! [line:#{line}, col:#{col}]"
    lines = @program_string[previous_line..next_line].split("\n")
    puts "..."
    lines.each_with_index do |_line, index|
      puts "#{line - (lines.size - index) + 1} | #{_line}"
    end
    puts "    #{" " * col}^ Expected #{expected}, got #{got}"

    abort
  end

  def print_failed_id_lookup(node)
    previous_line, next_line = get_line_positions_to_print node
    line, col = pos_to_line_and_col node.pos

    lines = @program_string[previous_line..next_line].split("\n")
    puts "..."
    lines.each_with_index do |_line, index|
      break if index == lines.size - 1
      puts "#{line - (lines.size - index) + 1} | #{_line}"
    end
    puts "#{line} | #{lines.last}"
    puts "    #{" " * col}^"
    puts "Identifier \"#{node.value}\" not found! [line:#{line}, col:#{col}]"

    abort
  end

  def check_type_of_op(node, local_stack)
    lhs_type = type_of node.lhs, local_stack
    rhs_type = type_of node.rhs, local_stack
    op_fn_type = OPERATOR_TYPES[node.type.to_s]

    if !types_match?(op_fn_type.args_type, Types::Tuple.new([lhs_type, rhs_type]))
      print_error node, op_fn_type.args_type, Types::Tuple.new([lhs_type, rhs_type])
    end

    op_fn_type.return_type
  end

  def type_of(node, temp_stack = {})
    local_stack = { **@stack, **temp_stack }

    case node
    when AST::Int
      Types::Number.new
    when AST::Float
      Types::Number.new
    when AST::SimpleString
      Types::String.new
    when AST::Op
      check_type_of_op(node, local_stack)
    when AST::IdLookup
      if !local_stack[node.value]
        print_failed_id_lookup node
      end
      local_stack[node.value]
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

  MATH_OPERATOR_TYPE = Types::Function.new(
    Types::Tuple.new([
      Types::Number.new,
      Types::Number.new,
    ]),
    Types::Number.new
  )

  OPERATOR_TYPES = {
    "+" => MATH_OPERATOR_TYPE,
    "*" => MATH_OPERATOR_TYPE,
    "-" => MATH_OPERATOR_TYPE,
    "/" => MATH_OPERATOR_TYPE,
    "**" => MATH_OPERATOR_TYPE,
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
    when AST::SingleLineDefWithArgs
      step_single_line_def_with_args node
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
    when AST::IdLookup
      @stack[node.value]
    else
      assert_not_reached!
    end
  end

  def args_type(args)
    arg_types = []
    for arg in args
      arg_types.push type_of arg
    end
    Types::Tuple.new arg_types
  end

  def type_of_def_args(node_args)
    case node_args
    when AST::SimpleFnArgs
      Types::Tuple.new node_args.value.map { Types::Any.new }
    else
      assert_not_reached!
    end
  end

  def infer_type_of(id, expr)
    case expr
    when AST::Op
      type = OPERATOR_TYPES[expr.type.to_s]
      if expr.lhs.value == id
        type.args_type.types[0]
      elsif expr.rhs.value == id
        type.args_type.types[1]
      else
        assert_not_reached!
      end
    end
  end

  def step_single_line_def_with_args(node)
    args_type = Types::Tuple.new(
      node.args.value.map { |id|
        infer_type_of id.name, node.return_value
      }
    )

    local_stack = node.args.value.map(&:name)
      .zip(args_type.types)
      .map { |name, type| [name, type] }.to_h
    return_type = type_of node.return_value, local_stack

    @stack[node.name] = Types::Function.new(
      args_type,
      return_type
    )
    node
  end

  def step_function_call(node)
    fn_type = function_type node.expr
    call_args_type = args_type node.args

    if !types_match?(fn_type.args_type, call_args_type)
      print_error node, fn_type.args_type, call_args_type
    end

    node
  end

  def types_match?(into, from)
    return true if into.is_a?(Types::Any) || from.is_a?(Types::Any)

    case into
    when Types::Number
      from.is_a? Types::Number
    when Types::String
      from.is_a? Types::String
    when Types::Tuple
      return false if !from.is_a?(Types::Tuple)
      return false if from.types.size != into.types.size
      into.types
        .zip(from.types)
        .all? { |type_a, type_b| types_match? type_a, type_b }
    else
      binding.pry
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
    end

    @stack[node.name] = rhs_type

    AST::SimpleAssignment.new(node.name, node.expr)
  end
end
