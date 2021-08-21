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
- [x] `let var = 'string';`
- [x] `let function = () => 3;`
- [x] functions with a body (& explicit return)
- [x] math operators (+, -, *, /)
- [x] function arguments
- [x] `let obj = { a: 3 }`
- [x] if & if else & elif
- [x] match expressions
- [x] arrays
- [x] object deconstruction
- [x] array deconstruction
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
- [x] functions with a body
- [x] `let obj = { a: 3 }`
- [x] arrays
- [ ] if & if else & elif expressions
- [ ] match expressions
- [ ] object deconstruction
- [ ] array deconstruction
- [x] math operators
- [ ] object property accessor (.)

## Interpreter

- [x] `let var = 3;`
- [x] `let mut var = 5;`
- [ ] `let var = 'string';`
- [ ] `var = 5;`
- [x] `let function = () => 3;`
- [x] `function()`
- [ ] math operators
- [ ] functions with a body
- [ ] function arguments
- [ ] function arguments used in body
- [x] function with variable lookup
- [x] `let obj = { a: 3 }`
- [ ] if & if else
- [ ] arrays
- [ ] if & if else & elif
- [ ] match expressions
- [ ] object deconstruction
- [ ] array deconstruction
- [ ] object property accessor (.)