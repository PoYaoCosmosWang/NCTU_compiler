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
extern string fileName;
extern int Opt_D;
extern int linenum;		/* declared in lex.l */
extern FILE *yyin;		/* declared by lex */
extern char *yytext;		/* declared by lex */
extern char buf[256];		/* declared in lex.l */
extern int yylex(void);
int yyerror(char* );

bool errFlag=false;

vector<vector<symbol> > table;
vector<symbol> entry;
symbol s;
vector<string> forNames;
vector<string> returnType;
vector<int> dim;
vector<string> parameterVec;


void errorMsg(string msg)
{
		errFlag=true;
		printf("<Error> found in Line %d: %s\n", linenum, msg.c_str());
}

void errorRedeclare(string name)
{
	string msg= "symbol "+name+" is redeclared";
	errorMsg(msg);
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
		errorRedeclare(s);
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
	a.attr.parameters=parameterVec;
	
	for(int i=0;i<parameterVec.size();++i)
	{
		cout<<parameterVec[i]<<" ";
	}
	cout<<endl;
	
	table[table.size()-1].push_back(a);
	IDNum=0;
	parameterVec.clear();
	dim.clear();
}

vector<string> ID2parameterVec(string ID)
{
	for(int i=table.size()-1;i>=0;--i)
	{
		for(int j=table[i].size()-1;j>=0;--j)
		{
			if(ID==table[i][j].name)
			{
				if(table[i][j].kind!=1)
				{
					continue;
				}
				return table[i][j].attr.parameters;
			}
		}
	}
	vector<string> c;
	c.clear();
	return c;
	
}

void parameterCheck(vector<string>fun,vector<string> para )
{

	if(fun.size()!=para.size())
	{
		errorMsg("parameter numbers inconsistent");
		return;
	}
	//sz same
	if(fun.size()==0)
	{
		//no parameter
		return;
	}
	else
	{
		for(int i=0;i<fun.size();++i)
		{
			if(fun[i]!=para[i])//not same
			{
				if(fun[i]=="real"&&para[i]=="integer")
				{
					continue;
				}
				else
				{
					errorMsg("parameter type not match");
					return;
				}
			}
			else
			{
				continue;//check next
			}
		}

	}
}

void setVariable(string s,bool isArr)
{
	int tsz=table.size();
	
	for(int i=table[tsz-1].size()-IDNum;i<(int)table[tsz-1].size();++i)
	{
		table[tsz-1][i].kind=3;//variable
		table[tsz-1][i].type=s;
		table[tsz-1][i].arrDim=dim.size();
		table[tsz-1][i].dim=dim;
		table[tsz-1][i].isArray=isArr;
	}
	dim.clear();
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
		table[tsz-1][i].dim=dim;
		table[tsz-1][i].arrDim=dim.size();
		//table[tsz-1][i].isArray=false;
	}
	dim.clear();
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
		table[tsz-1][i].isArray=false;
		table[tsz-1][i].arrDim=0;
	}
	IDNum=0;
}

bool isScalar(string s)
{
	if(s=="integer")
	return true;
	if(s=="boolean")
	return true;
	if(s=="real")
	return true;
	if(s=="string")
	return true;

	return false;
}

bool isVoid(string s)
{
	return s=="void";
}

bool returnTypeCheck(string s)
{
	if(returnType.size()==1)
	{
		errorMsg("program dont have return");
		return false;
	}
	else
	{
		if(s!=returnType[1])
		{	
			if(returnType[1]=="real" && s=="integer")
			{
				return true;
			}
			errorMsg("return type is not the same");
			return false;
		}
	}
	return true;
}

bool isNumType(string s)
{
	if(s=="integer")
	return true;
	if(s=="real")
	return true;

	return false;
}

string typeCoercion(string left,string right,bool isAssign)
{
	if(left=="real")
	{
		return left;
	}
	else if(right=="real")
	{
		if(isAssign)
		{
			errorMsg("cannot assign real to integer");
			return left;
		}
		return right;
	}
	else
	{
		return "integer";
	}
}

string ID2Type(string ID)
{
	for(int i=table.size()-1;i>=0;--i)
	{
		for(int j=table[i].size()-1;j>=0;--j)
		{
			if(ID==table[i][j].name)
			{
				return table[i][j].type;
			}
		}
	}
	return ID;
}

bool IDisArr(string ID)
{
	for(int i=table.size()-1;i>=0;--i)
	{
		for(int j=table[i].size()-1;j>=0;--j)
		{
			if(ID==table[i][j].name)
			{
				return table[i][j].isArray;
			}
		}
	}
	return false;

}

