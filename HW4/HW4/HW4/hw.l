/**
 * Introduction to Compiler Design by Prof. Yi Ping You
 * Project 2 Lex Sample
 */

%{
#include"struct.h"
#include<cmath>
#include <string.h>
#include "y.tab.h"
#include<sstream>
#include<iostream>
/*extern "C"
{
	int yywrap(void);
	int yylex(void);
}*/

#define LIST strcat( buf, yytext )
#define token(t) { LIST; if (Opt_T) printf("<%s>\n", #t );}
#define tokenChar(t) { LIST; if (Opt_T) printf("<%c>\n", t );}
#define tokenInteger(t, i) { LIST; if (Opt_T) printf("<%s: %d>\n", t, i); }
#define tokenOctInteger(t, i) { LIST; if (Opt_T) printf("<%s: %s>\n", t, i); }
#define tokenFloat(t, i) { LIST; if (Opt_T) printf("<%s: %s>\n", t, i ); }
#define tokenScientific(t, s) { LIST; if ( Opt_T ) printf("<%s: %s>\n", t, s); }
#define tokenString(t, s) { LIST; if (Opt_T) printf("<%s: %s>\n", t, s); }

#define  MAX_LINE_LENG  256

int Opt_S = 1;				/* list source code option */
int Opt_T = 1;				/* list token option */
int Opt_D = 1;
int linenum = 1;			/* line number */
char buf[MAX_LINE_LENG];		/* source code line buffer */
char strContent[MAX_LINE_LENG];		/* string buffer */

int radix_converter(const  char*  octal_in)
{
    int decimal_number = 0, remainder;

    int count = 0;
    int octal_number=atoi(octal_in);

    while(octal_number > 0)
    {
        remainder = octal_number % 10;
        decimal_number = decimal_number + remainder * pow(8, count);
        octal_number = octal_number / 10;
        count++;
    }
    return decimal_number;
}

double scientific_converter(char* s)
{
	string t;
    stringstream ss;
    stringstream sss;
    float f;
    int i;
    int sign=1;
    string s1;
  	
	string  pch;
	pch = strtok (yytext,"Ee");	
	
	ss<<pch;
    if(s[0]=='0')
    {
        if(s[1]=='.')
        {
          ss>>f;
		  s1=to_string(f);
        }
        else//oct
        {
            ss>>i;
            sss.clear();
            sss<<i;
            sss>>s1;
            i=radix_converter(s1.c_str());
			s1=to_string(i);
   		}
	}
   else
    {
        ss>>f;
		s1=to_string(f);
    }
   	
  	string s2;
	s2 = strtok (NULL,"+\0");
    if(s2[0]=='-'||s2[0]=='+')
    {
        if(s2[0]=='-')
            sign=-1;

        int tmp;
        if(s2[1]=='0')
        {
            s2=s2.substr(1);
            tmp=radix_converter(s2.c_str());
            tmp*=sign;
            sss.clear();
            sss<<tmp;
            sss>>s2;
        }

    }
    else if(s2[0]=='0')
    {
            int tmp;
            s2=s2.substr(1);
            tmp=radix_converter(s2.c_str());
            sss.clear();
            sss<<tmp;
            sss>>s2;
    }
    t=s1+'e';
	t+=s2;

    return atof(t.c_str());

}

void setPseudoComment( const char * );	/* pseudo comment option switch */
%}

whitespace [ \t]+
letter [A-Za-z]
digit [0-9]
integer 0|[1-9][0-9]*
octal 0[0-7]+
fraction 0|[0-9]*[1-9]
float {integer}"."{fraction}
scientific ({integer}|{float}|{octal})[Ee][+-]?({integer}|{octal})
identifier ({letter})({letter}|{digit})*

 /* exclusive start conditions */
%x COMMENT
%x COMMENT_CPP

%%

","				{ tokenChar(','); return MK_COMMA; }
";"				{ tokenChar(';'); return MK_SEMICOLON; }
":"				{ tokenChar(':'); return MK_COLON; }
")"				{ tokenChar(')'); return MK_RPAREN; }
"("				{ tokenChar('('); return MK_LPAREN; }
"["				{ tokenChar('['); return MK_LB;}
"]"				{ tokenChar(']'); return MK_RB; }

"+"				{ tokenChar('+'); return OP_ADD; }
"-"				{ tokenChar('-'); return OP_SUB; }
"*"				{ tokenChar('*'); return OP_MUL; }
"/"				{ tokenChar('/'); return OP_DIV; }
"mod"				{ token(mod); return OP_MOD; }
":="				{ token(:=); return OP_ASSIGN; }
"<"				{ token(<); return OP_LT; }
"<="				{ token(<=); return OP_LE; }
"<>"				{ token(<>); return OP_NE; }
">="				{ token(>=); return OP_GE; }
">"				{ token(>); return OP_GT; }
"="				{ token(=); return OP_EQ; }
"and"				{ token(and); return OP_AND; }
"or"				{ token(or); return OP_OR; }
"not"				{ token(not); return OP_NOT; }

