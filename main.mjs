import interpret from './interpreter.mjs';
import tokenize from "./tokenizer.mjs";
import parse from "./parser.mjs";

const program = `
let h = {
  a: () => 3,
  b: {
    c: () => 6
  }
};
let b = h.a();
let c = h.b.c();
print(b, c);
`;

const global = interpret(parse(tokenize(program)));