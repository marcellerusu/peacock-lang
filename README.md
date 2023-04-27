## Not Active Project

Peacock was a language I designed when I observed a lot of code like this.

```jsx
function PersonalYouTubeChannelLibrary() {
  let [videos, setVideos] = useState(null);
  let [error, setError] = useState(null);
  useEffect(() => {
    fetch(API.videos)
      .then((r) => r.json())
      .then(setVideos)
      .catch(setError);
  }, []);
  if (error) {
    return <div>You got an error :(</div>;
  } else if (!videos) {
    return <div>You Have no Videos yet! Make one</div>;
  } else if (videos.length === 1) {
    if (firstTimeViewingChannelSinceCreated(videos[0]))
      return <div>Congrats on creating your first video</div>;
  } else if (videos.length >= 50) {
    return <div>Congrats on 50 videos, considering upgrading to X tier</div>;
  } else {
    return <div>here are your videos</div>;
  }
}
```

Expressing complex states in vanilla js is hard.

At the same time, I did some small projects in Elixir and I was blown away by the expressive power of pattern matching.

I also read up a fair bit on clojure.spec, and the ideas of "patterns" as data. I thought, that's where peacock came out of:

The power of clojure's pattern as data, inspired by the usability from elixir and the syntax from typescript.

Patterns are expressive, but if they are not data, they cannot be reused.

Peacock patterns are simple data structures, and you can store patterns in variables and create new patterns from combining old patterns.

Here's some peacock code

```
schema User = {name, age}

User(me) := {name: "marcelle", age: 25}
```

Schemas are pattern definitions, and what we were doing here was creating a variable 'me' who was validated by 'User'.

You could also do this

```
schema Teenager = User & {age: #{ it < 20 }}

Teenager(me) := me # throws error
```

We've combined the User schema with a new pattern, and peacock holds me accountable in pretending to be a hip teen.

The goal of peacock was to take patterns and make them approachable to js/ts folks.

The aspirations for peacock was to be a full blown frontend framework, but this I think was the ultimately the downfall, it tried to do too much.

Another flaw I found with this system is that pattern matching is fundamentally limited, it developed closed systems that can not be extended from the outside.

There are many times this is great - state machines for example, but as a basis for a language it is far too limited.

To see more recent work, check out my other language coil-lang.
