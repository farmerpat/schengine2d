all: game-object.import.scm sprite.import.scm scene.import.scm world.import.scm
	csc -d3 -c -j schengine-util schengine-util.scm
	csc -d3 -c -j sprite sprite.scm
	csc -d3 -c -j body body.scm
	csc -d3 -c -j dynamic-body dynamic-body.scm
	csc -d3 -c -j boxed-dynamic-body boxed-dynamic-body.scm
	csc -d3 -c -j game-object game-object.scm
	csc -d3 -c -j world world.scm
	csc -d3 -c -j scene scene.scm
	csc -d3 schengine-util.o \
		sprite.o \
		body.o \
		dynamic-body.o \
		boxed-dynamic-body.o \
		game-object.o \
		world.o \
		scene.o \
		game.scm
