import tokenize, {TOKEN_NAMES} from "./tokenizer.mjs";
import assert from 'assert';

const eq = (a1, a2) =>
  a1.length === a2.length && a1.every((x, i) => Array.isArray(x) ? eq(x, a2[i]) : x === a2[i]);

let passed = 0;
const it = (str, fn) => {
  console.log(`it - ${str}`);
  fn();
  passed++;
}

it('should tokenize `let`', () => {
  const program = `
  let
  `;
  const tokens = tokenize(program);

  assert(eq(tokens, [
    TOKEN_NAMES.LET,
  ]))
});

it('should tokenize `let var`', () => {
  const program = `
  let var
  `;
  const tokens = tokenize(program);

  assert(eq(tokens, [
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'var'],
  ]))
});

it('should tokenize `let var =`', () => {
  const program = `
  let var =
  `;
  const tokens = tokenize(program);

  assert(eq(tokens, [
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'var'],
    TOKEN_NAMES.ASSIGNMENT,
  ]))
});

it('should tokenize `let var = 3`', () => {
  const program = `
  let var = 3
  `;
  const tokens = tokenize(program);

  assert(eq(tokens, [
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'var'],
    TOKEN_NAMES.ASSIGNMENT,
    [TOKEN_NAMES.LITERAL, 3],
  ]))
});

it('should tokenize `let var = \'str\';`', () => {
  const program = `
  let var = 'str';
  `;
  const tokens = tokenize(program);

  assert(eq(tokens, [
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'var'],
    TOKEN_NAMES.ASSIGNMENT,
    [TOKEN_NAMES.LITERAL, 'str'],
    TOKEN_NAMES.END_STATEMENT
  ]))
});


it('should tokenize `let var = \'str w spaces\';`', () => {
  const program = `
  let var = 'str w spaces';
  `;
  const tokens = tokenize(program);

  assert(eq(tokens, [
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'var'],
    TOKEN_NAMES.ASSIGNMENT,
    [TOKEN_NAMES.LITERAL, 'str w spaces'],
    TOKEN_NAMES.END_STATEMENT
  ]))
});

it('should tokenize `let var = 3;`', () => {
  const program = `
  let var = 3;
  `;
  const tokens = tokenize(program);
  // console.log(tokens);

  assert(eq(tokens, [
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'var'],
    TOKEN_NAMES.ASSIGNMENT,
    [TOKEN_NAMES.LITERAL, 3],
    TOKEN_NAMES.END_STATEMENT
  ]))
});


it('should tokenize `let var = [1, a, \'234\'];`', () => {
  const program = `
  let var = [1, a, \'234\'];
  `;
  const tokens = tokenize(program);
  assert(eq(tokens, [
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'var'],
    TOKEN_NAMES.ASSIGNMENT,
    TOKEN_NAMES.OPEN_SQ_BRACE,
    [TOKEN_NAMES.LITERAL, 1],
    TOKEN_NAMES.COMMA,
    [TOKEN_NAMES.SYMBOL, 'a'],
    TOKEN_NAMES.COMMA,
    [TOKEN_NAMES.LITERAL, '234'],
    TOKEN_NAMES.CLOSE_SQ_BRACE,
    TOKEN_NAMES.END_STATEMENT
  ]))
});

it('should tokenize `let [first, second, third] = [1, a, \'234\'];`', () => {
  const program = `
  let [first, second, third] = [1, a, \'234\'];
  `;
  const tokens = tokenize(program);
  assert(eq(tokens, [
    TOKEN_NAMES.LET,
    TOKEN_NAMES.OPEN_SQ_BRACE,
    [TOKEN_NAMES.SYMBOL, 'first'],
    TOKEN_NAMES.COMMA,
    [TOKEN_NAMES.SYMBOL, 'second'],
    TOKEN_NAMES.COMMA,
    [TOKEN_NAMES.SYMBOL, 'third'],
    TOKEN_NAMES.CLOSE_SQ_BRACE,
    TOKEN_NAMES.ASSIGNMENT,
    TOKEN_NAMES.OPEN_SQ_BRACE,
    [TOKEN_NAMES.LITERAL, 1],
    TOKEN_NAMES.COMMA,
    [TOKEN_NAMES.SYMBOL, 'a'],
    TOKEN_NAMES.COMMA,
    [TOKEN_NAMES.LITERAL, '234'],
    TOKEN_NAMES.CLOSE_SQ_BRACE,
    TOKEN_NAMES.END_STATEMENT
  ]))
});

