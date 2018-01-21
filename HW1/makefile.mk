out.o: lex.yy.c
	gcc -o out.o lex.yy.c -ll
lex.yy.c: hw.l
	flex hw.l
