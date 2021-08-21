import parse, {STATEMENT_TYPE} from './parser.mjs';
import { TOKEN_NAMES } from './tokenizer.mjs';
import { eq } from './utils.mjs';
import assert from 'assert';

let passed = 0;
const it = (str, fn) => {
  console.log(`it - ${str}`);
  fn();
  passed++;
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

  assert(eq(ast, {
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.DECLARATION,
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


it('should parse `let var = \'abc\';`', () => {
  const tokens = [
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'var'],
    TOKEN_NAMES.ASSIGNMENT,
    [TOKEN_NAMES.LITERAL, 'abc'],
    TOKEN_NAMES.END_STATEMENT
  ];
  const ast = parse(tokens);

  assert(eq(ast, {
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.DECLARATION,
        symbol: 'var',
        mutable: false,
        expr: {
          type: STATEMENT_TYPE.STRING_LITERAL,
          value: 'abc'
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
        type: STATEMENT_TYPE.DECLARATION,
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

it(`should parse variable assignment`, () => {
  const tokens = [
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
        type: STATEMENT_TYPE.DECLARATION,
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


it(`should parse function with variable lookup`, () => {
  const tokens = [
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'function'],
    TOKEN_NAMES.ASSIGNMENT,
    TOKEN_NAMES.OPEN_PARAN,
    TOKEN_NAMES.CLOSE_PARAN,
    TOKEN_NAMES.ARROW,
    [TOKEN_NAMES.SYMBOL, 'a'],
    TOKEN_NAMES.END_STATEMENT
  ];
  const ast = parse(tokens);
  // console.log(ast.body[0].expr.body);

  assert(eq(ast, {
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.DECLARATION,
        mutable: false,
        symbol: 'function',
        expr: {
          type: STATEMENT_TYPE.FUNCTION,
          paramNames: [],
          body: [
            {
              type: STATEMENT_TYPE.RETURN,
              expr: {
                type: STATEMENT_TYPE.SYMBOL_LOOKUP,
                symbol: 'a'
              }
            }
          ]
        }
      },
    ]
  }))
});

it(`should parse identity function`, () => {
  const tokens = [
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'id'],
    TOKEN_NAMES.ASSIGNMENT,
    TOKEN_NAMES.OPEN_PARAN,
    [TOKEN_NAMES.SYMBOL, 'x'],
    TOKEN_NAMES.CLOSE_PARAN,
    TOKEN_NAMES.ARROW,
    [TOKEN_NAMES.SYMBOL, 'x'],
    TOKEN_NAMES.END_STATEMENT
  ];
  const ast = parse(tokens);
  // console.log(JSON.stringify(ast.body[0].expr));

  assert(eq(ast, {
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.DECLARATION,
        mutable: false,
        symbol: 'id',
        expr: {
          type: STATEMENT_TYPE.FUNCTION,
          paramNames: ['x'],
          body: [ 
            {
              type: STATEMENT_TYPE.RETURN,
              expr: {
                type: STATEMENT_TYPE.SYMBOL_LOOKUP,
                symbol: 'x'
              }
            }
          ]
        }
      },
    ]
  }))
});


it(`should parse function application with arguments`, () => {
  const tokens = [
    [TOKEN_NAMES.SYMBOL, 'add'],
    TOKEN_NAMES.OPEN_PARAN,
    [TOKEN_NAMES.SYMBOL, 'a'],
    TOKEN_NAMES.COMMA,
    [TOKEN_NAMES.SYMBOL, 'b'],
    TOKEN_NAMES.CLOSE_PARAN,
    TOKEN_NAMES.END_STATEMENT
  ];
  const ast = parse(tokens);

  assert(eq(ast, {
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.FUNCTION_APPLICATION,
        symbol: 'add',
        paramExprs: [
          {
            type: STATEMENT_TYPE.SYMBOL_LOOKUP,
            symbol: 'a'
          },
          {
            type: STATEMENT_TYPE.SYMBOL_LOOKUP,
            symbol: 'b'
          }
        ]
      },
    ]
  }))
});


it(`should parse function with multiple args`, () => {
  const tokens = [
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'add'],
    TOKEN_NAMES.ASSIGNMENT,
    TOKEN_NAMES.OPEN_PARAN,
    [TOKEN_NAMES.SYMBOL, 'a'],
    TOKEN_NAMES.COMMA,
    [TOKEN_NAMES.SYMBOL, 'b'],
    TOKEN_NAMES.CLOSE_PARAN,
    TOKEN_NAMES.ARROW,
    [TOKEN_NAMES.SYMBOL, 'a'],
    [TOKEN_NAMES.OPERATOR, '+'],
    [TOKEN_NAMES.SYMBOL, 'b'],
    TOKEN_NAMES.END_STATEMENT
  ];
  const ast = parse(tokens);

  assert(eq(ast, {
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.DECLARATION,
        mutable: false,
        symbol: 'add',
        expr: {
          type: STATEMENT_TYPE.FUNCTION,
          paramNames: ['a', 'b'],
          body: [ 
            {
              type: STATEMENT_TYPE.RETURN,
              expr: {
                type: STATEMENT_TYPE.FUNCTION_APPLICATION,
                symbol: '+',
                paramExprs: [
                  {
                    type: STATEMENT_TYPE.SYMBOL_LOOKUP,
                    symbol: 'a'
                  },
                  {
                    type: STATEMENT_TYPE.SYMBOL_LOOKUP,
                    symbol: 'b'
                  }
                ]
              }
            }
          ]
        }
      },
    ]
  }))
});


it(`should parse function with body`, () => {
  const tokens = [
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'function'],
    TOKEN_NAMES.ASSIGNMENT,
    TOKEN_NAMES.OPEN_PARAN,
    TOKEN_NAMES.CLOSE_PARAN,
    TOKEN_NAMES.ARROW,
    TOKEN_NAMES.OPEN_BRACE,
    TOKEN_NAMES.RETURN,
    [TOKEN_NAMES.SYMBOL, 'a'],
    TOKEN_NAMES.END_STATEMENT,
    TOKEN_NAMES.CLOSE_BRACE,
    TOKEN_NAMES.END_STATEMENT
  ];
  const ast = parse(tokens);
  // console.log(ast.body[0].expr.body);

  assert(eq(ast, {
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.DECLARATION,
        mutable: false,
        symbol: 'function',
        expr: {
          type: STATEMENT_TYPE.FUNCTION,
          paramNames: [],
          body: [
            {
              type: STATEMENT_TYPE.RETURN,
              expr: {
                type: STATEMENT_TYPE.SYMBOL_LOOKUP,
                symbol: 'a'
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
        type: STATEMENT_TYPE.DECLARATION,
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


it(`should parse array literal`, () => {
  const tokens = [
    TOKEN_NAMES.LET,
    [TOKEN_NAMES.SYMBOL, 'arr'],
    TOKEN_NAMES.ASSIGNMENT,
    TOKEN_NAMES.OPEN_SQ_BRACE,
    [TOKEN_NAMES.LITERAL, 3],
    TOKEN_NAMES.COMMA,
    [TOKEN_NAMES.SYMBOL, 'a'],
    TOKEN_NAMES.COMMA,
    TOKEN_NAMES.OPEN_BRACE,
    [TOKEN_NAMES.SYMBOL, 'b'],
    TOKEN_NAMES.COLON,
    [TOKEN_NAMES.LITERAL, 'str'],
    TOKEN_NAMES.CLOSE_BRACE,
    TOKEN_NAMES.CLOSE_SQ_BRACE,
    TOKEN_NAMES.END_STATEMENT
  ];
  const ast = parse(tokens);

  // let arr = [3, a, { b: 'str' }];
  assert(eq(ast, {
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.DECLARATION,
        mutable: false,
        symbol: 'arr',
        expr: {
          type: STATEMENT_TYPE.ARRAY_LITERAL,
          elements: [
            {
              type: STATEMENT_TYPE.NUMBER_LITERAL,
              value: 3
            },
            {
              type: STATEMENT_TYPE.SYMBOL_LOOKUP,
              symbol: 'a'
            },
            {
              type: STATEMENT_TYPE.OBJECT_LITERAL,
              value: {
                b: {
                  type: STATEMENT_TYPE.STRING_LITERAL,
                  value: 'str'
                }
              }
            }
          ]
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

console.log('Passed', passed, 'tests!');