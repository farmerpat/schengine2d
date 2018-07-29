#!/bin/bash

#csc -c -j game-object game-object.scm
#csc -s game-object.import.scm
#csc -s -j game-object game-object.scm
#csc -s game-object.import.scm
csc -c game-object.scm -o game-object.o
csc -c sprite.scm -o sprite.o

#csc -s -j sprite sprite.scm
#csc -s sprite.import.scm

#csc -c -j sprite sprite.scm
#csc -s sprite.import.scm

#csc -c hello.scm

#csc game-object.o sprite.o hello.o -o hello
#csc game-object.o sprite.o hello.scm -o hello
#csc hello.scm -o hello -C -L .
csc -o hello hello.o game-object.o sprite.o
