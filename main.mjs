import interpret from './interpreter.mjs';
import tokenize from "./tokenizer.mjs";
import parse from "./parser.mjs";

const program = `
let add = (a, b) => a + b;
let add2 = (a) => add(2, a);

print(add(3, 4));
`;

interpret(parse(tokenize(program)));

