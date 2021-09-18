class Compiler
  def initialize(ast)
    @ast = ast
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

  def eval_record(node, indent = 0)
    padding = " " * (indent + 2)
    "{\n#{node[:value].map { |k, v| "#{padding}#{k}: #{eval_expr v}" }.join(",\n")}\n}"
  end

  def eval_declaration(node)
    declartion_type = if node[:mutable] then "let" else "const" end
    "#{declartion_type} #{node[:sym]} = #{eval_expr node[:expr]}"
  end

  def eval_expr(node, indent = 0)
    program = case node[:type]
      when :declare
        eval_declaration node
      when :array_lit
        eval_array node
      when :record_lit
        eval_record node, indent
      when :bool_lit
        eval_bool node
      when :int_lit
        eval_int node
      when :float_lit
        eval_float node
      when :str_lit
        eval_str node
      end
    return (" " * indent) + program
  end

  def eval
    program = ""
    for statement in @ast
      program += "#{eval_expr statement}\n"
    end
    program
  end
end
