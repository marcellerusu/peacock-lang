require "strscan"
require "utils"

module Lexer
  class Token
    attr_reader :raw_token, :start_pos, :end_pos, :type, :value, :captures
    def self.set_position!(pos)
      @@current_position = pos
    end

    def ==(other)
      type == other.type && value == other.value && captures == other.captures
    end

    def initialize(raw_token, type, value = nil, captures = nil)
      @raw_token = raw_token
      @start_pos = @@current_position
      @end_pos = @start_pos + @raw_token.size
      @type = type
      @value = value
      @captures = captures
    end

    def to_s
      s = "{ type: :#{type}"
      if value
        s += ", value: #{value}"
      end
      s + " }"
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
        tokens.push Token.new(scanner.matched, :"#\{")
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
        tokens.push Token.new("\"#{str}\"", :str_lit, str, captures)
      when scanner.scan(/\d+\.\d+/)
        tokens.push Token.new(scanner.matched, :float_lit, scanner.matched.to_f)
      when scanner.scan(/\d+/)
        tokens.push Token.new(scanner.matched, :int_lit, scanner.matched.to_i)
      when scanner.scan(/_/)
        tokens.push Token.new(scanner.matched, :identifier, "_")
      when scanner.scan(/(true|false)\b/)
        tokens.push Token.new(scanner.matched, :bool_lit, scanner.matched == "true")
      when scanner.scan(/null(?!\?)\b/)
        tokens.push Token.new(scanner.matched, :null)
      when scanner.scan(/undefined(?!\?)\b/)
        tokens.push Token.new(scanner.matched, :undefined)
      when scanner.scan(/this\b/)
        tokens.push Token.new(scanner.matched, :this)
      when scanner.scan(/new\b/)
        tokens.push Token.new(scanner.matched, :new)
      when scanner.scan(/static\b/)
        tokens.push Token.new(scanner.matched, :static)
      when scanner.scan(/do\b/)
        tokens.push Token.new(scanner.matched, :do)
      when scanner.scan(/function\b/)
        tokens.push Token.new(scanner.matched, :function)
      when scanner.scan(/class\b/)
        tokens.push Token.new(scanner.matched, :class)
      when scanner.scan(/get\b/)
        tokens.push Token.new(scanner.matched, :get)
      when scanner.scan(/for\b/)
        tokens.push Token.new(scanner.matched, :for)
      when scanner.scan(/of\b/)
        tokens.push Token.new(scanner.matched, :of)
      when scanner.scan(/case\b/)
        tokens.push Token.new(scanner.matched, :case)
      when scanner.scan(/when\b/)
        tokens.push Token.new(scanner.matched, :when)
      when scanner.scan(/assert\b/)
        tokens.push Token.new(scanner.matched, :assert)
      when scanner.scan(/component\b/)
        tokens.push Token.new(scanner.matched, :component)
      when scanner.scan(/in\b/)
        tokens.push Token.new(scanner.matched, :in)
      when scanner.scan(/instanceof\b/)
        tokens.push Token.new(scanner.matched, :instanceof)
      when scanner.scan(/if\b/)
        tokens.push Token.new(scanner.matched, :if)
      when scanner.scan(/unless\b/)
        tokens.push Token.new(scanner.matched, :unless)
      when scanner.scan(/else\b/)
        tokens.push Token.new(scanner.matched, :else)
      when scanner.scan(/end\b/)
        tokens.push Token.new(scanner.matched, :end)
      when scanner.scan(/<\//)
        tokens.push Token.new(scanner.matched, :"</")
      when scanner.scan(/=>/)
        tokens.push Token.new(scanner.matched, :"=>")
      when scanner.scan(/!==/)
        tokens.push Token.new(scanner.matched, :"!==")
      when scanner.scan(/===/)
        tokens.push Token.new(scanner.matched, :"===")
      when scanner.scan(/\!/)
        tokens.push Token.new(scanner.matched, :"!")
      when scanner.scan(/@/)
        tokens.push Token.new(scanner.matched, :"@")
      when scanner.scan(/:=/)
        tokens.push Token.new(scanner.matched, :assign)
      when scanner.scan(/\(/)
        tokens.push Token.new(scanner.matched, :open_paren)
      when scanner.scan(/\)/)
        tokens.push Token.new(scanner.matched, :close_paren)
      when scanner.scan(/\{/)
        tokens.push Token.new(scanner.matched, :"{")
      when scanner.scan(/\}/)
        tokens.push Token.new(scanner.matched, :"}")
      when scanner.scan(/\[/)
        tokens.push Token.new(scanner.matched, :"[")
      when scanner.scan(/\]/)
        tokens.push Token.new(scanner.matched, :"]")
      when scanner.scan(/\.\.\./)
        tokens.push Token.new(scanner.matched, :"...")
      when scanner.scan(/\?\./)
        tokens.push Token.new(scanner.matched, :"?.")
      when scanner.scan(/::/)
        tokens.push Token.new(scanner.matched, :"::")
      when scanner.scan(/\./)
        tokens.push Token.new(scanner.matched, :dot)
      when scanner.scan(/,/)
        tokens.push Token.new(scanner.matched, :comma)
      when scanner.scan(/\*/)
        tokens.push Token.new(scanner.matched, :*)
      when scanner.scan(/\//)
        tokens.push Token.new(scanner.matched, :/)
      when scanner.scan(/\+/)
        tokens.push Token.new(scanner.matched, :+)
      when scanner.scan(/\>=/)
        tokens.push Token.new(scanner.matched, :">=")
      when scanner.scan(/<=/)
        tokens.push Token.new(scanner.matched, :"<=")
      when scanner.scan(/\>/)
        tokens.push Token.new(scanner.matched, :>)
      when scanner.scan(/</)
        tokens.push Token.new(scanner.matched, :<)
      when scanner.scan(/=/)
        tokens.push Token.new(scanner.matched, :"=")
      when scanner.scan(/\|\|/)
        tokens.push Token.new(scanner.matched, :"||")
      when scanner.scan(/&&/)
        tokens.push Token.new(scanner.matched, :"&&")
      when scanner.scan(/\|/)
        tokens.push Token.new(scanner.matched, :|)
      when scanner.scan(/&/)
        tokens.push Token.new(scanner.matched, :&)
      when scanner.scan(/it\b/)
        tokens.push Token.new(scanner.matched, :it)
      when scanner.scan(/-/)
        tokens.push Token.new(scanner.matched, :-)
      when scanner.scan(/await\b/)
        tokens.push Token.new(scanner.matched, :await)
      when scanner.scan(/import\b/)
        tokens.push Token.new(scanner.matched, :import)
      when scanner.scan(/export\b/)
        tokens.push Token.new(scanner.matched, :export)
      when scanner.scan(/default\b/)
        tokens.push Token.new(scanner.matched, :default)
      when scanner.scan(/return\b/)
        tokens.push Token.new(scanner.matched, :return)
      when scanner.scan(/schema\b/)
        tokens.push Token.new(scanner.matched, :schema)
      when scanner.scan(/:[a-zA-Z][a-zA-Z0-9\_!]*/)
        tokens.push Token.new(scanner.matched, :capture, scanner.matched[1..])
      when scanner.scan(/:/)
        tokens.push Token.new(scanner.matched, :colon)
      when scanner.scan(/[a-zA-Z][a-zA-Z0-9\_!]*/)
        tokens.push Token.new(scanner.matched, :identifier, scanner.matched)
      else
        raise AssertionError
      end
    end
    return tokens
  end
end
