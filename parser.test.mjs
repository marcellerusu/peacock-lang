import parse, {
  STATEMENT_TYPE,
  declaration,
  assignment,
  objectLiteral,
  arrayLiteral,
  numberLiteral,
  stringLiteral,
  fn,
  fnCall,
  _return,
  symbolLookup,
  propertyLookup,
  dynamicLookup,
  conditional,
  matchExpression,
  matchCase,
  boundVariable,
  booleanLiteral,
  objectDeconstruction,
} from './parser.mjs';
import tokenize, { TOKEN_NAMES } from './tokenizer.mjs';
import assert from 'assert';
import pkg from 'immutable';
const { fromJS, is } = pkg;

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
  // console.log(ast.body[0]);
  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        symbol: 'var',
        mutable: false,
        expr: numberLiteral({value: 3})
      })
    ]
  })))
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

  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        symbol: 'var',
        mutable: false,
        expr: stringLiteral({value: 'abc'})
      })
    ]
  })))
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

  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        symbol: 'var',
        mutable: true,
        expr: numberLiteral({value: 3})
      }),
    ]
  })))
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

  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      assignment({symbol: 'var', expr: numberLiteral({value: 3})}),
    ]
  })))
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

  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        symbol: 'function',
        mutable: false,
        expr: fn({paramNames: [], body: [_return({expr: numberLiteral({value: 3})})]})
      })
    ]
  })))
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

  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        symbol: 'function',
        mutable: false,
        expr: fn({paramNames: [], body: [_return({expr: symbolLookup({symbol: 'a'})})]})
      })
    ]
  })))
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

  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        symbol: 'id',
        mutable: false,
        expr: fn({paramNames: ['x'], body: [_return({expr: symbolLookup({symbol: 'x'})})]})
      }),
    ]
  })))
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

  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      fnCall({
        expr: symbolLookup({symbol: 'add'}),
        paramExprs: [
          symbolLookup({symbol: 'a'}),
          symbolLookup({symbol: 'b'}),
        ]
      }),
    ]
  })))
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

  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        symbol: 'add',
        mutable: false,
        expr: fn({
          paramNames: ['a', 'b'],
          body: [_return({
            expr: fnCall({
              expr: symbolLookup({symbol: '+'}),
              paramExprs: [symbolLookup({symbol: 'a'}), symbolLookup({symbol: 'b'})]
            })
          })]
        })
      }),
    ]
  })))
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
  // console.log(tokens);
  const ast = parse(tokens);
  // console.log(ast.body[0].expr.body);

  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        symbol: 'function',
        mutable: false,
        expr: fn({
          paramNames: [],
          body: [_return({expr: symbolLookup({symbol: 'a'})})]
        })
      }),
    ]
  })))
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

  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        symbol: 'obj',
        mutable: false,
        expr: objectLiteral({value: { a: numberLiteral({value: 3}), yesa: numberLiteral({value: 5})}})
      })
    ]
  })))
});

it(`should parse object dot notation on variable`, () => {
  const tokens = [
    [TOKEN_NAMES.SYMBOL, 'obj'],
    TOKEN_NAMES.PROPERTY_ACCESSOR,
    [TOKEN_NAMES.SYMBOL, 'a'],
    TOKEN_NAMES.END_STATEMENT
  ];
  const ast = parse(tokens);

  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.PROPERTY_LOOKUP,
        expr: {
          type: STATEMENT_TYPE.SYMBOL_LOOKUP,
          symbol: 'obj',
        },
        property: 'a',
      }
    ]
  })))
});

it(`should parse object dot notation on object`, () => {
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
    TOKEN_NAMES.PROPERTY_ACCESSOR,
    [TOKEN_NAMES.SYMBOL, 'yesa'],
    TOKEN_NAMES.END_STATEMENT
  ];
  const ast = parse(tokens);

  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.DECLARATION,
        mutable: false,
        symbol: 'obj',
        expr: {
          type: STATEMENT_TYPE.PROPERTY_LOOKUP,
          property: 'yesa',
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
          },
        }
      }
    ]
  })))
});

