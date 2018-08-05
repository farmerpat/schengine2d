all: game-object.import.scm sprite.import.scm scene.import.scm world.import.scm
	csc -d3 -c -j sprite sprite.scm
	csc -d3 -c -j game-object game-object.scm
	csc -d3 -c -j scene scene.scm
	csc -d3 -c -j world world.scm
	#csc game-object.o sprite.o scene.o game.scm
