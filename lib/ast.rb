module AST
  def self.remove_numbers_single(node)
    node = node.except(:line, :column)
    node[:expr] = AST::remove_numbers_single(node[:expr]) if node[:expr]
    node[:property] = AST::remove_numbers_single(node[:property]) if node[:property]
    node[:lhs_expr] = AST::remove_numbers_single(node[:lhs_expr]) if node[:lhs_expr]
    node[:value] = AST::remove_numbers(node[:value]) if node[:value].is_a?(Array)
    node[:args] = AST::remove_numbers(node[:args]) if node[:args]
    node[:body] = AST::remove_numbers(node[:body]) if node[:body]
    return node
  end

  def self.remove_numbers(nodes)
    nodes.map { |n| AST::remove_numbers_single(n) }
  end

  def self.literal(line, c, type, value)
    { node_type: type,
      line: line,
      column: c,
      value: value }
  end

  def self.array(line, c, value)
    { node_type: :array_lit,
      line: line,
      column: c,
      value: value }
  end

  def self.record(line, c, value)
    { node_type: :record_lit,
      line: line,
      column: c,
      value: value }
  end

  def self.bool(line, c, value)
    { node_type: :bool_lit,
      line: line,
      column: c,
      value: value }
  end

  def self.str(line, c, value)
    { node_type: :str_lit,
      line: line,
      column: c,
      value: value }
  end

  def self.return(line, c, expr)
    { node_type: :return,
      line: line,
      column: c,
      expr: expr }
  end

  def self.if(line, c, expr, pass, _fail)
    { node_type: :if,
      line: line,
      column: c,
      expr: expr,
      pass: pass,
      fail: _fail }
  end

  def self.function_call(line, c, args, expr)
    { node_type: :function_call,
      line: line,
      column: c,
      args: args,
      expr: expr }
  end

  def self.function(line, c, body, args)
    { node_type: :function,
      line: line,
      column: c,
      args: args,
      body: body }
  end

  def self.function_argument(line, c, sym)
    { node_type: :function_argument,
      line: line,
      column: c,
      sym: sym }
  end

  def self.identifier_lookup(line, c, sym)
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

  def self.assignment(sym, line, c, expr)
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

  def self.dot(line, c, lhs_expr, id)
    lit_c, sym = id
    property = AST::literal line, lit_c, :str_lit, sym
    AST::property_lookup line, c, lhs_expr, property
  end

  def self.index_on(lhs, index)
    AST::property_lookup lhs[:line], lhs[:column], lhs, index
  end

  def self.throw(line, c, expr)
    { node_type: :throw,
      line: line,
      column: c,
      expr: expr }
  end
end
