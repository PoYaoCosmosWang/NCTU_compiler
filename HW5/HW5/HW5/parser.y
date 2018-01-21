%{
/**
 * Introduction to Compiler Design by Prof. Yi Ping You
 * Project 3 YACC sample
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "header.h"
#include "symtab.h"
#include "semcheck.h"
FILE* out;
char* name;
int yydebug;
int nextIndex;
int labelNum=1;
int isRead=0;
int loopStack[100];
int nowPtr=0;



extern int linenum;     /* declared in lex.l */
extern FILE *yyin;      /* declared by lex */
extern char *yytext;    /* declared by lex */
extern char buf[256];   /* declared in lex.l */
extern int yylex(void);
int yyerror(char*);

int scope = 0;
int Opt_D = 1;                  // symbol table dump option
char fileName[256];             // filename of input file
struct SymTable *symbolTable;	// main symbol table
__BOOLEAN paramError;			// indicate is parameter have any error?
struct PType *funcReturn;		// record return type of function, used at 'return statement' production rule

void pushStack()
{
	loopStack[nowPtr++]=labelNum;	
}
int popStack()
{
	return loopStack[--nowPtr];
}


%}

%union {
	int intVal;
	float realVal;
	//__BOOLEAN booleanVal;
	char *lexeme;
	struct idNode_sem *id;
	//SEMTYPE type;
	struct ConstAttr *constVal;
	struct PType *ptype;
	struct param_sem *par;
	struct expr_sem *exprs;
	/*struct var_ref_sem *varRef; */
	struct expr_sem_node *exprNode;
};

/* tokens */
%token ARRAY BEG BOOLEAN DEF DO ELSE END FALSE FOR INTEGER IF OF PRINT READ REAL RETURN STRING THEN TO TRUE VAR WHILE
%token OP_ADD OP_SUB OP_MUL OP_DIV OP_MOD OP_ASSIGN OP_EQ OP_NE OP_GT OP_LT OP_GE OP_LE OP_AND OP_OR OP_NOT
%token MK_COMMA MK_COLON MK_SEMICOLON MK_LPAREN MK_RPAREN MK_LB MK_RB

%token <lexeme>ID
%token <intVal>INT_CONST 
%token <realVal>FLOAT_CONST
%token <realVal>SCIENTIFIC
%token <lexeme>STR_CONST

%type<id> id_list
%type<constVal> literal_const
%type<ptype> type scalar_type array_type opt_type
%type<par> param param_list opt_param_list
%type<exprs> var_ref boolean_expr boolean_term boolean_factor relop_expr expr term factor boolean_expr_list opt_boolean_expr_list
%type<intVal> dim mul_op add_op rel_op array_index loop_param condition

/* start symbol */
%start program
%%

program			: ID
			{
				name=$1;
			  struct PType *pType = createPType (VOID_t);
			  struct SymNode *newNode = createProgramNode ($1, scope, pType);
			  insertTab (symbolTable, newNode);

			  if (strcmp(fileName, $1)) {
				fprintf (stdout, "<Error> found in Line %d: program beginning ID inconsist with file name\n", linenum);
			  }
			  
			  char f[30];
			  strcpy(f,$1);
			  strcat(f,".j");
			  out=fopen(f,"w");
			  fprintf(out,"; %s.j\n",$1);
			fprintf(out,".class public %s\n",$1);
			fprintf(out,".super java/lang/Object\n");
			fprintf(out,".field public static _sc Ljava/util/Scanner;\n");			
			}
			  MK_SEMICOLON
			  program_body
			  END ID
			{
			  if (strcmp($1, $6)) {
                  fprintf (stdout, "<Error> found in Line %d: program end ID inconsist with the beginning ID\n", linenum);
              }
			  if (strcmp(fileName, $6)) {
				  fprintf (stdout, "<Error> found in Line %d: program end ID inconsist with file name\n", linenum);
			  }
			  // dump symbol table
			  if( Opt_D == 1 )
				printSymTable( symbolTable, scope );


				fclose(out);
			}
			;

