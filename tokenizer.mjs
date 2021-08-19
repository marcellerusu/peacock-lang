export const TOKEN_NAMES = {
  LET: 'LET',
  MUT: 'MUT',
  ASSIGNMENT: 'ASSIGNMENT',
  EQUALS: 'EQUALS',
  NOT_EQUALS: 'NOT_EQUALS',
  OPEN_BRACE: 'OPEN_BRACE',
  CLOSE_BRACE: 'CLOSE_BRACE',
  COLON: 'COLON',
  END_STATEMENT: 'END_STATEMENT',
  SYMBOL: 'SYMBOL',
  LITERAL: 'LITERAL',
  OPEN_PARAN: 'OPEN_PARAN',
  CLOSE_PARAN: 'CLOSE_PARAN',
  ARROW: 'ARROW',
  IF: 'IF',
  ELSE: 'ELSE',
  COMMA: 'COMMA',
};

const TOKEN_TO_NAME = {
  'let': TOKEN_NAMES.LET,
  'mut': TOKEN_NAMES.MUT,
  '=': TOKEN_NAMES.ASSIGNMENT,
  '==': TOKEN_NAMES.EQUALS,
  '!=': TOKEN_NAMES.NOT_EQUALS,
  '{': TOKEN_NAMES.OPEN_BRACE,
  'if': TOKEN_NAMES.IF,
  'else': TOKEN_NAMES.ELSE,
  '}': TOKEN_NAMES.CLOSE_BRACE,
  '(': TOKEN_NAMES.OPEN_PARAN,
  ')': TOKEN_NAMES.CLOSE_PARAN,
  '=>': TOKEN_NAMES.ARROW,
  ':': TOKEN_NAMES.COLON,
  ';': TOKEN_NAMES.END_STATEMENT,
  ',': TOKEN_NAMES.COMMA,
};

// const take
const isWhiteSpace = c => [' ', '\n'].includes(c);

const takeWhileOf = program => (index, condFn) => {
  let str = program[index], cond;
  const check = str => condFn(str, str + program[index + 1])  
  while (!(cond = check(str)) && index < program.length) {
    const c = program[++index];
    if (isWhiteSpace(c)
    // TODO THIS IS ULTRA SKETCH... to make '==' tokenize not as '=' '='
    || (!check(str + c) && check(c))) {
      cond = true;
      index -= 1;
      break;
    }
    str += c;
  }
  if (!cond) str = null;
  return [index, str];
};

const isLiteral = str => {
  if (Number(str) == str) {
    return true;
  }
}

const parseLiteral = str => Number(str);

const tokenize = program => {
  const takeWhile = takeWhileOf(program);
  const tokens = [];
  for (let i = 0; i < program.length; i++) {
    const char = program[i];
    if (isWhiteSpace(char)) continue;
    const [newIndex, str] = takeWhile(i, (str, peek) => TOKEN_TO_NAME[str] && !TOKEN_TO_NAME[peek]);
    i = newIndex;
    if (TOKEN_TO_NAME[str]) {
      tokens.push(TOKEN_TO_NAME[str]);
    } else if (isLiteral(str)) {
      tokens.push([TOKEN_NAMES.LITERAL, parseLiteral(str)]);
    } else {
      tokens.push([TOKEN_NAMES.SYMBOL, str]);
    }
  }
  return tokens;
};

export default tokenize;