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
class PseudoElement extends Token {}
class Dot extends Token {}
class Comma extends Token {}

const tokenizeCSS = (str) => {
  const tokens = [];
  const scanner = new StringScanner(str);
  while (!scanner.is_end_of_str()) {
    if (scanner.scan(/\s+/)) {
      continue;
    } else if (scanner.scan(/&/)) {
      tokens.push(new Ampersand());
    } else if (scanner.scan(/\./)) {
      tokens.push(new Dot());
    } else if (scanner.scan(/\,/)) {
      tokens.push(new Comma());
    } else if (scanner.scan(/::([a-z]+)/)) {
      tokens.push(new PseudoElement(scanner.groups[0]));
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

class AstNode {
  is(NodeType) {
    return this instanceof NodeType;
  }
}
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
  constructor(pseudo_class, rules) {
    super();
    this.pseudo_class = pseudo_class;
    this.rules = rules;
  }
}

class PseudoElementNode extends AstNode {
  constructor(pseudo_element, rules) {
    super();
    this.pseudo_element = pseudo_element;
    this.rules = rules;
  }
}

class ClassSelectorNode extends AstNode {
  constructor(class_name, rules) {
    super();
    this.class_name = class_name;
    this.rules = rules;
  }
}

class MultipleIdentifierNode extends AstNode {
  constructor(first_tag_name, second_tag_name, rules) {
    super();
    this.first_tag_name = first_tag_name;
    this.second_tag_name = second_tag_name;
    this.rules = rules;
  }
}

class CSSParser {
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

  get peek_two() {
    return this.tokens[this.index + 2];
  }

  clone(end_token = null) {
    return new CSSParser(this.tokens, this.index, end_token || this.end_token);
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
      if (this.current.is(Dot) && this.peek?.is(IdentifierToken)) {
        ast.push(this.parse_class_selector());
      } else if (
        this.current.is(IdentifierToken) &&
        this.peek?.is(Comma) &&
        this.peek_two?.is(IdentifierToken)
      ) {
        ast.push(this.parse_multiple_identifier());
      } else if (this.current.is(Ampersand) && this.peek?.is(PseudoClass)) {
        ast.push(this.parse_child_pseudo_class_selector());
      } else if (this.current.is(Ampersand) && this.peek?.is(PseudoElement)) {
        ast.push(this.parse_child_pseudo_element_selector());
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

  parse_class_selector() {
    this.consume(Dot);
    const { value: class_name } = this.consume(IdentifierToken);
    this.consume(OpenBrace);
    const cloned_parser = this.clone(CloseBrace);
    const rules = cloned_parser.parse();
    this.consume_clone(cloned_parser);
    this.consume(CloseBrace);
    return new ClassSelectorNode(class_name, rules);
  }

  parse_child_pseudo_class_selector() {
    this.consume(Ampersand);
    const { value: selector } = this.consume(PseudoClass);
    this.consume(OpenBrace);
    const cloned_parser = this.clone(CloseBrace);
    const rules = cloned_parser.parse();
    this.consume_clone(cloned_parser);
    this.consume(CloseBrace);
    return new PseudoSelectorNode(selector, rules);
  }

  parse_multiple_identifier() {
    const { value: first_tag_name } = this.consume(IdentifierToken);
    this.consume(Comma);
    const { value: second_tag_name } = this.consume(IdentifierToken);
    this.consume(OpenBrace);
    const cloned_parser = this.clone(CloseBrace);
    const rules = cloned_parser.parse();
    this.consume_clone(cloned_parser);
    this.consume(CloseBrace);
    return new MultipleIdentifierNode(first_tag_name, second_tag_name, rules);
  }

  parse_child_pseudo_element_selector() {
    this.consume(Ampersand);
    const { value: pseudo_element } = this.consume(PseudoElement);
    this.consume(OpenBrace);
    const cloned_parser = this.clone(CloseBrace);
    const rules = cloned_parser.parse();
    this.consume_clone(cloned_parser);
    this.consume(CloseBrace);
    return new PseudoElementNode(pseudo_element, rules);
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

class CSSCompiler {
  constructor(ast, parent_selector, top_level = true) {
    this.ast = ast;
    this.parent_selector = parent_selector;
    this.top_level = top_level;
  }

  base_rules_end() {
    if (this.top_level) {
      return "}\n";
    } else {
      return "";
    }
  }

  eval() {
    let rules_str = `${this.parent_selector} {\n`;
    const [rules, sub_rules] = this.eval_rules_and_sub_rules();
    return [rules_str + rules, ...sub_rules];
  }

  eval_rules_and_sub_rules() {
    let rules = "";
    const rule_nodes = this.ast.filter((node) => node instanceof RuleNode);
    for (let node of rule_nodes) {
      rules += `  ${this.eval_rule(node)}\n`;
    }
    rules += this.base_rules_end();

    let sub_rules = [];
    const sub_rule_nodes = this.ast.filter(
      (node) => !rule_nodes.includes(node)
    );
    for (let node of sub_rule_nodes) {
      switch (node.constructor) {
        case ClassSelectorNode:
          sub_rules = sub_rules.concat(this.eval_class_selector(node));
          break;
        case PseudoSelectorNode:
          sub_rules = sub_rules.concat(this.eval_pseudo_class_selector(node));
          break;
        case PseudoElementNode:
          sub_rules = sub_rules.concat(this.eval_pseudo_element_selector(node));
          break;
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

  eval_class_selector({ class_name, rules: ast }) {
    if (!class_name) throw new NotReached();
    const selector = `${this.parent_selector} .${class_name}`;
    let output = `${selector} {\n`;
    const [rules, sub_rules] = new CSSCompiler(
      ast,
      selector,
      false
    ).eval_rules_and_sub_rules();
    output += rules;
    output += "}\n";

    return [output, ...sub_rules];
  }

  eval_pseudo_class_selector({ pseudo_class, rules: ast }) {
    if (!pseudo_class) throw new NotReached();
    const selector = `${this.parent_selector}:${pseudo_class}`;
    let output = `${selector} {\n`;
    const [rules, sub_rules] = new CSSCompiler(
      ast,
      selector,
      false
    ).eval_rules_and_sub_rules();
    output += rules;
    output += "}\n";

    return [output, ...sub_rules];
  }

  eval_pseudo_element_selector({ pseudo_element, rules: ast }) {
    if (!pseudo_element) throw new NotReached();
    const selector = `${this.parent_selector}::${pseudo_element}`;
    let output = `${selector} {\n`;
    const [rules, sub_rules] = new CSSCompiler(
      ast,
      selector,
      false
    ).eval_rules_and_sub_rules();
    output += rules;
    output += "}\n";

    return [output, ...sub_rules];
  }

  eval_child_selector({ tag_name, rules: ast }) {
    const selector = `${this.parent_selector} ${tag_name}`;
    let output = `${selector} {\n`;
    const [rules, sub_rules] = new CSSCompiler(
      ast,
      selector,
      false
    ).eval_rules_and_sub_rules();
    output += rules;
    output += "}\n";

    return [output, ...sub_rules];
  }
}

const compile_css = (style, tag_name) => {
  const tokens = tokenizeCSS(style);
  const ast = new CSSParser(tokens).parse();
  return new CSSCompiler(ast, tag_name).eval();
};

const parse_css = (style) => {
  const tokens = tokenizeCSS(style);
  return new CSSParser(tokens).parse();
};