it('should tokenize pattern matching array', () => {
  const program = `
  let expr = match ([1, 2]) {
    [] => 'Congrats... sorta',
    [1] => 'Oh no',
    [1, 2] => 'YES!'
  };
  `;
  const tokens = tokenize(program);
  assert(eq(tokens, [
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'expr'],
    TOKEN_NAMES.ASSIGNMENT,
    TOKEN_NAMES.MATCH,
    TOKEN_NAMES.OPEN_PARAN,
    TOKEN_NAMES.OPEN_SQ_BRACE,
    [TOKEN_NAMES.LITERAL, 1],
    TOKEN_NAMES.COMMA,
    [TOKEN_NAMES.LITERAL, 2],
    TOKEN_NAMES.CLOSE_SQ_BRACE,
    TOKEN_NAMES.CLOSE_PARAN,
    TOKEN_NAMES.OPEN_BRACE,
    TOKEN_NAMES.OPEN_SQ_BRACE,
    TOKEN_NAMES.CLOSE_SQ_BRACE,
    TOKEN_NAMES.ARROW,
    [TOKEN_NAMES.LITERAL, 'Congrats... sorta'],
    TOKEN_NAMES.COMMA,
    TOKEN_NAMES.OPEN_SQ_BRACE,
    [TOKEN_NAMES.LITERAL, 1],
    TOKEN_NAMES.CLOSE_SQ_BRACE,
    TOKEN_NAMES.ARROW,
    [TOKEN_NAMES.LITERAL, 'Oh no'],
    TOKEN_NAMES.COMMA,
    TOKEN_NAMES.OPEN_SQ_BRACE,
    [TOKEN_NAMES.LITERAL, 1],
    TOKEN_NAMES.COMMA,
    [TOKEN_NAMES.LITERAL, 2],
    TOKEN_NAMES.CLOSE_SQ_BRACE,
    TOKEN_NAMES.ARROW,
    [TOKEN_NAMES.LITERAL, 'YES!'],
    TOKEN_NAMES.CLOSE_BRACE,
    TOKEN_NAMES.END_STATEMENT
  ]))
});

it('should tokenize `let mut var = 3;`', () => {
  const program = `
  let mut var = 3;
  `;
  const tokens = tokenize(program);

  assert(eq(tokens, [
    TOKEN_NAMES.LET,
    TOKEN_NAMES.MUT,
    [TOKEN_NAMES.SYMBOL, 'var'],
    TOKEN_NAMES.ASSIGNMENT,
    [TOKEN_NAMES.LITERAL, 3],
    TOKEN_NAMES.END_STATEMENT
  ]))
});

it('should tokenize `let function = () => 3;`', () => {
  const program = `
  let function = () => 3;
  `;
  const tokens = tokenize(program);

  assert(eq(tokens, [
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'function'],
    TOKEN_NAMES.ASSIGNMENT,
    TOKEN_NAMES.OPEN_PARAN,
    TOKEN_NAMES.CLOSE_PARAN,
    TOKEN_NAMES.ARROW,
    [TOKEN_NAMES.LITERAL, 3],
    TOKEN_NAMES.END_STATEMENT
  ]))
});

it('should tokenize function body', () => {
  const program = `
  let function = () =>  {
    
  };
  `;
  const tokens = tokenize(program);

  assert(eq(tokens, [
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'function'],
    TOKEN_NAMES.ASSIGNMENT,
    TOKEN_NAMES.OPEN_PARAN,
    TOKEN_NAMES.CLOSE_PARAN,
    TOKEN_NAMES.ARROW,
    TOKEN_NAMES.OPEN_BRACE,
    TOKEN_NAMES.CLOSE_BRACE,
    TOKEN_NAMES.END_STATEMENT
  ]))
});