int ID2Dim(string ID)
{
	for(int i=table.size()-1;i>=0;--i)
	{
		for(int j=table[i].size()-1;j>=0;--j)
		{
			if(ID==table[i][j].name)
			{
				return table[i][j].arrDim;
			}
		}
	}
	return 0;

}

vector<int> ID2Vec(string ID)
{
	for(int i=table.size()-1;i>=0;--i)
	{
		for(int j=table[i].size()-1;j>=0;--j)
		{
			if(ID==table[i][j].name)
			{
				return table[i][j].dim;
			}
		}
	}
	vector<int> a;
	a.clear();
	return a;

}


bool isLoopVar(string ID)
{
	for(int i=0;i<forNames.size();++i)
	{
		if(ID==forNames[i])
		{
			return true;
		}
	}
	return false;
}

int ID2Kind(string ID)
{
	for(int i=table.size()-1;i>=0;--i)
	{
		for(int j=table[i].size()-1;j>=0;--j)
		{
			if(ID==table[i][j].name)
			{
				return table[i][j].kind;
			}
		}
	}
	return -1;
}

void boundCheck(int low,int high,bool isFor)
{
	if(low<0)
	{
		errorMsg("lower bound <0");
	}
	if(high<0)
	{
		errorMsg("higher bound <0");
	}

	if(low>=high)
	{	if(isFor)
		{
			if(low==high)
			{
				//ok
			}
			else
			{
				errorMsg("lower bound>higher bound");
				return;
			}
		}
		
		errorMsg("lower bound>=higher bound");
	}
}