program_body		: opt_decl_list opt_func_decl_list 
			  {
				fprintf(out,".method public static main([Ljava/lang/String;)V\n");
				fprintf(out,"new java/util/Scanner\n");
				fprintf(out,"dup\n");
				fprintf(out,"getstatic java/lang/System/in Ljava/io/InputStream;\n");
				fprintf(out,"invokespecial java/util/Scanner/<init>(Ljava/io/InputStream;)V\n");
				fprintf(out,"putstatic %s/_sc Ljava/util/Scanner;\n",name);
				fprintf(out,".limit stack 100\n.limit locals 100\n");
				symbolTable->nextIndex=1;
			  }
			  compound_stmt
			  {
				fprintf(out,"return\n");
				fprintf(out,".end method\n");
			  }
			;

opt_decl_list		: decl_list
			| /* epsilon */
			;

decl_list		: decl_list decl
			| decl
			;

decl			: VAR id_list MK_COLON scalar_type MK_SEMICOLON       /* scalar type declaration */
			{
			  // insert into symbol table
			  struct idNode_sem *ptr;
			  struct SymNode *newNode;
			  for (ptr=$2 ; ptr!=0; ptr=(ptr->next)) {
			  	if( verifyRedeclaration(symbolTable, ptr->value, scope) == __TRUE ) {
					newNode = createVarNode (ptr->value, scope, $4);
					insertTab (symbolTable, newNode);
					
					if(scope==0)
					{
						
						fprintf(out,".field public static %s ",ptr->value);						
						switch($4->type)
						{
							case INTEGER_t:
								fprintf(out,"I\n");
								break;
							case BOOLEAN_t:
								fprintf(out,"Z\n");
								break;
							case REAL_t:
								fprintf(out,"F\n");
								break;
							default:
								fprintf(out , "ERR\n");
								break;
						}
					}
					else
					{
						newNode->index=symbolTable->nextIndex++;
					}
				}
			  }
			  
			  deleteIdList( $2 );
			}
			| VAR id_list MK_COLON array_type MK_SEMICOLON        /* array type declaration */
			{
			  verifyArrayType( $2, $4 );
			  // insert into symbol table
			  struct idNode_sem *ptr;
			  struct SymNode *newNode;
			  for( ptr=$2 ; ptr!=0 ; ptr=(ptr->next) ) {
			  	if( $4->isError == __TRUE ) { }
				else if( verifyRedeclaration( symbolTable, ptr->value, scope ) ==__FALSE ) { }
				else {
					newNode = createVarNode( ptr->value, scope, $4 );
					insertTab( symbolTable, newNode );
				}
			  }
			  
			  deleteIdList( $2 );
			}
			| VAR id_list MK_COLON literal_const MK_SEMICOLON     /* const declaration */
			{
			  struct PType *pType = createPType( $4->category );
			  // insert constants into symbol table
			  struct idNode_sem *ptr;
			  struct SymNode *newNode;
			  for( ptr=$2 ; ptr!=0 ; ptr=(ptr->next) ) {
			  	if( verifyRedeclaration( symbolTable, ptr->value, scope ) ==__FALSE ) { }
				else {
					newNode = createConstNode( ptr->value, scope, pType, $4 );
					insertTab( symbolTable, newNode );
				}
			  }
			  
			  deleteIdList( $2 );
			}
			;

