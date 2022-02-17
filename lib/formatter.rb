require "ast"

class Formatter
  def initialize(ast)
    @ast = ast
    @context = nil
  end

  def eval
    output = ""
    for node in @ast
      output += eval_node node
    end
    output.strip + "\n"
  end

  def eval_node(node)
    case node
    when AST::Assign
      eval_assign node
    when AST::Int
      eval_int node
    when AST::List
      eval_list node
    when AST::Record
      eval_record node
    when AST::Sym
      eval_sym node
    else
      pp node.class
      assert_not_reached
    end
  end

  def eval_assign(node)
    return "" if node.name == "pea_module"
    "#{node.name} := #{eval_node node.expr}"
  end

  def eval_sym(node)
    assert { @context == :record }
    "#{node.value}"
  end

  def eval_int(node)
    node.value
  end

  def eval_list(node)
    "[#{node.value.map { |n| eval_node n }.join ", "}]"
  end

  def eval_record(node)
    r = "{"
    @context = :record
    node.value.map do |key, value|
      r += " #{eval_node key}: #{eval_node value} "
    end
    @context = nil
    r + "}"
  end
end
