import tokenize, {TOKEN_NAMES} from "./tokenizer.mjs";
import assert from 'assert';

const eq = (a1, a2) =>
  a1.length === a2.length && a1.every((x, i) => Array.isArray(x) ? eq(x, a2[i]) : x === a2[i]);

let passed = 0;
const it = (str, fn) => {
  console.log(`it - ${str}`);
  fn();
  console.log('succeeded!')
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

it('should tokenize `let var = 3;`', () => {
  const program = `
  let var = 3;
  `;
  const tokens = tokenize(program);

  assert(eq(tokens, [
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'var'],
    TOKEN_NAMES.ASSIGNMENT,
    [TOKEN_NAMES.LITERAL, 3],
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


it('should tokenize `if obj == { a: 3 } {`', () => {
  const program = `
  if obj == { a: 3 } {
  `;
  const tokens = tokenize(program);

  assert(eq(tokens, [
    TOKEN_NAMES.IF,
    [TOKEN_NAMES.SYMBOL, 'obj'],
    TOKEN_NAMES.EQUALS,
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
  if obj == { a: 3 } {
    let a = 4;
  } else {

  }
  `;
  const tokens = tokenize(program);

  assert(eq(tokens, [
    TOKEN_NAMES.IF,
    [TOKEN_NAMES.SYMBOL, 'obj'],
    TOKEN_NAMES.EQUALS,
    TOKEN_NAMES.OPEN_BRACE,
    [TOKEN_NAMES.SYMBOL, 'a'],
    TOKEN_NAMES.COLON,
    [TOKEN_NAMES.LITERAL, 3],
    TOKEN_NAMES.CLOSE_BRACE,
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

console.log('Passed', passed, 'tests!');