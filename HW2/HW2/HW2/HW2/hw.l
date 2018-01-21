%{

#include "y.tab.h"

#define LIST               strcat(buf, yytext)
#define token(t)           {LIST; if (Opt_T) printf("<%s>\n", #t);}
#define tokenChar(t)       {LIST; if (Opt_T) printf("<%c>\n", (t));}
#define tokenInteger(t, i) {LIST; if (Opt_T) printf("<%s: %d>\n", #t, (i));}
#define tokenString(t, s)  {LIST; if (Opt_T) printf("<%s: %s>\n", #t, (s));}
#define MAX_LINE_LENG      256

int comment=0;
int Opt_S = 1;
int Opt_T = 1;
int linenum = 1;
char buf[MAX_LINE_LENG];

void printString(){

	char* buff=malloc(sizeof(char)*yyleng);
	memset(buff,'\0',(int)yyleng);
	int i=1;
	int bufCnt=0;
	for(i=1;i<yyleng-1;++i)
	{
		char c=yytext[i];
		if(c=='"')
		{
			i++;	
		}
		buff[bufCnt]=c;
		bufCnt++;
	}
	tokenString(string,buff);
	
	free(buff);
}
%}
digit  [0-9]
letter [a-zA-Z]



%x COM 

%%

","     { tokenChar(',');return ',';}
";"     { tokenChar(';');return ';'; }
":"     { tokenChar(':');return ':';}
"("     { tokenChar('(');return '('; }
")"     { tokenChar(')'); return ')';}
"["     { tokenChar('['); return '[';}
"]"     { tokenChar(']'); return ']';}

"+"     { tokenChar('+'); return '+';}
"-"     { tokenChar('-'); return '-';}
"*"     { tokenChar('*'); return '*';}
"/"     { tokenChar('/'); return '/';}
"mod"     { token(mod); return MOD;}
":="     { token(:=); return ASSIGN;}
"<"     { tokenChar('<'); return '<';}
"<="     { token(<=); return LE;}
"<>"     { token(<>); return LG;}
">="     { token(>=); return GE;}
">"     { tokenChar('>'); return '>';}
"="     { tokenChar('='); return '=';}
"and"     { token(and); return AND;}
"or"     { token(or); return OR;}
"not"     { token(not); return NOT;}

"array"     { token(KWarray); return ARY;}
"begin"     { token(KWbegin); return BGN;}
"boolean"     { token(KWboolean); return BOOL;}
"def"     { token(KWdef); return DEF;}
"do"     { token(KWdo); return DO;}
"else"     { token(KWelse); return ELSE;}
"end"     { token(KWend); return END;}
"false"     { token(KWfalse); return FALSE;}
"for"     { token(KWfor); return FOR;}
"integer"     { token(KWinteger); return INTEGER;}
"if"     { token(KWif); return IF;}
"of"     { token(KWof); return OF;}
"print"     { token(KWprint); return PRINT;}
"read"     { token(KWread); return READ;}
"real"     { token(KWreal); return REAL;}
"string"     { token(KWstring); return STRING;}
"then"     { token(KWthen); return THEN;}
"to"     { token(KWto); return TO;}
"true"     { token(KWtrue); return TRUE;}
"return"     { token(KWreturn); return RETURN;}
"var"     { token(KWvar); return VAR;}
"while"     { token(KWwhile); return WHILE;}

{letter}({letter}|{digit})*   {tokenString(id,yytext);return IDENT; }
0|([1-9]{digit}*)  {tokenString(integer,yytext);return INT; }
(0+|[1-9]{digit}*)\.{digit}+  {tokenString(float,yytext);return FLOAT; }
((0+|({digit}+))|((0+|{digit}+)\.{digit}+))[eE][+-]?{digit}+ {tokenString(scientific,yytext)return EXPOENT;}
0+[0-7]*  {tokenString(oct_integer,yytext);return OCT; }
\"((([^\n\"]*\"\"[^\n\"]*)*)|([^\n\"]*))\" {printString();return STR; }

[ \t] LIST;

\/\/\&[S]\+.* 	{LIST;Opt_S=1;}
\/\/\&[S]\-.* 	{LIST;Opt_S=0;}
\/\/\&[T]\+.* 	{LIST;Opt_T=1;}
\/\/\&[T]\-.* 	{LIST;Opt_T=0;}
\/\/.* LIST;
						/*	{
							
							comment=linenum;
							LIST;
							int i=0;
							for(;i<yyleng;++i)
							{
								if(yytext[i]=='\n')
								linenum++;
							}
		/*if(Opt_S)
		{
			if(buf[0]!='\0')
			{
				printf("%d: %s",linenum,buf);
				buf[0]='\0';
			}
			else
			{
				printf("%d: ",linenum);
			}
			int i=0;
			for(;i<yyleng;++i)
			{
				if(yytext[i]=='\n')
				{
					printf("\n");
					linenum++;
					printf("%d: ",linenum);
				}
				else
				{
					printf("%c",yytext[i]);
				}
			}
		}

}
*/

\/\*  {
		//printf("COMMENT MODE ON\n");
		BEGIN COM;
		comment=linenum;
		LIST;
	}
<COM>\*\/ {
			//printf("COMMENT MODE OFF\n");
			BEGIN INITIAL;
			LIST;
			}
<COM>\n {
			 if (Opt_S)
          {
			/*if(comment)
			{
				printf("%d: %s\n", comment, buf);
				comment=0;
			}
			else
			{*/
				printf("%d: %s\n", linenum, buf);
		
		  }  
		  
		  linenum++;
          buf[0] = '\0';
        }

		
<COM>. {
		LIST;
}


\n      {
       	 // LIST;
          if (Opt_S)
          {
			/*if(comment)
			{
				printf("%d: %s\n", comment, buf);
				comment=0;
			}
			else
			{*/
				printf("%d: %s\n", linenum, buf);
			
		  }  
		  
		  linenum++;
          buf[0] = '\0';
        }

. {printf("error at line %d: bad character \"%s\"\n",linenum,yytext);
	exit(1);
	}

%%
/*
int main( int argc, char **argv )
{
  if( argc != 2 ) {
    fprintf( stderr, "Usage: ./scanner [filename]\n" );
    exit(0);
  }
	
  FILE *fp = fopen( argv[1], "r" );
  if( fp == NULL ) {
    fprintf( stderr, "Open file error\n" );
    exit(-1);
  }
	
  yyin = fp;

  yylex();

  exit(0);
}

*/