it(`should parse nested object dot notation on variable`, () => {
  const tokens = [
    [TOKEN_NAMES.SYMBOL, 'obj'],
    TOKEN_NAMES.PROPERTY_ACCESSOR,
    [TOKEN_NAMES.SYMBOL, 'a'],
    TOKEN_NAMES.PROPERTY_ACCESSOR,
    [TOKEN_NAMES.SYMBOL, 'b'],
    TOKEN_NAMES.END_STATEMENT
  ];
  const ast = parse(tokens);

  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.PROPERTY_LOOKUP,
        expr: {
          type: STATEMENT_TYPE.PROPERTY_LOOKUP,
          expr: {
            type: STATEMENT_TYPE.SYMBOL_LOOKUP,
            symbol: 'obj',
          },
          property: 'a',
        },
        property: 'b',
      }
    ]
  })))
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
  assert(is(ast, fromJS({
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
  })))
});

it('should parse assignment with variable & literal', () => {
  const program = tokenize(`
  let a = 1;
  let b = a + 1;
  `);
  const ast = parse(program);
  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.DECLARATION,
        mutable: false,
        symbol: 'a',
        expr: {
          type: STATEMENT_TYPE.NUMBER_LITERAL,
          value: 1
        }
      },
      {
        type: STATEMENT_TYPE.DECLARATION,
        mutable: false,
        symbol: 'b',
        expr: {
          type: STATEMENT_TYPE.FUNCTION_APPLICATION,
          expr: symbolLookup({symbol: '+'}),
          paramExprs: [
            {
              type: STATEMENT_TYPE.SYMBOL_LOOKUP,
              symbol: 'a'
            },
            {
              type: STATEMENT_TYPE.NUMBER_LITERAL,
              value: 1
            }
          ]
        }
      }
    ]
  })));
});

it('should parse function statements', () => {
  const program = tokenize(`
  let makeCounter = () => {
  };
  `);
  // console.log(program);
  const ast = parse(program);
  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      {
        type: STATEMENT_TYPE.DECLARATION,
        mutable: false,
        symbol: 'makeCounter',
        expr: {
          type: STATEMENT_TYPE.FUNCTION,
          paramNames: [],
          body: []
        }
      }
    ]
  })))
});

it('should parse double function application', () => {
  const program = tokenize(`
  let f = (a) => (b) => a + b;
  let h = f(1)(2);
  `);
  const ast = parse(program);
  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        mutable: false,
        symbol: 'f',
        expr: fn({
          paramNames: ['a'],
          body: [
            _return({
              expr: fn({
                paramNames: ['b'],
                body: [
                  _return({expr: fnCall({
                    expr: symbolLookup({symbol: '+'}),
                    paramExprs: [symbolLookup({symbol: 'a'}), symbolLookup({symbol: 'b'})]
                  })})
                ]
              })
            })
          ]
        })
      }),
      declaration({
        mutable: false,
        symbol: 'h',
        expr: fnCall({
          expr: fnCall({
            expr: symbolLookup({symbol: 'f'}),
            paramExprs: [numberLiteral({value: 1})]
          }),
          paramExprs: [numberLiteral({value: 2})]
        })
      })
    ]
  })))
})

it('should parse call function from object property', () => {
  const program = tokenize(`
  let h = {
    a: () => 3
  };
  let b = h.a();
  `);
  const ast = parse(program);
  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [  
      declaration({
        mutable: false,
        symbol: 'h',
        expr: objectLiteral({
          value: {
            a: fn({
              paramNames: [],
              body: [_return({expr: numberLiteral({value: 3})})]
            })
          }
        })
      }),
      declaration({
        mutable: false,
        symbol: 'b',
        expr: fnCall({
          expr: propertyLookup({
            property: 'a',
            expr: symbolLookup({symbol: 'h'})
          }),
          paramExprs: []
        })
      })
    ]
  })))
});

it('should parse object dot operator within function call', () => {
  const program = tokenize(`
  print(c.x);
  `);
  const ast = parse(program);
  // console.log(ast.body[0])
  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      fnCall({
        expr: symbolLookup({symbol: 'print'}),
        paramExprs: [
          propertyLookup({
            property: 'x',
            expr: symbolLookup({symbol: 'c'})
          })
        ]
      })
    ]
  })))
});

