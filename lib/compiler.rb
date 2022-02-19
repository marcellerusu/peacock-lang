require "utils"
require "pry"
require "parser"

class Compiler
  attr_reader :context
  # TODO: do something better for tests
  @@use_std_lib = true
  def self.use_std_lib=(other)
    @@use_std_lib = other
  end

  def initialize(ast, indent = 0, context = Context.new)
    @ast = ast
    @indent = indent
    @context = context
  end

  def eval
    program = ""
    program += std_lib if first_run?
    program += eval_assignment_declarations
    program += collapse_function_overloading
    @ast.each do |statement|
      program += " " * @indent
      program += eval_expr(statement)
      program += ";" << "\n"
    end
    program += start_program if first_run?
    program.rstrip
  end

  def start_program
    "__try(() => eval('Main')) && mount_element(Main, document.getElementById('main'))"
  end

  def eval_without_variable_declarations
    program = ""
    program += collapse_function_overloading
    @ast.each do |statement|
      program += " " * @indent
      program += eval_expr(statement)
      program += ";" << "\n"
    end
    program.rstrip
  end

  private

  def first_run?
    # TODO: I don't think this is correct
    @@use_std_lib && @indent == 0
  end

  def std_lib
    code = schema_lib
    code += css_preprocessor
    code += literals
    code += pspec
  end

  def pspec
    File.read(File.dirname(__FILE__) + "/pea_std_lib/pspec.js")
  end

  def literals
    File.read(File.dirname(__FILE__) + "/pea_std_lib/literals.js")
  end

  def schema_lib
    File.read(File.dirname(__FILE__) + "/pea_std_lib/schema.js")
  end

  def css_preprocessor
    File.read(File.dirname(__FILE__) + "/pea_std_lib/css_preprocessor.js")
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

  def collapse_function_overloading(ast = @ast, is_class = false)
    functions = ast
      .filter { |node| node.is_a? AST::Declare }
      .group_by { |node| node.name }

    function = ""
    functions.each do |sym, function_group|
      indent!
      function += "const #{sub_q(sym)} = (...params) => {" unless is_class
      function += "#{sub_q(sym)}(...params) {" if is_class
      function += "
  return Schema.case(List.new(params),
    List.new([
      #{function_group.map do |fn|
        "List.new([#{eval_expr(fn.schema)}, #{eval_function(fn.expr)}])"
      end.join ",\n"}
    ])
  );\n}\n"
      dedent!
      ast.filter! { |node| !node.is_a?(AST::Declare) || node.name != sym }
    end
    function
  end

  def eval_assignment_declarations
    nodes = find_assignments
    if nodes.any?
      vars = padding
      vars += "let "
      vars += nodes.map { |node| sub_q(node.name) }.join(", ")
      vars += ";" << "\n"
    end
    vars || ""
  end

  def find_assignments
    names = Parser::computed_files
    module_defs = @ast
      .filter { |node|
      node.is_a?(AST::Assign) &&
      node.expr.is_a?(AST::FnCall) &&
      node.expr.expr.is_a?(AST::Fn)
    }
      .flat_map { |node| node.expr.expr.body }
      .filter { |node| node.is_a?(AST::Assign) && names.include?(node.name) }
    @ast
      .flat_map { |node|
      if node.is_a?(AST::While)
        node.body
      elsif node.is_a?(AST::If)
        node.pass + node.fail
      else
        [node]
      end
    }
      .filter { |node| node.is_a?(AST::Assign) && !names.include?(node.name) }
      .uniq { |node| node.name } + module_defs
  end

  def eval_expr(node)
    case node
    when AST::Declare
      eval_declaration node
    when AST::Assign
      eval_assignment node
    when AST::PropertyLookup
      eval_property_lookup node
    when AST::List
      eval_list node
    when AST::Record
      eval_record node
    when AST::Bool
      eval_bool node
    when AST::Int
      eval_int node
    when AST::Float
      eval_float node
    when AST::Str
      eval_str node
    when AST::Nil
      eval_nil node
    when AST::Fn
      eval_function node
    when AST::Return
      eval_return node
    when AST::FnCall
      eval_function_call node
    when AST::IdLookup
      eval_identifier_lookup node
    when AST::InstanceLookup, AST::InstanceMethodLookup
      eval_instance_lookup node
    when AST::ParenExpr
      eval_paren_expr node
    when AST::If
      eval_if_expression node
    when AST::Sym
      eval_symbol node
    when AST::Throw
      eval_throw node
    when AST::Class
      eval_class_definition node
    when AST::HtmlTag
      eval_html_tag node
    when AST::HtmlText
      eval_html_text_node node
    when AST::Case
      eval_case_expression node
    when AST::NakedOr
      eval_naked_or node
    when AST::InstanceAssign
      eval_instance_assign node
    when AST::TryLookup
      eval_try_lookup node
    when AST::While
      eval_while node
    when AST::Next
      eval_next node
    else
      puts "no case matched node_type: #{node.class}"
      assert { false }
    end
  end

  def eval_if_expression(node)
    cond = eval_expr(node.value)
    pass_body = Compiler.new(node.pass, @indent + 2).eval_without_variable_declarations
    fail_body = Compiler.new(node.fail, @indent + 2).eval_without_variable_declarations

    "#{padding}if (#{cond}.to_b().to_js()) {\n" \
    "#{pass_body}\n" \
    "#{padding}} else {\n" \
    "#{fail_body}\n" \
    "#{padding}}"
  end

  def eval_while(node)
    assert { context.in_a? :return }
    cond = eval_expr(node.value)
    body = Compiler.new(node.body, @indent + 2, context.set_value(node)).eval_without_variable_declarations
    eval_expr(node.with_assignment) + "\n" \
    "#{padding}while (#{cond}.to_b().to_js()) {\n" \
    "#{body}\n" \
    "#{padding}}\n" \
    "#{padding}return #{node.with_assignment.name}"
  end

  def eval_next(node)
    assert { context.value.is_a? AST::While }
    name = context.value.with_assignment.name
    "#{name} = #{eval_expr(node.value)};\n" \
    "#{padding}continue"
  end

  def eval_throw(node)
    "throw #{eval_expr(node.expr)}"
  end

  def eval_paren_expr(node)
    "(#{eval_expr node.value})"
  end

  def eval_symbol(node)
    "Sym.new(\"#{node.value}\")"
  end

  def eval_str(node)
    "Str.new(`#{node.value}`)"
  end

  def eval_int(node)
    "Int.new(#{node.value})"
  end

  def eval_try_lookup(node)
    "__try(() => eval('#{node.value.name}'))"
  end

  def eval_naked_or(node)
    "(#{eval_expr node.lhs} || #{eval_expr node.rhs})"
  end

  def eval_html_tag(node)
    "DomNode.new(#{eval_expr(node.name)}, #{eval_expr(node.attributes)}, #{eval_expr(node.children)})"
  end

  def eval_html_text_node(node)
    "DomTextNode.new(#{eval_expr(node.value)})"
  end

  def eval_float(node)
    "Float.new(#{node.value})"
  end

  def eval_nil(node)
    "Nil.new()"
  end

  def eval_bool(node)
    "Bool.new(#{node.value})"
  end

  def eval_list(node)
    elements = node.value.map { |n| eval_expr n }.join(", ")
    "List.new([#{elements}])"
  end

  def eval_record(node)
    indent!
    record = "Record.new([\n"
    record += node.value.map do |key, value|
      "#{padding}[#{eval_expr(key)}, #{eval_expr(value)}]"
    end.join(",\n")
    dedent!
    record += "\n#{padding}], #{eval_list(node.splats)})"
  end

  def eval_property_lookup(node)
    lhs, key = eval_expr(node.lhs_expr), node.property
    if key =~ /[a-zA-Z\_][a-zA-Z1-9\_?]*/
      "#{lhs}.#{sub_q(key)}"
    else
      "#{lhs}[#{sub_q(key)}]"
    end
  end

  def sub_q(sym)
    sym
      .sub("?", "_q")
      .sub("!", "_b")
  end

  def eval_declaration(node)
    "const #{sub_q(node.name)} = #{eval_expr(node.expr)}"
  end

  def eval_instance_assign(node)
    "#{sub_q(eval_expr(node.lhs))} = #{eval_expr(node.expr)}"
  end

  def eval_assignment(node)
    "#{sub_q(node.name)} = #{eval_expr(node.expr)}"
  end

  def eval_function(node)
    body = Compiler.new(node.body, @indent + 2).eval
    args = node.args.join(", ")
    fn = "((#{args}) => {\n#{body}\n"
    fn += "return Nil.new();\n" unless node.body.last.is_a? AST::Return
    fn += "#{padding}})"
  end

  def eval_instance_lookup(node)
    "this.#{sub_q(node.name)}"
  end

  def eval_return(node)
    if node.value.is_a? AST::While
      context.push! :return
      val = eval_expr(node.value)
      context.pop! :return
      val
    else
      "return #{eval_expr node.value}"
    end
  end

  def eval_function_call(node)
    # binding.pry
    args = node.args.map { |arg| eval_expr arg }.join ", "
    fn = eval_expr node.expr
    "#{fn}(#{args})"
  end

  def eval_identifier_lookup(node)
    assert { node.value }
    sub_q(node.value)
  end

  def eval_class_definition(node)
    class_name, method_nodes = node.name, node.methods

    def method_body(node)
      body = Compiler.new(node.body, @indent + 2).eval
    end

    def constructor(node, class_name, method_nodes)
      con = "  constructor(...args) {"
      con += "super(...args);" if node.super_class
      con += method_nodes.map { |n|
        name = sub_q(n.name)
        "this.#{name} = this.#{name}.bind(this);"
      }.join("\n").strip()
      con += "this.init && this.init(...args);"
      con += "}"
      if !node.super_class
        con += "
  static [\"new\"](...args) {
    return new this(...args);
  }".strip
      end
      con
    end

    def extends(node)
      return "" if node.super_class.nil?
      "extends #{node.super_class}"
    end

    class_def = <<-EOF
class #{class_name} #{extends node} {
  #{constructor(node, class_name, method_nodes)}
  #{collapse_function_overloading(method_nodes, true)}
}
EOF
    class_def.strip()
  end

  def eval_case_expression(node)
    "Schema.case(#{eval_expr(node.expr)}, #{eval_expr(node.cases)})"
  end
end
