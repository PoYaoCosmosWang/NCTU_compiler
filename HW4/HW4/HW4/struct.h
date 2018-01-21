/**
 * Introduction to Compiler Design by Prof. Yi Ping You
 * Prjoect 2 main function
 */
#ifndef A
#define A

#include <string>
#include<vector>
using namespace std;

extern "C"
{
    int yyerror(const char *msg);
    extern int yylex(void);
}

struct type
{
	string sval;
	int ival;
	double rval;
	bool bval;
	vector<int> dim;
	int arrDim;
	vector<string> parameters;
};

#define YYSTYPE type



class attribute
{
	public:
	bool isConst;
	string pTypes; //parameterTYpes
	type t;
	int constType; //0:string 1:int 2:double 3:bool
	vector<string> parameters;
	void print()
	{
		if(isConst)
		{
			switch(constType)
			{
				case 0:
					printf("%s",t.sval.c_str());
					break;
				case 1:
					printf("%d",t.ival);
					break;
				case 2:
					printf("%ld",t.rval);
					break;
				case 3:
					printf("%s",t.bval?"true":"false");
					break;
			}
			
		}
		else
		{
			printf("%s",pTypes.c_str());
		}
	}
	
	void addType(string s)
	{
		isConst=false;
		if(pTypes.size()==0)
		{
			pTypes+=s;
		}
		else
		{
			pTypes+=", "+s;
		}
	}
	void add(int i)
	{
		isConst=true;
		constType=1;
		t.ival=i;
	}
	void add(double d)
	{
		isConst=true;
		constType=2;
		t.rval=d;
	}
	void add(string s)
	{
		isConst=true;
		constType=0;
		t.sval=s;
	}
	void add(bool b)
	{
		isConst=true;
		constType=3;
		t.bval=b;
	}

};


class symbol
{
	public:
	std::string name;
	int kind;// 0:program 1:function 2:parameter 3:variable 4:const
	int level;
	std::string type;
	bool isArray;
	int arrDim;
	vector<int> dim;
	attribute attr;	
	void print()
	{
		printf("%-33s", name.c_str());
		switch(kind)
		{
			case 0:
				printf("%-11s", "program");
				break;
			case 1:
				printf("%-11s", "function");
				break;
			case 2:
				printf("%-11s", "parameter");
				break;
			case 3:
				printf("%-11s", "variable");
				break;
			case 4:
				printf("%-11s", "constant");
				break;
		}
		printf("%d%-10s", level,level?"(local)":"(global)");
		printf("%-17s", type.c_str());
		
		if(kind==1||kind==4)
			attr.print();
		printf("\n");
	}
};
//vector<vector< symbol> > symbolTable;
//vector<symbol> entry;

#endif
