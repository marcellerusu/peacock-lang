import parse, {STATEMENT_TYPE} from './parser.mjs';
import { TOKEN_NAMES } from './tokenizer.mjs';
import { eq } from './utils.mjs';
import assert from 'assert';

const it = (str, fn) => {
  console.log(`it - ${str}`);
  fn();
  console.log('succeeded!')
}

it('should parse `let var = 3;`', () => {
  const tokens = [
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'var'],
    TOKEN_NAMES.ASSIGNMENT,
    [TOKEN_NAMES.LITERAL, 3],
    TOKEN_NAMES.END_STATEMENT
  ];
  const ast = parse(tokens);
  // console.log(ast);

  assert(eq(ast, {
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.ASSIGNMENT,
        symbol: 'var',
        mutable: false,
        value: 3
      },
    ]
  }))
});

it(`should parse mutable variable`, () => {
  const tokens = [
    TOKEN_NAMES.LET,
    TOKEN_NAMES.MUT,
    [TOKEN_NAMES.SYMBOL, 'var'],
    TOKEN_NAMES.ASSIGNMENT,
    [TOKEN_NAMES.LITERAL, 3],
    TOKEN_NAMES.END_STATEMENT
  ];
  const ast = parse(tokens);
  // console.log(ast);

  assert(eq(ast, {
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.ASSIGNMENT,
        mutable: true,
        symbol: 'var',
        value: 3
      },
    ]
  }))
});

/*
let var = 3
->
{
  type: 'ASSIGNMENT'
  symbol: 'var,
  value: 3
}

let function = () => 3;
->
{
  type: 'ASSIGNMENT'
  symbol: 'function,
  value: {
    type: 'FUNCTION',
    param_names: [],
    body: [{
      type: 'RETURN',
      expr: 3
    }]
  }
}


if obj == { a: 3 } {

} else {

}
->
{
  type: 'CONDITION_STATEMENT'
  cond: {
    type: 'EXPRESSION'
    expr: {
      type: 'FUNCTION_APPLICATION',
      function: '==',
      params: [
        {
          type: 'VARIABLE_LOOKUP',
          symbol: 'obj
        },
        {
          type: 'OBJECT_LITERAL',
          value: {
            a: 3
          }
        }
      ]
    }
  },
  succeedBranch: null,
  failBranch: null
*/