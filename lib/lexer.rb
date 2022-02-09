require "strscan"
require "utils"

module Lexer
  def self.get_escaped_part_of_str(str, offset)
    capture_start = i = 0
    num_open_braces = 1
    while true
      case str[i]
      when "#"
        if str[i + 1] == "{"
          assert { false }
        end
      when "{"
        num_open_braces += 1
      when "}"
        num_open_braces -= 1
        if num_open_braces == 0
          return { start: offset + capture_start,
                   end: offset + i,
                   value: str[capture_start...i] }
        end
      end
      i += 1
      assert_not_reached if i >= str.size
    end
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
        next
      when scanner.scan(/"/)
        str = ""
        captures = []
        i = scanner.pos
        while i < program.size
          if program[i..i + 1] == "\#{"
            captures.push Lexer::get_escaped_part_of_str(program[i + 2..], i + 2 - scanner.pos)
            str += program[i..scanner.pos + captures.last[:end]]
            i = scanner.pos + captures.last[:end] + 1
          end
          if program[i] == '"'
            scanner.pos = i + 1
            break
          end
          str += program[i]
          i += 1
        end
        captures = captures.map do |capture|
          { **capture,
            tokens: Lexer::tokenize(capture[:value]) }
        end
        tokens.push [line, column, :str_lit, str, captures]
      when scanner.scan(/\d+\.\d+/)
        tokens.push [line, column, :float_lit, scanner.matched.to_f]
      when scanner.scan(/\d+/)
        tokens.push [line, column, :int_lit, scanner.matched.to_i]
      when scanner.scan(/_/)
        tokens.push [line, column, :identifier, "_"]
      when scanner.scan(/(true|false)\b/)
        tokens.push [line, column, (scanner.matched == "true").to_s.to_sym]
      when scanner.scan(/nil(?!\?)\b/)
        tokens.push [line, column, :nil]
      when scanner.scan(/<([A-Z][a-zA-Z1-9_]*)/)
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
      when scanner.scan(/<\/([A-Z][a-z1-9_]*)>/)
        assert { scanner.captures.size == 1 }
        tokens.push [line, column, :close_custom_element_tag, scanner.captures.first]
      when scanner.scan(/self\b/)
        tokens.push [line, column, :self]
      when scanner.scan(/do\b/)
        tokens.push [line, column, :do]
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
      when scanner.scan(/then\b/)
        tokens.push [line, column, :then]
      when scanner.scan(/end\b/)
        tokens.push [line, column, :end]
      when scanner.scan(/=>/)
        tokens.push [line, column, :"=>"]
      when scanner.scan(/!=/)
        tokens.push [line, column, :"!="]
      when scanner.scan(/==/)
        tokens.push [line, column, :"=="]
      when scanner.scan(/\!/)
        tokens.push [line, column, :bang]
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
        tokens.push [line, column, :*]
      when scanner.scan(/\//)
        tokens.push [line, column, :/]
      when scanner.scan(/\+/)
        tokens.push [line, column, :+]
      when scanner.scan(/\>=/)
        tokens.push [line, column, :">="]
      when scanner.scan(/<=/)
        tokens.push [line, column, :"<="]
      when scanner.scan(/\>/)
        tokens.push [line, column, :>]
      when scanner.scan(/</)
        tokens.push [line, column, :<]
      when scanner.scan(/=/)
        tokens.push [line, column, :"="]
      when scanner.scan(/\|\|/)
        tokens.push [line, column, :"||"]
      when scanner.scan(/\|/)
        tokens.push [line, column, :"|"]
      when scanner.scan(/&&/)
        tokens.push [line, column, :"&&"]
      when scanner.scan(/\|/)
        tokens.push [line, column, :|]
      when scanner.scan(/&/)
        tokens.push [line, column, :&]
      when scanner.scan(/%/)
        tokens.push [line, column, :anon_short_id]
      when scanner.scan(/-/)
        tokens.push [line, column, :-]
      when scanner.scan(/from\b/)
        tokens.push [line, column, :from]
      when scanner.scan(/reduce\b/)
        tokens.push [line, column, :reduce]
      when scanner.scan(/next\b/)
        tokens.push [line, column, :next]
      when scanner.scan(/import\b/)
        tokens.push [line, column, :import]
      when scanner.scan(/export\b/)
        tokens.push [line, column, :export]
      when scanner.scan(/default\b/)
        tokens.push [line, column, :default]
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
