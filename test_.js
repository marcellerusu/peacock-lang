let items = [...]

function updateItem(id) {
  return items.map(item => {
    if (item.id === id) {
      return {...item, property: 'something'}
    } else {
      return item
    }
  })
}

items = updateItem("id")
