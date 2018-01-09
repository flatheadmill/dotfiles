# Synonymous Diary

Pluralization will be handled by having a file that that has a pluralization
function for each language, plus some ability to specify additional languages,
or simply a request for Pull Requests.

Then in the language we'll have something like:

```javascript
synopsis.format("there are %d %(puppy/puppies) in the puppy basket.", [ puppies, puppies ])
```

We can use pipes as an alternate in case you're plural forms have slashes in
them. Other ways around it, there it is.

```javascript
synopsis.format("there are %d %|dog/puppy|dogs/puppies| in the puppy basket.", [ puppies, puppies ])
```

If you have both pipes and slashes in your plural forms then Synonymous is not for
you, sorry.

# Word Tree

Synonymous builds a tree. At each level of the tree there is an optional string.
Each string can have branches that contain more strings.

If you request a path that does not have a string, do you get null, or empty
string, or do you panic? Let's return null and if the user wants to panic they
can NPE themselves.
