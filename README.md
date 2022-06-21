Peacock is a compile-to-js language that aims at embracing JavaScript while adding minimal syntax for "schemas"

The syntax is heavily inspired by ruby in efforts to bring some of the beauty of ruby but without drastically changing the language of JavaScript

A primary goal is to use plain JavaScript data types & emit idiomatic JavaScript.

For example, a more complex pattern in peacock like this, of updating a value in a list

```ruby
# todos := [{ id: 10, completed: false, ... }, ...]

def updateTodo(id, todoList) =
  for todoList of
    { id: id, ...todo } => { ...todo, id, completed: true },
    continue
  end
```

would get compiled to the following JavaScript

```javascript
// let todos = [{ id: 10, completed: false, ... }, ...]

function updateTodo(id, todoList) {
  return todoList.map((_elem) => {
    if (_elem.id === id) {
      let { id, ...todo } = _elem;
      return { ...todo, id, completed: true };
    }
  });
}
```
