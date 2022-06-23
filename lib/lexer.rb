require "strscan"
require "utils"

module Lexer
  class Token
    attr_reader :pos, :type, :value, :captures
    def self.set_position!(pos)
      @@current_position = pos
    end

    def ==(other)
      type == other.type && value == other.value && captures == other.captures
    end

    def initialize(type, value = nil, captures = nil)
      @pos = @@current_position
      @type = type
      @value = value
      @captures = captures
    end

    def value=(value)
      @value = value
    end

    def is?(type)
      type == @type
    end

    def is_not?(type)
      !is?(type)
    end

    def is_one_of?(*types)
      types.include? @type
    end

    def is_not_one_of?(*types)
      !is_one_of?(*types)
    end
  end

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

  def self.tokenize(program)
    tokens = []
    scanner = StringScanner.new(program)
    while true
      Token.set_position!(scanner.pos)
      case
      when scanner.eos?
        break
      when scanner.scan(/\s+/)
        next
      when scanner.scan(/#\{/)
        tokens.push Token.new(:"#\{")
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
        tokens.push Token.new(:str_lit, str, captures)
      when scanner.scan(/\d+\.\d+/)
        tokens.push Token.new(:float_lit, scanner.matched.to_f)
      when scanner.scan(/\d+/)
        tokens.push Token.new(:int_lit, scanner.matched.to_i)
      when scanner.scan(/_/)
        tokens.push Token.new(:identifier, "_")
      when scanner.scan(/(true|false)\b/)
        tokens.push Token.new(scanner.matched.to_sym)
      when scanner.scan(/nil(?!\?)\b/)
        tokens.push Token.new(:nil)
      when scanner.scan(/<([A-Z][a-zA-Z1-9_]*)/)
        assert { scanner.captures.size == 1 }
        tokens.push Token.new(:open_custom_element_tag, scanner.captures.first)
      when scanner.scan(/<([a-z][a-z1-9_]*)/)
        assert { scanner.captures.size == 1 }
        tokens.push Token.new(:open_html_tag, scanner.captures.first)
      when scanner.scan(/\/>/)
        tokens.push Token.new(:self_close_html_tag)
      when scanner.scan(/<\/([a-z][a-z1-9_]*)>/)
        assert { scanner.captures.size == 1 }
        tokens.push Token.new(:close_html_tag, scanner.captures.first)
      when scanner.scan(/<\/([A-Z][a-z1-9_]*)>/)
        assert { scanner.captures.size == 1 }
        tokens.push Token.new(:close_custom_element_tag, scanner.captures.first)
      when scanner.scan(/self\b/)
        tokens.push Token.new(:self)
      when scanner.scan(/do\b/)
        tokens.push Token.new(:do)
      when scanner.scan(/function\b/)
        tokens.push Token.new(:function)
      when scanner.scan(/for\b/)
        tokens.push Token.new(:for)
      when scanner.scan(/of\b/)
        tokens.push Token.new(:of)
      when scanner.scan(/case\b/)
        tokens.push Token.new(:case)
      when scanner.scan(/when\b/)
        tokens.push Token.new(:when)
      when scanner.scan(/in\b/)
        tokens.push Token.new(:in)
      when scanner.scan(/if\b/)
        tokens.push Token.new(:if)
      when scanner.scan(/unless\b/)
        tokens.push Token.new(:unless)
      when scanner.scan(/else\b/)
        tokens.push Token.new(:else)
      when scanner.scan(/end\b/)
        tokens.push Token.new(:end)
      when scanner.scan(/=>/)
        tokens.push Token.new(:"=>")
      when scanner.scan(/!==/)
        tokens.push Token.new(:"!==")
      when scanner.scan(/===/)
        tokens.push Token.new(:"===")
      when scanner.scan(/\!/)
        tokens.push Token.new(:"!")
      when scanner.scan(/:=/)
        tokens.push Token.new(:assign)
      when scanner.scan(/\(/)
        tokens.push Token.new(:open_paren)
      when scanner.scan(/\)/)
        tokens.push Token.new(:close_paren)
      when scanner.scan(/\{/)
        tokens.push Token.new(:"{")
      when scanner.scan(/\}/)
        tokens.push Token.new(:"}")
      when scanner.scan(/\[/)
        tokens.push Token.new(:"[")
      when scanner.scan(/\]/)
        tokens.push Token.new(:"]")
      when scanner.scan(/\.\.\./)
        tokens.push Token.new(:"...")
      when scanner.scan(/\./)
        tokens.push Token.new(:dot)
      when scanner.scan(/,/)
        tokens.push Token.new(:comma)
      when scanner.scan(/\*/)
        tokens.push Token.new(:*)
      when scanner.scan(/\//)
        tokens.push Token.new(:/)
      when scanner.scan(/\+/)
        tokens.push Token.new(:+)
      when scanner.scan(/\>=/)
        tokens.push Token.new(:">=")
      when scanner.scan(/<=/)
        tokens.push Token.new(:"<=")
      when scanner.scan(/\>/)
        tokens.push Token.new(:>)
      when scanner.scan(/</)
        tokens.push Token.new(:<)
      when scanner.scan(/=/)
        tokens.push Token.new(:"=")
      when scanner.scan(/\|\|/)
        tokens.push Token.new(:"||")
      when scanner.scan(/\|/)
        tokens.push Token.new(:"|")
      when scanner.scan(/&&/)
        tokens.push Token.new(:"&&")
      when scanner.scan(/\|/)
        tokens.push Token.new(:|)
      when scanner.scan(/&/)
        tokens.push Token.new(:&)
      when scanner.scan(/it\b/)
        tokens.push Token.new(:it)
      when scanner.scan(/-/)
        tokens.push Token.new(:-)
      when scanner.scan(/from\b/)
        tokens.push Token.new(:from)
      when scanner.scan(/await\b/)
        tokens.push Token.new(:await)
      when scanner.scan(/import\b/)
        tokens.push Token.new(:import)
      when scanner.scan(/export\b/)
        tokens.push Token.new(:export)
      when scanner.scan(/default\b/)
        tokens.push Token.new(:default)
      when scanner.scan(/return\b/)
        tokens.push Token.new(:return)
      when scanner.scan(/schema\b/)
        tokens.push Token.new(:schema)
      when scanner.scan(/:[a-zA-Z][a-zA-Z0-9\_!?]*/)
        tokens.push Token.new(:capture, scanner.matched[1..])
      when scanner.scan(/:/)
        tokens.push Token.new(:colon)
      when scanner.scan(/[a-zA-Z][a-zA-Z0-9\_!?]*/)
        tokens.push Token.new(:identifier, scanner.matched)
      else
        raise AssertionError
      end
    end
    return tokens
  end
end
