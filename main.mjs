import interpret from './interpreter.mjs';
import tokenize from "./tokenizer.mjs";
import parse from "./parser.mjs";

const program = `
let f = (a) => (b) => a + b;
let h = f(1);
let g = h(2);
`;

const global = interpret(parse(tokenize(program)));

console.log(JSON.stringify(global.g.value))

