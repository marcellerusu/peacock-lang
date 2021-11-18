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

```

# Broken Things

# Not Implemented Things

```
# Dynamic property lookup
# on arrays
[1, 2, 3][0]
# on objects
{string: 3}["string"]
```