string arr2Scalar(type t)
{
	
	if(!isScalar(t.sval))
					{
						
						if(t.dim.size()<0)
						{
							errorMsg("array out of range");
						}
						else 
						{
							switch(t.sval[0])
							{
								case 'i':
									t.sval="integer";
									break;
								case 'r':
									t.sval="real";
									break;
								case 'b':
									t.sval="boolean";
									break;
								case 's':
									t.sval="string";
									break;
								default:
									t.sval="integer";
							}
							if(t.arrDim>0)
							{
								t.sval+=" ";
								int ptr=t.arrDim-1;
								for(int i=0;i<t.arrDim;++i)
								{
									int n=t.dim[ptr-i];
									t.sval+='['+to_string(n)+']';
								}
							}

						}
							
					}
	return t.sval;
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
						returnType.push_back("");
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
						if(table[0][0].name!=$7.sval)
						{
							errorMsg("inconsistent program name");
						}
						
						if(table[0][0].name!=fileName)
						{
							errorMsg("fileName!= program name");
						}
						if($7.sval!=fileName)
						{
							errorMsg("fileName!= end ID program name");
						}
						
						
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
						setVariable($4.sval,false);
					}
			| VAR id_list MK_COLON array_type MK_SEMICOLON 
			/* array type declaration */
					{
						setVariable($4.sval,true);
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
							$$.ival=$1.ival;
							$$.sval="integer";

							nowType="integer";
							nowAttr=to_string($1.ival);
						}
			| OP_SUB int_const
						{
							$$.ival=$1.ival*-1;
							$$.sval="integer";

							nowType="integer";
							nowAttr=to_string($1.ival*-1);
					}
			| FLOAT_CONST
						{
							$$.rval=$1.rval;
							$$.sval="real";

							nowType="real";
							nowAttr=to_string($1.rval);
						}

			| OP_SUB FLOAT_CONST
						{
							$$.rval=$1.rval*-1;
							$$.sval="real";

							nowType="real";
							nowAttr=to_string($1.ival*-1);
						}

			| SCIENTIFIC
						{
							$$.rval=$1.rval;
							$$.sval="real";

							nowType="real";
							nowAttr=to_string($1.rval);
						}

			| OP_SUB SCIENTIFIC
						{
							$$.rval=$1.rval*-1;
							$$.sval="real";

							nowType="real";
							nowAttr=to_string($1.rval*-1);
						}

			| STR_CONST
						{
							$$.sval="string";

							nowType="string";
							nowAttr=$1.sval;
						}

			| TRUE
						{
							$$.bval=$1.bval;
							$$.sval="boolean";

							nowType="boolean";
							nowAttr="true";
						}

			| FALSE
						{
							$$.bval=$1.bval;
							$$.sval="boolean";

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
								errorRedeclare($1.sval);
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
MK_RPAREN opt_type
							{
								returnType.push_back($8.sval);
								dim.clear();
							}
				MK_SEMICOLON
			  compound_stmt
			  END ID
			  {
			if(!isRe($1.sval))
			{
			  addFunction($1.sval,$8.sval,parameters);
			  if($1.sval!=$13.sval)
			  {
				errorMsg("function name inconsistent");
			  }
			}		
			parameters.clear();
			if(isScalar($8.sval))
			{
								
			}
			else if((isVoid($8.sval)))
			{
			}
			else
			{
				errorMsg("function return type is array type");

			}
			returnType.pop_back();
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
						
						parameterVec.push_back($3.sval);
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
						boundCheck($2.ival,$4.ival,false);
						stringstream ss;
						int num=$4.ival-$2.ival+1;
						dim.push_back(num);
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
					{
					
						if($1.ival==-1)//not symbol
						{
							errorMsg("ID mismatch");
						}
						else if($1.ival==-2)
						{
							errorMsg("loop variable cannot be assigned");
						}
						else
						{
							$1.sval=arr2Scalar($1);
						
							if($1.ival==4)//const
							{
								errorMsg("const cannot be assigned");
							}
							else if($1.sval==$3.sval)
							{
								if(!isScalar($1.sval))
								{
									errorMsg("array type cannot be assigned");
								}
								;//not thiing ,it's fine
							}
							else//s1!=s3
							{
								if(isNumType($1.sval)&&isNumType($3.sval))
								{
									$$.sval=typeCoercion($1.sval,$3.sval,1);
								}
								else if(!isScalar($1.sval))//array type
								{
									errorMsg("array type cannot be assigned");
								}
								else
								{
									errorMsg("assign with wrong type:"+$1.sval+"!="+$3.sval);
								}
							}
						}
						
					}
			| PRINT boolean_expr MK_SEMICOLON
				{
					if(!isScalar($2.sval))
					{
						errorMsg("print without scalar type");
					}
				}
			| READ boolean_expr MK_SEMICOLON
				{
					if(!isScalar($2.sval))
					{
						errorMsg("read without scalar type");
					}
				}
			;

proc_call_stmt		: ID MK_LPAREN opt_boolean_expr_list MK_RPAREN MK_SEMICOLON
					{
						vector<string> fun=ID2parameterVec($1.sval);
						parameterCheck(fun,$3.parameters);	
					}
			;

cond_stmt		: IF boolean_expr THEN
			  opt_stmt_list
			  ELSE
			  opt_stmt_list
			  END IF
			  {
				if($2.sval!="boolean")
				{
					errorMsg("condition without boolean type");
				}
			  }
			| IF boolean_expr THEN opt_stmt_list END IF
				{
					if($2.sval!="boolean")
					{
						errorMsg("condition without boolean type");
					}
				}
			;

while_stmt		: WHILE boolean_expr DO
			  opt_stmt_list
			  END DO
			  {
				if($2.sval!="boolean")
				{
					errorMsg("while without boolean type");
				}
			  }
			;

for_stmt		: FOR 
						{
							addEntry();
						}
						ID
						{
							if(isRe($3.sval))
							{
								errorRedeclare($3.sval);
							}
							forNames.push_back($3.sval);
							dim.clear();
						}
				OP_ASSIGN int_const TO int_const DO
			  opt_stmt_list
			  END DO
			  {
				boundCheck($6.ival,$8.ival,true);
			  	level--;
			  	table.pop_back();
			  	forNames.pop_back();
			  }
			;

return_stmt		: RETURN boolean_expr MK_SEMICOLON
			 {
				returnTypeCheck($2.sval);
			 }
			;

opt_boolean_expr_list	: boolean_expr_list
					  {
						$$=$1;
					  }
			| /* epsilon */
				{
					$$.parameters.clear();
				}
			;

boolean_expr_list	: boolean_expr_list MK_COMMA boolean_expr
						{
							$$=$1;
							$$.parameters.push_back($3.sval);
						}
			| boolean_expr
				{
					$$=$1;
					$$.parameters.push_back($1.sval);
				}
			;

boolean_expr		: boolean_expr OP_OR boolean_term
					{
						if($1.sval!="boolean")
						{
							errorMsg("orOp with wrong type:");
						}
						if($3.sval!="boolean")
						{
							errorMsg("orOp with wrong type:");
						}

						$$=$1;
					}
			| boolean_term
			{
				$$=$1;
			}
			;

boolean_term		: boolean_term OP_AND boolean_factor
					{
						
						if($1.sval!="boolean")
						{
							errorMsg("andOp with wrong type:");
						}
						if($3.sval!="boolean")
						{
							errorMsg("andOp with wrong type:");
						}

						$$=$1;
					}
			| boolean_factor
			{
				$$=$1;
			}
			;

boolean_factor		: OP_NOT boolean_factor 
					{
						if($2.sval!="boolean")
						{
							errorMsg("notOp with wrong type:");
						}
						$$=$2;
					}
			| relop_expr
			{
				$$=$1;
			}
			;

relop_expr		: expr rel_op expr
				{
					/*if($1.sval=="integer"&& $3.sval=="integer")
					{
						//OK
					}
					else if($1.sval=="real"&& $3.sval=="real")
					{
						//OK
					}*/
					if(isNumType($1.sval)&&isNumType($3.sval))
					{
						//OK
					}
					else
					{
						errorMsg("relOp with wrong type:");
					}

					$$.sval="boolean";
				}
			| expr
			{
				$$=$1;
			}
			;

rel_op			: OP_LT
			| OP_LE
			| OP_EQ
			| OP_GE
			| OP_GT
			| OP_NE
			;

expr			: expr add_op term
				{
					bool isString=false;

					if(!isNumType($1.sval))
					{
						if($2.ival!=1)//-
						{
							
							errorMsg("addOp with wrong type:");

						}
						else
						{
							if($1.sval!="string")
							{
								errorMsg("addOp with wrong type:");

							}
							else
							{
								isString=true;
							}
						}
					}
											
					if(!isNumType($3.sval))
					{
						if($2.ival!=1)//-
						{
							
							errorMsg("addOp with wrong type:");

						}
						else
						{
							if($3.sval!="string")
							{
								errorMsg("addOp with wrong type:");

							}
							else
							{
								if(!isString)//first is num, next is string
								{
									errorMsg("addOp with inconsistent type");
								}
							}

							
						}
					}
					else
					{
						if(isString)//first is string, next is num
						{
							errorMsg("add with inconsistent");
							isString=false;
						}
					}
			
					if(isString)//string + or num +
					{
						$$.sval="string";
					}
					else
					{
					$$.sval=typeCoercion($1.sval,$3.sval,0);
					}
				}
			| term
				{
					$$=$1;
				}
			;

add_op			: OP_ADD
				{
					$$.ival=1;
				}
			| OP_SUB
				{
					$$.ival=0;
				}
			;

term			: term mul_op factor
				{
					
					if($2.ival==2)//MOD	
					{
						if($1.sval!="integer")
						{
							errorMsg("incompatible Type");
						}
						if($3.sval!="integer")
						{
							errorMsg("incompatible type");
						}
						$$=$1;
						$$.sval="integer";
					}
					else
					{

					
						if(!isNumType($1.sval))
						{
							errorMsg("incompatible Type");
						}
						if(!isNumType($3.sval))
						{
							errorMsg("incompatible Type");
						}
						$$=$1;
						$$.sval=typeCoercion($1.sval,$3.sval,0);
					}
				}
			| factor
			{
				$$=$1;
			}
			;

mul_op			: OP_MUL
					{
						$$.ival=0;
					}
			| OP_DIV
					{
						$$.ival=1;
					}
			| OP_MOD
					{
						$$.ival=2;
					}
			;

factor			: var_ref
				{
					$$=$1;
					$$.sval=arr2Scalar($1);
				}
			| OP_SUB var_ref
				{
					$$=$2;
					$$.sval=arr2Scalar($2);
				}
			| MK_LPAREN boolean_expr MK_RPAREN
				{
					$$=$2;
				}
			| OP_SUB MK_LPAREN boolean_expr MK_RPAREN
				{
					$$=$3;
				}
			| ID MK_LPAREN opt_boolean_expr_list MK_RPAREN
				{
					$$.sval=ID2Type($1.sval);
					vector<string> fun=ID2parameterVec($1.sval);
					parameterCheck(fun,$3.parameters);
				}
			| OP_SUB ID MK_LPAREN opt_boolean_expr_list MK_RPAREN
				{
					$$.sval=ID2Type($2.sval);
				}
			| literal_const
				{
					$$=$1;
				}
			;

var_ref			: ID
					{
						$$.sval=ID2Type($1.sval);
						$$.ival=ID2Kind($1.sval);
						$$.bval=IDisArr($1.sval);
						$$.arrDim=ID2Dim($1.sval);
						$$.dim=ID2Vec($1.sval);
						if($$.ival==-1)
						{
							if(isLoopVar($1.sval))
							{
								$$.sval="integer";
								$$.ival=-2;
							}
						}
					}
			| var_ref dim
			{
				$$=$1;
				$$.arrDim--;

				
			}
			;

dim			: MK_LB boolean_expr MK_RB
				{
					if($2.sval!="integer")
					{
						errorMsg("index not integer");
					}
				}
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


