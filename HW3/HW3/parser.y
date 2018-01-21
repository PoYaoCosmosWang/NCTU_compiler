%{
/**
 * Introduction to Compiler Design by Prof. Yi Ping You
 * Project 2 YACC sample
 */
#include "struct.h"
#include <stdio.h>
#include <stdlib.h>
#include<iostream>
#include<sstream>
/*extern "C"
{
	void yyerror(const char* s);
	extern int yylex(void);
}*/

extern int Opt_D;
extern int linenum;		/* declared in lex.l */
extern FILE *yyin;		/* declared by lex */
extern char *yytext;		/* declared by lex */
extern char buf[256];		/* declared in lex.l */
extern int yylex(void);
int yyerror(char* );

vector<vector<symbol> > table;
vector<symbol> entry;
symbol s;
vector<string> forNames;

void errorMsg(string name)
{

	string msg= "symbol "+name+" is redeclared";
	printf("<Error> found in Line %d: %s\n", linenum, msg.c_str());
}

bool isRe(string n)
{
	for(int i=0;i<table[table.size()-1].size();++i)
	{
				if(n==table[table.size()-1][i].name)
		{
			return true;
		}

	}
	for (int i=0;i<forNames.size();++i)
	{
		if(n==forNames[i])
		{
			return true;
		}
	}
	return false;
}

string nowType;
string nowAttr;
string parameters;
int IDNum=0;

void print()
{
	if(!Opt_D)
		return;
	
	int i;
	for(i=0;i< 110;i++)
		printf("=");
	printf("\n");
	printf("%-33s%-11s%-11s%-17s%-11s\n","Name","Kind","Level","Type","Attribute");
	for(i=0;i< 110;i++)
		printf("-");
	printf("\n");
	int sz=table[table.size()-1].size();
	for(int i=0;i<sz;++i)
	{
		table[table.size()-1][i].print();
	}
	for(i=0;i< 110;i++)
		printf("-");
	printf("\n");
}

int level=0;


void addEntry()
{
	level++;
	if(level<=table.size())
	{
		return;
	}
	else
	{
		table.push_back(entry);

	}
}

void popEntry()
{
	level--;
	print();
	table.pop_back();
}

void addSymbol(string s)
{
	if(isRe(s))
	{
		errorMsg(s);
		return;
	}
	IDNum++;
	symbol a;
	a.level=table.size()-1;
	a.name=s;
	table[table.size()-1].push_back(a);

}

void addFunction(string name,string type,string attr)
{


	symbol a;
	a.level=table.size()-1;
	a.name=name;
	a.kind=1;
	a.type=type;
	a.attr.addType(attr);
	table[table.size()-1].push_back(a);
	IDNum=0;
}

void setVariable(string s)
{
	int tsz=table.size();

	for(int i=table[tsz-1].size()-IDNum;i<(int)table[tsz-1].size();++i)
	{
		table[tsz-1][i].kind=3;//variable
		table[tsz-1][i].type=s;
	}
	IDNum=0;
}
void setParameter(string s)
{
	int tsz=table.size();
	int inSz=table[tsz-1].size();
	for(int i=inSz-IDNum;i<inSz;++i)
	{
		table[tsz-1][i].kind=2;//parameter
		table[tsz-1][i].type=s;
	}
	IDNum=0;
}



void setConst()
{
	int tsz=table.size();

	for(int i=table[tsz-1].size()-IDNum;i<(int)table[tsz-1].size();++i)
	{
		table[tsz-1][i].kind=4;//const
		table[tsz-1][i].type=nowType;
		table[tsz-1][i].attr.isConst=true;
		table[tsz-1][i].attr.add(nowAttr);
	}
	IDNum=0;
}



%}
/* tokens */
%token ARRAY
%token BEG
%token BOOLEAN
%token DEF
%token DO
%token ELSE
%token END
%token FALSE
%token FOR
%token INTEGER
%token IF
%token OF
%token PRINT
%token READ
%token REAL
%token RETURN
%token STRING
%token THEN
%token TO
%token TRUE
%token VAR
%token WHILE

%token ID
%token OCTAL_CONST
%token INT_CONST
%token FLOAT_CONST
%token SCIENTIFIC
%token STR_CONST

