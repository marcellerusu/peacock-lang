import interpret from './interpreter.mjs';
import tokenize from "./tokenizer.mjs";
import parse from "./parser.mjs";

const program = `
let add = (a, b) => a + b;
let four = add(1, 3);
print(four);
`;

interpret(parse(tokenize(program)));

