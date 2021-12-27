require "utils"
require "ast"
require "parser/literals"
require "parser/helpers"
require "parser/functions"
require "parser/schemas"
require "parser/classes"
# require "pry"

OPERATORS = [:plus, :minus, :mult, :div, :and, :or, :schema_and, :schema_or, :eq, :not_eq, :gt, :lt, :gt_eq, :lt_eq]

ANON_SHORTHAND_ID = "__ANON_SHORT_ID"

class Parser
  include Literals
  include Helpers
  include Functions
  include Schemas
  include Classes

  def initialize(statements, line = 0, token_index = 0, indentation = 0, context = nil)
    @statements = statements
    @line = line
    @token_index = token_index
    @indentation = indentation
    @context = context
    @expr_context = nil
  end

  def parse!
    _, _, @ast = parse_with_position!
    return @ast
  end

  def parse_with_position!(end_tokens = [])
    @ast = []
    next_line! unless token
    while more_statements? && still_indented?
      break if end_tokens.include? peek_type
      if peek_type == :class
        @ast.push parse_class_definition!
      elsif peek_type == :schema
        @ast.push parse_schema!
      elsif peek_type == :identifier && peek_type(1) == :assign
        @ast.push parse_assignment!
      elsif peek_type == :return
        @ast.push parse_return!
        break
      else
        @ast.push parse_expr!
      end
      next_line!
    end
    if [:declare, :function].include?(@context) && @ast.last[:node_type] != :return
      node = @ast.pop
      @ast.push AST::return(node, node[:line], node[:column])
    end
    return @line, @token_index, @ast
  end

  private

  # Parsing begins!

  def parse_expr!
    type = peek_type
    case
    when [:int_lit, :str_lit, :float_lit, :symbol].include?(type)
      lit_expr = parse_lit! type
      peek = peek_type
      case
      when OPERATORS.include?(peek)
        parse_operator_call! lit_expr
      else lit_expr
      end
    when [:true, :false].include?(type)
      parse_bool! type
    when type == :property
      parse_property!
    when type == :open_square_bracket
      parse_array!
    when type == :open_brace
      parse_record!
    when type == :fn
      parse_anon_function_def!
    when type == :if
      parse_if_expression!
    when type == :identifier
      parse_identifier!
    when type == :case
      parse_case_expression!
    when type == :anon_short_fn_start
      parse_anon_function_shorthand!
    when type == :anon_short_id
      parse_anon_short_id!
    else
      puts "no match [parse_expr!] :#{type}"
      assert { false }
    end
  end

  def parse_id_modifier_if_exists!(sym_expr)
    type = peek_type
    case
    when type == :open_square_bracket
      parse_dynamic_lookup! sym_expr
    when type == :dot
      node = parse_dot_expression! sym_expr
      parse_id_modifier_if_exists! node
    when type == :class_property
      node = parse_class_properity_expression! sym_expr
      parse_id_modifier_if_exists! node
    when OPERATORS.include?(type)
      parse_operator_call! sym_expr
    when is_function_call?
      node = parse_function_call! sym_expr
      parse_id_modifier_if_exists! node
    when is_function?
      parse_function_def! sym_expr
    else sym_expr
    end
  end

  # Individual parsers

  def parse_return!(implicit_return = false)
    c, _ = consume! :return unless implicit_return
    expr = parse_expr!
    c = expr[:column] if implicit_return
    AST::return expr, @line, c
  end

  def parse_assignment!
    c, sym = consume! :identifier
    consume! :assign
    line = @line
    expr = parse_expr!
    AST::assignment sym, expr, line, c
  end

  def parse_operator_call!(lhs)
    c1, _, op = consume!
    rhs_expr = parse_expr!
    if [:schema_and, :schema_or].include?(op)
      operator = dot(schema, [c1, op.to_s.split("schema_")[1]])
      AST::function_call [lhs, rhs_expr], operator, @line, c1
    else
      function = dot(lhs, [c1, "__#{op.to_s}__"])
      AST::function_call [rhs_expr], function, @line, c1
    end
  end

  def parse_if_expression!
    end_tokens = [:end, :else]
    c, _ = consume! :if
    if_line = @line
    check = parse_expr!
    @line, @token_index, pass_body = Parser.new(@statements, @line, @token_index, @indentation, :if).parse_with_position! end_tokens
    consume! :then if peek_type == :then
    if peek_type != :else
      consume! :end
      return AST::if check, pass_body, [], if_line, c
    end
    consume! :else
    return AST::if(check, pass_body, [parse_if_expression!], if_line, c) if peek_type == :if
    @line, @token_index, fail_body = Parser.new(@statements, @line, @token_index, @indentation, :if).parse_with_position! end_tokens
    consume! :end
    AST::if check, pass_body, fail_body, if_line, c
  end

  def parse_dot_expression!(lhs)
    c, line = @column, @line
    consume! :dot
    AST::dot lhs, consume!(:identifier), line, c
  end

  def parse_class_properity_expression!(lhs)
    c, line = @column, @line
    AST::dot lhs, consume!(:class_property), line, c
  end

  def parse_dynamic_lookup!(lhs)
    c, line = @column, @line
    consume! :open_square_bracket
    expr = parse_expr!
    consume! :close_square_bracket
    assert { [:str_lit, :symbol, :int_lit, :float_lit].include? expr[:args][0][:node_type] }
    node = AST::lookup(lhs, expr)
    parse_id_modifier_if_exists!(node)
  end

  # Schema parsing

  def dot(lhs, id)
    id = [@column, id] unless id.is_a?(Array)
    AST::dot lhs, id, @line, @column
  end

  def function_call(args, expr)
    AST::function_call(args, expr, @line, @column)
  end
end
