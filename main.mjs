import interpret, { globals } from './interpreter.mjs';
import tokenize from "./tokenizer.mjs";
import parse from "./parser.mjs";

const program = `
let f = () => 3;
let v = f();
`;

interpret(parse(tokenize(program)));

console.log(globals)