it('should tokenize function body with return', () => {
  const program = `
  let function = () =>  {
    return a;
  };
  `;
  const tokens = tokenize(program);

  assert(eq(tokens, [
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'function'],
    TOKEN_NAMES.ASSIGNMENT,
    TOKEN_NAMES.OPEN_PARAN,
    TOKEN_NAMES.CLOSE_PARAN,
    TOKEN_NAMES.ARROW,
    TOKEN_NAMES.OPEN_BRACE,
    TOKEN_NAMES.RETURN,
    [TOKEN_NAMES.SYMBOL, 'a'],
    TOKEN_NAMES.END_STATEMENT,
    TOKEN_NAMES.CLOSE_BRACE,
    TOKEN_NAMES.END_STATEMENT
  ]))
});

it('should tokenize function params', () => {
  const program = `
  let function = (a, b, c) => a + b + c;
  `;
  const tokens = tokenize(program);
  assert(eq(tokens, [
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'function'],
    TOKEN_NAMES.ASSIGNMENT,
    TOKEN_NAMES.OPEN_PARAN,
    [TOKEN_NAMES.SYMBOL, 'a'],
    TOKEN_NAMES.COMMA,
    [TOKEN_NAMES.SYMBOL, 'b'],
    TOKEN_NAMES.COMMA,
    [TOKEN_NAMES.SYMBOL, 'c'],
    TOKEN_NAMES.CLOSE_PARAN,
    TOKEN_NAMES.ARROW,
    [TOKEN_NAMES.SYMBOL, 'a'],
    [TOKEN_NAMES.OPERATOR, '+'],
    [TOKEN_NAMES.SYMBOL, 'b'],
    [TOKEN_NAMES.OPERATOR, '+'],
    [TOKEN_NAMES.SYMBOL, 'c'],
    TOKEN_NAMES.END_STATEMENT
  ]))
});

it('should tokenize `let obj = { a: 3 }`', () => {
  const program = `
  let obj = { a: 3 };
  `;
  const tokens = tokenize(program);

  assert(eq(tokens, [
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'obj'],
    TOKEN_NAMES.ASSIGNMENT,
    TOKEN_NAMES.OPEN_BRACE,
    [TOKEN_NAMES.SYMBOL, 'a'],
    TOKEN_NAMES.COLON,
    [TOKEN_NAMES.LITERAL, 3],
    TOKEN_NAMES.CLOSE_BRACE,
    TOKEN_NAMES.END_STATEMENT
  ]))
});

it('should tokenize `let { a } = { a: 3 }`', () => {
  const program = `
  let { a } = { a: 3 };
  `;
  const tokens = tokenize(program);

  assert(eq(tokens, [
    TOKEN_NAMES.LET,
    TOKEN_NAMES.OPEN_BRACE,
    [TOKEN_NAMES.SYMBOL, 'a'],
    TOKEN_NAMES.CLOSE_BRACE,
    TOKEN_NAMES.ASSIGNMENT,
    TOKEN_NAMES.OPEN_BRACE,
    [TOKEN_NAMES.SYMBOL, 'a'],
    TOKEN_NAMES.COLON,
    [TOKEN_NAMES.LITERAL, 3],
    TOKEN_NAMES.CLOSE_BRACE,
    TOKEN_NAMES.END_STATEMENT
  ]))
});

it('should tokenize `obj.property`', () => {
  const program = `
  obj.property;
  `;
  const tokens = tokenize(program);

  assert(eq(tokens, [
    [TOKEN_NAMES.SYMBOL, 'obj'],
    TOKEN_NAMES.PROPERTY_ACCESSOR,
    [TOKEN_NAMES.SYMBOL, 'property'],
    TOKEN_NAMES.END_STATEMENT
  ]))
});

