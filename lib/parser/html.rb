module HTML
  def parse_html_tag!
    line = @line
    c, tag_name = consume! :open_html_tag
    _, close_tag_name = consume! :close_html_tag
    assert { tag_name == close_tag_name }
    AST::html_tag tag_name, [], line, c
  end
end
