require "strscan"
require "utils"

module Lexer
  def self.str_find_escaped_sections(str)
    return [] if str.index('#{').nil?
    capture_start = i = str.index('#{') + 2

    last_index = str.size - str.reverse.index("}") - 1
    num_open_braces = 0
    captures = []
    while i <= last_index
      case str[i]
      when "#"
        if str[i + 1] == "{"
          assert { capture_start.nil? }
          num_open_braces = 0
          i += 1
          capture_start = i + 1
        end
      when "{"
        num_open_braces += 1
      when "}"
        if num_open_braces == 0 && !capture_start.nil?
          captures.push({
            start: capture_start,
            end: i,
            value: str[capture_start...i],
          })
          capture_start = nil
        else
          num_open_braces -= 1
        end
      end
      i += 1
    end

    captures
  end

  def self.pos_to_line_and_column(pos, program)
    i = 0
    line = 0
    column = 0
    while i < pos
      if program[i] == "\n"
        line += 1
        column = 0
      end
      column += 1
      i += 1
    end
    return line, column
  end

  def self.tokenize(program)
    tokens = []
    scanner = StringScanner.new(program)
    while true
      line, column = Lexer::pos_to_line_and_column(scanner.pos, program)
      case
      when scanner.eos?
        break
      when scanner.scan(/\s+/)
        next
      when scanner.scan(/#\{/)
        tokens.push [line, column, :anon_short_fn_start]
      when scanner.scan(/#.*/)
        break
      when scanner.scan(/"((.|\n)+?)"/)
        str = scanner.captures[0]
        escaped = Lexer::str_find_escaped_sections(str)
        escaped = escaped.map do |capture|
          # TODO: the line & column numbers of :tokens will be off - always 0, 0
          { **capture, tokens: Lexer::tokenize(capture[:value]) }
        end
        tokens.push [line, column, :str_lit, str, escaped]
      when scanner.scan(/\d+\.\d+/)
        tokens.push [line, column, :float_lit, scanner.matched.to_f]
      when scanner.scan(/\d+/)
        tokens.push [line, column, :int_lit, scanner.matched.to_i]
      when scanner.scan(/(true|false)\b/)
        tokens.push [line, column, (scanner.matched == "true").to_s.to_sym]
      when scanner.scan(/nil(?!\?)\b/)
        tokens.push [line, column, :nil]
      when scanner.scan(/<([A-Z][a-z1-9_]*)/)
        assert { scanner.captures.size == 1 }
        tokens.push [line, column, :open_custom_element_tag, scanner.captures.first]
      when scanner.scan(/<([a-z][a-z1-9_]*)/)
        assert { scanner.captures.size == 1 }
        tokens.push [line, column, :open_html_tag, scanner.captures.first]
      when scanner.scan(/\/>/)
        tokens.push [line, column, :self_close_html_tag]
      when scanner.scan(/<\/([a-z][a-z1-9_]*)>/)
        assert { scanner.captures.size == 1 }
        tokens.push [line, column, :close_html_tag, scanner.captures.first]
      when scanner.scan(/self\b/)
        tokens.push [line, column, :self]
      when scanner.scan(/fn\b/)
        tokens.push [line, column, :fn]
      when scanner.scan(/case\b/)
        tokens.push [line, column, :case]
      when scanner.scan(/of\b/)
        tokens.push [line, column, :of]
      when scanner.scan(/if\b/)
        tokens.push [line, column, :if]
      when scanner.scan(/unless\b/)
        tokens.push [line, column, :unless]
      when scanner.scan(/else\b/)
        tokens.push [line, column, :else]
      when scanner.scan(/end\b/)
        tokens.push [line, column, :end]
      when scanner.scan(/=>/)
        tokens.push [line, column, :arrow]
      when scanner.scan(/==/)
        tokens.push [line, column, :eq]
      when scanner.scan(/:=/)
        tokens.push [line, column, :assign]
      when scanner.scan(/\(/)
        tokens.push [line, column, :open_parenthesis]
      when scanner.scan(/\)/)
        tokens.push [line, column, :close_parenthesis]
      when scanner.scan(/\{/)
        tokens.push [line, column, :open_brace]
      when scanner.scan(/\}/)
        tokens.push [line, column, :close_brace]
      when scanner.scan(/\[/)
        tokens.push [line, column, :open_square_bracket]
      when scanner.scan(/\]/)
        tokens.push [line, column, :close_square_bracket]
      when scanner.scan(/\./)
        tokens.push [line, column, :dot]
      when scanner.scan(/,/)
        tokens.push [line, column, :comma]
      when scanner.scan(/\*/)
        tokens.push [line, column, :mult]
      when scanner.scan(/\//)
        tokens.push [line, column, :div]
      when scanner.scan(/\+/)
        tokens.push [line, column, :plus]
      when scanner.scan(/\>=/)
        tokens.push [line, column, :gt_eq]
      when scanner.scan(/<=/)
        tokens.push [line, column, :lt_eq]
      when scanner.scan(/\>/)
        tokens.push [line, column, :gt]
      when scanner.scan(/</)
        tokens.push [line, column, :lt]
      when scanner.scan(/=/)
        tokens.push [line, column, :declare]
      when scanner.scan(/\|\|/)
        tokens.push [line, column, :or]
      when scanner.scan(/&&/)
        tokens.push [line, column, :and]
      when scanner.scan(/\|/)
        tokens.push [line, column, :schema_or]
      when scanner.scan(/&/)
        tokens.push [line, column, :schema_and]
      when scanner.scan(/%/)
        tokens.push [line, column, :anon_short_id]
      when scanner.scan(/-/)
        tokens.push [line, column, :minus]
      when scanner.scan(/from\b/)
        tokens.push [line, column, :from]
      when scanner.scan(/to\b/)
        tokens.push [line, column, :to]
      when scanner.scan(/reduce\b/)
        tokens.push [line, column, :reduce]
      when scanner.scan(/next\b/)
        tokens.push [line, column, :next]
      when scanner.scan(/break\b/)
        tokens.push [line, column, :break]
      when scanner.scan(/module\b/)
        tokens.push [line, column, :module]
      when scanner.scan(/class\b/)
        tokens.push [line, column, :class]
      when scanner.scan(/return\b/)
        tokens.push [line, column, :return]
      when scanner.scan(/schema\b/)
        tokens.push [line, column, :schema]
      when scanner.scan(/::[a-zA-Z][a-zA-Z1-9\_!?]*/)
        tokens.push [line, column, :class_property, scanner.matched[2..]]
      when scanner.scan(/@[a-zA-Z][a-zA-Z1-9\_!?]*/)
        tokens.push [line, column, :property, scanner.matched[1..]]
      when scanner.scan(/:[a-zA-Z][a-zA-Z1-9\_!?]*/)
        tokens.push [line, column, :symbol, scanner.matched[1..]]
      when scanner.scan(/:/)
        tokens.push [line, column, :colon]
      when scanner.scan(/[a-zA-Z][a-zA-Z1-9\_!?]*/)
        tokens.push [line, column, :identifier, scanner.matched]
      else
        raise AssertionError
      end
    end
    return tokens
  end
end
