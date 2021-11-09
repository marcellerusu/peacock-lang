require "lexer"

describe Lexer, "#tokenize" do
  describe "single tokens" do
    it "should tokenize variable" do
      res = Lexer::tokenize("variable_name!")
      expect(res).to eq([
        # Line 1, col 0
        [[0, :identifier, "variable_name!"]],
      ])
    end

    it "true" do
      res = Lexer::tokenize("true")
      expect(res).to eq([
        # Line 1, col 0
        [[0, :true]],
      ])
    end

    it "false" do
      res = Lexer::tokenize("false")
      expect(res).to eq([
        # Line 1, col 0
        [[0, :false]],
      ])
    end

    it "should ignore comments" do
      res = Lexer::tokenize("# something-ok = ")
      expect(res).to eq([
        [],
      ])
    end

    it "identifier 'a'" do
      res = Lexer::tokenize("a")
      expect(res).to eq([
        # Line 1, col 0
        [[0, :identifier, "a"]],
      ])
    end

    it "=" do
      res = Lexer::tokenize("=")
      expect(res).to eq([
        # Line 1, col 0
        [[0, :declare]],
      ])
    end

    it ":=" do
      res = Lexer::tokenize(":=")
      expect(res).to eq([
        # Line 1, col 0
        [[0, :assign]],
      ])
    end

    it "30" do
      res = Lexer::tokenize("30")
      expect(res).to eq([
        # Line 1, col 0
        [[0, :int_lit, 30]],
      ])
    end

    it "30.5" do
      res = Lexer::tokenize("30.5")
      expect(res).to eq([
        # Line 1, col 0
        [[0, :float_lit, 30.5]],
      ])
    end

    it "\"string 3.0\"" do
      res = Lexer::tokenize("\"string 3.0\"")
      expect(res).to eq([
        [[0, :str_lit, "string 3.0"]],
      ])
    end

    it "string with space" do
      res = Lexer::tokenize(" \"some string\"")
      expect(res).to eq([
        [[1, :str_lit, "some string"]],
      ])
    end

    # TODO: fix
    it "string with no space at start" do
      res = Lexer::tokenize("\"some string\"")
      expect(res).to eq([
        [[0, :str_lit, "some string"]],
      ])
    end

    it ":symbol" do
      res = Lexer::tokenize(":symbol")
      expect(res).to eq([
        # Line 1, col 0
        [[0, :symbol, "symbol"]],
      ])
    end
  end

  describe "single-line" do
    it "a := 3" do
      res = Lexer::tokenize("a := 3")
      expect(res).to eq([
        [[0, :identifier, "a"], [2, :assign], [5, :int_lit, 3]],
      ])
    end
    it "a := 3 == 4.0" do
      res = Lexer::tokenize("a := 3 == 4.0")
      expect(res).to eq([
        [[0, :identifier, "a"], [2, :assign], [5, :int_lit, 3], [7, :eq], [10, :float_lit, 4.0]],
      ])
    end
    it "a := 3 == \"4\"" do
      res = Lexer::tokenize("a := 3 == \"4\"")
      expect(res).to eq([
        [[0, :identifier, "a"], [2, :assign], [5, :int_lit, 3], [7, :eq], [10, :str_lit, "4"]],
      ])
    end
    describe "array" do
      it "[1]" do
        res = Lexer::tokenize("[1]")
        expect(res).to eq([
          [[0, :open_square_bracket], [1, :int_lit, 1], [2, :close_square_bracket]],
        ])
      end
      it "[ 1 ]" do
        res = Lexer::tokenize("[ 1 ]")
        expect(res).to eq([
          [[0, :open_square_bracket], [2, :int_lit, 1], [4, :close_square_bracket]],
        ])
      end
    end
    describe "record" do
      it "{a: 3}" do
        res = Lexer::tokenize("{a: 3}")
        expect(res).to eq([
          [[0, :open_brace], [1, :identifier, "a"], [2, :colon], [4, :int_lit, 3], [5, :close_brace]],
        ])
      end
      it "{   a   :  3, }" do
        res = Lexer::tokenize("{   a   :  3, }")
        expect(res).to eq([
          [[0, :open_brace], [4, :identifier, "a"], [8, :colon], [11, :int_lit, 3], [12, :comma], [14, :close_brace]],
        ])
      end
    end
    describe "function" do
      it "a x = x * x" do
        res = Lexer::tokenize("a x = x * x")
        expect(res).to eq([
          [[0, :identifier, "a"], [2, :identifier, "x"], [4, :declare], [6, :identifier, "x"], [8, :mult], [10, :identifier, "x"]],
        ])
      end
    end
  end

  describe "multi-line" do
  end
end
