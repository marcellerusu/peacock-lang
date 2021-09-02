# m-lang

A small fun FP language for JS developers that want a more solid foundation.

## Value Equality

```
let t = [1, { a: 2 }] == [1, { a: 2 }];
print(t); # true
```

## Pattern matching

```
let product = vec => match (vec) {
  [x, y, z] => x * y * z,
  {x, y, z} => x * y * z
};
```

## Pipe operator

```
let users = [{ id: 3, country: 'canada', name: 'Marcelle' }];
let has_canadians = users
  |> List.map(Map.pick(['country']))
  |> List.includes({ country: 'canada' });

print(has_canadians); # true
```

## Immutable data structures

We use immutable.js underneath for all the core data structures, so you never have to worry about odd mutation bugs. & immutable.js implements persistent immutable data-structures, so performance is much better than you might think!

## Auto-currying

```
let f = (a, b) => a + b;
let add1 = f(1);
print(add1(2)); # 3
```

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
- [x] objects with strings as keys
- [x] object string lookup
- [ ] object deconstruction
- [ ] array deconstruction
- [x] math operators
- [x] object property accessor (.)

## compile-to-js

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
- [x] objects with strings as keys
- [x] object string lookup
- [x] match expressions
- [ ] object deconstruction
- [ ] array deconstruction
- [x] object property accessor (.)


# interesting ideas

generate md files from source files from comments