literal_const		: INT_CONST
			{
			  int tmp = $1;
			  $$ = createConstAttr( INTEGER_t, &tmp );
			}
			| OP_SUB INT_CONST
			{
			  int tmp = -$2;
			  $$ = createConstAttr( INTEGER_t, &tmp );
			}
			| FLOAT_CONST
			{
			  float tmp = $1;
			  $$ = createConstAttr( REAL_t, &tmp );
			}
			| OP_SUB FLOAT_CONST
			{
			  float tmp = -$2;
			  $$ = createConstAttr( REAL_t, &tmp );
			}
			| SCIENTIFIC 
			{
			  float tmp = $1;
			  $$ = createConstAttr( REAL_t, &tmp );
			}
			| OP_SUB SCIENTIFIC
			{
			  float tmp = -$2;
			  $$ = createConstAttr( REAL_t, &tmp );
			}
			| STR_CONST
			{
			  $$ = createConstAttr( STRING_t, $1 );
			}
			| TRUE
			{
			  __BOOLEAN tmp = __TRUE;
			  $$ = createConstAttr( BOOLEAN_t, &tmp );
			}
			| FALSE
			{
			  __BOOLEAN tmp = __FALSE;
			  $$ = createConstAttr( BOOLEAN_t, &tmp );
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
					fprintf(out,".method public static %s(",$1);
					symbolTable->nextIndex=0;
				}
				MK_LPAREN opt_param_list
			{
			  // check and insert parameters into symbol table
			  paramError = insertParamIntoSymTable( symbolTable, $4, scope+1 );
			}
			  MK_RPAREN opt_type 
			{
				char c;
				switch($7->type)
				{
					case VOID_t:
						c='V';
						break;
					case INTEGER_t:
						c='I';
						break;
					case BOOLEAN_t:
						c='Z';
						break;
					case REAL_t:
						c='F';
						break;
				}
				fprintf(out,")%c\n",c);
				fprintf(out,".limit stack 100\n");
				fprintf(out,".limit locals 100\n");
			  // check and insert function into symbol table
			  if( paramError == __TRUE ) {
			  	printf("<Error> found in Line %d: param(s) with several error\n", linenum);
			  } else if( $7->isArray == __TRUE ) {
					
					printf("<Error> found in Line %d: a function cannot return an array type\n", linenum);
				} else {
					
				insertFuncIntoSymTable( symbolTable, $1, $4, $7, scope );
			  }
			  funcReturn = $7;
			}
			  MK_SEMICOLON
			  compound_stmt
			  END ID
			{
				
				
				switch(funcReturn->type)
				{
					case INTEGER_t:
						fprintf(out,"ireturn\n");
						break;
					case BOOLEAN_t:
						fprintf(out,"ireturn\n");
						break;
					case REAL_t:
						fprintf(out,"freturn\n");
						break;
					default:
						fprintf(out,"return\n");
				}
				fprintf(out,".end method\n");
			  if( strcmp($1,$12) ) {
				fprintf( stdout, "<Error> found in Line %d: the end of the functionName mismatch\n", linenum );
			  }
			  funcReturn = 0;
			}
			;

opt_param_list		: param_list { $$ = $1; }
			| /* epsilon */ { $$ = 0; }
			;

param_list		: param_list MK_SEMICOLON param
			{
			  param_sem_addParam( $1, $3 );
			  $$ = $1;
			}
			| param { $$ = $1; }
			;

param			: id_list MK_COLON type
					{
					$$ = createParam( $1, $3 );
					struct idNode_sem* ptr;
					char c;
					switch($3->type)
					{
						case INTEGER_t:
							c='I';	
							break;
						case REAL_t:
							c='F';
							break;
						case BOOLEAN_t:
							c='Z';
							break;
					}
					for(ptr=$1;ptr!=NULL;ptr=ptr->next)
					{
						fprintf(out,"%c",c);
					}


					}
			;

id_list			: id_list MK_COMMA ID
			{
			  idlist_addNode( $1, $3 );
			  $$ = $1;
			}
			| ID { $$ = createIdList($1); }
			;

opt_type		: MK_COLON type { $$ = $2; }
			| /* epsilon */ { $$ = createPType( VOID_t ); }
			;

type			: scalar_type { $$ = $1; }
			| array_type { $$ = $1; }
			;

scalar_type		: INTEGER { $$ = createPType (INTEGER_t); }
			| REAL { $$ = createPType (REAL_t); }
			| BOOLEAN { $$ = createPType (BOOLEAN_t); }
			| STRING { $$ = createPType (STRING_t); }
			;

array_type		: ARRAY array_index TO array_index OF type
			{
				verifyArrayDim ($6, $2, $4);
				increaseArrayDim ($6, $2, $4);
				$$ = $6;
			}
			;

array_index		: INT_CONST { $$ = $1; }
			;

stmt			: compound_stmt
			| simple_stmt
			| cond_stmt
			| while_stmt
			| for_stmt
			| return_stmt
			| proc_call_stmt
			;

