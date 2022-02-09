require "utils"
require "pry"
require "parser"

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
    code = "const __Symbols = {}\n"
    code += schema_lib
    code += css_preprocessor
    code += literals
    code += punit
    code += "const Peacock = {\n"
    indent!
    code += padding + "symbol: symName => __Symbols[symName] || (__Symbols[symName] = Symbol(symName)),\n"
    dedent!
    code += "};\n"
  end

  def punit
    File.read(File.dirname(__FILE__) + "/pea_std_lib/punit.js")
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
      .filter { |node| node[:node_type] == :declare }
      .group_by { |node| node[:sym] }

    function = ""
    functions.each do |sym, function_group|
      indent!
      function += "const #{sub_q(sym)} = (...params) => {" unless is_class
      function += "#{sub_q(sym)}(...params) {" if is_class
      function += "
  return Schema.case(List.new(params),
    List.new([
      #{function_group.map do |fn|
        "List.new([#{eval_expr(fn[:schema])}, #{eval_function(fn[:expr])}])"
      end.join ",\n"}
    ])
  );\n}\n"
      dedent!
      ast.filter! { |node| node[:sym] != sym }
    end
    function
  end

  def eval_assignment_declarations
    nodes = find_assignments
    if nodes.any?
      vars = padding
      vars += "let "
      vars += nodes.map { |node| sub_q(node[:sym]) }.join(", ")
      vars += ";" << "\n"
    end
    vars || ""
  end

  def find_assignments
    names = Parser::computed_files
    module_defs = @ast
      .filter { |node|
      node[:node_type] == :assign &&
      node[:expr][:node_type] == :function_call &&
      node[:expr][:expr][:node_type] == :function
    }
      .flat_map { |node| node[:expr][:expr][:body] }
      .filter { |node| node[:node_type] == :assign && names.include?(node[:sym]) }
    @ast
      .flat_map { |node|
      if node[:node_type] == :if
        node[:pass] + node[:fail]
      else
        [node]
      end
    }
      .filter { |node| node[:node_type] == :assign && !names.include?(node[:sym]) }
      .uniq { |node| node[:sym] } + module_defs
  end

  def eval_expr(node)
    case node[:node_type]
    when :declare
      eval_declaration node
    when :assign
      eval_assignment node
    when :property_lookup
      eval_property_lookup node
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
    when :nil_lit
      eval_nil node
    when :function
      eval_function node
    when :return
      eval_return node
    when :function_call
      eval_function_call node
    when :identifier_lookup
      eval_identifier_lookup node
    when :instance_lookup, :instance_method_lookup
      eval_instance_lookup node
    when :paren_expr
      eval_paren_expr node
    when :if
      eval_if_expression node
    when :symbol
      eval_symbol node
    when :throw
      eval_throw node
    when :class
      eval_class_definition node
    when :html_tag
      eval_html_tag node
    when :html_text_node
      eval_html_text_node node
    when :case
      eval_case_expression node
    when :naked_or
      eval_naked_or node
    else
      puts "no case matched node_type: #{node[:node_type]}"
      assert { false }
    end
  end

  def eval_if_expression(node)
    cond = eval_expr(node[:expr])
    pass_body = Compiler.new(node[:pass], @indent + 2).eval_without_variable_declarations
    fail_body = Compiler.new(node[:fail], @indent + 2).eval_without_variable_declarations

    "#{padding}if (#{cond}.to_b().to_js()) {\n" \
    "#{pass_body}\n" \
    "#{padding}} else {\n" \
    "#{fail_body}\n" \
    "#{padding}}"
  end

  def eval_throw(node)
    "throw #{eval_expr(node[:expr])}"
  end

  def eval_paren_expr(node)
    "(#{eval_expr node[:expr]})"
  end

  def eval_symbol(node)
    "Peacock.symbol(\"#{node[:value]}\")"
  end

  def eval_str(node)
    "`#{node[:value]}`"
  end

  def eval_int(node)
    "#{node[:value]}"
  end

  def eval_naked_or(node)
    "(#{eval_expr node[:lhs]} || #{eval_expr node[:rhs]})"
  end

  def eval_html_tag(node)
    "DomNode.new(#{eval_expr(node[:name])}, #{eval_expr(node[:attributes])}, #{eval_expr(node[:children])})"
  end

  def eval_html_text_node(node)
    "DomTextNode.new(#{eval_expr(node[:value])})"
  end

  def eval_float(node)
    "#{node[:value]}"
  end

  def eval_nil(node)
    "null"
  end

  def eval_bool(node)
    "#{node[:value]}"
  end

  def eval_array(node)
    elements = node[:value].map { |n| eval_expr n }.join(", ")
    "[#{elements}]"
  end

  def eval_record(node)
    indent!
    record = "[\n"
    record += node[:value].map do |key, value|
      "#{padding}[#{eval_expr(key)}, #{eval_expr(value)}]"
    end.join(",\n")
    dedent!
    record += "\n#{padding}]"
  end

  def eval_property_lookup(node)
    lhs, key = eval_expr(node[:lhs_expr]), eval_expr(node[:property])
    if key =~ /`[a-zA-Z\_][a-zA-Z1-9\_?]*`/
      "#{lhs}.#{sub_q(key[1...-1])}"
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
    "const #{sub_q(node[:sym])} = #{eval_expr(node[:expr])}"
  end

  def eval_assignment(node)
    "#{sub_q(node[:sym])} = #{eval_expr(node[:expr])}"
  end

  def eval_function(node)
    body = Compiler.new(node[:body], @indent + 2).eval
    args = node[:args].map { |arg| arg[:sym] }.join(", ")
    fn = "((#{args}) => {\n#{body}\n"
    fn += "return Nil.new();\n" unless node[:body].last[:node_type] == :return
    fn += "#{padding}})"
  end

  def eval_instance_lookup(node)
    "this.#{sub_q(node[:sym])}"
  end

  def eval_return(node)
    "return #{eval_expr node[:expr]}"
  end

  def eval_function_call(node)
    args = node[:args].map { |arg| eval_expr arg }.join ", "
    fn = eval_expr node[:expr]
    "#{fn}(#{args})"
  end

  def eval_identifier_lookup(node)
    assert { node[:sym] }
    sub_q(node[:sym])
  end

  def eval_class_definition(node)
    class_name, args, methods = node[:sym], node[:args].map { |arg| arg[:sym] }, node[:methods]

    def method_args(node)
      node[:args].map { |arg| arg[:sym] }.join(", ")
    end

    def method_body(node)
      body = Compiler.new(node[:body], @indent + 2).eval
    end

    def constructor(node, args, class_name)
      if !node[:super_class].nil?
        ""
      else
        "
  constructor(#{args.join(", ")}) {
    #{args.map { |arg|
          "this.#{arg} = #{arg};"
        }.join("\n").strip()}
  }
  static [\"new\"](#{args.join(", ")}) {
    return new this(#{args.join(", ")});
  }".strip
      end
    end

    def extends(node)
      return "" if node[:super_class].nil?
      "extends #{node[:super_class]}"
    end

    # binding.pry
    class_def = <<-EOF
class #{class_name} #{extends node} {
  #{constructor node, args, class_name}
  #{collapse_function_overloading methods, true}
}
EOF
    class_def.strip()
  end

  def eval_case_expression(node)
    "Schema.case(#{eval_expr(node[:expr])}, #{eval_expr(node[:cases])})"
  end
end
