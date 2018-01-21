%{
#include <stdio.h>
#include <stdlib.h>

extern int linenum;             /* declared in lex.l */
extern FILE *yyin;              /* declared by lex */
extern char *yytext;            /* declared by lex */
extern char buf[256];           /* declared in lex.l */
%}

%token SEMICOLON END IDENT MOD ASSIGN LE LG GE AND OR NOT ARY BGN BOOL DEF DO ELSE FALSE FOR INTEGER IF OF PRINT READ REAL STRING THEN TO TRUE RETURN VAR WHILE INT FLOAT EXPOENT OCT STR

%right ASSIGN
%left OR
%left AND
%right NOT
%left '<' LE '=' GE '>' LG
%left '+' '-'
%left '*' '/' MOD

%%

program		: programname ';'  programbody END IDENT
			
		;

programname	: identifier
		;

programbody : optDeclaration optFunctionDeclaration compoundStatement

		;

optFunctionDeclaration :optFunctionDeclaration functionDeclaration
			|
		;

functionDeclaration :IDENT '(' optFormalArgument ')' ':' type ';'  compoundStatement END IDENT  
			|IDENT '(' optFormalArgument ')' ';' compoundStatement END IDENT
		;

optFormalArgument : formalArgument
			|
			;

formalArgument : identList ':' type
			| formalArgument ';' formalArgument
;

identList : IDENT
			| identList ',' IDENT
		;

optDeclaration :optDeclaration  declaration
			| 
		;
declaration : VAR identList ':'type ';'
			| constDeclaration
		;

constDeclaration : VAR identList ':' literalConst ';'
		;

literalConst : INT
			 | STR
			 | FLOAT
			 | EXPOENT
			 | OCT
			 | TRUE
			 | FALSE
		;

sclarType  :INTEGER
			|REAL
			|STRING
			|BOOL
		;

type		:sclarType
			|ARRAY
		;

ARRAY 		:ARY INT TO INT OF type
		;

compoundStatement :BGN optDeclaration optStatement END  
		;

optStatement :optStatement statement
			 | 
		;


statement 	 : compoundStatement
			 | simpleStatement
			 | conditionalStatement
			 | whileStatement
			 | forStatement
			 | returnStatement
			 | procedureCallStatement ';'
		;

simpleStatement : variableRef ASSIGN expr ';'
				| PRINT variableRef ';'
				| PRINT expr ';'
				| READ variableRef ';'
		;

variableRef : IDENT
			 | aryRef
		;

aryRef 		: IDENT '[' expr ']'
			| aryRef '['expr  ']'
		;

expr		:'(' expr ')'
			|'-' expr  %prec '*'
			| expr '*' expr
			| expr '/' expr
			| expr MOD expr
			| expr '+' expr
			| expr '-' expr
			| expr '<' expr
			| expr LE expr
			| expr '=' expr
			| expr GE expr
			| expr '>' expr
			| expr LG expr
			| NOT expr
			| expr AND expr
			| expr OR expr
			| literalConst
			| variableName
			| functionInvocation
			| aryRef
		;

variableName : IDENT
		;

exprs 		: expr
			| exprs ',' expr
			|
		;


functionInvocation : funcivk1
		;

funcivk1:IDENT '(' exprs ')'
		;

conditionalStatement : IF expr THEN optStatement ELSE optStatement END IF
					 | IF expr THEN optStatement END IF
		;

whileStatement : WHILE expr DO optStatement END DO
		;

forStatement : FOR IDENT ASSIGN INT TO INT DO optStatement END DO
		;

returnStatement : RETURN expr ';'
		;

procedureCallStatement : functionInvocation
		;


identifier	: IDENT 
		;


%%
extern int yylex(void);

int yyerror( char *msg )
{
        fprintf( stderr, "\n|--------------------------------------------------------------------------\n" );
	fprintf( stderr, "| Error found in Line #%d: %s\n", linenum, buf );
	fprintf( stderr, "|\n" );
	fprintf( stderr, "| Unmatched token: %s\n", yytext );
        fprintf( stderr, "|--------------------------------------------------------------------------\n" );
        exit(-1);
}

int yywrap()
{
	return 1;
}

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
	
	yyin = fp;
	yyparse();

	fprintf( stdout, "\n" );
	fprintf( stdout, "|--------------------------------|\n" );
	fprintf( stdout, "|  There is no syntactic error!  |\n" );
	fprintf( stdout, "|--------------------------------|\n" );
	exit(0);
}

