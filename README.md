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
- [x] functions with a body
- [x] math operators (+, -, *, /)
- [x] function arguments
- [x] `let obj = { a: 3 }`
- [x] if & if else & elif
- [x] match expressions
- [x] arrays
- [x] object deconstruction
- [x] array deconstruction

## Parser

- [x] `let var = 3;`
- [x] `let mut var = 5;`
- [ ] `let var = 'string';`
- [x] `var = 5;`
- [x] `let function = () => 3;`
- [ ] functions with a body
- [ ] function arguments
- [ ] function arguments used in body
- [x] function with variable lookup
- [x] `let obj = { a: 3 }`
- [ ] if & if else

## Interpreter

- [x] `let var = 3;`
- [x] `let mut var = 5;`
- [ ] `let var = 'string';`
- [ ] `var = 5;`
- [x] `let function = () => 3;`
- [x] `function()`
- [ ] functions with a body
- [ ] function arguments
- [ ] function arguments used in body
- [x] function with variable lookup
- [x] `let obj = { a: 3 }`
- [ ] if & if else
