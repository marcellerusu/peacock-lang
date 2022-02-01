require "utils"
require "ast"
require "parser/literals"
require "parser/helpers"
require "parser/functions"
require "parser/schemas"
require "parser/classes"
require "parser/html"
require "parser/modules"
# require "pry"

OPERATORS = [:+, :-, :*, :/, :"&&", :"||", :&, :|, :"==", :"!=", :>, :<, :">=", :"<="]

OP_TO_METHOD_NAME = {
  :"&&" => "__and__",
  :"||" => "__or__",
  :">=" => "__gt_eq__",
  :"<=" => "__lt_eq__",
  :> => "__gt__",
  :< => "__lt__",
  :"==" => "__eq__",
  :"!=" => "__not_eq__",
  :+ => "__plus__",
  :- => "__minus__",
  :* => "__mult__",
  :/ => "__div__",
  :& => "and",
  :| => "or",
}

ANON_SHORTHAND_ID = "__ANON_SHORT_ID"

class Parser
  include Functions
  include Helpers
  include Literals
  include Schemas
  include Classes
  include HTML
  include Modules

  def computed_files
    @@computed_files ||= []
  end

  def initialize(tokens, token_index = 0, indentation = 0, parser_context = nil, expr_context = nil, first_run = true)
    @tokens = tokens
    @token_index = token_index
    @indentation = indentation
    @parser_context = parser_context
    @expr_context = expr_context
    if first_run
      @@computed_files = []
    end
  end

  def self.computed_files
    @@computed_files
  end

  def unused_count
    @@unused_count ||= 0
  end

  def increment_unused_count!
    @@unused_count += 1
  end

  def self.reset_unused_count!
    @@unused_count = 0
  end

  def clone(tokens: nil, token_index: nil, indentation: nil, parser_context: nil, expr_context: nil)
    Parser.new(
      tokens || @tokens,
      token_index || @token_index,
      indentation || @indentation,
      parser_context || @parser_context,
      expr_context || @expr_context,
      false
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
    @ast.push module_def if parser_context.empty?
    while more_tokens? && still_indented?
      break if end_tokens.include? peek_type
      if peek_type == :export
        @ast.push(*parse_export!)
      elsif peek_type == :import
        @ast.push(*parse_import!)
      elsif peek_type == :return
        assert { parser_context.in_a?(:function) }
        @ast.push parse_return!
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
      parse_lit! type
    when [:true, :false].include?(type)
      parse_bool! type
    when type == :str_lit
      parse_str!
    when type == :nil
      parse_nil!
    when type == :bang
      parse_bang!
    when type == :open_parenthesis
      parse_paren_expr!
    when type == :schema
      parse_schema!
    when type == :identifier && peek_type(1) == :assign
      parse_assignment!
    when type == :property
      parse_property!
    when type == :class
      parse_class_definition!
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

  def parse_paren_expr!
    line, c = consume! :open_parenthesis
    expr = parse_expr!
    consume! :close_parenthesis
    node = AST::paren_expr expr, line, c
    parse_id_modifier_if_exists! node
  end

  def parse_id_modifier_if_exists!(sym_expr)
    # TODO: kinda hacky.. :/
    # This is because all the tokens (text nodes)
    # of html child aren't tokenized as raw text
    return sym_expr if expr_context.directly_in_a? :html_tag
    type = peek_type
    node = case
      when function_call?(sym_expr)
        parse_function_call! sym_expr
      when end_of_file?
        return sym_expr
      when function?
        return parse_function_def! sym_expr
      when type == :open_square_bracket
        parse_dynamic_lookup! sym_expr
      when type == :& && peek_type(1) == :open_square_bracket
        parse_nil_safe_lookup! sym_expr
      when type == :& && peek_type(1) == :dot
        parse_nil_safe_call! sym_expr
      when type == :dot
        parse_dot_expression! sym_expr
      when type == :class_property
        parse_class_properity_expression! sym_expr
      when operator?
        return parse_operator_call! sym_expr
      else
        return sym_expr
      end
    parse_id_modifier_if_exists! node
  end

  def operator?
    OPERATORS.include?(peek_type) && !expr_context.directly_in_a?(:operator)
  end

  # Individual parsers

  def parse_nil_safe_lookup!(lhs)
    consume! :&
    consume! :open_square_bracket
    expr = parse_expr!
    consume! :close_square_bracket
    node = AST::lookup lhs, expr
    node = AST::function_call(
      [AST::function([], [AST::return(node)])],
      dot(lhs, "__and__")
    )
  end

  def parse_nil_safe_call!(lhs)
    consume! :&
    consume! :dot
    line, c, method = consume! :identifier
    node = parse_function_call! dot(lhs, [line, c, method])
    node = AST::function_call(
      [AST::function([], [AST::return(node)])],
      dot(lhs, "__and__")
    )
  end

  def parse_return!(implicit_return = false)
    line, c, _ = consume! :return unless implicit_return
    expr = parse_expr!
    c = expr[:column] if implicit_return
    node = AST::return expr, line, c
    if peek_type == :if
      line, c = consume! :if
      cond = parse_expr!
      AST::if(cond, [node], [], line, c)
    else
      node
    end
  end

  def parse_assignment!
    line, c, sym = consume! :identifier
    consume! :assign
    expr = parse_expr!
    AST::assignment sym, expr, line, c
  end

  def parse_operator_call!(lhs)
    line, c1, _, op = consume!
    expr_context.push! :operator
    rhs_expr = parse_expr!
    expr_context.pop! :operator
    method_name = OP_TO_METHOD_NAME[op]
    assert { !method_name.nil? }

    if [:&, :|].include?(op)
      operator = dot(schema, [line, c1, method_name])
      AST::function_call [lhs, rhs_expr], operator, line, c1
    else
      function = dot(lhs, [line, c1, method_name])
      node = AST::function_call [rhs_expr], function, line, c1
      parse_id_modifier_if_exists! node
    end
  end

  def parse_if_body!
    end_tokens = [:end, :else]
    @token_index, body = clone(
      parser_context: parser_context.clone.push!(:if),
    ).parse_with_position! end_tokens
    body
  end

  def parse_if_expression!
    if_line, c, _ = consume! :if
    check = parse_expr!
    consume! :then if peek_type == :then
    pass_body = parse_if_body!
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
