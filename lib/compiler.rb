require "utils"
require "pry"

class Compiler
  # TODO: do something better for tests
  @@use_std_lib = true
  def self.use_std_lib=(other)
    @@use_std_lib = other
  end
  def initialize(ast, indent = 0)
    @ast = ast
    @indent = indent
  end

  def eval
    program = ""
    program << std_lib if first_run?
    program << eval_assignment_declarations
    program << collapse_function_overloading
    @ast.each do |statement|
      program << " " * @indent
      program << eval_expr(statement)
      program << ";" << "\n"
    end
    program.rstrip
  end

  private

  def first_run?
    # TODO: I don't think this is correct
    @@use_std_lib && @indent == 0
  end

  def std_lib
    functions = find_used_peacock_functions
    code = "const __Symbols = {}\n"
    code << "const Peacock = {\n"
    indent!
    code << padding << "plus: (a, b) => a + b,\n" if functions.include? "Peacock.plus"
    code << padding << "minus: (a, b) => a - b,\n" if functions.include? "Peacock.minus"
    code << padding << "symbol: symName => __Symbols[symName] || (__Symbols[symName] = Symbol(symName)),\n"
    code << padding << "eq: (a, b) => a === b,\n"
    dedent!
    code << "};\n"
    code << "const print = (...params) => console.log(...params);\n"
  end

  def find_function_call_in(node)
    return if node.nil?
    return node if node[:node_type] == :function_call
    find_function_call_in(node[:expr])
  end

  def find_used_peacock_functions(scope = @ast)
    # TODO: examine non :identifier_lookup expressions too
    # TODO: will need to update when dot (.) expressions are implemented
    peacock_calls = scope
      .map { |node| find_function_call_in(node) }
      .filter { |node| !node.nil? }
      .map do |node|
      assert { node[:expr][:node_type] == :identifier_lookup }
      node[:expr][:sym]
    end
      .filter { |sym| sym.start_with? "Peacock." }

    # dig into functions
    scope.filter { |node| node[:node_type] == :declare }
      .map do |scope|
      assert { scope[:expr][:node_type] == :function }
      peacock_calls += find_used_peacock_functions(scope[:expr][:body])
    end
    peacock_calls.uniq
  end

  def indent!
    @indent += 2
  end

  def dedent!
    @indent -= 2
  end

  def padding(by = 0)
    assert { @indent + by >= 0 }
    " " * (@indent + by)
  end

  def from_kabob_case(sym)
    sym.sub("_", "__").sub("-", "_")
  end

  def to_kabob_case(sym)
    sym.sub("__", "_").sub("_", "-")
  end

  def collapse_function_overloading
    functions = @ast
      .filter { |node| node[:node_type] == :declare }
      .group_by { |node| node[:sym] }
      .filter { |group| group.length > 1 }

    # binding.pry
    function = ""
    functions.each do |sym, function_group|
      indent!
      function_name = from_kabob_case(sym)
      function << "const " << function_name << " = "
      function << "(...params)" << " => "
      function << "{" << "\n" << padding
      function << "const functions = ["
      function << function_group.map { |f| eval_function(f[:expr]) }.join(", ")
      function << "];" << "\n" << padding
      function << "const f_by_length = functions.find(f => f.length === params.length);\n" << padding
      function << "if (f_by_length) return f_by_length(...params);\n"
      # TODO: function by shape
      # function << "const f_by_shape = functions.find(([_, shape]) => shape_eq(shape_of(params), shape));\n" << padding
      # function << "assert("
      function << "};\n"
      dedent!
      @ast = @ast.filter { |node| node[:sym] != sym }
    end
    function
  end

  def eval_shape_of(function_node)
    # function_node[:args]
    "{}"
  end

  def eval_assignment_declarations
    nodes = find_assignments
    if nodes.any?
      vars = padding
      vars << "let "
      vars << nodes.map { |node| from_kabob_case(node[:sym]) }.join(", ")
      vars << ";" << "\n"
    end
    vars || ""
  end

  def find_assignments
    @ast.filter { |node| node[:node_type] == :assign }
      .uniq { |node| node[:sym] }
  end

  def eval_expr(node)
    case node[:node_type]
    when :declare
      eval_declaration node
    when :assign
      eval_assignment node
    when :array_lit
      eval_array node
    when :record_lit
      eval_record node
    when :bool_lit
      eval_bool node
    when :int_lit
      eval_int node
    when :float_lit
      eval_float node
    when :str_lit
      eval_str node
    when :function
      eval_function node
    when :return
      eval_return node
    when :function_call
      eval_function_call node
    when :identifier_lookup
      eval_identifier_lookup node
    when :if
      eval_if_expression node
    when :symbol
      eval_symbol node
    else
      puts "no case matched node_type: #{node[:node_type]}"
      assert { false }
    end
  end

  def eval_symbol(node)
    "Peacock.symbol('#{node[:value]}')"
  end

  def eval_str(node)
    "\"#{node[:value]}\""
  end

  def eval_int(node)
    "#{node[:value]}"
  end

  def eval_float(node)
    "#{node[:value]}"
  end

  def eval_bool(node)
    "#{node[:value]}"
  end

  def eval_array(node)
    arr = "["
    arr << node[:value].map { |n| eval_expr n }.join(", ")
    arr << "]"
  end

  def eval_record(node)
    indent!
    record = "{" << "\n"
    record << node[:value].map do |key, value|
      entry = padding
      entry << "\"" << key << "\""
      entry << ": "
      entry << eval_expr(value)
    end.join(",\n")
    dedent!
    record << "\n" << padding << "}"
  end

  def eval_declaration(node)
    declaration = "const "
    declaration << from_kabob_case(node[:sym])
    declaration << " = "
    declaration << eval_expr(node[:expr])
  end

  def eval_assignment(node)
    assignment = from_kabob_case(node[:sym])
    assignment << " = "
    assignment << eval_expr(node[:expr])
  end

  def eval_function(node)
    body = Compiler.new(node[:body], @indent + 2).eval
    function = "("
    function << node[:args].map { |arg| arg[:sym] }.join(", ")
    function << ")"
    function << " => "
    function << "{" << "\n"
    function << body << "\n"
    function << padding
    function << "}"
  end

  def eval_return(node)
    "return #{eval_expr node[:expr]}"
  end

  def eval_function_call(node)
    args = node[:args].map { |arg| eval_expr arg }.join ", "
    "#{eval_expr node[:expr]}(#{args})"
  end

  def eval_identifier_lookup(node)
    node[:sym]
  end
end
