all: game-object.import.scm sprite.import.scm scene.import.scm
	csc -c -j game-object game-object.scm
	csc -c -j sprite sprite.scm
	csc -c -j scene scene.scm
	#csc game-object.o sprite.o scene.o game.scm
