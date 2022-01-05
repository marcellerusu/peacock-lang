ID_TO_STR = {
  dot: ".",
  gt: ">",
  lt: "<",
}

module HTML
  def parse_html_tag!
    line, c, tag_name = consume! :open_html_tag
    attributes = parse_html_attributes!
    children = parse_html_children!
    _, _, close_tag_name = consume! :close_html_tag
    assert { tag_name == close_tag_name }
    AST::html_tag(
      AST::str(tag_name),
      AST::record(attributes),
      AST::array(children),
      line,
      c
    )
  end

  def parse_html_attributes!
    attributes = {}
    while peek_type != :gt # `>` as in capture <div [name="3">] part
      _, _, sym = consume! :identifier
      consume! :declare
      assert { peek_type == :str_lit }
      expr_context.set! :html_tag
      value = parse_lit! :str_lit
      expr_context.unset! :html_tag
      attributes[sym] = value
    end
    consume! :gt
    attributes
  end

  def parse_html_children!
    children = []
    while peek_type != :close_html_tag
      children.push(parse_text_node!) if peek_type == :identifier
      children.push(parse_html_tag!) if peek_type == :open_html_tag
    end
    children
  end

  def parse_text_node!
    text = []
    # TODO: heckin' hack! find a way to consume raw text..
    # maybe I'll have to put this in the lexer somehow..
    # Things to think about..
    while ![:open_html_tag, :close_html_tag].include?(peek_type)
      _, _, word, type = consume!
      text.push(word || ID_TO_STR[type] || type.to_s)
    end
    AST::html_text_node(AST::str(text.join(" ")))
  end
end
