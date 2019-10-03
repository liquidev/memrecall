# _MEM.RECALL();
[itch.io](https://lqdev.itch.io/memrecall) · [trailer](https://www.youtube.com/watch?v=79-7hRCEsGg)

This future is war. Go back in time to fix it all.

A platformer for Open Jam 2019.

## Controls

 - Left/right - movement
 - Up - jump
 - X - flip
 - Z - dash

## Compiling

Should be as straightforward as:
```
nimble build
```
Keep in mind that
[rapid's dependencies](https://github.com/liquid600pgm/rapid/#installing) also
need to be present.
**Warning:** There's a bug somewhere in nimterop's wrapping process that causes
it to not execute `git fetch` when GLFW sources are first pulled from GitHub.
The solution is simple: go to rapid's directory, and navigate to `src/rapid/lib/glfw_src`.
Then, execute `git fetch`. Running `nimble build` another time works too.

## Contributing

Feel free to contribute new levels and stuff. At the time of writing this, most
Atoms are missing and need to be placed into their own rooms.
