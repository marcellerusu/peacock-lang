class NotReached extends Error {
  constructor(...artifacts) {
    console.log(...artifacts);
    super();
  }
}

class StringScanner {
  index = 0;
  matched = null;
  groups = [];
  constructor(str) {
    this.str = str;
  }

  scan(regex) {
    const result = this.rest_of_str().match(regex);
    if (result === null || result.index !== 0) return false;
    const [matched, ...groups] = Array.from(result);
    this.index += matched.length;
    this.matched = matched;
    this.groups = groups;
    return true;
  }

  rest_of_str() {
    return this.str.slice(this.index);
  }

  is_end_of_str() {
    return this.index >= this.str.length;
  }
}

class Token {
  constructor(value) {
    this.value = value;
  }
  is(TokenType) {
    return this instanceof TokenType;
  }
}
class ValueToken extends Token {}
class IdentifierToken extends Token {}
class OpenBrace extends Token {}
class CloseBrace extends Token {}
class Ampersand extends Token {}
class PseudoClass extends Token {}

const tokenize = (str) => {
  const tokens = [];
  const scanner = new StringScanner(str);
  while (!scanner.is_end_of_str()) {
    if (scanner.scan(/\s+/)) {
      continue;
    } else if (scanner.scan(/&/)) {
      tokens.push(new Ampersand());
    } else if (scanner.scan(/:([a-z]+)/)) {
      tokens.push(new PseudoClass(scanner.groups[0]));
    } else if (scanner.scan(/:(\s)*(.*);/)) {
      tokens.push(new ValueToken(scanner.groups[1]));
    } else if (scanner.scan(/([a-z][a-z1-9\-]*|\*)/)) {
      tokens.push(new IdentifierToken(scanner.matched));
    } else if (scanner.scan(/\{/)) {
      tokens.push(new OpenBrace());
    } else if (scanner.scan(/\}/)) {
      tokens.push(new CloseBrace());
    } else {
      throw new NotReached([scanner.index, scanner.rest_of_str()]);
    }
  }
  return tokens;
};

class TokenMismatch extends Error {
  constructor(expected, got) {
    super(`expected - ${expected.name}, got - ${got.constructor.name}`);
  }
}

class AstNode {}
class RuleNode extends AstNode {
  constructor(name, value) {
    super();
    this.name = name;
    this.value = value;
  }
}
class ChildSelectorNode extends AstNode {
  constructor(tag_name, rules) {
    super();
    this.tag_name = tag_name;
    this.rules = rules;
  }
}

class PseudoSelectorNode extends AstNode {
  constructor(selector, rules) {
    super();
    this.selector = selector;
    this.rules = rules;
  }
}

class Parser {
  constructor(tokens, index = 0, end_token = null) {
    this.tokens = tokens;
    this.index = index;
    this.end_token = end_token;
  }

  get current() {
    return this.tokens[this.index];
  }

  get peek() {
    return this.tokens[this.index + 1];
  }

  clone(end_token = null) {
    return new Parser(this.tokens, this.index, end_token || this.end_token);
  }

  consume_clone(parser) {
    this.index = parser.index;
  }

  consume(TokenClass) {
    if (!(this.current instanceof TokenClass))
      throw new TokenMismatch(TokenClass, this.current);
    const token = this.current;
    this.index += 1;
    return token;
  }

  can_parse() {
    if (this.index >= this.tokens.length) return false;
    if (!this.end_token) return true;
    return !this.current.is(this.end_token);
  }

  parse() {
    const ast = [];
    while (this.can_parse()) {
      if (this.current.is(Ampersand) && this.peek?.is(PseudoClass)) {
        ast.push(this.parse_child_pseudo_selector());
      } else if (this.current.is(IdentifierToken) && this.peek?.is(OpenBrace)) {
        ast.push(this.parse_child_selector());
      } else if (this.current.is(IdentifierToken)) {
        ast.push(this.parse_rule());
      } else {
        throw new NotReached(this.current);
      }
    }
    return ast;
  }

  parse_child_pseudo_selector() {
    this.consume(Ampersand);
    const { value: selector } = this.consume(PseudoClass);
    this.consume(OpenBrace);
    const cloned_parser = this.clone(CloseBrace);
    const rules = cloned_parser.parse();
    this.consume_clone(cloned_parser);
    this.consume(CloseBrace);
    return new PseudoSelectorNode(selector, rules);
  }

  parse_child_selector() {
    const { value: tag_name } = this.consume(IdentifierToken);
    this.consume(OpenBrace);
    const cloned_parser = this.clone(CloseBrace);
    const rules = cloned_parser.parse();
    this.consume_clone(cloned_parser);
    this.consume(CloseBrace);
    return new ChildSelectorNode(tag_name, rules);
  }

  parse_rule() {
    const { value: name } = this.consume(IdentifierToken);
    const { value } = this.consume(ValueToken);
    return new RuleNode(name, value);
  }
}

class Compiler {
  constructor(ast, tag_names = [], top_level = true) {
    this.ast = ast;
    this.tag_names = tag_names;
    this.top_level = top_level;
  }

  base_rules_start() {
    if (this.top_level) {
      if (this.tag_names.length !== 1) throw new NotReached();
      return `${this.tag_names[0]} {\n`;
    } else {
      return "";
    }
  }

  base_rules_end() {
    if (this.top_level) {
      return "}\n";
    } else {
      return "";
    }
  }

  eval() {
    const [rules, sub_rules] = this.eval_rules_and_sub_rules();
    return [rules, ...sub_rules];
  }

  eval_rules_and_sub_rules() {
    let rules = this.base_rules_start();
    const rule_nodes = this.ast.filter((node) => node instanceof RuleNode);
    for (let node of rule_nodes) {
      rules += "  " + this.eval_rule(node) + "\n";
    }
    rules += this.base_rules_end();

    let sub_rules = [];
    const sub_rule_nodes = this.ast.filter(
      (node) => !rule_nodes.includes(node)
    );
    for (let node of sub_rule_nodes) {
      switch (node.constructor) {
        case PseudoSelectorNode:
          sub_rules = sub_rules.concat(this.eval_pseudo_selector(node));
        case ChildSelectorNode:
          sub_rules = sub_rules.concat(this.eval_child_selector(node));
          break;
        default:
          throw new NotReached();
      }
    }
    return [rules, sub_rules];
  }

  eval_rule({ name, value }) {
    return `${name}: ${value};`;
  }

  eval_pseudo_selector({ selector, rules: ast }) {
    if (!selector) throw new NotReached();
    let output = `${this.tag_names.join(" ")}:${selector} {\n`;
    const [rules, sub_rules] = new Compiler(
      ast,
      [...this.tag_names, selector],
      false
    ).eval_rules_and_sub_rules();
    output += rules;
    output += "}\n";

    return [output, ...sub_rules];
  }

  eval_child_selector({ tag_name, rules: ast }) {
    let output = `${this.tag_names.join(" ")} ${tag_name} {\n`;
    const [rules, sub_rules] = new Compiler(
      ast,
      [...this.tag_names, tag_name],
      false
    ).eval_rules_and_sub_rules();
    output += rules;
    output += "}\n";

    return [output, ...sub_rules];
  }
}

const compile_css = (style, tag_name) => {
  const tokens = tokenize(style);
  const ast = new Parser(tokens).parse();
  return new Compiler(ast, [tag_name]).eval();
};
