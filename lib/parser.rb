require "utils"
require "ast"
require "parser/literals"
require "parser/helpers"
require "parser/functions"
require "parser/schemas"
require "parser/classes"
require "parser/html"
# require "pry"

OPERATORS = [:plus, :minus, :mult, :div, :and, :or, :schema_and, :schema_or, :eq, :not_eq, :gt, :lt, :gt_eq, :lt_eq]

ANON_SHORTHAND_ID = "__ANON_SHORT_ID"

class Parser
  include Functions
  include Helpers
  include Literals
  include Schemas
  include Classes
  include HTML

  def initialize(tokens, token_index = 0, indentation = 0, parser_context = nil, expr_context = nil)
    @tokens = tokens
    @token_index = token_index
    @indentation = indentation
    @parser_context = parser_context
    @expr_context = expr_context
  end

  def clone(tokens: nil, token_index: nil, indentation: nil, parser_context: nil, expr_context: nil)
    Parser.new(
      tokens || @tokens,
      token_index || @token_index,
      indentation || @indentation,
      parser_context || @parser_context,
      expr_context || @expr_context,
    )
  end

  def parser_context
    @parser_context ||= Context.new
  end

  def expr_context
    @expr_context ||= Context.new
  end

  def parse!
    _, @ast = parse_with_position!
    return @ast
  end

  def parse_with_position!(end_tokens = [])
    @ast = []
    while more_tokens? && still_indented?
      break if end_tokens.include? peek_type
      if peek_type == :class
        @ast.push parse_class_definition!
      elsif peek_type == :schema
        @ast.push parse_schema!
      elsif peek_type == :identifier && peek_type(1) == :assign
        @ast.push parse_assignment!
      elsif peek_type == :return
        assert { parser_context.in_a? :function }
        @ast.push parse_return!
        break
      else
        @ast.push parse_expr!
      end
    end

    if parser_context.directly_in_a?(:function)
      last_node = @ast.last[:node_type]
      case
      when last_node != :return && last_node != :if
        node = @ast.pop
        @ast.push AST::return node
      end
    else
    end
    return @token_index, @ast
  end

  # Parsing begins!

  def parse_expr!
    type = peek_type
    case
    when [:int_lit, :float_lit, :symbol].include?(type)
      lit_expr = parse_lit! type
      peek = peek_type
      case
      when OPERATORS.include?(peek)
        parse_operator_call! lit_expr
      else lit_expr
      end
    when [:true, :false].include?(type)
      parse_bool! type
    when type == :str_lit
      parse_str!
    when type == :nil
      parse_nil!
    when type == :bang
      parse_bang!
    when type == :property
      parse_property!
    when type == :open_square_bracket
      parse_array!
    when type == :open_html_tag
      parse_html_tag!
    when type == :open_custom_element_tag
      parse_custom_element!
    when type == :open_brace
      parse_record!
    when type == :fn
      parse_anon_function_def!
    when type == :if
      node = parse_if_expression!
      modify_if_statement_for_context node
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
    # TODO: kinda hacky.. :/
    # This is because all the tokens (text nodes)
    # of html child aren't tokenized as raw text
    return sym_expr if expr_context.directly_in_a? :html_tag
    type = peek_type
    case
    when is_function_call?(sym_expr)
      node = parse_function_call! sym_expr
      parse_id_modifier_if_exists! node
    when end_of_file?
      sym_expr
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
    when is_function?
      parse_function_def! sym_expr
    else sym_expr
    end
  end

  # Individual parsers

  def parse_return!(implicit_return = false)
    line, c, _ = consume! :return unless implicit_return
    expr = parse_expr!
    c = expr[:column] if implicit_return
    AST::return expr, line, c
  end

  def parse_assignment!
    line, c, sym = consume! :identifier
    consume! :assign
    expr = parse_expr!
    AST::assignment sym, expr, line, c
  end

  def parse_operator_call!(lhs)
    line, c1, _, op = consume!
    rhs_expr = parse_expr!
    if [:schema_and, :schema_or].include?(op)
      operator = dot(schema, [line, c1, op.to_s.split("schema_")[1]])
      AST::function_call [lhs, rhs_expr], operator, line, c1
    else
      function = dot(lhs, [line, c1, "__#{op.to_s}__"])
      AST::function_call [rhs_expr], function, line, c1
    end
  end

  def parse_if_body!
    end_tokens = [:end, :else]
    @token_index, body = clone(parser_context: parser_context.clone.push!(:if)).parse_with_position! end_tokens
    body
  end

  def parse_if_expression!
    if_line, c, _ = consume! :if
    check = parse_expr!
    pass_body = parse_if_body!
    consume! :then if peek_type == :then
    if peek_type != :else
      consume! :end
      return AST::if check, pass_body, [], if_line, c
    end
    consume! :else
    fail_body = if peek_type == :if
        [parse_if_expression!]
      else
        body = parse_if_body!
        consume! :end
        body
      end
    AST::if check, pass_body, fail_body, if_line, c
  end

  def insert_return(body)
    return body if body.size == 0
    last = body.pop
    new_last = if last[:node_type] == :return
        last
      else
        AST::return last
      end
    body.push new_last
    body
  end

  def modify_if_statement_for_context(if_expr)
    def replace_return(if_expr)
      { **if_expr,
        pass: insert_return(if_expr[:pass]),
        fail: insert_return(if_expr[:fail]) }
    end

    if parser_context.directly_in_a? :str
      assert {
        !(if_expr[:pass] + if_expr[:fail])
          .any? { |node| node[:node_type] == :return }
      }
      AST::function_call(
        [],
        AST::function(
          [],
          [replace_return(if_expr)]
        )
      )
    elsif parser_context.directly_in_a? :function
      replace_return(if_expr)
    else
      if_expr
    end
  end

  def parse_dot_expression!(lhs)
    line, c = consume! :dot
    AST::dot lhs, consume!(:identifier), line, c
  end

  def parse_class_properity_expression!(lhs)
    c, l = column, line
    AST::dot lhs, consume!(:class_property), l, c
  end

  def parse_dynamic_lookup!(lhs)
    consume! :open_square_bracket
    expr = parse_expr!
    consume! :close_square_bracket
    # too many possibilities, will leave unchecked for now
    # assert { [:str_lit, :bool_lit, :symbol, :int_lit, :float_lit].include? expr[:args][0][:node_type] }
    node = AST::lookup(lhs, expr)
    parse_id_modifier_if_exists!(node)
  end

  # Schema parsing

  def dot(lhs, id)
    id = [line, column, id] unless id.is_a?(Array)
    AST::dot lhs, id, line, column
  end

  def function_call(args, expr)
    AST::function_call(args, expr, line, column)
  end
end
