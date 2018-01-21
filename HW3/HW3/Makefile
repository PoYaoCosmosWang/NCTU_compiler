parser: parser.y hw.l
	yacc -d  parser.y
	flex hw.l
	g++  -o  parser  struct.h   main.cpp  lex.yy.c y.tab.c -ly -lfl
clean:	
	rm -f out.o
	rm -f y.tab.h
	rm -f y.tab.c
	
