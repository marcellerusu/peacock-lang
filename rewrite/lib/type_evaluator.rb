class TypeEvaluator
  def initialize(ast)
    @ast = ast.clone
  end

  def union(types)
    assert { types.is_a? Array }
    { type: :union, of: types }
  end

  def array(node)
    types = node[:value]
      .map { |node| eval_expr_type(node)[:type] }
      .uniq
    assert { types.size >= 1 }
    type = if types.size == 1
        types[0]
      else
        union types
      end

    { type: :array, of: type }
  end

  def record(node)
    type_hash = node[:value]
      .transform_values { |v| eval_expr_type(v)[:type] }

    { type: :record, of: type_hash }
  end

  def eval_expr_type(node)
    # puts "#{node[:node_type]}"
    type = case node[:node_type]
      when :int_lit
        { type: :int }
      when :float_lit
        { type: :float }
      when :str_lit
        { type: :str }
      when :symbol
        { type: :symbol }
      when :array_lit
        array node
      when :record_lit
        record node
      else
        puts "match not found [eval_expr_type] #{node[:node_type]}"
        assert { false }
      end
    { **node, type: type }
  end

  def eval
    ast_with_types = []
    for statement in @ast
      ast_with_types.push(eval_expr_type statement)
    end
    ast_with_types
  end
end
