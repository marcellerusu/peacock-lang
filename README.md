Peacock has 1 main goal

Take the validation logic out of the view function

For example, lets take a look at the following typical react code

```jsx
const Admin = () => {
  const [users, setUsers] = useState(null);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);
  useEffect(() => {
    setLoading(true);
    fetch("/api/users")
      .then((r) => r.json())
      .then(setUsers)
      .catch(setError)
      .finally(() => setLoading(false));
  }, []);

  if (users === null && !loading) {
    return <div>Not loaded yet</div>;
  }
  if (loading) {
    return <div>Loading...</div>;
  }
  if (error) {
    return <div>Error loading user</div>;
  }
  if (users) {
    return (
      <div>
        {users.map((user) => (
          <User user={user} />
        ))}
      </div>
    );
  }
  // what if we want to add a specific case for when you only have 1 user?
  // - "Add 5 users to get a discount!"
  // what about if we don't have a user created within the last month
  // - "Looks like you haven't added a new user in a while.."
};
```

Lets take a look at how this might look in Peacock

```peacock
schema Error<T> = { error: T }
schema Success<T> = { data: T }
schema Loading = { loading: true }

class Admin < Component
  def init
    set_state Loading
    HTTP::fetch("/api/users")
      .then(users => set_state Success(users))
      .catch(error => set_state Error(error))
  end

  def view(_, nil, _)
    <div>
      Not loaded yet
    </div>
  end

  def view(_, Loading, _)
    <div>
      Loading...
    </div>
  end

  def view(_, Error, _)
    <div>
      Error loading user
    </div>
  end

  def view(_, Success<users>, _)
    <div>
      {users.map(user => <User user={user} />)}
    </div>
  end
end
```

Now our view functions have only 1 concern, render logic :)

Schemas utilize a powerful technique called pattern matching, and makes it even more powerful by making it a first class data type.

Schemas look a little like types, this is intentional to make it more familiar but there are some key differences.
1 - schemas do validation at runtime
2 - schemas can utilize runtime information

An example of this is say we do want to overload the view method once again for the case of there being only 1 user in the list.

```peacock
def view(_, Success<[user]>, _)
  <div>
    <Banner>Add 5 users to get a discount!</Banner>
    <User user={user} />
  </div>
end
```

What if we only want to show that banner on the first week.

```peacock
schema WithinThisWeek = date => date > Time.now - 1.week
def view(_, Success<[{ created_at: WithinThisWeek }]>, _)
  <div>
    <Banner>Add 5 users to get a discount! ending soon!</Banner>
    <User user={user} />
  </div>
end
```
