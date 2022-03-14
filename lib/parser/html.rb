ID_TO_STR = {
  dot: ".",
  comma: ",",
  colon: ":",
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
    AST::HtmlTag.new(
      AST::Str.new(open_tag_token.value, open_tag_token.position),
      attributes,
      AST::List.new(children || [], attributes.position),
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
      assert { attributes.does_not_have_sym? "children" }
      attributes.insert_sym!(
        "children",
        AST::List.new(children, close_tag_token.position)
      )
    end
    AST::IdLookup.new(open_tag_token.value, open_tag_token.position)
      .dot("new")
      .call([attributes])
  end

  def parse_html_attributes!
    attributes = AST::Record.new [], AST::List.new([]), current_token.position
    if current_token.is? :self_close_html_tag
      consume! :self_close_html_tag
      return true, attributes
    end
    while current_token.is_not_one_of?(:>, :self_close_html_tag)
      id_token = consume! :identifier
      if current_token.is_not? :"="
        attributes.insert_sym!(
          id_token.value,
          AST::Bool.new(true, id_token.position)
        )
        next
      end
      consume! :"="
      context.push! :html_tag
      value = parse_html_attribute!
      context.pop! :html_tag
      attributes.insert_sym! id_token.value, value
    end
    closing_token = consume!
    return closing_token.is?(:self_close_html_tag), attributes
  end

  def parse_html_attribute!
    case current_token.type
    when :str_lit
      parse_str!
    when :"#\{"
      context.pop! :html_tag
      fn = parse_anon_function_shorthand!
      context.push! :html_tag
      fn
    when :"{"
      context.pop! :html_tag
      consume! :"{"
      val = parse_expr!
      consume! :"}"
      context.push! :html_tag
      val
    else
      assert { false }
    end
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
      when :"{"
        children.push parse_html_expr_node!
      else
        assert { false }
      end
    end
    children
  end

  def parse_html_expr_node!
    consume! :"{"
    context.push! :html_escaped_expr
    expr = parse_expr!
    context.pop! :html_escaped_expr
    consume! :"}"
    expr
  end

  def parse_text_node!
    text = ""
    # TODO: heckin' hack! find a way to consume raw text..
    # maybe I'll have to put this in the lexer somehow..
    # Things to think about..
    # ^^ this is starting to be better
    original_position = current_token.position
    prev_pos = original_position
    while current_token.is_not_one_of?(
      :open_html_tag,
      :open_custom_element_tag,
      :close_custom_element_tag,
      :close_html_tag,
      :"{",
    )
      word_token = consume!
      padding = ""
      padding = " " if word_token.position - prev_pos >= 1
      if word_token.value
        text += padding + word_token.value
        prev_pos = word_token.position + word_token.value.size
      elsif ID_TO_STR[word_token.type]
        id_str = ID_TO_STR[word_token.type]
        text += padding + id_str
        prev_pos = word_token.position + id_str.size
      else
        text += padding + word_token.type.to_s
        prev_pos = word_token.position + word_token.type.to_s.size
      end
    end
    AST::HtmlText.new(AST::Str.new(text, original_position), original_position)
  end
end
