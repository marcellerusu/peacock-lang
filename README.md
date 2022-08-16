# Intro

Peacock is an exploration of how far we can take pattern matching to tame the complexity in JavaScript

The language does not implement new data structures for the most part since we aim to be highly compatible with the javascript ecosystem & specifically web standards.

## Syntax Primer

### Hello World

```
console.log "Hello world"
```

### Array methods

- As you would expect in JavaScript

```
# this will print [3]
console.log [1, 2, 3]
  .filter(num => num > 2)
  .map(num => num * 10)
```

### Functions

#### 1 line functions

```
function add(a, b) = a + b
```

#### Multline

- end with `end`
- last expression is returned

```
function safe_divide(a, b)
  panic! "division by zero" if b === 0
  a / b
end
```

#### Bind operator

see javascript's [bind operator proposal](https://github.com/tc39/proposal-bind-operator)

- this is an elegant way to write generic functions that chain without modifying core data structures

```
function to_a = Array.from(this)

console.log new Set([1, 2, 3])::to_a
```

### Schemas

- Schemas are shapes or predicates that can be used to verify data

```
schema User = { id }
```

We can use it where we pattern match.

#### Match Assignment

```
User(marcelle) := { id: 10 }
```

#### Predicates

```
schema EarlyBird = { id: #{ % <= 1000 } }

case user
when EarlyBird
  console.log "Invite your friends!"
end
```

#### Functions

Let's see how we can handle the division by 0 more elegantly without needing to liter the function body with panic!

```
schema NotZero = #{ % !== 0 }
```

in the example above we can rewrite it to be

```
function safe_divide(a, NotZero(b)) = a / b
```

#### Case Functions

```
schema Loading = { loading: true }
schema Error = { error! } # { error: #{ % != null }}
schema Loaded = { data! }

case function render
when (Loading)
  console.log "loading"
when (Error({ error: { msg } }))
  console.error "Error: #{msg}"
when (Loaded({ data }))
  console.log "Loaded", data
end

render { loading: true }
render { error: { msg: "Api failed" } }
render { data: { id: 10 } }
```

#### Case Functions & Bind Patterns

- if you saw the bind example before was relatively limited, lets fix that

```
case function to_a
when Array::()
  this
when String::() | Set::()
  Array.from this
when Object::()
  Object.entries this
end

console.log [1, 2, 3]::to_a
console.log new Set([1, 2, 3])::to_a
console.log "abc"::to_a
console.log { a: 10, b: 20 }::to_a

```

## Optimizations

Schemas carry multiple meanings when implemented.

First and for most they are named patterns that can be used in any case expression or function definition.

This usually is implemented as a runtime feature but it can also be optimized to be partially implemented at compile time as a type.

lets take an example.

```
NotZero(a) := 10

# safe_divide is defined above.

safe_divide(20, a)
```

Without any optimizations the following code would be generated

```js
let a;

a = s.verify(NotZero, 10);

s.verify(NotZero, a);
safe_divide(20, a);
```

There are 2 issues.

- We are verifying that `a` is `NotZero` twice without `a` changing.
- we know that 10 is not 0, so we could evaluate the predicate as compile time.

With optimizations the output is

```js
let a;

a = 10;

safe_divide(20, a);
```

These are the ways that Peacock can use high level features like pattern matching quite a lot with reasonable performance.
