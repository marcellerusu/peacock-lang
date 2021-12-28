# Peacock

A joyful language aimed towards writing front end applications

inspired by ruby, clojure, elixir, ML family & javascript

## Core Features

### Schemas

Schemas are how we describe the state in our program

```
schema User = { id, email, created_at }
schema NewUser = User & { created_at: #{ Date::now.diff(%.created_at) < 1.month } }

class Home < Component =
  view NewUser(user) =
    <div>
      <Banner>Click here to check out a quick tour!</Banner>
      {view_body(user)}
    </div>

  view User(user) = view_body(user)

  view_body user = <div>...</div>
```

as you can see Schemas are also used for `pattern matching`.

We can also define rigid state transitions using custom constructors

```
schema Bread = { toasted, type: :white | :whole_wheat }
schema UntoastedBread = Bread & { toasted: false }
schema ToastedBread = Bread & { toasted: true }
  from UntoastedBread({ type }) to { type, toasted: true }

# This line below will fail
ToastedBread(b) := { toasted: true, type: :white }
```

`from` & `to` keywords are how we define a custom constructor before the data gets validated.

This is more than just defining rigid state machines, but also for parsing data between different formats.

### Immutable data structures

The core data structures are `List` `Record` `Int` `Float` `Str` `Sym`, all of which are immutable [will implement collections as persistent immutable structures]

### Classes

classes are the only way you can have mutation in Peacock. This is important, because although we avoid mutation at large, there are times where it is extremely convenient to have, Ex. local component state.

all values (even primitives) are objects, this is very much inspired by the joy I experienced in ruby.

# Working Things

```
# Functions
add a b = a + b
print(add(20, 20))

# Arrays
arr := [1, "2", :three]
print(arr)

# Objects
arr := { a: [1, 2, 3 ] }
print(arr, arr.a)

# Dynamic property lookup
# on arrays
[1, 2, 3][0]
# on objects
{key: 3}[:key]

# Schemas
schema GT3 = #{ % > 3 }

GT3(f) := 4
print(f) # prints '4'

GT3(t) := 3 # throw `match error`

schema Bool = true | false
schema User = { id, email, username, active: Bool, created_at }
schema ActiveUser = User & { active: false }
# Ok, Date & classes aren't implemented yet... bit of a stretch
schema NewUser = User & { created_at: #{ % > Date::start_of_month() }}

# proper value equality (will implement via operator overloading)
# wrap primitive values in classes
# case expressions (via schemas)

```

# Broken Things

classes

# Not Implemented (Yet) Things

```
[a, a] := [2, 3] # Match error!
# capture bound variables & create constraints across rules
write File({ user_id: user_id }) User({ id: user_id }) = true
# The above two examples will be implemented the same, because function arguments is an ArraySchema

# reduce expressions
# import & export
# ifs as expressions
# immutable data structures
```
