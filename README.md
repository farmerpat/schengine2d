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

Build Environment
=================
- https://github.com/nickg/swank-chicken
- Install dependencies
```shell
$ export SDL2_FLAGS=`sdl2-config --cflags --libs`
$ # because https://gitlab.com/chicken-sdl2/chicken-sdl2/issues/43 ...
$  SDL2_FLAGS="$SDL2_FLAGS -w"
$ chicken-install -s sdl2
$ chicken-install -s sdl2-image
$ chicken-install -s apropos
$ chicken-install -s debug
$ chicken-install -s srfi-99
```

- Set up chicken-doc
```shell
$ # write me
```

- Fix Vim
See my [dotfiles](https://github.com/farmerpat/dotfiles)
for a vimrc that's at least for this purpose and
a modified scheme.vim syntax file that has added
syntax hightlighting for a number of chicken-specic/project-specific
symbols

If you run make, and then launch csi from the same directory, it can see the .import.scm files
that the build generated. So for example, you could

```shell
$ cd /path/to/schengine2d
$ make
$ csi
> ,l game.scm
```