it('should parse dot operator after function call', () => {
  const program = tokenize(`
  let f = () => {
    return { x: 3 };
  };
  let c = f().x;
  `);
  const ast = parse(program);
  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        mutable: false,
        symbol: 'f',
        expr: fn({
          paramNames: [],
          body: [_return({expr: objectLiteral({value: {x: numberLiteral({value: 3})}})})]
        })
      }),
      declaration({
        mutable: false,
        symbol: 'c',
        expr: propertyLookup({
          property: 'x',
          expr: fnCall({
            expr: symbolLookup({symbol: 'f'}),
            paramExprs: []
          })
        })
      })
    ]
  })))
})

it('should parse object with operator expressions inside', () => {
  const program = tokenize(`
  let f = { x: 1 + 3 };
  `);
  const ast = parse(program);
  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        mutable: false,
        symbol: 'f',
        expr: objectLiteral({value: {
          x: fnCall({
            expr: symbolLookup({symbol: '+'}),
            paramExprs: [
              numberLiteral({value: 1}),
              numberLiteral({value: 3})
            ]
          })
        }})
      })
    ]
  })));
});

it('should parse fn call inside fn call', () => {
  const program = tokenize(`
  print(f());
  `);
  const ast = parse(program);
  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      fnCall({
        expr: symbolLookup({symbol: 'print'}),
        paramExprs: [
          fnCall({
            expr: symbolLookup({symbol: 'f'}),
            paramExprs: []
          })
        ]
      })
    ]
  })));
});

it('should parse double nested fn call inside fn call', () => {
  const program = tokenize(`
  print(f()());
  `);
  const ast = parse(program);
  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      fnCall({
        expr: symbolLookup({symbol: 'print'}),
        paramExprs: [
          fnCall({
            expr: fnCall({
              expr: symbolLookup({symbol: 'f'}),
              paramExprs: [],
            }),
            paramExprs: []
          })
        ]
      })
    ]
  })));
});

it('should parse if cond', () => {
  const program = tokenize(`
  if (a == 3) {
  }
  `);
  const ast = parse(program);
  // console.log(JSON.stringify(ast, null, 2));

  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      conditional({
        expr: fnCall({
          expr: symbolLookup({ symbol: '==' }),
          paramExprs: [
            symbolLookup({ symbol: 'a' }),
            numberLiteral({ value: 3 })
          ]
        }),
        pass: fnCall({ expr: fn({ body: [] }) }),
        fail: fnCall({ expr: fn({ body: [] }) })
      })
    ]
  })))
});

it('should parse inline if', () => {
  const ast = parse(tokenize(`
  if (true) 3
  `));

  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      conditional({
        expr: booleanLiteral({ value: true }),
        pass: fnCall({ expr: fn({ body: [_return({ expr: numberLiteral({ value: 3 }) })] }) }),
        fail: fnCall({ expr: fn({ body: [] }) })
      })
    ],
  })))
});


it('should parse inline if else', () => {
  const ast = parse(tokenize(`
  let a = if (true) 3 else 4;
  `));

  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        symbol: 'a',
        expr: conditional({
          expr: booleanLiteral({ value: true }),
          pass: fnCall({ expr: fn({ body: [_return({ expr: numberLiteral({ value: 3 }) })] }) }),
          fail: fnCall({ expr: fn({ body: [_return({ expr: numberLiteral({ value: 4 }) })] }) })
        })
      })
    ],
  })));
});



it('should parse inline if elif else', () => {
  const ast = parse(tokenize(`
  let a = if (true) 3 elif (false) 5 else 4;
  `));

  // console.log(JSON.stringify(ast, null, 2));

  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        symbol: 'a',
        expr: conditional({
          expr: booleanLiteral({ value: true }),
          pass: fnCall({ expr: fn({ body: [_return({ expr: numberLiteral({ value: 3 }) })] }) }),
          fail: fnCall({ expr: fn({ body: [conditional({
            expr: booleanLiteral({ value: false }),
            pass: fnCall({ expr: fn({ body: [_return({ expr: numberLiteral({ value: 5 }) })] }) }),
            fail: fnCall({ expr: fn({ body: [_return({ expr: numberLiteral({ value: 4 }) })] }) }),
          })] }) })
        })
      })
    ],
  })))
});

