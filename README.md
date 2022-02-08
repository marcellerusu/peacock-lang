# Peacock

A dynamic functional language aimed at bringing joy to the front-end

Inspired by the power of clojure spec & the joy of ruby

## Core Features

### Schemas

Schemas are how we describe the state in our program

```
# Helper schemas that would be provided by peacock
schema NotNil = fn val => !val.nil? end
schema Loading = { loading: true }
schema Loaded = { loading: false, error: nil }
schema Error = { loading: false, error: NotNil }

# User code
schema User = { id, email, created_at }

class UserAdmin < Element =
  style Loading _ _ = "background: grey;"
  style Error _ _ = "background: red;"
  style Loaded _ _ = "background: green;"

  view Loading _ _ =
    <div>
      Loading user!
    </div>
  view Error _ _ =
    <div>
      Error loading user
    </div>
  view User({ email, created_at }) _ _ =
    <div>
      User details
      <div>[email = {email}]</div>
      <div>[created_at = {created_at}]</div>
    </div>
```

### Immutable data structures

The core data structures are `List` `Record` `Int` `Float` `Str` `Sym`, all of which are immutable [will implement collections as persistent immutable structures]
