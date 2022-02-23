# <img src="https://user-images.githubusercontent.com/7607387/153535569-5c42a9a9-73bb-447a-a0d9-7aa521ebd52f.png" height=50 /> Peacock

A beautiful language aimed at bringing joy & control to the front-end

# Core Values

- Readable code > concise code
- Validate as soon as possible
- Aesthetics matter
- A little WETness is better than too much DRYness

# Core Features

## Schemas

Schemas are the primary method of validating state in our application

At a first glance, schemas will look similar to TypeScript style type definitions. This is intentional.

The difference between types & schemas are that schemas are checked at run-time.

Q: Isn't this a huge disadvantage since it impacts runtime performance?

A: That is true, runtime validation will always be slower than static, but all abstractions have pros & cons. The pro for schemas are much strong guarantees & automatic parsing. As an addition to address performance, we can cache validation so we don't revalidate the same information multiple times.

- For example, a schema can be a predicate (function) which takes the data & returns true or false.
  - Example: `schema OlderThan20 = { age: #{ % > 20 } }`

In the code example below `NewUser` is only valid if the data has a created_at property that has a value within the range `Time::last_week..Time::now`. This is not possible to validate statically.

Another advantage of schemas over types is typically in a statically typed language, you have write both type & the validation code to ensure data fits into that type. In Peacock we can simply do `NewUser(user) := untrusted_data`.

Note: I am not saying schemas are strictly better than type systems, this is a trade off. We lose many benefits, such as compile time correctness & possible optimizations from static analysis. In the future it would be nice to do more static analysis, but the immediate goal is to address the problem of runtime validation.

Here is an example of a common issue in front end, data fetching & handling of unique data responses.

```ruby
schema Loading = { loading: true }
schema WebError = { loading: false, error: NotNil }
schema Loaded<T> = { data: T, loading: false, error: nil }

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
  def view(WebError, _, _)
    <div>
      Error loading user
    </div>
  end
  def view(Loaded<User({ email, created_at })>, _, _)
    <div>
      User details
      [email = {email}]
      [created_at = {created_at}]
    </div>
  end
  def view(Loaded<NewUser(user)>)
    <div>
      <Tutorial user={user}/>
    </div>
  end
end
```

## Immutable data structures

Strong & first class immutable data structures are extremely beneficial in working in a data-first codebase.

They are useful for problems such as concurrency, optimized state diffing algorithms & tracking state flow.

The core data structures in Peacock are `List`, `Record`, `Int`, `Float`, `Str`, `Sym`, `Nil` all of which are immutable.

Q: What if I need mutation in my code?

A: Mutation is possible via classes, see below. If you want more, you can directly interface with JavaScript. It is intentionally meant to feel a bit of friction when mutating, since isn't rarely the idiomatic way of programming in Peacock.

## Classes

Classes are a useful & powerful tool, but can be easily misused. This doesn't eliminate their value though.

In Peacock, they are the only place where mutation is possible.

Q: Why not just use pure functions?

A: I found classes to be very useful for data transformations that produce artifacts (errors, tracking context). Its possible to write pure immutable functional code that tracks these artifacts, but I found myself "reinventing the wheel" by writing difficult to read closures, or using abstractions I found complex. Instead I think it is much simpler & elegant to use the provided abstraction of instance variables that classes provide.

```ruby
class FormValidator
  def init(fields)
    @fields := fields
    @errors := []
  end

  def push_error!(error)
    @errors := @errors.push error
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
