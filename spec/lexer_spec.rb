require "lexer"

describe Lexer, "#tokenize" do
  describe "single tokens" do
    it "should tokenize variable" do
      res = Lexer::tokenize("variable_name!")
      expect(res).to eq([
        Lexer::Token.new("variable_name!", :identifier, "variable_name!"),
      ])
    end

    it "true" do
      res = Lexer::tokenize("true")
      expect(res).to eq([
        Lexer::Token.new("true", :bool_lit, true),
      ])
    end

    it "false" do
      res = Lexer::tokenize("false")
      expect(res).to eq([Lexer::Token.new("false", :bool_lit, false)])
    end

    it "should ignore comments" do
      res = Lexer::tokenize("# something-ok = ")
      expect(res).to eq([])
    end

    it "identifier 'a'" do
      res = Lexer::tokenize("a")
      expect(res).to eq([
        Lexer::Token.new("a", :identifier, "a"),
      ])
    end

    it "=" do
      res = Lexer::tokenize("=")
      expect(res).to eq([
        Lexer::Token.new("=", :"="),
      ])
    end

    it ":=" do
      res = Lexer::tokenize(":=")
      expect(res).to eq([
        Lexer::Token.new(":=", :assign),
      ])
    end

    it "30" do
      res = Lexer::tokenize("30")
      expect(res).to eq([
        Lexer::Token.new("30", :int_lit, 30),
      ])
    end

    it "30.5" do
      res = Lexer::tokenize("30.5")
      expect(res).to eq([
        Lexer::Token.new("30.5", :float_lit, 30.5),
      ])
    end

    it "\"string 3.0\"" do
      res = Lexer::tokenize("\"string 3.0\"")
      expect(res).to eq([
        Lexer::Token.new('"string 3.0"', :str_lit, "string 3.0", []),
      ])
    end

    it "string with space" do
      res = Lexer::tokenize(" \"some string\"")

      expect(res).to eq([
        Lexer::Token.new(' "some string"', :str_lit, "some string", []),
      ])
    end

    it "string with no space at start" do
      res = Lexer::tokenize("\"some string\"")
      expect(res).to eq([
        Lexer::Token.new('"some string', :str_lit, "some string", []),
      ])
    end

    it ":symbol", :i do
      res = Lexer::tokenize(":symbol")
      expect(res).to eq([
        Lexer::Token.new(":symbol", :symbol, "symbol"),
      ])
    end
  end

  describe "single-line" do
    it "a := 3" do
      res = Lexer::tokenize("a := 3")
      expect(res).to eq([
        Lexer::Token.new("a", :identifier, "a"),
        Lexer::Token.new(":=", :assign),
        Lexer::Token.new("3", :int_lit, 3),
      ])
    end
    it "a := 3 === 4.0" do
      res = Lexer::tokenize("a := 3 === 4.0")
      expect(res).to eq([
        Lexer::Token.new("a", :identifier, "a"),
        Lexer::Token.new(":=", :assign),
        Lexer::Token.new("3", :int_lit, 3),
        Lexer::Token.new("===", :"==="),
        Lexer::Token.new("4.0", :float_lit, 4.0),
      ])
    end
    it "a := 3 === \"4\"" do
      res = Lexer::tokenize("a := 3 === \"4\"")
      expect(res).to eq([
        Lexer::Token.new("a", :identifier, "a"),
        Lexer::Token.new(":=", :assign),
        Lexer::Token.new("3", :int_lit, 3),
        Lexer::Token.new("===", :"==="),
        Lexer::Token.new('"4"', :str_lit, "4", []),
      ])
    end
    describe "array" do
      it "[1]" do
        res = Lexer::tokenize("[1]")
        expect(res).to eq([
          Lexer::Token.new("[", :"["),
          Lexer::Token.new("1", :int_lit, 1),
          Lexer::Token.new("]", :"]"),
        ])
      end
      it "[ 1 ]" do
        res = Lexer::tokenize("[ 1 ]")
        expect(res).to eq([
          Lexer::Token.new("[", :"["),
          Lexer::Token.new("1", :int_lit, 1),
          Lexer::Token.new("]", :"]"),
        ])
      end
    end
    describe "record" do
      it "{a: 3}" do
        res = Lexer::tokenize("{a: 3}")
        expect(res).to eq([
          Lexer::Token.new("{", :"{"),
          Lexer::Token.new("a", :identifier, "a"),
          Lexer::Token.new(":", :colon),
          Lexer::Token.new("3", :int_lit, 3),
          Lexer::Token.new("}", :"}"),
        ])
      end
      it "{   a   :  3, }" do
        res = Lexer::tokenize("{   a   :  3, }")
        expect(res).to eq([
          Lexer::Token.new("{", :"{"),
          Lexer::Token.new("a", :identifier, "a"),
          Lexer::Token.new(":", :colon),
          Lexer::Token.new("3", :int_lit, 3),
          Lexer::Token.new(",", :comma),
          Lexer::Token.new("}", :"}"),
        ])
      end
    end
  end
end
