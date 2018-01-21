parser: parser.y hw.l
	yacc -d  parser.y
	flex hw.l
	gcc -o parser lex.yy.c y.tab.c -ly -lfl

	
