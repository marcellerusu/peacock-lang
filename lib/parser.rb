require "utils"
require "ast"
require "parser/literals"
require "parser/helpers"
require "parser/functions"
require "parser/schemas"
require "parser/html"
require "parser/modules"

OPERATORS = [:+, :-, :*, :/, :in, :"&&", :"||", :"==", :"!=", :>, :<, :">=", :"<="]

ANON_SHORTHAND_ID = "__ANON_SHORT_ID"

class Parser
  include Functions
  include Helpers
  include Literals
  include Schemas
  include HTML
  include Modules

  def initialize(tokens, program_string, token_index = 0, context = nil)
    @tokens = tokens
    @program_string = program_string
    @token_index = token_index
    @context = context
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

  def clone(tokens: nil, program_string: nil, token_index: nil, context: nil)
    Parser.new(
      tokens || @tokens,
      program_string || @program_string,
      token_index || @token_index,
      context || @context
    )
  end

  def context
    @context ||= Context.new
  end

  def parse!
    _, @ast = parse_with_position!
    return @ast
  end

  def parse_with_position!(*end_tokens)
    @ast = []
    while more_tokens? && current_token.is_not?(:end)
      break if current_token.is_one_of?(*end_tokens)
      case current_token.type
      when :export
        @ast.push parse_export!
      when :import
        @ast.push parse_import!
      when :return
        assert { context.directly_in_a?(:function) }
        @ast.push parse_return!
      else
        @ast.push parse_expr!
      end
    end

    wrap_last_expr_in_return!

    return @token_index, @ast
  end

  def wrap_last_expr_in_return!
    return if !context.directly_in_a?(:function)
    return if !@ast.last.is_not_one_of?(AST::Return, AST::If)

    @ast[-1] = @ast[-1].to_return
  end

  # Parsing begins!

  def parse_expr!
    # more complex conditions first
    if current_token.is_one_of?(:true, :false)
      return parse_bool! current_token.type
    elsif current_token.is?(:identifier) && peek_token&.is?(:assign)
      return parse_assignment!
    elsif arrow_function?
      return parse_arrow_function!
    elsif paren_expr?
      return parse_paren_expr!
    end
    # simple after
    case current_token.type
    when :int_lit
      node = parse_int!
    when :float_lit
      parse_float!
    when :str_lit
      parse_str!
    when :nil
      parse_nil!
    when :"["
      parse_array_literal!
    when :"{"
      parse_object_literal!
    when :"!"
      parse_bang!
    when :identifier
      parse_identifier!
    when :property
      parse_property!
    when :open_html_tag
      parse_html_tag!
    when :open_custom_element_tag
      parse_custom_element!
    when :def
      parse_function_def!
    when :do
      parse_anon_function_def!
    when :"#\{"
      parse_anon_function_shorthand!
    when :%
      parse_anon_short_id!
    when :if
      node = parse_if_expression!
      modify_if_statement_for_context! node
    when :schema
      parse_schema!
    when :case
      parse_case_expression!
    else
      # binding.pry
      assert { false }
    end
  end

  def paren_expr?
    current_token.is?(:open_paren)
  end

  def parse_paren_expr!
    token = consume! :open_paren
    context.push! :paren
    expr = parse_expr!
    context.pop! :paren
    consume! :close_paren
    node = AST::ParenExpr.new expr, token.position
    parse_id_modifier_if_exists! node
  end

  def parse_id_modifier_if_exists!(expr)
    # TODO: kinda hacky.. :/
    # This is because all the tokens (text nodes)
    # of html child aren't tokenized as raw text
    return expr if context.directly_in_a? :html_tag
    node = case
      when function_call?(expr)
        parse_function_call! expr
      when end_of_file?
        return expr
      when current_token.is?(:"[") && !new_line?
        parse_dynamic_lookup! expr
      when current_token.is?(:&) && peek_token.is?(:"[")
        parse_nil_safe_lookup! expr
      when current_token.is?(:&) && peek_token.is?(:dot)
        parse_nil_safe_call! expr
      when current_token.is?(:dot)
        parse_dot_expression! expr
      when operator?
        return parse_operator_call! expr
      else
        return expr
      end

    return node if node == expr
    parse_id_modifier_if_exists! node
  end

  def operator?
    current_token.is_one_of?(*OPERATORS) && !context.directly_in_a?(:operator)
  end

  # Individual parsers

  def parse_nil_safe_lookup!(lhs)
    and_t = consume! :&
    consume! :"["
    expr = parse_expr!
    consume! :"]"
    assert { false }
    AST::AndDot.new(lhs, expr)
  end

  def parse_nil_safe_call!(lhs)
    and_t = consume! :&
    consume! :dot
    id_token = consume! :identifier
    node = parse_function_call! lhs.dot(id_token.value, id_token.position)
    node = AST::AndDot.new(lhs, node)
  end

  def parse_return!(implicit_return = false)
    return_token = consume! :return unless implicit_return
    expr = parse_expr!
    node = AST::Return.new expr, return_token.position
    if current_token.is? :if
      if_token = consume! :if
      cond = parse_expr!
      AST::If.new(cond, [node], [], if_token.position)
    else
      node
    end
  end

  def parse_assignment!
    id_token = consume! :identifier
    consume! :assign
    context.push! :assignment
    expr = parse_expr!
    context.pop! :assignment
    AST::Assign.new id_token.value, expr, id_token.position
  end

  def parse_operator_call!(lhs)
    op_token = consume!
    context.push! :operator
    rhs = parse_expr!
    context.pop! :operator

    method_name = op_token.type.to_s
    assert { !method_name.nil? }

    node = case op_token.type
      when :+
        AST::Add.new(lhs, rhs, op_token.position)
      when :-
        AST::Minus.new(lhs, rhs, op_token.position)
      when :*
        AST::Multiply.new(lhs, rhs, op_token.position)
      when :/
        AST::Divide.new(lhs, rhs, op_token.position)
      when :"&&"
        AST::AndAnd.new(lhs, rhs, op_token.position)
      when :"||"
        AST::OrOr.new(lhs, rhs, op_token.position)
      when :"=="
        AST::EqEq.new(lhs, rhs, op_token.position)
      when :"!="
        AST::NotEq.new(lhs, rhs, op_token.position)
      when :>
        AST::Gt.new(lhs, rhs, op_token.position)
      when :<
        AST::Lt.new(lhs, rhs, op_token.position)
      when :">="
        AST::GtEq.new(lhs, rhs, op_token.position)
      when :"<="
        AST::LtEq.new(lhs, rhs, op_token.position)
      when :in
        AST::In.new(lhs, rhs, op_token.position)
      else
        assert { false }
      end
    parse_id_modifier_if_exists! node
  end

  def parse_if_body!
    @token_index, body = clone(context: context.push(:if)).parse_with_position! :end, :else
    body
  end

  def parse_if_expression!
    if_token = consume! :if
    check = parse_expr!
    consume! :then if current_token.is? :then
    pass_body = parse_if_body!
    if current_token.is_not? :else
      consume! :end
      return AST::If.new check, pass_body, [], if_token.position
    end
    consume! :else
    fail_body = if current_token.is? :if
        [parse_if_expression!]
      else
        body = parse_if_body!
        consume! :end
        body
      end
    AST::If.new check, pass_body, fail_body, if_token.position
  end

  def insert_return!(body)
    return body if body.size == 0
    return body if body.last.is_a? AST::Return
    body[-1] = body[-1].to_return
    body
  end

  def modify_if_statement_for_context!(if_expr)
    def replace_return!(if_expr)
      insert_return!(if_expr.pass)
      insert_return!(if_expr.fail)
      if_expr
    end

    if context.directly_in_a? :str
      assert { !if_expr.has_return? }
      replace_return!(if_expr).wrap_in_fn.call
    elsif context.directly_in_a? :assignment
      # TODO: we shouldn't have to create a function here
      # we could do something similar to insert_return!, but insert_assignment
      # but that requires context to store the actual node, not just node_type
      replace_return!(if_expr).wrap_in_fn.call
    elsif context.directly_in_a? :html_escaped_expr
      replace_return!(if_expr).wrap_in_fn
    elsif context.directly_in_a? :function
      replace_return!(if_expr)
    else
      if_expr
    end
  end

  def parse_dot_expression!(lhs)
    dot = consume! :dot
    token = consume!(:identifier)
    lhs.dot(token.value, token.position)
  end

  def parse_dynamic_lookup!(lhs)
    consume! :"["
    expr = parse_expr!
    consume! :"]"
    lhs.lookup(expr)
  end
end