it('should parse if else cond', () => {
  const program = tokenize(`
  if (a == 3) {
    return 'str';
  } else {
    return 5;
  }
  `);
  const ast = parse(program);

  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      conditional({
        expr: fnCall({
          expr: symbolLookup({ symbol: '==' }),
          paramExprs: [
            symbolLookup({ symbol: 'a' }),
            numberLiteral({ value: 3 })
          ]
        }),
        pass: fnCall({ expr: fn({ body: [_return({ expr: stringLiteral({value: 'str'}) })] }) }),
        fail: fnCall({ expr: fn({ body: [_return({ expr: numberLiteral({value: 5}) })] }) })
      })
    ]
  })))
});

it('should parse if elif else cond', () => {
  const program = tokenize(`
  if (a == 3) {
    return 'str';
  } elif (b == 4) {
  } else {
    return 5;
  }
  `);
  const ast = parse(program);
  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      conditional({
        expr: fnCall({
          expr: symbolLookup({ symbol: '==' }),
          paramExprs: [
            symbolLookup({ symbol: 'a' }),
            numberLiteral({ value: 3 })
          ]
        }),
        pass: fnCall({ expr: fn({ body: [_return({ expr: stringLiteral({value: 'str'}) })] }) }),
        fail: fnCall({ expr: fn({
          body: [
            conditional({
              expr: fnCall({
                expr: symbolLookup({ symbol: '==' }),
                paramExprs: [
                  symbolLookup({ symbol: 'b' }),
                  numberLiteral({ value: 4 })
                ]
              }),
              pass: fnCall({ expr: fn({ body: [] }) }),
              fail: fnCall({ expr: fn({ body: [_return({ expr: numberLiteral({value: 5}) })] }) })
            })
          ]
        }) })
      })
    ]
  })))
});

it('should parse array lookup', () => {
  const program = tokenize(`
  let a = [1, 2, 3][2];
  `);
  const ast = parse(program);
  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        expr: dynamicLookup({
          expr: arrayLiteral({
            elements: [
              numberLiteral({value: 1}),
              numberLiteral({value: 2}),
              numberLiteral({value: 3})
            ]
          }),
          lookupKey: 2
        }),
        symbol: 'a'
      })
    ]
  })))
});


it('should parse array lookup on symbol', () => {
  const program = tokenize(`
  let a = arr[2];
  `);
  const ast = parse(program);
  // console.log(ast.body[0].expr.expr);
  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        expr: dynamicLookup({
          expr: symbolLookup({ symbol: 'arr' }),
          lookupKey: 2
        }),
        symbol: 'a'
      })
    ]
  })))
});


it('should parse match expression', () => {
  const program = tokenize(`
  let a = match (true) {
    true => 'str'
  };
  `);
  // TODO: make true a token
  const ast = parse(program);
  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        mutable: false,
        symbol: 'a',
        expr: matchExpression({
          expr: booleanLiteral({ value: true }),
          cases: [
            matchCase({
              expr: booleanLiteral({ value: true }),
              invoke: fnCall({
                expr: fn({
                  body: [_return({ expr: stringLiteral({ value: 'str' }) })]
                }),
              })
            })
          ]
        }),
      })
    ]
  })))
});

it('should parse match expression with multiple cases', () => {
  const program = tokenize(`
  let a = match (true) {
    true => 'str',
    [1, 2] => {
      let b = 3;
      return b + 5;
    }
  };
  `);
  const ast = parse(program);
  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        mutable: false,
        symbol: 'a',
        expr: matchExpression({
          expr: booleanLiteral({ value: true }),
          cases: [
            matchCase({
              expr: booleanLiteral({ value: true }),
              invoke: fnCall({
                expr: fn({
                  body: [_return({ expr: stringLiteral({ value: 'str' }) })]
                }),
              })
            }),
            matchCase({
              expr: arrayLiteral({ elements: [numberLiteral({ value: 1 }), numberLiteral({ value: 2 })] }),
              invoke: fnCall({
                expr: fn({
                  body: [
                    declaration({
                      mutable: false,
                      symbol: 'b',
                      expr: numberLiteral({ value: 3 })
                    }),
                    _return({ expr: fnCall({
                      expr: symbolLookup({ symbol: '+' }),
                      paramExprs: [
                        symbolLookup({ symbol: 'b' }),
                        numberLiteral({ value: 5 })
                      ]
                    }) })
                  ]
                }),
              })
            })
          ]
        }),
      })
    ]
  })))
});

