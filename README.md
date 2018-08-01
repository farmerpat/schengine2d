schengine2d
-----------

Building Physcis
================
I am trying out chipmunk physics, so this depends on these eggs:
- [2d-primitives](https://github.com/pluizer/2d-primitives)
- [chipmunk](https://github.com/pluizer/chicken-chipmunk)
- [physics](https://github.com/pluizer/chicken-physics)

chicken-chipmunk's setup file clobbers the chicken module and chipmunk.scm attempts
to include coati-primitives, which is apparently what 2d-primitives used to be named.
The documentation sucks also, as it is using a different syntax for primitives
than that appearinig in 2d-primitives. Perhaps the syntax changed when
coati-primitives became 2d-primitives, and the projects were orphaned...
perhaps clobbering a module that's fundamental to chicken's ecosystem
was unintentional. At one point I thought this guy was literally trolling...
either way, I forked all these repos...so use:

- [2d-primitives](https://github.com/farmerpat/2d-primitives)
- [chipmunk](https://github.com/farmerpat/chipmunk)
- [physics](https://github.com/farmerpat/physics)

...well at the time, clicking "fork" just gave a 500 error, so I cloned and pushed to new private repos...

clone my repos and run chicken-install -s from inside each of them in the order in which they
appear in the lists above.

Building
=========
If you run make, and then launch csi from the same directory, it can see the .import.scm files
that the build generated. So for example, you could

```shell
$ cd /path/to/schengine2d
$ make
$ csi
> ,l game.scm
```
