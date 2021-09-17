require "token"

describe Token, "#peek_rest_of_token" do
  it "should tokenize let" do
    t = Token.new("l", "let", 0)
    expect(t.peek_rest_of_token).to eq(Token.new("let", nil, nil))
  end

  it "should tokenize let including space" do
    t = Token.new("l", "let a", 0)
    expect(t.peek_rest_of_token).to eq(Token.new("let", nil, nil))
  end
end
