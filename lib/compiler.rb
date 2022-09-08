require "utils"
require "pry"
require "parser"

class Compiler
  def initialize(ast, indent = 0, fn_arg_names: [], bundle_std_lib: false, is_class_definition: false)
    @ast = ast
    @indent = indent
    @fn_arg_names = fn_arg_names
    @bundle_std_lib = bundle_std_lib
    @is_class_definition = is_class_definition
  end

  def eval
    program = ""
    program += std_lib if @bundle_std_lib
    program += eval_assignment_declarations
    # program += collapse_function_overloading
    @ast.each do |statement|
      program += " " * @indent
      program += eval_expr(statement)
      program += ";" << "\n"
    end
    program.rstrip
  end

  def eval_without_variable_declarations
    program = ""
    # program += collapse_function_overloading
    @ast.each do |statement|
      program += " " * @indent
      program += eval_expr(statement)
      program += ";" << "\n"
    end
    program.rstrip
  end

  private

  def std_lib
    if ARGV[1] == "-s"
      ""
    else
      [symbols, schema_lib, range, pea_std, pea_array].join("\n") + "\n"
    end
  end

  def pea_std
    file_str = File.read(File.dirname(__FILE__) + "/pea_std_lib/std.pea")
    tokens = Lexer.tokenize file_str
    ast = Parser.new(tokens, file_str).parse!
    Compiler.new(ast).eval
  end

  def pea_array
    file_str = File.read(File.dirname(__FILE__) + "/pea_std_lib/array.pea")
    tokens = Lexer.tokenize file_str
    ast = Parser.new(tokens, file_str).parse!
    Compiler.new(ast).eval
  end

  def range
    File.read(File.dirname(__FILE__) + "/pea_std_lib/range.js")
  end

  def schema_lib
    File.read(File.dirname(__FILE__) + "/pea_std_lib/schema.js")
  end

  def symbols
    File.read(File.dirname(__FILE__) + "/pea_std_lib/symbols.js")
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

  def eval_assignment_declarations
    names = find_assignments
    if names.any?
      vars = padding
      vars += "let "
      vars += names.map { |names| sub_q(names) }.join(", ")
      vars += ";" << "\n"
    end
    vars || ""
  end

  def find_assignments
    nodes = @ast.flat_map do |node|
      if node.is_a?(AST::If)
        node.pass + node.branches.flatten
      else
        [node]
      end
    end

    (nodes
      .filter { |node| node.is_a?(AST::Assign) }
      .uniq { |node| node.name }
      .select { |node| !@fn_arg_names.include?(node.name) }
      .map(&:name) +
     nodes
       .select(&:declare?)
       .flat_map { |node| node.captures }
       .uniq).uniq
  end

  def eval_expr(node)
    case node
    when AST::Class
      eval_class node
    when AST::SimpleAssignment, AST::SimpleReassignment
      eval_assignment node
    when AST::SimpleSchemaAssignment
      eval_simple_schema_assignment node
    when AST::SchemaUnion
      eval_schema_union node
    when AST::SchemaIntersect
      eval_schema_intersect node
    when AST::Assign
      eval_assignment node
    when AST::ArrayLiteral
      eval_array_literal node
    when AST::ObjectLiteral
      eval_object_literal node
    when AST::SimpleObjectEntry,
         AST::ArrowMethodObjectEntry
      eval_object_entry node
    when AST::FunctionObjectEntry
      eval_function_object_entry node
    when AST::SpreadObjectEntry
      eval_spread_object_entry node
    when AST::Bool
      eval_bool node
    when AST::Int
      eval_int node
    when AST::Float
      eval_float node
    when AST::SimpleString
      eval_simple_string node
    when AST::SingleLineDefWithArgs
      eval_single_line_fn_with_args node
    when AST::SingleLineDefWithoutArgs
      eval_single_line_fn_without_args node
    when AST::SingleLineArrowFnWithoutArgs
      eval_arrow_fn_without_args node
    when AST::SingleLineArrowFnWithArgs
      eval_single_line_arrow_fn_with_args node
    when AST::MultiLineArrowFnWithArgs
      eval_arrow_fn_with_args node
    when AST::SingleLineArrowFnWithOneArg
      eval_arrow_fn_with_one_arg node
    when AST::StaticMethod
      eval_static_method node
    when AST::MultilineDefWithoutArgs
      eval_multiline_def_without_args node
    when AST::MultilineDefWithArgs
      eval_multiline_def_with_args node
    when AST::ShortFnWithArgs
      eval_short_fn_with_args node
    when AST::ShortFn
      eval_short_fn node
    when AST::AnonIdLookup
      eval_anon_id_lookup
    when AST::Empty
      ""
    when AST::Return
      eval_return node
    when AST::FnCall
      eval_function_call node
    when AST::IdLookup
      eval_identifier_lookup node
    when AST::If
      eval_if_expression node
    when AST::Else
      eval_else node
    when AST::ElseIf
      eval_else_if node
    when AST::SchemaCapture
      eval_schema_capture node
    when AST::DotAssignment
      eval_dot_assignment node
    when AST::Dot
      eval_dot node
    when AST::Range
      eval_range node
    when AST::Op
      eval_operator node
    when AST::SimpleForOfLoop
      eval_simple_for_of_loop node
    when AST::ForOfObjDeconstructLoop
      eval_for_of_obj_descontruct_loop node
    when AST::SchemaDefinition
      eval_schema_definition node
    when AST::SchemaObjectLiteral
      eval_schema_object_literal node
    when AST::Await
      eval_await node
    when AST::ExprComponent
      eval_expr_component node
    when AST::ExprComponentWithAttributes
      eval_expr_component_with_attrs node
    when AST::BodyComponentWithoutAttrs
      eval_body_component_without_attrs node
    when AST::EscapedElementExpr
      eval_escaped_element_expr node
    when AST::This
      "this"
    when AST::New
      eval_new node
    when AST::ShortHandConstructor
      eval_short_hand_constructor node
    when AST::DynamicLookup
      eval_dynamic_lookup node
    when AST::OneLineGetter
      eval_one_line_getter node
    when AST::InstanceProperty
      eval_instance_property node
    when AST::CaseFunctionDefinition
      eval_case_function_definition node
    when AST::ThisSchemaArg
      eval_this_schema_arg node
    when AST::Bind
      eval_bind node
    when AST::OptionalChain
      eval_optional_chain node
    when AST::ArrayAssignment
      eval_array_assignment node
    when AST::SimpleForInLoop
      eval_simple_for_in_loop node
    when AST::NullSchema
      "null"
    when AST::Null
      eval_null node
    when AST::SpreadExpr
      eval_spread_expr node
    when AST::SingleLineBindFunctionDefinition
      eval_single_line_bind_function_definition node
    when AST::MultiLineBindFunctionDefinition
      eval_multi_line_bind_function_definition node
    when AST::ArrayComprehension
      eval_array_comprehension node
    when AST::DefaultAssignment
      eval_default_assignment node
    when AST::PlusAssignment
      eval_plus_assignment node
    when AST::DefaultConstructorArg
      eval_default_constructor_arg node
    when AST::SimpleConstructorArg
      eval_simple_constructor_arg node
    when AST::EmptyCaseExpr
      eval_empty_case_expr node
    when AST::SimpleWhen
      eval_simple_when node
    when AST::CaseElse
      eval_case_else node
    else
      binding.pry
      puts "no case matched node_type: #{node.class}"
      assert_not_reached!
    end
  end

  def eval_case_else(node)
    # else is put in by `eval_empty_case_expr`
    c = " {\n"
    c += Compiler.new(node.body, @indent + 2).eval + "\n"
    c += "#{padding}}"
  end

  def eval_simple_when(node)
    c = "if (#{eval_expr node.expr}) {\n"
    c += Compiler.new(node.body, @indent + 2).eval + "\n"
    c += "#{padding}}"
  end

  def eval_empty_case_expr(node)
    return "" if node.cases.size == 0
    c = "#{eval_expr node.cases.first}"
    for case_ in node.cases[1..]
      c += " else #{eval_expr case_}"
    end
    c
  end

  def eval_default_constructor_arg(node)
    "#{node.name} = #{eval_expr node.expr}"
  end

  def eval_simple_constructor_arg(node)
    node.name
  end

  def eval_plus_assignment(node)
    "#{eval_expr node.lhs} += #{eval_expr node.expr}"
  end

  def eval_default_assignment(node)
    "#{eval_expr node.lhs} ||= #{eval_expr node.expr}"
  end

  def eval_multi_line_bind_function_definition(node)
    args = node.args.value.map(&:name).join ", "
    fn = "#{fn_prefix}#{node.function_name}(#{args}) {\n"
    indent!
    fn += "#{padding}if (!(this instanceof #{node.object_name})) throw new MatchError('Expected `this` to be a `#{node.object_name}`');\n"
    fn += Compiler.new(node.body, @indent).eval + "\n"
    dedent!
    fn += "#{padding}}"
  end

  def eval_array_comprehension(node)
    arr = eval_expr node.array_expr
    if node.if_expr
      arr += ".filter(#{node.variable} => #{eval_expr node.if_expr})"
    end
    "Array.from(#{arr}, #{node.variable} => #{eval_expr node.expr})"
  end

  def eval_single_line_bind_function_definition(node)
    args = node.args.value.map(&:name).join ", "
    fn = "#{fn_prefix}#{node.function_name}(#{args}) {\n"
    indent!
    fn += "#{padding}if (!(this instanceof #{node.object_name})) throw new MatchError('Expected `this` to be a `#{node.object_name}`');\n"
    fn += "#{padding}return #{eval_expr node.return_expr};\n"
    dedent!
    fn += "#{padding}}"
  end

  def eval_spread_expr(node)
    "...#{eval_expr node.value}"
  end

  def eval_null(node)
    "null"
  end

  def eval_this_schema_arg(node)
    eval_expr node.schema
  end

  def eval_simple_for_in_loop(node)
    f = "for (let #{node.variable} in #{eval_expr node.object_expr}) {\n"
    f += Compiler.new(node.body, @indent + 2).eval + "\n"
    f += "}"
  end

  def eval_array_assignment(node)
    "[#{node.variables.join ", "}] = #{eval_expr node.expr}"
  end

  def eval_optional_chain(node)
    "#{padding}#{eval_expr node.lhs}?.#{node.property}"
  end

  def eval_bind(node)
    args = node.args.map { |arg| eval_expr arg }.join ", "
    if args.size > 0
      args = ", #{args}"
    end
    "#{eval_expr node.function}.call(#{eval_expr node.lhs}#{args})"
  end

  def eval_case_function_definition(node)
    f = "#{padding}#{fn_prefix}#{node.name}(...args) {\n"
    node.patterns.each_with_index do |s_case, i|
      if s_case.patterns.all? { |arg| arg.is_a? AST::SimpleSchemaArg }
        schemas = s_case.patterns.map(&:schema_name)
        args = s_case.patterns.map(&:name)
      elsif s_case.patterns.all? { |arg| arg.is_a? AST::Int }
        schemas = s_case.patterns.map(&:value)
        args = []
      elsif s_case.patterns.all? { |arg| arg.is_a? AST::SimpleArg }
        schemas = s_case.patterns.map { |p| "s('#{p.name}')" }
        args = s_case.patterns.map(&:name)
      else
        assert_not_reached!
      end
      if i == 0
        f += "#{padding}  if "
      else
        f += " else if "
      end
      f += "("
      if s_case.this_pattern
        f += "s.check(#{eval_expr s_case.this_pattern}, this) && "
      end
      f += "s.check([#{schemas.join ", "}], args)) {\n"

      args.each_with_index do |arg, i|
        f += "#{padding}    let #{arg} = args[#{i}];\n"
      end
      f += "#{padding}#{Compiler.new(s_case.body, @indent + 4).eval}\n"
      if i == node.patterns.size - 1
        f += "#{padding}  }\n"
      else
        f += "#{padding}  }"
      end
    end
    f + "}"
  end

  def eval_instance_property(node)
    "#{padding}#{node.name} = #{eval_expr node.expr};"
  end

  def eval_one_line_getter(node)
    m = "#{padding}get #{node.name}() {\n"
    m += "#{padding}  return #{eval_expr node.expr};\n"
    m += "#{padding}}\n"
  end

  def eval_dynamic_lookup(node)
    "#{eval_expr node.lhs}[#{eval_expr node.expr}]"
  end

  def eval_short_hand_constructor(node)
    args = node.args.map { |arg| eval_expr arg }.join ", "
    c = "#{padding}constructor(#{args}) {\n"
    for arg in node.args.map(&:name)
      c += "#{padding}  this.#{arg} = #{arg};\n"
    end
    c += "#{padding}}"
  end

  def eval_new(node)
    args = node.args.map { |node| eval_expr node }.join ", "
    "new #{eval_expr node.class_expr}(#{args})"
  end

  def eval_static_method(node)
    "#{padding}static #{eval_multiline_def_with_args(node).lstrip}"
  end

  def eval_dot_assignment(node)
    "#{eval_expr node.lhs} = #{eval_expr node.expr}"
  end

  def eval_class(node)
    super_class = " extends #{node.parent_class}" if node.parent_class
    c = "class #{node.name}#{super_class} {\n"
    indent!
    @is_class_definition = true
    for entry in node.entries
      c += "#{eval_expr entry}\n"
    end
    @is_class_definition = false
    dedent!
    c += "}"
  end

  def eval_escaped_element_expr(node)
    node = node.value
    value = if node.is_a?(AST::IdLookup)
        "this.#{node.value} || #{node.value}"
      else
        eval_expr node.value
      end
    "${#{value}}"
  end

  def kebab_case(name)
    name.gsub(/([a-z\d])([A-Z])/, '\1-\2').downcase
  end

  def create_shadow_root
    "this.attachShadow({ mode: 'open' });"
  end

  def define_component(node)
    "customElements.define('#{kebab_case node.name}', #{node.name})"
  end

  def eval_body_component_without_attrs(node)
    c = "class #{node.name} extends HTMLElement {\n"
    node.constructor_body
      .select { |node| node.is_a? AST::SimpleAssignment }
      .each do |node|
      c += "  #{node.name} = #{eval_expr node.expr};\n"
    end
    c += "  constructor() {\n"
    c += "    super();\n"
    c += "    #{create_shadow_root}\n"
    c += "  }\n"
    c += "  connectedCallback() {\n"
    c += "    #{eval_render node};\n"
    c += "  }\n"
    c += "}\n"
    c + define_component(node)
  end

  def get_attr_names(node)
    node.attributes.properties.map { |attr, _| attr }
  end

  def assign_attributes(node, padding)
    node.attributes.properties.map do |attr, schema|
      assert { schema.is_a? AST::SchemaCapture }
      "#{padding}this.#{attr} = this.getAttribute('#{attr}');"
    end.join "\n"
  end

  def get_var_queries(elem, path = elem.expr.name)
    assert { elem.expr.children.size == 1 }
    assert { elem.expr.children[0].is_a? AST::EscapedElementExpr }
    assert { elem.expr.children[0].value.is_a? AST::IdLookup }
    {
      elem.expr.children[0].value.value => {
        :path => path,
        :expr => elem.expr.children[0],
      },
    }
  end

  def eval_expr_component_with_attrs(node)
    c = "class #{node.name} extends HTMLElement {\n"
    c += "  static get observedAttributes() {\n"
    c += "    return #{get_attr_names(node).to_s};\n"
    c += "  }\n"
    c += "  constructor() {\n"
    c += "    super();\n"
    c += "    #{create_shadow_root}\n"
    c += "  }\n"
    c += "  connectedCallback() {\n"
    c += "#{assign_attributes(node, "    ")}\n"
    c += "    #{eval_render node}\n"
    c += "  }\n"
    c += "  attributeChangedCallback(name, oldValue, newValue) {\n"
    c += "    if (this.shadowRoot.innerHTML.trim() === '') return;\n"
    var_name_to_query = get_var_queries node
    var_name_to_query.each do |key, value|
      c += "    if (name === '#{key}') {\n"
      c += "      this.#{key} = newValue;\n"
      c += "      this.shadowRoot.querySelector('#{value[:path]}').innerHTML = `#{eval_expr value[:expr]}`;\n"
      c += "    }\n"
    end
    c += "  }\n"
    c += "}\n"
    c + define_component(node)
  end

  def eval_render(node)
    "this.shadowRoot.innerHTML = #{eval_simple_element node.expr};"
  end

  def eval_simple_element(node)
    assert { node.is_a? AST::SimpleElement }
    e = "`<#{node.name}>"
    e += "  #{node.children.map { |el| eval_expr el }.join("\n")}"
    e += "</#{node.name}>`"
  end

  def eval_expr_component(node)
    c = "class #{node.name} extends HTMLElement {\n"
    c += "  constructor() {\n"
    c += "    super();\n"
    c += "    #{create_shadow_root}\n"
    c += "    #{eval_render node};\n"
    c += "  }\n"
    c += "}\n"
    c + define_component(node)
  end

  def eval_await(node)
    "await #{eval_expr node.value}"
  end

  def eval_simple_schema_assignment(node)
    "#{node.name} = s.verify(#{node.schema_name}, #{eval_expr node.expr}, '#{node.schema_name}')"
  end

  def unpack_object(object_str)
    assert { object_str[0] == "{" }
    assert { object_str[-1] == "}" }
    object_str[1...-1].strip
  end

  def eval_schema_intersect(node)
    schema = "{ "
    schema += node.schema_exprs.map do |expr|
      case expr
      when AST::IdLookup
        "...#{eval_expr expr}"
      when AST::SchemaObjectLiteral
        unpack_object eval_expr(expr)
      else
        assert_not_reached!
      end
    end.join ", "
    schema + " }"
  end

  def eval_schema_union(node)
    "s.union(#{node.schema_exprs.map { |expr| eval_expr expr }.join ", "})"
  end

  def eval_schema_object_literal(node)
    schema_obj = "{ "
    for name, value in node.properties
      schema_obj += "#{name}: #{eval_expr value}, "
    end
    # remove last ", "
    schema_obj[0...-2] + " }"
  end

  def eval_schema_definition(node)
    "const #{node.name} = #{eval_expr node.schema_expr}"
  end

  def eval_for_of_obj_descontruct_loop(node)
    properties = node.iter_properties.join ", "
    for_loop = "for (let { #{properties} } of #{eval_expr node.arr_expr}) {\n"
    for_loop += Compiler.new(node.body, @indent + 2).eval + "\n"
    for_loop += "#{padding}}"
  end

  def eval_simple_for_of_loop(node)
    for_loop = "for (let #{node.iter_name} of #{eval_expr node.arr_expr}) {\n"
    for_loop += Compiler.new(node.body, @indent + 2).eval + "\n"
    for_loop += "#{padding}}"
  end

  def fn_prefix
    if @is_class_definition
      ""
    else
      "function "
    end
  end

  def eval_multiline_def_without_args(fn_node)
    fn = "#{padding}#{fn_prefix}#{fn_node.name}() {\n"
    fn += Compiler.new(fn_node.body, @indent + 2).eval + "\n"
    fn += "#{padding}}"
    fn
  end

  def eval_dot(node)
    "#{eval_expr(node.lhs)}.#{eval_expr(node.rhs)}"
  end

  def eval_range(node)
    "new Range(#{eval_expr node.lhs}, #{eval_expr node.rhs})"
  end

  def eval_dbl_eq(node)
    "#{eval_expr(node.lhs)}[Symbol.peacock_equals](#{eval_expr(node.rhs)})"
  end

  def eval_in(node)
    "#{eval_expr(node.rhs)}[Symbol.peacock_contains](#{eval_expr(node.lhs)})"
  end

  def eval_operator(node)
    return eval_in(node) if node.type == :in
    return eval_dbl_eq(node) if node.type == :"=="
    op = node.type
    op = "%" if node.type == :mod

    "#{eval_expr(node.lhs)} #{op} #{eval_expr(node.rhs)}"
  end

  def eval_schema_capture(node)
    "s('#{node.name}')"
  end

  def eval_else_if(node)
    b = " else if (#{eval_expr node.cond}) {\n"
    b += Compiler.new(node.body, @indent + 2).eval + "\n"
    b += "}"
    b
  end

  def eval_else(node)
    b = " else {\n"
    b += Compiler.new(node.body, @indent + 2).eval + "\n"
    b += "}"
    b
  end

  def eval_if_expression(node)
    cond = eval_expr(node.cond)
    pass_body = Compiler.new(node.pass, @indent + 2).eval_without_variable_declarations

    i = "if (#{cond}) {\n"
    i += "#{pass_body}\n"
    i += "#{padding}}"
    i += node.branches.map { |branch| eval_expr branch }.join ""

    i
  end

  def eval_simple_string(node)
    if node.value.include?("\n")
      "`#{node.value}`"
    else
      "\"#{node.value}\""
    end
  end

  def eval_int(node)
    "#{node.value}"
  end

  def eval_float(node)
    "#{node.value}"
  end

  def eval_bool(node)
    "#{node.value}"
  end

  def eval_array_literal(node)
    elements = node.value.map { |n| eval_expr n }.join(", ")
    "[#{elements}]"
  end

  def eval_object_entry(node)
    "#{padding}#{node.key_name}: #{eval_expr node.value}"
  end

  def eval_spread_object_entry(node)
    "#{padding}...#{eval_expr node.value}"
  end

  def eval_function_object_entry(node)
    fn = node.value
    args = arg_names fn.args
    output = "#{padding}#{node.key_name}(#{args}) {\n"
    output += Compiler.new(fn.body, @indent + 2, fn.args.value.map(&:name)).eval + "\n"
    output + "#{padding}}"
  end

  def eval_object_literal(node)
    whitespace = if node.value.size > 3
        indent!
        "\n"
      else
        " "
      end
    object_literal = "{#{whitespace}"
    object_literal += node.value.map { |node| eval_expr node }.join(",#{whitespace}")
    dedent! if whitespace != " "
    object_literal += "#{whitespace}#{padding}}"
  end

  def sub_q(sym)
    sym
      .sub("?", "_q")
      .sub("!", "_b")
  end

  def eval_declaration(node)
    "const #{sub_q(node.name)} = #{eval_expr(node.expr)}"
  end

  def eval_assignment(node)
    "#{sub_q(node.name)} = #{eval_expr(node.expr)}"
  end

  def eval_arrow_fn_with_one_arg(node)
    "(#{node.arg}) => #{eval_expr node.return_expr}"
  end

  def arg_names(args_node)
    args_node.value.map { |node| node.name }.compact.join ", "
  end

  def eval_multiline_def_with_args(fn_node)
    args = arg_names fn_node.args

    fn = "#{padding}#{fn_prefix}#{fn_node.name}(#{args}) {\n"
    fn += Compiler.new(fn_node.body, @indent + 2).eval + "\n"
    fn += "#{padding}}"
    fn
  end

  def schema_arg_assignments(args_node)
    assignments = args_node.value
      .select { |node| node.is_a?(AST::SimpleSchemaArg) }
      .map do |arg|
      "#{padding}#{arg.name} = s.verify(#{arg.schema_name}, #{arg.name});"
    end.join("\n")

    assignments += args_node.value
      .map.with_index { |node, i| { node: node, i: i } }
      .select { |h| h[:node].is_a?(AST::NullSchema) }
      .map { |h| "#{padding}s.verify(null, arguments[#{h[:i]}], null)" }
      .join("\n")

    if assignments.empty?
      ""
    else
      assignments + "\n"
    end
  end

  def eval_single_line_fn_without_args(fn_node)
    fn = "#{padding}#{fn_prefix}#{fn_node.name}() {\n"
    indent!
    fn += "#{padding}return #{eval_expr fn_node.return_value};\n"
    dedent!
    fn += "#{padding}}"
    fn
  end

  def eval_single_line_fn_with_args(fn_node)
    args = arg_names fn_node.args

    fn = "#{padding}#{fn_prefix}#{fn_node.name}(#{args}) {\n"
    indent!
    fn += schema_arg_assignments(fn_node.args)
    fn += "#{padding}return #{eval_expr fn_node.return_value};\n"
    dedent!
    fn += "#{padding}}"
    fn
  end

  def eval_single_line_arrow_fn_with_args(node)
    args = arg_names node.args

    fn = "(#{args}) => {\n"
    indent!
    fn += schema_arg_assignments(node.args)
    fn += padding + "return #{eval_expr node.return_expr};\n"
    dedent!
    fn + "#{padding}}"
  end

  def eval_arrow_fn_with_args(node)
    args = arg_names node.args

    fn = "(#{args}) => {\n"
    fn += schema_arg_assignments(node.args)
    fn += Compiler.new(node.body, @indent + 2, fn_arg_names: node.args.value.map(&:name)).eval + "\n"
    fn + "}"
  end

  def eval_arrow_fn_without_args(node)
    "(() => { return #{eval_expr node.return_expr}; })"
  end

  def eval_short_fn_with_args(node)
    "(#{node.args.join ", "} => #{eval_expr node.return_expr})"
  end

  def eval_anon_id_lookup
    "_it"
  end

  def eval_short_fn(node)
    "(#{eval_anon_id_lookup} => #{eval_expr node.return_expr})"
  end

  def eval_return(node)
    "return #{eval_expr node.value}"
  end

  def eval_function_call(node)
    args = node.args.map { |arg| eval_expr arg }.join ", "
    fn = eval_expr node.expr
    "#{fn}(#{args})"
  end

  def eval_identifier_lookup(node)
    assert { node.value }
    sub_q(node.value)
  end
end
