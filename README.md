Peacock is a compile-to-js language that aims at embracing JavaScript semantics (data structures, web standards NOT syntax) while adding support for "schemas"

The syntax is heavily inspired by ruby in efforts to bring some of the beauty of ruby but without drastically changing the language of JavaScript

A primary goal is to use plain JavaScript data types & emit idiomatic JavaScript.

I went on quite the journey to make this language & likely have a long time to go.

Initially this language was meant to be a impure Elm sorta like Derw, but after exploring more ruby & rewriting the language in ruby I fell in love.

On top of that I've been a big fan of clojure/spec for a few years & so I began trying to combine all these things together.

The beauty of ruby, the power of clojure/spec with a syntax that is familiar to js/ts developers.

A number of features have been added & removed over time.

But the primary idea is the concept of a schema

for example

```
schema User = { id, email }
```

In this example, a schema looks a lot like a type signature and can function like one, but its much more. Note that no fields are specified.

It compiles to the following code

Here's how we use it.

```
User(user) := await fetch("/api/me").then(r => r.json())
```

This is basically making an assertion that user conforms to the schema `User`.

This will be transformed to the the following JavaScript

```javascript
let User = { id: s("id"), email: s("email") };

let user = s.verify(User, await fetch("/api/me").then((r) => r.json()));
```

`s` is a runtime schema specification library. Similar to clojure/spec in some ways.

Other times the runtime library is not necessary. For example, we'll use the built-in JavaScript type constructors as schemas here

```
Number(num) := 10
```

->

```javascript
let num = 10;
```

This is a trivial case, but we aim to utilize static analysis to remove the majority of runtime checks and when possible generate code that doesn't depend on `s`.

What we end up with is a schema definition that can double as a type definition & a runtime validation. This is very powerful & we can do a lot more.

see here.

```
import differenceInCalendarDays from "date-fns/differenceInCalendarDays"
import sub from "date-fns/sub"


function verifyWithinLastWeek(Date(date))
  lastWeek := sub(new Date(), { weeks: 1 })
  return differenceInCalendarDays(date, lastWeek) > 0
end

schema NewUser = User & { createdAt: verifyWithinLastWeek }
```

NewUser only is valid for users created within the last week.