%token OP_ADD
%token OP_SUB
%token OP_MUL
%token OP_DIV
%token OP_MOD
%token OP_ASSIGN
%token OP_EQ
%token OP_NE
%token OP_GT
%token OP_LT
%token OP_GE
%token OP_LE
%token OP_AND
%token OP_OR
%token OP_NOT

%token MK_COMMA
%token MK_COLON
%token MK_SEMICOLON
%token MK_LPAREN
%token MK_RPAREN
%token MK_LB
%token MK_RB

/* start symbol */
%start program
%%

program			:
					{
						addEntry();
					}
					ID
					{
						addSymbol($2.sval);
						table[0][0].kind=0;
						table[0][0].type="void";
						IDNum=0;
					}
					MK_SEMICOLON  program_body END ID
					{
						popEntry();
					}
				;

program_body		: opt_decl_list opt_func_decl_list compound_stmt
			;

opt_decl_list		: decl_list
			| /* epsilon */
			;

decl_list		: decl_list decl
			| decl
			;

decl			: VAR id_list MK_COLON scalar_type MK_SEMICOLON
			/* scalar type declaration */
					{
						setVariable($4.sval);
					}
			| VAR id_list MK_COLON array_type MK_SEMICOLON 
			/* array type declaration */
					{
						setVariable($4.sval);
					}
			| VAR id_list MK_COLON literal_const MK_SEMICOLON     /* const declaration */
					{
						setConst();
					}
			;
int_const	:	INT_CONST
				{
					$$=$1;
				}
			|	OCTAL_CONST
				{
					$$=$1;
				}
			;

literal_const		: int_const
						{
							nowType="integer";
							nowAttr=to_string($1.ival);
						}
			| OP_SUB int_const
						{
							nowType="integer";
							nowAttr=to_string($1.ival*-1);
					}
			| FLOAT_CONST
						{
							nowType="real";
							nowAttr=to_string($1.rval);
						}

			| OP_SUB FLOAT_CONST
									{
							nowType="real";
							nowAttr=to_string($1.ival*-1);
						}

			| SCIENTIFIC
						{
							nowType="real";
							nowAttr=to_string($1.rval);
						}

			| OP_SUB SCIENTIFIC
						{
							nowType="real";
							nowAttr=to_string($1.rval*-1);
						}

			| STR_CONST
						{
							nowType="string";
							nowAttr=$1.sval;
						}

			| TRUE
						{
							nowType="boolean";
							nowAttr="true";
						}

			| FALSE
						{
							nowType="boolean";
							nowAttr="false";
						}

			;

opt_func_decl_list	: func_decl_list
			| /* epsilon */
			;

func_decl_list		: func_decl_list func_decl
			| func_decl
			;

func_decl		: ID
					{
							if(isRe($1.sval))
							{
								errorMsg($1.sval);
							}
					}
					MK_LPAREN
							{
								addEntry();
							}
				opt_param_list
							{	
								
								level--;
							}
MK_RPAREN opt_type MK_SEMICOLON
			  compound_stmt
			  END ID
			  {
			if(!isRe($1.sval))
			{
			  addFunction($1.sval,$8.sval,parameters);
			}		
			parameters.clear();
			  }

			;

opt_param_list		: param_list
				{
					$$.sval=$1.sval;
					parameters=$$.sval;
				}
			| /* epsilon */
				{
					
				}
			;

param_list		: param_list MK_SEMICOLON param
				{
					$$.sval=$1.sval+", "+$3.sval;
				}
			| param
				{
					$$=$1;
				}
			;

param			: id_list MK_COLON type
				{
					for(int i=0;i<IDNum;++i)
					{
						if(i==0)
						{
							$$.sval=$3.sval;
						}
						else
						{
							$$.sval+=", "+$3.sval;

						}
					
					}
					setParameter($3.sval);
					
				}
			;

id_list			: id_list MK_COMMA ID
				{
					addSymbol($3.sval);
				}
			| ID
				{

				
					addSymbol($1.sval);
				}
			;

opt_type		: MK_COLON type
				{
					$$=$2;
				}
			| /* epsilon */
				{
					$$.sval="void";
				}
			;

