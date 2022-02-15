ID_TO_STR = {
  dot: ".",
}

module HTML
  def parse_html_tag!
    open_tag_token = consume! :open_html_tag
    self_closed, attributes = parse_html_attributes!

    if !self_closed
      children = parse_html_children!
      close_tag_token = consume! :close_html_tag
      assert { open_tag_token.value == close_tag_token.value }
    end
    AST::html_tag(
      AST::str(open_tag_token.value),
      AST::record(attributes),
      AST::array(children || []),
      open_tag_token.position
    )
  end

  def parse_custom_element!
    open_tag_token = consume! :open_custom_element_tag
    self_closed, attributes = parse_html_attributes!
    if !self_closed
      children = parse_html_children!
      close_tag_token = consume! :close_custom_element_tag
      assert { open_tag_token.value == close_tag_token.value }
      assert { !attributes.has_key?(AST::sym("children")) }
      attributes[AST::sym("children")] = AST::array(children)
    end
    AST::function_call(
      [AST::record(attributes)],
      AST::dot(
        AST::identifier_lookup(open_tag_token.value, open_tag_token.position),
        "new"
      ),
      open_tag_token.position
    )
  end

  def parse_html_attributes!
    if current_token.is_a? :self_close_html_tag
      consume! :self_close_html_tag
      return true, {}
    end
    attributes = {}
    while current_token.is_not_one_of?(:>, :self_close_html_tag)
      id_token = consume! :identifier
      if current_token.is_not_a? :"="
        attributes[AST::sym(id_token.value)] = AST::bool(true)
        next
      end
      consume! :"="
      expr_context.push! :html_tag
      value = case current_token.type
        when :str_lit
          parse_lit! :str_lit
        when :anon_short_fn_start
          expr_context.pop! :html_tag
          fn = parse_anon_function_shorthand!
          expr_context.push! :html_tag
          fn
        when :open_brace
          expr_context.pop! :html_tag
          consume! :open_brace
          val = parse_expr!
          consume! :close_brace
          expr_context.push! :html_tag
          val
        else
          assert { false }
        end
      expr_context.pop! :html_tag
      attributes[AST::sym(id_token.value)] = value
    end
    closing_token = consume!
    return closing_token.is_a?(:self_close_html_tag), attributes
  end

  def parse_html_children!
    children = []
    while current_token.is_not_one_of?(:close_html_tag, :close_custom_element_tag)
      case current_token.type
      when :identifier
        children.push parse_text_node!
      when :open_custom_element_tag
        children.push parse_custom_element!
      when :open_html_tag
        children.push parse_html_tag!
      when :open_brace
        children.push parse_html_expr_node!
      else
        assert { false }
      end
    end
    children
  end

  def parse_html_expr_node!
    consume! :open_brace
    expr_context.push! :html_escaped_expr
    expr = parse_expr!
    expr_context.pop! :html_escaped_expr
    consume! :close_brace
    expr
  end

  def parse_text_node!
    text = ""
    # TODO: heckin' hack! find a way to consume raw text..
    # maybe I'll have to put this in the lexer somehow..
    # Things to think about..
    # ^^ this is starting to be better
    prev_c = current_token.position
    while current_token.is_not_one_of?(
      :open_html_tag,
      :open_custom_element_tag,
      :close_custom_element_tag,
      :close_html_tag,
      :open_brace,
    )
      word_token = consume!
      padding = ""
      padding = " " if word_token.position - prev_c >= 1
      if word_token.value
        text += padding + word_token.value
        prev_c = word_token.position + word_token.value.size
      elsif ID_TO_STR[word_token.type]
        id_str = ID_TO_STR[word_token.type]
        text += padding + id_str
        prev_c = word_token.position + id_str.size
      else
        text += padding + word_token.type.to_s
        prev_c = word_token.position + word_token.type.to_s.size
      end
    end
    AST::html_text_node(AST::str(text))
  end
end
