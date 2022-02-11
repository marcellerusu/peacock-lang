
# <img src="https://user-images.githubusercontent.com/7607387/153535569-5c42a9a9-73bb-447a-a0d9-7aa521ebd52f.png" height=50 /> Peacock

A dynamic functional language aimed at bringing joy to the front-end

Inspired by the power of clojure spec & the joy of ruby

## Core Features

### Schemas

Schemas are how we describe the state in our program


```
schema Loading = { loading: true }
schema Loaded = { loading: false, error: nil }
schema WebError = { loading: false, error: NotNil }

# User code
schema User = { id, email, created_at }

class UserAdmin < Element
  def style(Loading, _, _) = "background: grey;"
  def style(WebError, _, _) = "background: red;"
  def style(Loaded, _, _) = "background: green;"

  view (Loading, _, _)
    <div>
      Loading user!
    </div>
  end
  view (Error, _, _)
    <div>
      Error loading user
    </div>
  end
  view (User({ email, created_at }), _, _)
    <div>
      User details
      <div>[email = {email}]</div>
      <div>[created_at = {created_at}]</div>
    </div>
  end
end
```

### Immutable data structures

The core data structures are `List` `Record` `Int` `Float` `Str` `Sym` `Nil`, all of which are immutable [will implement collections as persistent immutable structures]