compound_stmt		: 
			{ 
			  scope++;
			}
			  BEG
			  opt_decl_list
			  opt_stmt_list
			  END 
			{ 
			  // print contents of current scope
			  if( Opt_D == 1 )
			  	printSymTable( symbolTable, scope );
			  deleteScope( symbolTable, scope );	// leave this scope, delete...
			  scope--; 
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
			  // check if LHS exists
			  __BOOLEAN flagLHS = verifyExistence( symbolTable, $1, scope, __TRUE );
			  // id RHS is not dereferenced, check and deference
			  __BOOLEAN flagRHS = __TRUE;
			  if( $3->isDeref == __FALSE ) {
				flagRHS = verifyExistence( symbolTable, $3, scope, __FALSE );
			  }
			  // if both LHS and RHS are exists, verify their type
			  if( flagLHS==__TRUE && flagRHS==__TRUE )
				verifyAssignmentTypeMatch( $1, $3 );
				

				struct SymNode* nowNode=lookupSymbol(symbolTable,$1->varRef->id,scope,__FALSE);

				if(nowNode->type->type==REAL_t && $3->pType->type==INTEGER_t)
				{
					fprintf(out,"i2f\n");
				}

				if(nowNode->scope==0)//global
				{
					fprintf(out,"putstatic %s/%s ",name,$1->varRef->id);
					switch(nowNode->type->type)
					{
						case INTEGER_t:
							fprintf(out,"I\n");
							break;
						case BOOLEAN_t:
							fprintf(out,"Z\n");
							break;
						case REAL_t:
							fprintf(out,"F\n");
					}
				}
				else
				{
					switch(nowNode->type->type)
					{
						case INTEGER_t:
							fprintf(out,"i");
							break;
						case BOOLEAN_t:
							fprintf(out,"i");
							break;
						case REAL_t:
							fprintf(out,"f");
							break;
					}
					fprintf(out,"store %d\n",nowNode->index);


				}

			}
			| PRINT
			{
				fprintf(out,"getstatic java/lang/System/out Ljava/io/PrintStream;\n");
			}
			boolean_expr MK_SEMICOLON 
			{ verifyScalarExpr( $3, "print" );
				fprintf(out,"invokevirtual java/io/PrintStream/print");
				switch($3->pType->type)
				{
					case INTEGER_t:
						fprintf(out,"(I)V\n");
						break;
					case BOOLEAN_t:
						fprintf(out,"(Z)V\n");
						break;
					case REAL_t:
						fprintf(out,"(F)V\n");
						break;
					case STRING_t:
						fprintf(out,"(Ljava/lang/String;)V\n");
						break;
				}
			}
 			| READ
			{
				isRead=1;
			}
			boolean_expr MK_SEMICOLON 
			{
				isRead=0;
				verifyScalarExpr( $3, "read" );
				fprintf(out,"getstatic %s/_sc Ljava/util/Scanner;\n",name);
				fprintf(out,"invokevirtual java/util/Scanner/next");
				struct SymNode* nowNode=lookupSymbol(symbolTable,$3->varRef->id,scope,__FALSE);

				switch(nowNode->type->type)
				{
					case INTEGER_t:
						fprintf(out,"Int()I\ni");
						break;
					case BOOLEAN_t:
						fprintf(out,"Boolean()Z\ni");
						break;
					case REAL_t:
						fprintf(out,"Real()F\nf");
						break;

				}
				fprintf(out,"store %d\n",nowNode->index);
				}
			;

proc_call_stmt		: ID MK_LPAREN opt_boolean_expr_list MK_RPAREN MK_SEMICOLON
			{
			  verifyFuncInvoke( $1, $3, symbolTable, scope );
			}
			;

cond_stmt		: IF condition THEN
			  opt_stmt_list
			  ELSE
			  {
				
				fprintf(out,"goto L%d\n",$2+1);
				fprintf(out,"L%d:\n",$2);
			  }
			  opt_stmt_list
			  {
				fprintf(out,"L%d:\n",$2+1);
			  }
			  END IF
			| IF condition THEN opt_stmt_list END IF
			{
				fprintf(out,"L%d:\n",$2);
			}
			;

condition		: boolean_expr 
		   { verifyBooleanExpr( $1, "if" );
			fprintf(out,"ifeq L%d\n",labelNum);
			$$=labelNum;
			labelNum+=2;
		   } 
			;

while_stmt		: WHILE
				{
					pushStack();
					fprintf(out,"L%d:\n",labelNum++);
				}
				
				condition_while DO
				{
					pushStack();
					fprintf(out,"ifeq L%d\n",labelNum++);
				}
			  opt_stmt_list
			  {
				fprintf(out,"goto L%d\n",loopStack[nowPtr-2]);
				fprintf(out,"L%d:\n",popStack());
				popStack();
			  }
			  END DO
			;

condition_while		: boolean_expr { verifyBooleanExpr( $1, "while" ); } 
			;

