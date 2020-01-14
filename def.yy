%{
#include <string.h>
#include <iostream>
#include <fstream>
#include <stack>
#include <vector>
#include <map> 
extern "C" int yylex(); 
extern "C" int yyerror(const char *msg,...);
using namespace std; 
extern FILE *yyout;
fstream trioFile;
fstream symbolsFile;
fstream sourceFile;
void genTrio(char op, string asmOp); 
int tempCounter = 0; 
struct StackOb
{
	string type;
	string val;
};
stack<StackOb> s;
map<string, string> symbols; 

//Utility functions
void genAsm(string asmOp, StackOb sOb1, StackOb sOb2, StackOb sOb3);
void saveSymbol(StackOb sOb);
void createSymbolsTable();
void stackVar(const char* val, string type);
void generateSource();
void stdoutGenerator(string asmOp, int syscall_id, string reg); 

vector<string> asmCode;    
%}

%union
{
	char* text;
	char chr; 
	int ival;
	double dval;
};
%token NEQ EQ GT LT GEQ LEQ
%token STRING CHAR INT BOOL DOUBLE
%token STDIN STDOUT
%token FN RET
%token <text> ID
%token <text> STR
%token <ival> LB
%token <ival> LC 
%token <dval> LR 
%%
program	
	:block {cout<<"program \n";}
	|program block {cout<<"program with block\n";}
	;

if_expr
	:if_begin block {}

if_begin 
	:IF '(' condition ')'{}

block	
	:assign {cout<<"block\n";}
	|stdout
	|stdin
      	;

stdout	:STDOUT LC {}
      	|STDOUT LR {}
	;

stdin	:STDIN LC {}
      	|STDIN LR {}
	;

assign 	
	:ID '=' wyr ';'{cout<<"B1: "<<$1<<"\n"; stackVar($1, "ID");genTrio('=', "assign");}
	;

condition
	:wyr EQ wyr {}
	|wyr NEQ wyr {}
	|wyr GT wyr {}
	|wyr LT wyr {}
	|wyr GEQ wyr {}
	|wyr LEQ wyr {}

wyr 
	:wyr '+' skladnik {genTrio('+', "add");}
	|wyr '-' skladnik {genTrio('-', "sub");}
	|skladnik {}
	;

skladnik
	:skladnik '*' czynnik {genTrio('*', "mul");}
	|skladnik '/' czynnik {genTrio('/', "div");}
	|skladnik '%' czynnik {genTrio('%', "mod");}
	|czynnik {cout<<"here\n";}
	;

czynnik
	:ID {stackVar($1, "ID"); }
	|LC {StackOb sOb; sOb.type = "INT"; sOb.val = to_string($1); s.push(sOb);cout<<"Pushed: "<<sOb.val<<"\n";}
	|LR {StackOb sOb; sOb.type = "DOUBLE"; sOb.val = to_string($1); s.push(sOb);cout<<"Here\n";}
	| {cout<< "not recognized terminal\n";}
	;
%%
int main(int argc, char **argv)
{
	trioFile.open("out.txt", ios_base::out|ios_base::in);
	symbolsFile.open("symbols.txt", ios_base::out|ios_base::in);
	sourceFile.open("source.asm", ios_base::out|ios_base::in);
	if(trioFile.is_open())
	{
		yyparse();
	}
	else
	{
		cout<<"Could not openi\n";
	}

	createSymbolsTable();
	generateSource();
	trioFile.close();
	symbolsFile.close();
	sourceFile.close(); 
	return 0; 
} 

void stackVar(const char* val, string type)
{
	string value(val);
	StackOb sOb; 
	sOb.type = type; 
	sOb.val = value; 
	s.push(sOb);
	saveSymbol(sOb);
}

void genAsm(string op, StackOb sOb1, StackOb sOb2, StackOb sOb3)
{	
	string line;
	line = "#Operation "+op+" for arguments: "+sOb1.val+" "+sOb2.val+"\n";
	asmCode.push_back(line);
	if(op != "assign")
	{
		if(sOb1.type == "ID")
		{
			line ="lw $t0, "+ sOb1.val + "\n";
		}
		else
		{
			line ="li $t0, "+ sOb1.val + "\n";
		}
		asmCode.push_back(line);
	

		if(sOb2.type == "ID")
		{
			line ="lw $t1, "+ sOb2.val + "\n";
		}
		else
		{
			line ="li $t1, "+ sOb2.val + "\n";
		}
		asmCode.push_back(line);

		line =op+" $t0, $t0, $t1\n";
		asmCode.push_back(line);
		line ="sw $t0, "+ sOb3.val + "\n";
		asmCode.push_back(line);
	}
	else
	{
		line ="lw $t0, "+ sOb1.val + "\n";
		asmCode.push_back(line);
		line ="sw $t0, "+ sOb2.val + "\n";
		asmCode.push_back(line);
	}
}

void genTrio(char op, string asmOp)
{
	cout<<"Stack count begin: "<<s.size()<<"\n";

	if(s.size() > 1)
	{
		StackOb sOb1 = s.top(); 
		s.pop();
		StackOb sOb2 = s.top(); 
		s.pop(); 

		string temp = "result";
		StackOb resOb; 
		resOb.type = "ID"; 
		resOb.val = temp.append(to_string(tempCounter));
		s.push(resOb); 
		cout<<"Stack count after push: "<<s.size()<<"\n";
		saveSymbol(resOb); 

		trioFile<<"result"<<tempCounter<<" = "<<sOb2.val<<" "<<sOb1.val<<" "<<op<<"\n";
		genAsm(asmOp, sOb2, sOb1, resOb);
		tempCounter++;
		
	}
	else
	{
		trioFile<<"Failed\n";
		std::cout<<"Stack size < 2\n";
	}

}

void saveSymbol(StackOb sOb)
{
	auto res = symbols.find(sOb.val); 
	if(res == symbols.end())
	{
		symbols.insert(make_pair(sOb.val, sOb.type)); 
	}
	else 
	{
		cout<<"symbol already exist\n"; 
	}
}

void createSymbolsTable()
{
	for (auto it : symbols)
	{
		symbolsFile<<it.first<<" "<<it.second<<"\n";
	}	
}

void generateSource()
{
	sourceFile<<".data\n";
	for(auto it: symbols)
	{
		sourceFile<<"\t"<<it.first<<":\t.word\t0\n";
	}

	sourceFile<<".text\n";
	for(auto it : asmCode)
	{
		sourceFile<<it;
	}	
}

void stdoutGenerator(string asmOp, int syscall_id, string reg)
{
	string line;
	line = "#Printing value";
	asmCode.push_back(line);
	line = "li $v0, " + syscall_id + "\n";
	asmCode.push_back(line);
	line = asmOp + " " + reg + ", " + "\n";
	asmCode.push_back(line); 
	line = "syscall\n";
	asmCode.push_back(line); 
}
