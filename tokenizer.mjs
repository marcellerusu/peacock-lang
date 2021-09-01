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
  ELIF: 'ELIF',
  COMMA: 'COMMA',
  OPERATOR: 'OPERATOR',
  OPEN_SQ_BRACE: 'OPEN_SQ_BRACE',
  CLOSE_SQ_BRACE: 'CLOSE_SQ_BRACE',
  MATCH: 'MATCH',
  PROPERTY_ACCESSOR: 'PROPERTY_ACCESSOR',
  REST_OPERATOR: 'REST_OPERATOR',
  RETURN: 'RETURN',
  TRUE: 'TRUE',
  FALSE: 'FALSE',
};

const TOKEN_TO_NAME = {
  'let': TOKEN_NAMES.LET,
  'mut': TOKEN_NAMES.MUT,
  '=': TOKEN_NAMES.ASSIGNMENT,
  '{': TOKEN_NAMES.OPEN_BRACE,
  'if': TOKEN_NAMES.IF,
  'else': TOKEN_NAMES.ELSE,
  'elif': TOKEN_NAMES.ELIF,
  'match': TOKEN_NAMES.MATCH,
  'return': TOKEN_NAMES.RETURN,
  'true': TOKEN_NAMES.TRUE,
  'false': TOKEN_NAMES.FALSE,
  '}': TOKEN_NAMES.CLOSE_BRACE,
  '(': TOKEN_NAMES.OPEN_PARAN,
  ')': TOKEN_NAMES.CLOSE_PARAN,
  '[': TOKEN_NAMES.OPEN_SQ_BRACE,
  ']': TOKEN_NAMES.CLOSE_SQ_BRACE,
  '=>': TOKEN_NAMES.ARROW,
  ':': TOKEN_NAMES.COLON,
  ';': TOKEN_NAMES.END_STATEMENT,
  ',': TOKEN_NAMES.COMMA,
  '.': TOKEN_NAMES.PROPERTY_ACCESSOR,
  '..': TOKEN_NAMES.REST_OPERATOR,
};

const UNARY_OPERATORS = {
  '+': [TOKEN_NAMES.OPERATOR, '+'],
  '-': [TOKEN_NAMES.OPERATOR, '-'],
  '*': [TOKEN_NAMES.OPERATOR, '*'],
  '/': [TOKEN_NAMES.OPERATOR, '/'],
  '==': [TOKEN_NAMES.OPERATOR, '=='],
  '!=': [TOKEN_NAMES.OPERATOR, '!='],
  '>': [TOKEN_NAMES.OPERATOR, '>'],
  '<': [TOKEN_NAMES.OPERATOR, '<'],
  // '|>': [TOKEN_NAMES.OPERATOR, '|>'],
};

const isWhiteSpace = c => [' ', '\n'].includes(c);

const takeUntilOf = program => (index, condFn) => {
  let str = program[index], cond;
  const check = str => condFn(program[index], str, str + program[index])  
  while (!(cond = check(str)) && index < program.length - 1) {
    const c = program[++index];
    if (cond = check(str)) {
      index -= 1;
      break;
    }
    str += c;
  }
  if (!cond) str = null;
  return [index, str];
};

const getLiteralParser = str => {
  if (isWhiteSpace(str)) return;
  if (Number(str) == str) {
    return Number;
  } else if (str[0] === '\'' && str[str.length - 1] === '\'') {
    return s => s.slice(1, s.length - 1);
  }
};

const lookup = str => TOKEN_TO_NAME[str] || UNARY_OPERATORS[str];

const tokenize = program => {
  const takeUntil = takeUntilOf(program);
  const tokens = [];
  for (let i = 0; i < program.length; i++) {
    const char = program[i];
    // comments
    if (char === '#') {
      const index = program.slice(i).indexOf('\n') + 1;
      if (index === 0) break;
      i = i + index;
    }
    if (isWhiteSpace(char)) continue;
    // todo should we be checking OPERATORS[str] in the cb here?
    let isParsingStr = char === '\'';
    const [newIndex, str] = takeUntil(i, (nextChar, str, peek) =>
      // cases ULTRA SKETCHY
      // #1 - the next str is an operator
      isParsingStr ?
        ([...str].filter(c => c === '\'').length === 2) :
        (
          isWhiteSpace(nextChar)
          || (lookup(str) && !lookup(peek))
          || (lookup(nextChar) && !lookup(peek))
        )
    );
    i = newIndex;
    if (UNARY_OPERATORS[str]) {
      tokens.push(UNARY_OPERATORS[str]);
    } else if (TOKEN_TO_NAME[str]) {
      tokens.push(TOKEN_TO_NAME[str]);
    } else if (getLiteralParser(str)) {
      const parser = getLiteralParser(str);
      tokens.push([TOKEN_NAMES.LITERAL, parser(str)]);
    } else {
      tokens.push([TOKEN_NAMES.SYMBOL, str]);
    }
  }
  return tokens;
};

export default tokenize;