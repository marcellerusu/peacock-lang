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

  def initialize(tokens, program_string, token_index = 0, parser_context = nil, expr_context = nil, first_run = true)
    @tokens = tokens
    @program_string = program_string
    @token_index = token_index
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

  def clone(tokens: nil, program_string: nil, token_index: nil, parser_context: nil, expr_context: nil)
    Parser.new(
      tokens || @tokens,
      program_string || @program_string,
      token_index || @token_index,
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
    while more_tokens? && current_token.is_not_a?(:end)
      break if current_token.is_one_of?(*end_tokens)
      case current_token.type
      when :export
        @ast.push(*parse_export!)
      when :import
        @ast.push(*parse_import!)
      when :return
        assert { parser_context.in_a?(:function) }
        @ast.push parse_return!
      else
        @ast.push parse_expr!
      end
    end

    if parser_context.directly_in_a?(:function)
      last_node_type = @ast.last[:node_type]
      if ![:return, :if].include?(last_node_type)
        node = @ast.pop
        @ast.push AST::return node
      end
    else
    end
    return @token_index, @ast
  end

  # Parsing begins!

  def parse_expr!
    # more complex conditions first
    if current_token.is_one_of?(:int_lit, :float_lit, :symbol)
      return parse_lit! current_token.type
    elsif current_token.is_one_of?(:true, :false)
      return parse_bool! current_token.type
    elsif current_token.is_a?(:identifier) && peek_token&.is_a?(:assign)
      return parse_assignment!
    end
    # simple after
    case current_token.type
    when :str_lit
      parse_str!
    when :nil
      parse_nil!
    when :open_square_bracket
      parse_array!
    when :open_brace
      parse_record!
    when :bang
      parse_bang!
    when :open_parenthesis
      parse_paren_expr!
    when :identifier
      parse_identifier!
    when :property
      parse_property!
    when :open_html_tag
      parse_html_tag!
    when :open_custom_element_tag
      parse_custom_element!
    when :class
      parse_class_definition!
    when :def
      parse_function_def!
    when :do
      parse_anon_function_def!
    when :anon_short_fn_start
      parse_anon_function_shorthand!
    when :anon_short_id
      parse_anon_short_id!
    when :if
      node = parse_if_expression!
      modify_if_statement_for_context node
    when :schema
      parse_schema!
    when :case
      parse_case_expression!
    else
      puts "no match [parse_expr!] :#{type}"
      assert { false }
    end
  end

  def parse_paren_expr!
    token = consume! :open_parenthesis
    expr = parse_expr!
    consume! :close_parenthesis
    node = AST::paren_expr expr, token.position
    parse_id_modifier_if_exists! node
  end

  def parse_id_modifier_if_exists!(sym_expr)
    # TODO: kinda hacky.. :/
    # This is because all the tokens (text nodes)
    # of html child aren't tokenized as raw text
    return sym_expr if expr_context.directly_in_a? :html_tag
    node = case
      when current_token&.is_a?(:assign)
        parse_instance_assignment! sym_expr
      when function_call?(sym_expr)
        parse_function_call! sym_expr
      when end_of_file?
        return sym_expr
      when current_token.is_a?(:open_square_bracket)
        parse_dynamic_lookup! sym_expr
      when current_token.is_a?(:&) && peek_token.is_a?(:open_square_bracket)
        parse_nil_safe_lookup! sym_expr
      when current_token.is_a?(:&) && peek_token.is_a?(:dot)
        parse_nil_safe_call! sym_expr
      when current_token.is_a?(:dot)
        parse_dot_expression! sym_expr
      when current_token.is_a?(:class_property)
        parse_class_properity_expression! sym_expr
      when operator?
        return parse_operator_call! sym_expr
      else
        return sym_expr
      end
    parse_id_modifier_if_exists! node
  end

  def operator?
    current_token.is_one_of?(*OPERATORS) && !expr_context.directly_in_a?(:operator)
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
    id_token = consume! :identifier
    node = parse_function_call! dot(lhs, [id_token.position, id_token.value])
    node = AST::function_call(
      [AST::function([], [AST::return(node)])],
      dot(lhs, "__and__")
    )
  end

  def parse_return!(implicit_return = false)
    return_token = consume! :return unless implicit_return
    expr = parse_expr!
    node = AST::return expr, return_token.position
    if current_token.is_a? :if
      if_token = consume! :if
      cond = parse_expr!
      AST::if(cond, [node], [], if_token.position)
    else
      node
    end
  end

  def parse_instance_assignment!(lhs)
    consume! :assign
    expr_context.push! :assignment
    expr = parse_expr!
    expr_context.pop! :assignment
    AST::instance_assignment lhs, expr
  end

  def parse_assignment!
    id_token = consume! :identifier
    consume! :assign
    expr_context.push! :assignment
    expr = parse_expr!
    expr_context.pop! :assignment
    AST::assignment id_token.value, expr, id_token.position
  end

  def parse_operator_call!(lhs)
    op_token = consume!
    expr_context.push! :operator
    rhs_expr = parse_expr!
    expr_context.pop! :operator
    method_name = OP_TO_METHOD_NAME[op_token.type]
    assert { !method_name.nil? }

    if op_token.is_one_of?(:&, :|)
      operator = dot(schema, [op_token.position, method_name])
      AST::function_call [lhs, rhs_expr], operator, op_token.position
    else
      function = dot(lhs, [op_token.position, method_name])
      node = AST::function_call [rhs_expr], function, op_token.position
      parse_id_modifier_if_exists! node
    end
  end

  def parse_if_body!
    end_tokens = [:end, :else]
    @token_index, body = clone(parser_context: parser_context.push(:if)).parse_with_position! end_tokens
    body
  end

  def parse_if_expression!
    if_token = consume! :if
    check = parse_expr!
    consume! :then if current_token.is_a? :then
    pass_body = parse_if_body!
    if current_token.is_not_a? :else
      consume! :end
      return AST::if check, pass_body, [], if_token.position
    end
    consume! :else
    fail_body = if current_token.is_a? :if
        [parse_if_expression!]
      else
        body = parse_if_body!
        consume! :end
        body
      end
    AST::if check, pass_body, fail_body, if_token.position
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
    elsif expr_context.directly_in_a? :assignment
      # TODO: we shouldn't have to create a function here
      # we could do something similar to insert_return, but insert_assignment
      # but that requires expr_context to store the actual node, not just node_type
      AST::function_call [], AST::function([], [replace_return(if_expr)])
    elsif expr_context.directly_in_a? :html_escaped_expr
      AST::function([], [replace_return(if_expr)])
    elsif parser_context.directly_in_a? :function
      replace_return(if_expr)
    else
      if_expr
    end
  end

  def parse_dot_expression!(lhs)
    dot = consume! :dot
    AST::dot lhs, consume!(:identifier), dot.position
  end

  def parse_class_properity_expression!(lhs)
    position = current_token.position
    AST::dot lhs, consume!(:class_property), position
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
    id = [prev_token.position, id] unless id.is_a?(Array)
    AST::dot lhs, id, prev_token.position
  end

  def function_call(args, expr)
    AST::function_call(args, expr, prev_token.position)
  end
end
