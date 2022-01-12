# Peacock

A dynamic functional language aimed at bringing joy to the front-end

Inspired by the power of clojure spec & the joy of ruby

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

all values (even primitives) are records, this is very much inspired by the joy I experienced in ruby.