"array"				{ token(KWarray); return ARRAY; }
"begin"				{ token(KWbegin); return BEG; }
"boolean"			{ token(KWboolean); yylval.sval=yytext;  return BOOLEAN; }
"def"				{ token(KWdef); return DEF; }
"do"				{ token(KWdo); return DO; }
"else"				{ token(KWelse); return ELSE; }
"end"				{ token(KWend); return END; }
"false"				{ token(KWfalse); return FALSE; }
"for"				{ token(KWfor); return FOR; }
"integer"			{ token(KWinteger); yylval.sval=yytext;  return INTEGER; }
"if"				{ token(KWif); return IF; }
"of"				{ token(KWof); return OF; }
"print"				{ token(KWprint); return PRINT; }
"read"				{ token(KWread); return READ; }
"real"				{ token(KWreal); yylval.sval=yytext;  return REAL; }
"return"			{ token(KWreturn); return RETURN; }
"string"			{ token(KWstring); yylval.sval=yytext;  return STRING; }
"then"				{ token(KWthen); return THEN; }
"to"				{ token(KWto); return TO; }
"true"				{ token(KWtrue); return TRUE; }
"var"				{ token(KWvar); return VAR; }
"while"				{ token(KWwhile); return WHILE; }

{octal}				{ tokenOctInteger("oct_integer",yytext); yylval.ival=radix_converter(yytext);
  return OCTAL_CONST;}
{identifier}			{
						tokenString("id",yytext);
						if(strlen(yytext)>32)
						{
							string s(yytext);

							yylval.sval=s.substr(0,32);
						}
						else
						{
							yylval.sval=yytext;
						}
						return ID; }
{integer}			{ tokenInteger("integer",atoi(yytext));
						yylval.ival=atoi(yytext);
						return INT_CONST; }
{float}				{ tokenFloat("float",yytext); yylval.rval=atof(yytext);  return FLOAT_CONST; }
{scientific}			{ tokenScientific("scientific", yytext);yylval.rval=scientific_converter(yytext);  return SCIENTIFIC; }

\"((\"\")|[^\"\n])*\"	{
					LIST;
					size_t wrt_idx = 0;
					size_t rd_idx = 1;
					int quote = 0;
					while( yytext[rd_idx] ){
						if( yytext[rd_idx] == '\"' ){
							if( quote )
								strContent[wrt_idx++] = '\"';
							quote = 1 - quote;
						}
						else
							strContent[wrt_idx++] = yytext[rd_idx];
						rd_idx++;
					}
					strContent[wrt_idx] = '\0';
					string s(strContent);
					yylval.sval='"'+s+'"';


					if (Opt_T){
						printf("<%s: %s>\n", "string", strContent);
						}
								return STR_CONST;
						}

"//&"[A-Z][+-][^\n]*		{ /* pseudo comment */
				  LIST;
				  setPseudoComment( yytext );
				
				}
"//"				{ /* C++ stype comment */
				  LIST;
				  BEGIN COMMENT_CPP;
				}

<COMMENT_CPP>[^\n]+		{
				  LIST;
				}

<COMMENT_CPP>"\n"		{
				  LIST;
				  if( Opt_S )
				  	printf("%d: %s",  linenum,  buf);
				  linenum++;
				  buf[0] = '\0';
				  BEGIN INITIAL;
				}

"/*"				{ /* C-style comment */
				  LIST;
				  BEGIN COMMENT;
				}
<COMMENT>"*/"			{
				  LIST;
				  BEGIN INITIAL;
				}
<COMMENT>"\n"			{
				  LIST;
				  if  (Opt_S)
				  	printf("%d: %s",  linenum,  buf);
				  linenum++;
				  buf[0] = '\0';
				}
<COMMENT>.			{
				  LIST;
				}

{whitespace}			{ 
				  LIST; 
				}

\n 				{
				  LIST;
				  if  (Opt_S)
				  	printf("%d: %s",  linenum,  buf);
				  linenum++;
				  buf[0] = '\0';
		   		}

.				{
				  /* error */
				  printf("error at line %d: bad character \"%s\"\n", linenum, yytext );
				  exit(-1);
				}

%%

void setPseudoComment( const char *text )
{
	/* format : //&[A-Z][+-] */
	switch( text[3] ) {
	 case 'S':			/* Source code */
		if( text[4] == '+' )
			Opt_S = 1;
		else if( text[4] == '-' )
			Opt_S = 0;
		break;
	 case 'T':			/* Tokens */
		if( text[4] == '+' )
			Opt_T = 1;
		else if( text[4] == '-' )
			Opt_T = 0;
	 	break;
	 case 'D':
	 	if(text[4]=='+')
		{
			Opt_D=1;
		}
		else if(text[4]=='-')
			Opt_D = 0;
		break;
	 default:
	 	break;
	}

}

