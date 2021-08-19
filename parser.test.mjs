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
        expr: {
          type: STATEMENT_TYPE.NUMBER_LITERAL,
          value: 3
        }
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
        expr: {
          type: STATEMENT_TYPE.NUMBER_LITERAL,
          value: 3
        }
      },
    ]
  }))
});

it(`should parse function`, () => {
  const tokens = [
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'function'],
    TOKEN_NAMES.ASSIGNMENT,
    TOKEN_NAMES.OPEN_PARAN,
    TOKEN_NAMES.CLOSE_PARAN,
    TOKEN_NAMES.ARROW,
    [TOKEN_NAMES.LITERAL, 3],
    TOKEN_NAMES.END_STATEMENT
  ];
  const ast = parse(tokens);
  // console.log(ast.body[0].expr.body);

  assert(eq(ast, {
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.ASSIGNMENT,
        mutable: false,
        symbol: 'function',
        expr: {
          type: STATEMENT_TYPE.FUNCTION,
          paramNames: [],
          body: [
            {
              type: STATEMENT_TYPE.RETURN,
              expr: {
                type: STATEMENT_TYPE.NUMBER_LITERAL,
                value: 3
              }
            }
          ]
        }
      },
    ]
  }))
});


it(`should parse object literal`, () => {
  const tokens = [
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'obj'],
    TOKEN_NAMES.ASSIGNMENT,
    TOKEN_NAMES.OPEN_BRACE,
    [TOKEN_NAMES.SYMBOL, 'a'],
    TOKEN_NAMES.COLON,
    [TOKEN_NAMES.LITERAL, 3],
    TOKEN_NAMES.COMMA,
    [TOKEN_NAMES.SYMBOL, 'yesa'],
    TOKEN_NAMES.COLON,
    [TOKEN_NAMES.LITERAL, 5],
    TOKEN_NAMES.COMMA,
    TOKEN_NAMES.CLOSE_BRACE,
    TOKEN_NAMES.END_STATEMENT
  ];
  const ast = parse(tokens);

  assert(eq(ast, {
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.ASSIGNMENT,
        mutable: false,
        symbol: 'obj',
        expr: {
          type: STATEMENT_TYPE.OBJECT_LITERAL,
          value: {
            a: {
              type: STATEMENT_TYPE.NUMBER_LITERAL,
              value: 3
            },
            yesa: {
              type: STATEMENT_TYPE.NUMBER_LITERAL,
              value: 5
            }
          }
        }
      }
    ]
  }))
});

/*

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