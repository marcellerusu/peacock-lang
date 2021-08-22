import interpret from './interpreter.mjs';
import tokenize from "./tokenizer.mjs";
import parse from "./parser.mjs";

const program = `

let h = [1, 2, 3];
print(h);
`;

const global = interpret(parse(tokenize(program)));