it('should parse match expression with bound variable', () => {
  const program = tokenize(`
  let a = match ('hello') {
    a => a + ' world!'
  };
  `);
  const ast = parse(program);
  // console.log(JSON.stringify(ast.toJS(), null, 2));
  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        mutable: false,
        symbol: 'a',
        expr: matchExpression({
          expr: stringLiteral({ value: 'hello' }),
          cases: [
            matchCase({
              expr: boundVariable({ symbol: 'a' }),
              invoke: fnCall({
                expr: fn({
                  paramNames: ['a'],
                  body: [
                    _return({
                      expr: fnCall({
                        expr: symbolLookup({ symbol: '+' }),
                        paramExprs: [
                          symbolLookup({ symbol: 'a' }),
                          stringLiteral({ value: ' world!' })
                        ]
                      })
                    })
                  ]
                }),
                paramExprs: [
                  fnCall({
                    expr: fn({
                      paramNames: ['arg'],
                      body: [_return({ expr: symbolLookup({ symbol: 'arg' }) })]
                    }),
                    paramExprs: [ stringLiteral({ value: 'hello' }) ]
                  })
                ]
              })
            }),
          ]
        }),
      })
    ]
  })))
});


it('should parse match expression with bound variable in array', () => {
  const program = tokenize(`
  let a = match (['hello']) {
    [a] => a + ' world!'
  };
  `);
  const ast = parse(program);
  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        mutable: false,
        symbol: 'a',
        expr: matchExpression({
          expr: arrayLiteral({ elements: [stringLiteral({ value: 'hello' })] }),
          cases: [
            matchCase({
              expr: arrayLiteral({ elements: [boundVariable({ symbol: 'a' })] }),
              invoke: fnCall({
                expr: fn({
                  paramNames: ['a'],
                  body: [
                    _return({
                      expr: fnCall({
                        expr: symbolLookup({ symbol: '+' }),
                        paramExprs: [
                          symbolLookup({ symbol: 'a' }),
                          stringLiteral({ value: ' world!' })
                        ]
                      })
                    })
                  ]
                }),
                paramExprs: [
                  fnCall({
                    expr: fn({
                      paramNames: ['arg'],
                      body: [_return({expr: dynamicLookup({ expr: symbolLookup({ symbol: 'arg'}), lookupKey: 0 }) })],
                    }),
                    paramExprs: [
                      arrayLiteral({ elements: [stringLiteral({ value: 'hello' })] })
                    ]
                  })
                ]
              })
            }),
          ]
        }),
      })
    ]
  })))
});

it('should eval pattern matching w diff levels of nested arrays', () => {
  const program = tokenize(`
  let three = match ([1, [2]]) {
    [a, [b]] => a * b
  };
  `);
  const ast = parse(program);

  const arrArg = arrayLiteral({ elements: [
    numberLiteral({ value: 1 }),
    arrayLiteral({ elements: [ numberLiteral({ value: 2 }) ]})
  ] });
  // console.log(JSON.stringify(ast.toJS(), null, 2))

  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        mutable: false,
        symbol: 'three',
        expr: matchExpression({
          expr: arrArg,
          cases: [
            matchCase({
              expr: arrayLiteral({ elements: [
                boundVariable({ symbol: 'a' }),
                arrayLiteral({ elements: [boundVariable({ symbol: 'b' })]})
              ] }),
              invoke: fnCall({
                expr: fn({
                  paramNames: ['a', 'b'],
                  body: [
                    _return({
                      expr: fnCall({
                        expr: symbolLookup({ symbol: '*' }),
                        paramExprs: [
                          symbolLookup({ symbol: 'a' }),
                          symbolLookup({ symbol: 'b' })
                        ]
                      })
                    })
                  ]
                }),
                paramExprs: [
                  fnCall({
                    expr: fn({
                      paramNames: ['arg'],
                      body: [_return({expr: dynamicLookup({ expr: symbolLookup({ symbol: 'arg'}), lookupKey: 0 }) })],
                    }),
                    paramExprs: [arrArg]
                  }),
                  fnCall({
                    expr: fn({
                      paramNames: ['arg'],
                      body: [_return({expr: dynamicLookup({ expr: dynamicLookup({ expr: symbolLookup({ symbol: 'arg'}), lookupKey: 1 }), lookupKey: 0 }) })],
                    }),
                    paramExprs: [arrArg]
                  })
                ]
              })
            }),
          ]
        }),
      })
    ]
  })))  
})