for_stmt		: FOR ID 
			{ 
			  insertLoopVarIntoTable( symbolTable, $2 );
			}
			  OP_ASSIGN loop_param TO loop_param
			{
			  verifyLoopParam( $5, $7 );
			  struct SymNode* loop=lookupLoopVar(symbolTable,$2);
			  loop->index=symbolTable->nextIndex++;
			  //init
			  fprintf(out,"ldc %d\n",$5);
			  fprintf(out,"istore %d\n",loop->index);
			  
			  //loop
			  pushStack();
			  fprintf(out,"L%d:\n",labelNum++);
			  //relation op
			  fprintf(out,"iload %d\n",loop->index);
			  fprintf(out,"ldc %d\n",$7+1);
			  fprintf(out,"isub\n");
				fprintf(out,"iflt L%d\n",labelNum++);
				fprintf(out,"iconst_0\n");
				fprintf(out,"goto L%d\n",labelNum);
				fprintf(out,"L%d:\n",labelNum-1);
				fprintf(out,"iconst_1\n");
				fprintf(out,"L%d:\n",labelNum++);
				pushStack();
				fprintf(out,"ifeq L%d\n",labelNum++);

				
			}
			  DO
			  opt_stmt_list
			  
			  END DO
			{
				struct SymNode* loop=lookupLoopVar(symbolTable,$2);

				fprintf(out,"iload %d\n",loop->index);
				fprintf(out, "ldc 1\n");
				fprintf(out, "iadd \n");
				fprintf(out,"istore %d\n",loop->index);
				fprintf(out,"goto L%d\n",loopStack[nowPtr-2]);
				fprintf(out,"L%d:\n",popStack());
				popStack();
			  popLoopVar( symbolTable );
			}
			;

loop_param		: INT_CONST { $$ = $1; }
			| OP_SUB INT_CONST { $$ = -$2; }
			;

return_stmt		: RETURN boolean_expr MK_SEMICOLON
			{
				switch(funcReturn->type)
				{
					case REAL_t:
						fprintf(out,"freturn\n");
						break;
					case VOID_t:
						fprintf(out,"return\n");
						break;
					default:
						fprintf(out,"ireturn\n");
				}
			  verifyReturnStatement( $2, funcReturn );
			}
			;

opt_boolean_expr_list	: boolean_expr_list { $$ = $1; }
			| /* epsilon */ { $$ = 0; }	// null
			;

boolean_expr_list	: boolean_expr_list MK_COMMA boolean_expr
			{
			  struct expr_sem *exprPtr;
			  for( exprPtr=$1 ; (exprPtr->next)!=0 ; exprPtr=(exprPtr->next) );
			  exprPtr->next = $3;
			  $$ = $1;
			}
			| boolean_expr
			{
			  $$ = $1;
			}
			;

boolean_expr		: boolean_expr OP_OR boolean_term
			{
			  verifyAndOrOp( $1, OR_t, $3 );
			  $$ = $1;
			  fprintf(out,"ior\n");
			}
			| boolean_term { $$ = $1; }
			;

boolean_term		: boolean_term OP_AND boolean_factor
			{
			  verifyAndOrOp( $1, AND_t, $3 );
			  $$ = $1;
			  fprintf(out,"iand\n");
			}
			| boolean_factor { $$ = $1; }
			;

boolean_factor		: OP_NOT boolean_factor 
			{
			  verifyUnaryNOT( $2 );
			  $$ = $2;
			  fprintf(out,"iconst_1\n");
			  fprintf(out,"ixor\n");
			}
			| relop_expr { $$ = $1; }
			;

relop_expr		: expr rel_op expr
			{
				if($1->pType->type==INTEGER_t)
				{
					fprintf(out,"isub\n");
				}
				else
				{
					fprintf(out,"fcmpl\n");
				}
				switch($2)
				{
					case LT_t:
						fprintf(out,"iflt");
						break;
					case LE_t:
						fprintf(out,"ifle");
						break;
					case EQ_t:
						fprintf(out,"ifeq");
						break;
					case GE_t:
						fprintf(out,"ifge");
						break;
					case GT_t:
						fprintf(out,"ifgt");
						break;
					case NE_t:
						fprintf(out,"ifne");
						break;
				}
				fprintf(out," L%d\n",labelNum);
				fprintf(out,"iconst_0\n");
				fprintf(out,"goto L%d\n",labelNum+1);
				fprintf(out,"L%d:\n",labelNum++);
				fprintf(out,"iconst_1\n");
				fprintf(out,"L%d:\n",labelNum++);

			  verifyRelOp( $1, $2, $3 );
			  $$ = $1;
							}
			| expr { $$ = $1; }
			;