type			: scalar_type
					{
						$$.sval=$1.sval;
					}
			| array_type
					{
						$$=$1;
					}
			;

scalar_type		: INTEGER 
					{
					
						$$=$1;
					}
			| REAL
					{
					    $$=$1;
					}
			| BOOLEAN
					{
						$$=$1;
					}
			| STRING
					{
						$$=$1;
					}
			;

array_type		: ARRAY int_const TO int_const OF type
					{
						stringstream ss;
						int num=$4.ival-$2.ival+1;
						string s;
						ss<<num;
						ss>>s;
						ss.clear();
						string front,back;
						ss<<$6.sval;
						ss>>front;
						ss>>back;
						$$.sval=front+" ["+s+"]"+back;
					}

								;

stmt			: compound_stmt
			| simple_stmt
			| cond_stmt
			| while_stmt
			| for_stmt
			| return_stmt
			| proc_call_stmt
			;

compound_stmt		: BEG
						{
							addEntry();
						}
			  opt_decl_list
			  opt_stmt_list
			  END
			  			{
							popEntry();
						}
			;

opt_stmt_list		: stmt_list
			| /* epsilon */
			;

stmt_list		: stmt_list stmt
			| stmt
			;

simple_stmt		: var_ref OP_ASSIGN boolean_expr MK_SEMICOLON
			| PRINT boolean_expr MK_SEMICOLON
			| READ boolean_expr MK_SEMICOLON
			;

proc_call_stmt		: ID MK_LPAREN opt_boolean_expr_list MK_RPAREN MK_SEMICOLON
			;

cond_stmt		: IF boolean_expr THEN
			  opt_stmt_list
			  ELSE
			  opt_stmt_list
			  END IF
			| IF boolean_expr THEN opt_stmt_list END IF
			;

while_stmt		: WHILE boolean_expr DO
			  opt_stmt_list
			  END DO
			;

for_stmt		: FOR 
						{
							addEntry();
						}
						ID
						{
							if(isRe($3.sval))
							{
								errorMsg($3.sval);
							}
							forNames.push_back($3.sval);
						}
				OP_ASSIGN int_const TO int_const DO
			  opt_stmt_list
			  END DO
			  {
			  	level--;
			  	table.pop_back();
			  	forNames.pop_back();
			  }
			;

return_stmt		: RETURN boolean_expr MK_SEMICOLON
			;

opt_boolean_expr_list	: boolean_expr_list
			| /* epsilon */
			;

boolean_expr_list	: boolean_expr_list MK_COMMA boolean_expr
			| boolean_expr
			;

boolean_expr		: boolean_expr OP_OR boolean_term
			| boolean_term
			;

boolean_term		: boolean_term OP_AND boolean_factor
			| boolean_factor
			;

boolean_factor		: OP_NOT boolean_factor 
			| relop_expr
			;

relop_expr		: expr rel_op expr
			| expr
			;

rel_op			: OP_LT
			| OP_LE
			| OP_EQ
			| OP_GE
			| OP_GT
			| OP_NE
			;

expr			: expr add_op term
			| term
			;

add_op			: OP_ADD
			| OP_SUB
			;

term			: term mul_op factor
			| factor
			;

mul_op			: OP_MUL
			| OP_DIV
			| OP_MOD
			;

factor			: var_ref
			| OP_SUB var_ref
			| MK_LPAREN boolean_expr MK_RPAREN
			| OP_SUB MK_LPAREN boolean_expr MK_RPAREN
			| ID MK_LPAREN opt_boolean_expr_list MK_RPAREN
			| OP_SUB ID MK_LPAREN opt_boolean_expr_list MK_RPAREN
			| literal_const
			;

var_ref			: ID
			| var_ref dim
			;

dim			: MK_LB boolean_expr MK_RB
			;

%%

int yyerror( char *msg )
{
	(void) msg;
	fprintf( stderr, "\n|--------------------------------------------------------------------------\n" );
	fprintf( stderr, "| Error found in Line #%d: %s\n", linenum, buf );
	fprintf( stderr, "|\n" );
	fprintf( stderr, "| Unmatched token: %s\n", yytext );
	fprintf( stderr, "|--------------------------------------------------------------------------\n" );
	exit(-1);
}

