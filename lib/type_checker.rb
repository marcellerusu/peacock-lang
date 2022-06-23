require "ast"
require "utils"

class TypeChecker
  attr_reader :ast, :program_string, :pos

  def self.can_parse?(_self)
    not_implemented!
  end

  def self.from(_self)
    self.new(_self.ast, _self.program_string, _self.pos)
  end

  def consume_checker!(checker_klass, *check_args)
    checker = checker_klass.from(self)
    expr_n = checker.check! *check_args
    @pos = checker.pos
    expr_n
  end

  def initialize(ast, program_string, pos = 0)
    @ast = ast
    @program_string = program_string
    @pos = pos
    @errors = []
  end

  def check!
    for i in 0...@ast.size
      @ast[i] = consume_checker! StatementChecker, @ast[i]
    end
    assert_not_reached! if @has_errors
    @ast
  end

  def ignore!
    puts "ignoring type"
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
end

module Types
  class Type
    def self.to_s
      self.name.split("::")[1]
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

  class Array < Type
  end
end

class StatementChecker < TypeChecker
  def check!(node)
    case node
    when AST::SimpleSchemaAssignment
      check_simple_schema_assignment(node)
    when AST::Int
      Types::Number
    when AST::Float
      Types::Number
    when AST::SimpleString
      Types::String
    else
      assert_not_reached!
    end
  end

  GLOBAL_CONSTRUCTORS = {
    "String" => Types::String,
    "Number" => Types::Number,
    "Boolean" => Types::Boolean,
    "Object" => Types::Object,
    "Array" => Types::Array,
  }

  def check_simple_schema_assignment(node)
    type = GLOBAL_CONSTRUCTORS[node.schema_name]
    ignore! if !type
    rhs_type = check! node.expr
    if rhs_type != type
      print_error node, type, rhs_type
      return
    end

    return AST::SimpleAssignment.new(node.name, node.expr)
  end
end
