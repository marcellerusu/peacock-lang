import interpret from './interpreter.mjs';
import tokenize from "./tokenizer.mjs";
import parse from "./parser.mjs";

const program = `
let f = (a) => (b) => a + b + 3;
print(f(1)(2) + 3 + f(3)(4));
`;

const global = interpret(parse(tokenize(program)));