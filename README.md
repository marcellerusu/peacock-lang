# <img src="https://user-images.githubusercontent.com/7607387/153535569-5c42a9a9-73bb-447a-a0d9-7aa521ebd52f.png" height=50 /> Peacock

A dynamic functional language aimed at bringing joy & control to the front-end

# Core Values

- Aesthetics matter
- Always seek out the minimal use of abstractions
- Mutation is limited, but not eliminated
- Application state is best described in plain core data structures like Lists & Records
- Schemas should rarely be used outside of overloading Element#view or Element#style
- Classes are used minimally

# Core Features

## Schemas

Schemas are the primary method of validating state in our application

At a first glance, schemas will look similar to TypeScript style type definitions. This is intentional.

The difference between types & schemas are that schemas are checked at run-time. At first this may seem like a disadvantage, but this is actually a huge advantage. There is much more information available at runtime & we can leverage this at the most extreme by providing any predicate function as a schema.

In the example below `NewUser` is only valid if the data has a created_at property that has a value within the range `Time::last_week..Time::now`. This is not possible to validate statically (for ex, in a type system).

Another advantage of schemas over types is typically in a statically typed language, you have write both type & the validation code to ensure data fits into that type. In Peacock we can simply do `NewUser(user) := untrusted_data`.

Here is an example of a common issue in front end, data fetching & handling of unique data responses.

```
schema Loading = { loading: true }
schema Loaded = { loading: false, error: nil }
schema WebError = { loading: false, error: NotNil }

schema User = { id, email, created_at }
schema NewUser = User & { created_at: Time::last_week..Time::now }

class UserAdmin < Element
  def style(Loading, _, _) = "background: grey;"
  def style(WebError, _, _) = "background: red;"
  def style(Loaded, _, _) = "background: green;"

  def view(Loading, _, _)
    <div>
      Loading user!
    </div>
  end
  def view(Error, _, _)
    <div>
      Error loading user
    </div>
  end
  def view(User({ email, created_at }), _, _)
    <div>
      User details
      <div>[email = {email}]</div>
      <div>[created_at = {created_at}]</div>
    </div>
  end
  def view(NewUser(user))
    <div>
      <Tutorial user={user}/>
    </div>
  end
end
```

## Immutable data structures

Immutable data structures have HUGE undeniable advantages.

In the modern world of front-end we've seen how effective immutable data structures are for areas such as - props diffing, concurrent systems, unidirectional data flow & unpredictability of globally mutable data.

These problems either go away, or get dramatically simpler with strictly immutable data structures.

The core data structures are `List`, `Record`, `Int`, `Float`, `Str`, `Sym`, `Nil` all of which are immutable

## Classes

Classes are a useful & powerful tool, in recent years the misuse of power has led many people to believe that classes have no value & turned to things like data-oriented programming.

After years of working in a data-oriented/FP style, I found myself re-inventing something that looks like an immutable class over & over. Throughout the development of this language I started with class-less/minimal design & over time learned how to use classes effectively & in a disciplined manner leading me to gain a appreciation for the abstraction.

Here's an example of a Form validator as a class

```
class FormValidator
  def init(fields)
    @fields = fields
    @errors = []
  end

  def push_error!(error)
    @errors = @errors.push(error)
  end

  def validate!
    for field in @fields
      check!(field)
    end
    @errors
  end

  def check!(Input({ name: "email", value, *input }))
    case value.match /(.*)@(.*)\.(.*)/
    when RegexFail(e)
      push_error! { *input, error: e }
    end
  end
  # etc.
end
```