it('should parse objects with string as key', () => {
  const program = tokenize(`
  let obj = { 'a key': 3 };
  `)
  const ast = parse(program);

  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        symbol: 'obj',
        expr: objectLiteral({
          value: {
            'a key': numberLiteral({ value: 3 })
          }
        })
      })
    ]
  })))
})

it('should parse lookup', () => {
  const program = tokenize(`
  let obj = { 'a key': 3 };
  let b = obj['a key'];
  `)
  const ast = parse(program);

  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        symbol: 'obj',
        expr: objectLiteral({
          value: {
            'a key': numberLiteral({ value: 3 })
          }
        })
      }),
      declaration({
        symbol: 'b',
        expr: dynamicLookup({
          expr: symbolLookup({ symbol: 'obj' }),
          lookupKey: 'a key'
        })
      })
    ]
  })))
});

it('should parse object deconstruction in match', () => {
  const program = tokenize(`
  let eight = match ({ a: 2, b: 4 }) {
    { a, b } => a * b
  };
  `);
  const ast = parse(program);

  const matchArg = objectLiteral({ value: {
    a: numberLiteral({ value: 2}),
    b: numberLiteral({ value: 4})
  }});
  // console.log(JSON.stringify(ast.toJS(), null, 2))

  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        mutable: false,
        symbol: 'eight',
        expr: matchExpression({
          expr: matchArg,
          cases: [
            matchCase({
              expr: objectDeconstruction({ expr: {
                a: boundVariable({ symbol: 'a' }),
                b: boundVariable({ symbol: 'b' })
              } }),
              invoke: fnCall({
                expr: fn({
                  paramNames: ['a', 'b'],
                  body: [
                    _return({
                      expr: fnCall({
                        expr: symbolLookup({ symbol: '*' }),
                        paramExprs: [
                          symbolLookup({ symbol: 'a' }),
                          symbolLookup({ symbol: 'b' })
                        ]
                      })
                    })
                  ]
                }),
                paramExprs: [
                  fnCall({
                    expr: fn({
                      paramNames: ['arg'],
                      body: [_return({expr: dynamicLookup({ expr: symbolLookup({ symbol: 'arg'}), lookupKey: 'a' }) })],
                    }),
                    paramExprs: [matchArg]
                  }),
                  fnCall({
                    expr: fn({
                      paramNames: ['arg'],
                      body: [_return({expr: dynamicLookup({ expr: symbolLookup({ symbol: 'arg'}), lookupKey: 'b' }) })],
                    }),
                    paramExprs: [matchArg]
                  })
                ]
              })
            }),
          ]
        }),
      })
    ]
  })));
});

it('should parse arrow function w 1 param not needing ()', () => {
  const program = tokenize(`
  let id = x => x;
  `);
  const ast = parse(program);
  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        symbol: 'id',
        expr: fn({
          paramNames: ['x'],
          body: [_return({ expr: symbolLookup({ symbol: 'x' })})]
        })
      })
    ]
  })))
});

it('should parse piping array literal', () => {
  const program = tokenize(`
  let powers = [1, 2, 3] |> List.map(x => x * x);
  `)
  const ast = parse(program);
  // console.log(JSON.stringify(ast.toJS(), null, 2))
  assert(is(ast, fromJS({
    type: STATEMENT_TYPE.PROGRAM,
    body: [
      declaration({
        symbol: 'powers',
        expr: fnCall({
          expr: symbolLookup({ symbol: '|>' }),
          paramExprs: [
            arrayLiteral({ elements: [numberLiteral({ value: 1}), numberLiteral({ value: 2}), numberLiteral({ value: 3})]}),
            fnCall({
              expr: propertyLookup({ property: 'map', expr: symbolLookup({ symbol: 'List' }) }),
              paramExprs: [ fn({
                paramNames: ['x'],
                body: [_return({ expr:
                  fnCall({
                    expr: symbolLookup({ symbol: '*' }),
                    paramExprs: [symbolLookup({ symbol: 'x'}), symbolLookup({ symbol: 'x'})]
                  })})]
              }) ]
            })
          ]
        })
      })
    ]
  })))
});

console.log('Passed', passed, 'tests!');