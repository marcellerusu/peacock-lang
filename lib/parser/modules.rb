require "lexer"
require "digest"

module Modules
  def parse_import!
    import = consume! :import
    context.push! :schema
    pattern = parse_expr!
    context.pop! :schema
    consume! :from
    file_name_token = consume! :str_lit
    assert { file_name_token.captures.size == 0 }
    file_name = file_name_token.value
    file_name = "#{file_name}.pea" if !file_name.end_with? ".pea"
    AST::Import.new(pattern, file_name, import.position)
  end

  def parse_export!
    export = consume! :export
    expr = parse_expr!
    assert { expr.exportable? }
    AST::Export.new(expr, export.position)
  end
end
