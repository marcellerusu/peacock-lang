require "utils"

class Compiler
  def initialize(ast, indent = 0)
    @ast = ast
    @symbols = {}
    @sym_number = 0
    @indent = indent
  end

  def eval
    program = eval_assignment_declarations
    @ast.each do |statement|
      program << " " * @indent
      program << eval_expr(statement)
      program << ";\n"
    end
    program.rstrip
  end

  private

  def padding(by = 0)
    " " * (@indent + by)
  end

  def eval_assignment_declarations
    nodes = find_assignments
    if nodes.any?
      vars = padding
      vars << "let "
      vars << nodes.map { |node| node[:sym] }.join(", ")
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
    else
      puts "no case matched node_type: #{node[:node_type]}"
      assert { false }
    end
  end

  def eval_symbol(node)
    # :value -> 0
    if @symbols[node[:value]]
      "#{@symbols[node[:value]]}"
    else
      @sym_number += 1
      @symbols[node[:value]] = @sym_number
      "#{@symbols[node[:value]]}"
    end
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
    @indent += 2

    record = "{" << "\n"
    record << node[:value].map do |key, value|
      entry = padding
      entry << "\"" << key << "\""
      entry << ": "
      entry << eval_expr(value)
    end.join(",\n")
    record << "\n" << padding(-2) << "}"

    @indent -= 2

    record
  end

  def eval_declaration(node)
    "const #{node[:sym]} = #{eval_expr node[:expr]}"
  end

  def eval_assignment(node)
    "#{node[:sym]} = #{eval_expr node[:expr]}"
  end

  def eval_function(node)
    body = Compiler.new(node[:body], @indent + 2).eval
    args = node[:args].map { |arg| arg[:sym] }.join ", "
    "(#{args}) => {\n#{body}\n#{" " * @indent}}"
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
