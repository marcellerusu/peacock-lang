require "lexer"

describe Lexer, "#tokenize" do
  describe "single tokens" do
    it "should tokenize let" do
      res = Lexer.new("let").tokenize
      expect(res).to eq([
        # Line 1, col 0
        [[0, :let]],
      ])
    end

    it "should ignore comments" do
      res = Lexer.new("# let something = ").tokenize
      expect(res).to eq([
        [],
      ])
    end

    it "symbol 'a'" do
      res = Lexer.new("a").tokenize
      expect(res).to eq([
        # Line 1, col 0
        [[0, :identifier, "a"]],
      ])
    end

    it "=" do
      res = Lexer.new("=").tokenize
      expect(res).to eq([
        # Line 1, col 0
        [[0, :assign]],
      ])
    end

    it "30" do
      res = Lexer.new("30").tokenize
      expect(res).to eq([
        # Line 1, col 0
        [[0, :int_lit, 30]],
      ])
    end

    it "30.5" do
      res = Lexer.new("30.5").tokenize
      expect(res).to eq([
        # Line 1, col 0
        [[0, :float_lit, 30.5]],
      ])
    end

    it "\"string 3.0\"" do
      res = Lexer.new("\"string 3.0\"").tokenize
      expect(res).to eq([
        [[0, :str_lit, "string 3.0"]],
      ])
    end
  end

  describe "single-line" do
    it "let a = 3" do
      res = Lexer.new("let a = 3").tokenize
      expect(res).to eq([
        [[0, :let], [4, :identifier, "a"], [6, :assign], [8, :int_lit, 3]],
      ])
    end
    it "let a = 3 == 4.0" do
      res = Lexer.new("let a = 3 == 4.0").tokenize
      expect(res).to eq([
        [[0, :let], [4, :identifier, "a"], [6, :assign], [8, :int_lit, 3], [10, :eq], [13, :float_lit, 4.0]],
      ])
    end
    it "let a = 3 == \"4\"" do
      res = Lexer.new("let a = 3 == \"4\"").tokenize
      expect(res).to eq([
        [[0, :let], [4, :identifier, "a"], [6, :assign], [8, :int_lit, 3], [10, :eq], [13, :str_lit, "4"]],
      ])
    end
    describe "array" do
      it "[1]" do
        res = Lexer.new("[1]").tokenize
        expect(res).to eq([
          [[0, :open_sb], [1, :int_lit, 1], [2, :close_sb]],
        ])
      end
      it "[ 1 ]" do
        res = Lexer.new("[ 1 ]").tokenize
        expect(res).to eq([
          [[0, :open_sb], [2, :int_lit, 1], [4, :close_sb]],
        ])
      end
    end
    describe "record" do
      it "{a: 3}" do
        res = Lexer.new("{a: 3}").tokenize
        expect(res).to eq([
          [[0, :open_b], [1, :identifier, "a"], [2, :colon], [4, :int_lit, 3], [5, :close_b]],
        ])
      end
      it "{   a   :  3, }" do
        res = Lexer.new("{   a   :  3, }").tokenize
        expect(res).to eq([
          [[0, :open_b], [4, :identifier, "a"], [8, :colon], [11, :int_lit, 3], [12, :comma], [14, :close_b]],
        ])
      end
    end
    describe "function" do
      it "let a = x => x * x" do
        res = Lexer.new("let a = x => x * x").tokenize
        expect(res).to eq([
          [[0, :let], [4, :identifier, "a"], [6, :assign], [8, :identifier, "x"], [10, :arrow], [13, :identifier, "x"], [15, :mult], [17, :identifier, "x"]],
        ])
      end
    end
  end

  describe "multi-line" do
  end
end
