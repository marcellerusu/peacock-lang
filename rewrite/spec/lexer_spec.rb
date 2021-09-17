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
        [[0, :sym, "a"]],
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
  end

  describe "single-line" do
    it "let a = 3" do
      res = Lexer.new("let a = 3").tokenize
      expect(res).to eq([
        [[0, :let], [4, :sym, "a"], [6, :assign], [8, :int_lit, 3]],
      ])
    end
    it "let a = 3 == 4" do
      res = Lexer.new("let a = 3 == 4.0").tokenize
      expect(res).to eq([
        [[0, :let], [4, :sym, "a"], [6, :assign], [8, :int_lit, 3], [10, :eq], [13, :float_lit, 4.0]],
      ])
    end
  end

  describe "multi-line" do
  end
end
