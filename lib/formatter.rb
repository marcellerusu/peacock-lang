require "ast"

METHOD_TO_OP = {
  "__and__" => "&&",
  "__or__" => "||",
  "__gt_eq__" => ">=",
  "__lt_eq__" => "<=",
  "__gt__" => ">",
  "__lt__" => "<",
  "__eq__" => "==",
  "__not_eq__" => "!=",
  "__plus__" => "+",
  "__minus__" => "-",
  "__mult__" => "*",
  "__div__" => "/",
  "and" => "&",
  "or" => "|",
}

class Formatter
  attr_reader :context

  def initialize(ast, context = Context.new)
    @ast = ast
    @context = context
  end

  def eval
    output = ""
    for node in @ast
      output += eval_node(node) + "\n"
    end
    output.strip!
    return output if context.directly_in_a? :short_fn
    output + "\n"
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
    when AST::OpCall
      eval_op_call node
    when AST::ShortFn
      eval_short_fn node
    when AST::Return
      eval_return node
    when AST::IdLookup
      eval_id_lookup node
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
    assert { context.directly_in_a? :record }
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
    context.push! :record
    node.value.map do |key, value|
      r += " #{eval_node key}: #{eval_node value} "
    end
    context.pop! :record
    r + "}"
  end

  def eval_id_lookup(node)
    return "%" if node.value == ANON_SHORTHAND_ID
    node.value
  end

  def eval_return(node)
    return eval_node node.value if context.directly_in_a?(:short_fn)
    "return #{eval_node node.value}"
  end

  def eval_short_fn(node)
    '#{ ' + Formatter.new(node.body, context.push(:short_fn)).eval + " }"
  end

  def eval_op_call(node)
    rhs = node.args.first
    lhs = node.expr.lhs_expr
    method = node.expr.property

    "#{eval_node lhs} #{METHOD_TO_OP[method]} #{eval_node rhs}"
  end
end
