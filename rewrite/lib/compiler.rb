require "utils"

class Compiler
  def initialize(ast, indent = 0)
    @ast = ast
    @symbols = {}
    @sym_number = 0
    @indent = indent
  end

  def eval
    program = ""
    for statement in @ast
      program += "#{" " * @indent}#{eval_expr statement}\n"
    end
    program.rstrip
  end

  private

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
    "[#{node[:value].map { |n| eval_expr n }.join ", "}]"
  end

  def eval_record(node)
    padding = " " * (@indent + 2)
    "{\n#{node[:value].map do |k, v|
      "#{padding}#{k}: #{eval_expr v}"
    end.join(",\n")}\n}"
  end

  def eval_declaration(node)
    declartion_type = if node[:mutable] then "let" else "const" end
    "#{declartion_type} #{node[:sym]} = #{eval_expr node[:expr]}"
  end

  def eval_assignment(node)
    "#{node[:sym]} = #{eval_expr node[:expr]}"
  end

  def eval_function(node)
    body = Compiler.new(node[:body], @indent + 2).eval
    "(#{node[:arg]}) => {\n#{body}\n#{" " * @indent}}"
  end

  def eval_return(node)
    "return #{eval_expr node[:expr]}"
  end

  def eval_function_call(node)
    "#{eval_expr node[:expr]}(#{eval_expr node[:arg]})"
  end

  def eval_identifier_lookup(node)
    node[:sym]
  end
end
