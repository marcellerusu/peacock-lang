# Peacock

A small fun dynamic FP language

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
{string: 3}["string"]

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
# classes

```

# Broken Things

# Not Implemented (Yet) Things

```
[a, a] := [2, 3] # Match error!

# capture bound variables & create constraints across rules
write File({ user_id: user_id }) User({ id: user_id }) = true

# import & export
# modules (ts style namespaces)
# case expressions (via schemas)
# ifs as expressions
# operator overloading (via classes)
# immutable data structures
```
