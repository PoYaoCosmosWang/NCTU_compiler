%{
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

","     { tokenChar(','); }
";"     { tokenChar(';'); }
":"     { tokenChar(':'); }
"("     { tokenChar('('); }
")"     { tokenChar(')'); }
"["     { tokenChar('['); }
"]"     { tokenChar(']'); }

"+"     { tokenChar('+'); }
"-"     { tokenChar('-'); }
"*"     { tokenChar('*'); }
"/"     { tokenChar('/'); }
"mod"     { token(mod); }
":="     { token(:=); }
"<"     { tokenChar('<'); }
"<="     { token(<=); }
"<>"     { token(<>); }
">="     { token(>=); }
">"     { tokenChar('>'); }
"="     { tokenChar('='); }
"and"     { token(and); }
"or"     { token(or); }
"not"     { token(not); }

"array"     { token(KWarray); }
"begin"     { token(KWbegin); }
"boolean"     { token(KWboolean); }
"def"     { token(KWdef); }
"do"     { token(KWdo); }
"else"     { token(KWelse); }
"end"     { token(KWend); }
"false"     { token(KWfalse); }
"for"     { token(KWfor); }
"integer"     { token(KWinteger); }
"if"     { token(KWif); }
"of"     { token(KWof); }
"print"     { token(KWprint); }
"read"     { token(KWread); }
"real"     { token(KWreal); }
"string"     { token(KWstring); }
"then"     { token(KWthen); }
"to"     { token(KWto); }
"true"     { token(KWtrue); }
"return"     { token(KWreturn); }
"var"     { token(KWvar); }
"while"     { token(KWwhile); }

{letter}({letter}|{digit})*   {tokenString(id,yytext); }
0|([1-9]{digit}*)  {tokenString(integer,yytext); }
(0+|[1-9]{digit}*)\.{digit}+  {tokenString(float,yytext); }
((0+|({digit}+))|((0+|{digit}+)\.{digit}+))[eE][+-]?{digit}+ {tokenString(scientific,yytext)}
0+[0-7]*  {tokenString(oct_integer,yytext); }
\"((([^\n\"]*\"\"[^\n\"]*)*)|([^\n\"]*))\" {printString(); }

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
