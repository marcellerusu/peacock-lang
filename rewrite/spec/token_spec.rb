require "token"

describe Token, "#peek_rest_of_token" do
  it "should tokenize let" do
    t = Token.new("l", "let", 0)
    expect(t.peek_rest_of_token.token).to eq("let")
  end

  it "should tokenize let including space" do
    t = Token.new("l", "let a", 0)
    expect(t.peek_rest_of_token.token).to eq("let")
  end

  it "should tokenize token" do
    t = Token.new("\"s", "\"some string\"", 0)
    expect(t.peek_rest_of_token.token).to eq("\"some string\"")
  end
end