rel_op			: OP_LT { $$ = LT_t; }
			| OP_LE { $$ = LE_t; }
			| OP_EQ { $$ = EQ_t; }
			| OP_GE { $$ = GE_t; }
			| OP_GT { $$ = GT_t; }
			| OP_NE { $$ = NE_t; }
			;

expr			: expr add_op term
			{
				nextIndex=symbolTable->nextIndex;
			  verifyArithmeticOp( $1, $2, $3 );
			  $$ = $1;
				char c=$1->pType->type==INTEGER_t?'i':'f';
				switch($2)
				{
					case ADD_t:
						
						fprintf(out,"%cadd\n",c);
						break;
					case SUB_t:
						fprintf(out,"%csub\n",c);
						break;
				}

			}
			| term { $$ = $1; }
			;

add_op			: OP_ADD { $$ = ADD_t; }
			| OP_SUB { $$ = SUB_t; }
			;

term			: term mul_op factor
			{
			  if( $2 == MOD_t ) {
				verifyModOp( $1, $3 );
				fprintf(out,"irem\n");
			  }
			  else {
					nextIndex=symbolTable->nextIndex;

				verifyArithmeticOp( $1, $2, $3 );
				char c=$1->pType->type==INTEGER_t?'i':'f';
				switch($2)
				{
					case MUL_t:
						
						fprintf(out,"%cmul\n",c);
						break;
					case DIV_t:
						fprintf(out,"%cdiv\n",c);
						break;
				}
			  }
			  $$ = $1;
			}
			| factor { $$ = $1; }
			;

mul_op			: OP_MUL { $$ = MUL_t; }
			| OP_DIV { $$ = DIV_t; }
			| OP_MOD { $$ = MOD_t; }
			;

