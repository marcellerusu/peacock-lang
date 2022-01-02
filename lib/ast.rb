AST_LIT_TO_CONSTRUCTOR = {
  int_lit: "Int",
  str_lit: "Str",
  float_lit: "Float",
  symbol: "Sym",
}

module AST
  def self.remove_numbers_single(node)
    assert { node.is_a? Hash }
    node.delete(:line)
    node.delete(:column)
    node[:expr] = AST::remove_numbers_single(node[:expr]) if node[:expr]
    node[:property] = AST::remove_numbers_single(node[:property]) if node[:property]
    node[:lhs_expr] = AST::remove_numbers_single(node[:lhs_expr]) if node[:lhs_expr]
    node[:value] = AST::remove_numbers(node[:value]) if node[:value].is_a?(Array)
    node[:value] = AST::remove_numbers_from_hash(node[:value]) if node[:value].is_a?(Hash)
    node[:args] = AST::remove_numbers(node[:args]) if node[:args]
    node[:body] = AST::remove_numbers(node[:body]) if node[:body]
    node[:methods] = AST::remove_numbers(node[:methods]) if node[:methods]
    node[:pass] = AST::remove_numbers(node[:pass]) if node[:pass]
    node[:fail] = AST::remove_numbers(node[:fail]) if node[:fail]
    node[:cases] = AST::remove_numbers_single(node[:cases]) if node[:cases]
    return node
  end

  def self.remove_numbers(nodes)
    assert { nodes.is_a? Array }
    nodes.map { |n| AST::remove_numbers_single(n) }
  end

  def self.remove_numbers_from_hash(hash)
    hash.map { |k, n| [k, AST::remove_numbers_single(n)] }.to_h
  end

  def self.int(value, line = nil, column = nil)
    AST::literal_constructor(
      { node_type: :int_lit,
        line: line,
        column: column,
        value: value },
      "Int"
    )
  end

  def self.literal(line, c, type, value)
    AST::literal_constructor(
      { node_type: type,
        line: line,
        column: c,
        value: value },
      AST_LIT_TO_CONSTRUCTOR[type]
    )
  end

  def self.array(value, line = nil, c = nil)
    AST::literal_constructor(
      { node_type: :array_lit,
        line: line,
        column: c,
        value: value },
      "List"
    )
  end

  def self.record(value, line = nil, c = nil)
    AST::literal_constructor(
      { node_type: :record_lit,
        line: line,
        column: c,
        value: value },
      "Record"
    )
  end

  def self.sym(value, line = nil, c = nil)
    AST::literal_constructor(
      { node_type: :symbol,
        line: line,
        column: c,
        value: value },
      "Sym"
    )
  end

  def self.bool(value, line = nil, c = nil)
    AST::literal_constructor(
      { node_type: :bool_lit,
        line: line,
        column: c,
        value: value },
      "Bool"
    )
  end

  def self.float(value, line = nil, c = nil)
    AST::literal_constructor(
      { node_type: :float_lit,
        line: line,
        column: c,
        value: value },
      "Float"
    )
  end

  def self.str(value, line = nil, c = nil)
    AST::literal_constructor(
      { node_type: :str_lit,
        line: line,
        column: c,
        value: value },
      "Str"
    )
  end

  def self.return(expr, line = nil, c = nil)
    { node_type: :return,
      line: line,
      column: c,
      expr: expr }
  end

  def self.if(expr, pass, _fail, line = nil, c = nil)
    { node_type: :if,
      line: line,
      column: c,
      expr: expr,
      pass: pass,
      fail: _fail }
  end

  def self.function_call(args, expr, line = nil, c = nil)
    { node_type: :function_call,
      line: line,
      column: c,
      args: args,
      expr: expr }
  end

  def self.function(args, body, line = nil, c = nil)
    { node_type: :function,
      line: line,
      column: c,
      args: args,
      body: body }
  end

  def self.function_argument(sym, line = nil, c = nil)
    { node_type: :function_argument,
      line: line,
      column: c,
      sym: sym }
  end

  def self.identifier_lookup(sym, line = nil, c = nil)
    { node_type: :identifier_lookup,
      line: line,
      column: c,
      sym: sym }
  end

  def self.declare(sym_expr, expr)
    { node_type: :declare,
      sym: sym_expr[:sym],
      line: sym_expr[:line],
      column: sym_expr[:column],
      expr: expr }
  end

  def self.assignment(sym, expr, line = nil, c = nil)
    { node_type: :assign,
      sym: sym,
      line: line,
      column: c,
      expr: expr }
  end

  def self.property_lookup(line, c, lhs_expr, property)
    # just convert to string for now... TODO: idk
    { node_type: :property_lookup,
      lhs_expr: lhs_expr,
      line: line,
      column: c,
      property: property }
  end

  def self.dot(lhs_expr, id, line = nil, c = nil)
    id = [lhs_expr[:column], id] unless id.is_a?(Array)
    lit_c, sym = id
    property = { line: line, column: lit_c, node_type: :str_lit, value: sym }
    AST::property_lookup line, c, lhs_expr, property
  end

  def self.instance_lookup(name, line = nil, c = nil)
    { node_type: :instance_lookup,
      sym: name,
      line: line,
      column: c }
  end

  def self.lookup(lhs, expr)
    AST::function_call(
      [expr],
      AST::dot(lhs, "__lookup__", lhs[:line], lhs[:column])
    )
  end

  def self.throw(expr, line = nil, c = nil)
    { node_type: :throw,
      line: line,
      column: c,
      expr: expr }
  end

  def self.literal_constructor(value_expr, type_name, line = nil, c = nil)
    AST::function_call(
      [value_expr],
      AST::dot(
        AST::identifier_lookup(type_name, line, c),
        [c, "create"],
        line,
        c
      ),
      line,
      c
    )
  end

  def self.html_tag(name, attributes, children, line = nil, column = nil)
    { node_type: :html_tag,
      name: name,
      attributes: attributes,
      children: children,
      line: line,
      column: column }
  end

  def self.html_text_node(value, line = nil, column = nil)
    { node_type: :html_text_node,
      value: value,
      line: line,
      column: column }
  end

  def self.class(name, args, methods, line = nil, column = nil)
    { node_type: :class,
      sym: name,
      args: args,
      methods: methods,
      line: line,
      column: column }
  end

  def self.case(expr, cases, line = nil, column = nil)
    { node_type: :case,
      expr: expr,
      cases: cases,
      line: line,
      column: column }
  end
end
