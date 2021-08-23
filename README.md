# WIP m-lang

```
# pattern matching

let expr = match ([1, 2]) {
  [] => 'Congrats... sorta',
  [1] => 'Oh no',
  [1, 2] => 'YES!'
};

```


## Tokenizer

- [x] `let var = 3;`
- [x] `let mut var = 5;`
- [ ] comments - # -- take out here
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
- [x] `let obj = { a: 3 };`
 - [x] objects with functions as values
- [x] arrays
- [ ] if, else & elif expressions
- [ ] match expressions
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
  - [ ] rhs should be any expression
    - [x] number literal
    - [x] symbol lookup
    - [ ] object property lookup
  - [ ] lhs should be any expression
- [x] functions with a body
- [x] function arguments
- [x] function arguments used in body
- [x] function with variable lookup
- [x] `let obj = { a: 3 };`
- [x] arrays
- [ ] if, else & elif
- [ ] match expressions
- [ ] object deconstruction
- [ ] array deconstruction
- [x] object property accessor (.)