factor			: var_ref
			{
			  verifyExistence( symbolTable, $1, scope, __FALSE );
			  $$ = $1;
			  $$->beginningOp = NONE_t;
			 struct SymNode* loop=lookupLoopVar(symbolTable,$1->varRef->id);
			 if(loop!=NULL)
			 {
				fprintf(out,"iload %d\n",loop->index);
			 }
			 else
			 {

			 
				 struct SymNode* nowNode=lookupSymbol(symbolTable,$1->varRef->id,scope,__FALSE);
				  if(nowNode->category==CONSTANT_t)
				  {
						switch(nowNode->type->type)
						{
							case INTEGER_t:
								fprintf(out,"ldc");
								fprintf(out," %d\n",nowNode->attribute->constVal->value.integerVal);
								break;
							case BOOLEAN_t:
								fprintf(out,"iconst_");
								fprintf(out,"%d\n",nowNode->attribute->constVal->value.booleanVal);
	
								break;
							case REAL_t:
								fprintf(out,"ldc");
									fprintf(out," %f\n",nowNode->attribute->constVal->value.realVal);
	
								break;
							case STRING_t:
								fprintf(out,"ldc \"%s\"\n",nowNode->attribute->constVal->value.stringVal);
								break;
						}
					
					
					  
				  }
				  else
				{

					  if(isRead==0)
					{
	
					
						if(nowNode->scope==0)
						  {
							fprintf(out,"getstatic %s/%s ",name,$1->varRef->id);
							switch(nowNode->type->type)
							{
								case INTEGER_t:
									fprintf(out,"I\n");
										break;
								case BOOLEAN_t:
									fprintf(out,"Z\n");
									break;
								case REAL_t:
									fprintf(out,"F\n");
									break;
								}

							}
						 else
						  {
							switch(nowNode->type->type)
							{
								case INTEGER_t:
									fprintf(out,"i");
										break;
								case BOOLEAN_t:
									fprintf(out,"i");
										break;
								case REAL_t:
									fprintf(out,"f");
									break;
							}
					
							fprintf(out,"load %d\n",nowNode->index);

							}
						}
					}
				}
			}
			| OP_SUB var_ref
			{
			  if( verifyExistence( symbolTable, $2, scope, __FALSE ) == __TRUE )
				verifyUnaryMinus( $2 );
			  $$ = $2;
			  $$->beginningOp = SUB_t;
			  struct SymNode* nowNode=lookupSymbol(symbolTable,$2->varRef->id,scope,__FALSE);
				 if(nowNode->category==CONSTANT_t)
			  {
					switch(nowNode->type->type)
					{
						case INTEGER_t:
							fprintf(out,"ldc");
							fprintf(out," %d\n",nowNode->attribute->constVal->value.integerVal);
							break;
						case BOOLEAN_t:
							fprintf(out,"iconst_");
							fprintf(out,"%d\n",nowNode->attribute->constVal->value.booleanVal);

							break;
						case REAL_t:
							fprintf(out,"ldc");
							fprintf(out," %f\n",nowNode->attribute->constVal->value.realVal);

							break;
						case STRING_t:
							fprintf(out,"ldc \"%s\"\n",nowNode->attribute->constVal->value.stringVal);
							break;
					}
				
				
			  
			  }
			  else
			  {

			  
				if(nowNode->scope==0)
				  {
					fprintf(out,"getstatic %s/%s ",name,$2->varRef->id);
					switch(nowNode->type->type)
					{
						case INTEGER_t:
							fprintf(out,"I\n");
							break;
						case BOOLEAN_t:
							fprintf(out,"Z\n");
							break;
						case REAL_t:
							fprintf(out,"F\n");
							break;
					}

				  }
				  else
				  {
					switch(nowNode->type->type)
					{
						case INTEGER_t:
							fprintf(out,"i");
							break;
						case BOOLEAN_t:
							fprintf(out,"i");
							break;
						case REAL_t:
							fprintf(out,"f");
							break;
					}
				
					fprintf(out,"load %d\n",nowNode->index);

				  }
				}
				
				switch(nowNode->type->type)
				{
					case INTEGER_t:
						fprintf(out,"ineg\n");
						break;
					case REAL_t:
						fprintf(out,"fneg\n");
						break;
				}

			}
			| MK_LPAREN boolean_expr MK_RPAREN 
			{
			  $2->beginningOp = NONE_t;
			  $$ = $2; 
			}
			| OP_SUB MK_LPAREN boolean_expr MK_RPAREN
			{
			  verifyUnaryMinus( $3 );
			  $$ = $3;
			  $$->beginningOp = SUB_t;
				
				switch($3->pType->type)
				{
					case INTEGER_t:
						fprintf(out,"ineg\n");
						break;
					case REAL_t:
						fprintf(out,"fneg\n");
						break;
				}
			}
			| ID MK_LPAREN opt_boolean_expr_list MK_RPAREN
			{
			  $$ = verifyFuncInvoke( $1, $3, symbolTable, scope );
			  $$->beginningOp = NONE_t;
			  
			}
			| OP_SUB ID MK_LPAREN opt_boolean_expr_list MK_RPAREN
			{
				$$=verifyFuncInvoke($2,$4,symbolTable,scope);
				$$->beginningOp=SUB_t;

				struct SymNode* fun=lookupSymbol(symbolTable,$2,0,__FALSE);
				switch(fun->type->type)
				{
					case INTEGER_t:
						fprintf(out,"ineg\n");
						break;
					case REAL_t:
						fprintf(out,"fneg\n");
						break;
				}

			}
			|literal_const
			{
				$$= (struct expr_sem * )malloc(sizeof(struct expr_sem));
				$$->isDeref = __TRUE;
				$$->varRef = 0;
				$$->pType = createPType($1->category);
				$$->next = 0;
				if($1->hasMinus == __TRUE)
				{
					$$->beginningOp= SUB_t;
				}
				else
				{
					$$->beginningOp=NONE_t;
				}

				switch($1->category)
				{
					case INTEGER_t:
						fprintf(out," ldc %d\n",$1->value.integerVal);
						break;
					case REAL_t:
						fprintf(out," ldc %f\n",$1->value.realVal);
						break;
					case BOOLEAN_t:
						fprintf(out,"iconst_%d\n",$1->value.booleanVal);
						break;
					case STRING_t:
						fprintf(out,"ldc \"%s\"\n",$1->value.stringVal);
				}

			}
			;

var_ref			: ID
			{
			  $$ = createExprSem( $1 );

			}
			| var_ref dim
			{
			  increaseDim( $1, $2 );
			  $$ = $1;
			}
			;

dim			: MK_LB boolean_expr MK_RB
			{
			  $$ = verifyArrayIndex( $2 );
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

