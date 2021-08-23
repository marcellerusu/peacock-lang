import interpret from './interpreter.mjs';
import tokenize from "./tokenizer.mjs";
import parse from "./parser.mjs";

const program = `
let f = () => 3;
print(3 + f());
`;

const global = interpret(parse(tokenize(program)));