it('should tokenize `if obj == { a: 3 } {`', () => {
  const program = `
  if obj == { a: 3 } {
  `;
  const tokens = tokenize(program);

  assert(eq(tokens, [
    TOKEN_NAMES.IF,
    [TOKEN_NAMES.SYMBOL, 'obj'],
    [TOKEN_NAMES.OPERATOR, '=='],
    TOKEN_NAMES.OPEN_BRACE,
    [TOKEN_NAMES.SYMBOL, 'a'],
    TOKEN_NAMES.COLON,
    [TOKEN_NAMES.LITERAL, 3],
    TOKEN_NAMES.CLOSE_BRACE,
    TOKEN_NAMES.OPEN_BRACE
  ]))
});


it('should tokenize if else', () => {
  const program = `
  if (obj == { a: 3 }) {
    let a = 4;
  } else {

  }
  `;
  const tokens = tokenize(program);

  assert(eq(tokens, [
    TOKEN_NAMES.IF,
    TOKEN_NAMES.OPEN_PARAN,
    [TOKEN_NAMES.SYMBOL, 'obj'],
    [TOKEN_NAMES.OPERATOR, '=='],
    TOKEN_NAMES.OPEN_BRACE,
    [TOKEN_NAMES.SYMBOL, 'a'],
    TOKEN_NAMES.COLON,
    [TOKEN_NAMES.LITERAL, 3],
    TOKEN_NAMES.CLOSE_BRACE,
    TOKEN_NAMES.CLOSE_PARAN,
    TOKEN_NAMES.OPEN_BRACE,
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'a'],
    TOKEN_NAMES.ASSIGNMENT,
    [TOKEN_NAMES.LITERAL, 4],
    TOKEN_NAMES.END_STATEMENT,
    TOKEN_NAMES.CLOSE_BRACE,
    TOKEN_NAMES.ELSE,
    TOKEN_NAMES.OPEN_BRACE,
    TOKEN_NAMES.CLOSE_BRACE
  ]))
});


it('should tokenize if elif else', () => {
  const program = `
  if (obj == { a: 3 }) {
    let a = 4;
  } elif (b == true) {
    let b = 4;
  } else {
    let c = 4;
  }
  `;
  const tokens = tokenize(program);
  // console.log(tokens);
  assert(eq(tokens, [
    TOKEN_NAMES.IF,
    TOKEN_NAMES.OPEN_PARAN,
    [TOKEN_NAMES.SYMBOL, 'obj'],
    [TOKEN_NAMES.OPERATOR, '=='],
    TOKEN_NAMES.OPEN_BRACE,
    [TOKEN_NAMES.SYMBOL, 'a'],
    TOKEN_NAMES.COLON,
    [TOKEN_NAMES.LITERAL, 3],
    TOKEN_NAMES.CLOSE_BRACE,
    TOKEN_NAMES.CLOSE_PARAN,
    TOKEN_NAMES.OPEN_BRACE,
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'a'],
    TOKEN_NAMES.ASSIGNMENT,
    [TOKEN_NAMES.LITERAL, 4],
    TOKEN_NAMES.END_STATEMENT,
    TOKEN_NAMES.CLOSE_BRACE,
    TOKEN_NAMES.ELIF,
    TOKEN_NAMES.OPEN_PARAN,
    [TOKEN_NAMES.SYMBOL, 'b'],
    [TOKEN_NAMES.OPERATOR, '=='],
    TOKEN_NAMES.TRUE,
    TOKEN_NAMES.CLOSE_PARAN,
    TOKEN_NAMES.OPEN_BRACE,
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'b'],
    TOKEN_NAMES.ASSIGNMENT,
    [TOKEN_NAMES.LITERAL, 4],
    TOKEN_NAMES.END_STATEMENT,
    TOKEN_NAMES.CLOSE_BRACE,
    TOKEN_NAMES.ELSE,
    TOKEN_NAMES.OPEN_BRACE,
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'c'],
    TOKEN_NAMES.ASSIGNMENT,
    [TOKEN_NAMES.LITERAL, 4],
    TOKEN_NAMES.END_STATEMENT,
    TOKEN_NAMES.CLOSE_BRACE
  ]))
});
console.log('Passed', passed, 'tests!');