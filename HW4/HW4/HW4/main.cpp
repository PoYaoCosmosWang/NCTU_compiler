/**
 * Introduction to Compiler Design by Prof. Yi Ping You
 * Prjoect 2 main function
 */
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include<string.h>
using namespace std;
extern int yyparse();	/* declared by yacc */
extern FILE* yyin;	/* declared by lex */
extern bool errFlag;
string fileName;



int  main( int argc, char **argv )
{
	if( argc != 2 ) {
		fprintf(  stdout,  "Usage:  ./parser  [filename]\n"  );
		exit(0);
	}
	
	FILE *fp = fopen( argv[1], "r" );

	if( fp == NULL )  {
		fprintf( stdout, "Open  file  error\n" );
		exit(-1);
	}
	for(int i=0;i<strlen(argv[1])-2;++i)
	{
		fileName+=argv[1][i];
	}
	
	yyin = fp;
	yyparse();	/* primary procedure of parser */
	if(!errFlag)
	{

	
		fprintf( stdout,"\n|--------------------------------|\n" );
		fprintf( stdout, "|  There is no syntactic error and semantic error!  |\n" );
		fprintf( stdout, "|--------------------------------|\n" );
	}
	exit(0);
}


