all: main.scm schengine-util.o sprite.o body.o dynamic-body.o boxed-dynamic-body.o \
	game-object.o world.o scene.o game.o
	csc -d3 \
		schengine-util.o \
		sprite.o \
		body.o \
		dynamic-body.o \
		boxed-dynamic-body.o \
		game-object.o \
		world.o \
		scene.o \
		game.o \
		main.scm

schengine-util.o: schengine-util.scm
	csc -d3 -c -j schengine-util schengine-util.scm

sprite.o: sprite.scm
	csc -d3 -c -j sprite sprite.scm

world.o: world.scm
	csc -d3 -c -j world world.scm

body.o: body.scm world.scm
	csc -d3 -c -j body body.scm

dynamic-body.o: dynamic-body.scm body.scm world.scm
	csc -d3 -c -j dynamic-body dynamic-body.scm

boxed-dynamic-body.o: boxed-dynamic-body.scm body.scm dynamic-body.scm
	csc -d3 -c -j boxed-dynamic-body boxed-dynamic-body.scm

game-object.o: game-object.scm schengine-util.scm sprite.scm body.scm
	csc -d3 -c -j game-object game-object.scm

scene.o: scene.scm game-object.scm sprite.scm world.scm
	csc -d3 -c -j scene scene.scm

game.o: game.scm schengine-util.scm game-object.scm sprite.scm scene.scm \
	world.scm boxed-dynamic-body.scm
	csc -d3 -c -j game game.scm
