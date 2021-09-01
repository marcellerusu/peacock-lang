# WIP m-lang

# BIG goals

## pattern matching [ done ]

```
let product = (vec) => match (vec) {
  [x, y] => x * y,
  [x, y, z] => x * y * z
};
```

## almost everything is an expression [ done ]

only thing that is not an expression is `let` statements

## immutable data structures [ done ]

uses immutable.js underneath

## auto-currying [ not started ]

let f = (a, b) => a + b;
let add1 = f(1);
print(add1(2)); # 3

## Tokenizer

- [x] `let var = 3;`
- [x] `let mut var = 5;`
- [x] comments - # -- take out here
- [x] `let var = 'string';`
- [x] `let function = () => 3;`
- [x] functions with a body (& explicit return)
- [x] math operators (+, -, *, /)
- [x] function arguments
- [x] `let obj = { a: 3 }`
- [x] if, else & elif
- [x] match expressions
- [x] arrays
- [x] object deconstruction
- [ ] object rest operator
- [x] array deconstruction
- [ ] array rest operator
- [x] object property accessor (.)

## Parser

- [x] `let var = 3;`
- [x] `let mut var = 5;`
- [x] `let var = 'string';`
- [x] `var = 5;`
- [x] `let function = () => 3;`
- [x] function with variable lookup
- [x] function arguments in definition
- [x] function arguments used in body
- [x] call function with arguments
- [x] function statements
- [x] arbitrarily nested function calls
- [x] objects
- [x] arrays
 - [x] index lookup
- [x] if, else & elif expressions
 - [x] single line if elif else
- [x] match expressions
- [ ] import statements
- [ ] objects with strings as keys
- [ ] object string lookup
- [ ] object deconstruction
- [ ] array deconstruction
- [x] math operators
- [x] object property accessor (.)

## Interpreter

- [x] `let var = 3;`
- [x] `let mut var = 5;`
- [x] `let var = 'string';`
- [x] `var = 5;`
- [x] `let function = () => 3;`
- [x] `function()`
- [x] operators
- [x] functions with multiple statements
- [x] function arguments
- [x] function arguments used in body
- [x] function with variable lookup
- [x] `let obj = { a: 3 };`
- [x] arrays
 - [x] index lookup
- [x] if, else & elif
- [ ] objects with strings as keys
- [ ] object string lookup
- [x] match expressions
- [ ] object deconstruction
- [ ] array deconstruction
- [x] object property accessor (.)


# interesting ideas

generate md files from source files from comments