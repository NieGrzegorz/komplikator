%{
#include <string.h>
#include <iostream>
#include <fstream>
#include <stack>
#include <vector>
#include <map> 

extern "C" int yylex(); 
extern "C" int yyerror(const char *msg,...);
extern FILE *yyout;

using namespace std; 
 
struct StackOb
{
	string type;
	string val;
	bool isArr = false;
};

//Globals
fstream trioFile;
fstream symbolsFile;
fstream sourceFile;
int tempCounter = 0;
int labelCounter = 0;
string conditionOp = ""; 
stack<StackOb> s;
stack<string> labelStack; 
map<string, string> symbols; 
vector<string> asmCode;    
vector<pair<string, int>> arrayList;

//Utility functions
void genTrio(char op, string asmOp); 
void genAsm(string asmOp, StackOb sOb1, StackOb sOb2, StackOb sOb3);
void saveSymbol(StackOb sOb);
void createSymbolsTable();
void stackVar(string val, string type, bool isArr = false);
void generateSource();
void stdoutGenerator(string asmOp, int syscall_id, string reg);
void stdinHandler(string symbol, int syscall_id);
void genCondition(string asmOp, bool is_loop);
void genElseStatement();
void genLabel();  
bool isSymbolDefined(string symbol);
void genUnconJump();
string createLabel(); 
string getAsmOpType(string argType);
void declArray(string name, int size); 
string translOp(string argType, string argOp); 
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
%token IF ELSE
%token WHILE
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
	|if_expr {}
	|while_expr {}
	|program block {cout<<"program with block\n";}
	|program if_expr {}
	|program while_expr {}
	;

while_expr
	:while_begin '{' block '}' {genUnconJump(); genLabel();}
	;

while_begin
	:WHILE '(' condition ')' {genCondition(conditionOp, true);}
	;

if_expr
	:if_begin '{' block '}' {genLabel();}
	|if_begin '{' block '}' else_expr {genLabel();}
	;

if_begin 
	:IF '(' condition ')'{genCondition(conditionOp, false);}
	;

else_expr
	:else_begin '{' block '}' {}
	;

else_begin
	:ELSE {genElseStatement();} 
	;

block	
	:assign {cout<<"block\n";}
	|block block{}
	|stdout {}
	|stdin {}
	|if_expr {}
	|while_expr {}
	|arr_decl {}
      	;

stdout	:STDOUT '(' LC ')' ';' {StackOb sOb; sOb.type = "INT"; sOb.val = to_string($3); s.push(sOb); stdoutGenerator("li", 1, "$a0");}
      	|STDOUT LR {}
	;

stdin	:STDIN '('ID')'';' {string value($3); stdinHandler(value, 5);}
      	|STDIN LR {}
	;

arr_expr
	:ID '[' wyr ']' {string value($1); stackVar(value, "ID", true);}
	;

arr_decl
	:INT ID '[' LC ']' ';' {declArray($2, $4);}  
	;

assign 	
	:ID '=' wyr ';'{cout<<"B1: "<<$1<<"\n"; stackVar($1, "ID");genTrio('=', "assign");}
	;

condition
	:wyr EQ wyr {conditionOp = "bne";}
	|wyr NEQ wyr {conditionOp = "beq";}
	|wyr GT wyr {conditionOp = "ble";}
	|wyr LT wyr {conditionOp = "bge";}
	|wyr GEQ wyr {conditionOp = "blt";}
	|wyr LEQ wyr {conditionOp = "bgt";}
	;

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
	:ID {string value($1); stackVar(value, "ID"); }
	|LC {stackVar(to_string($1), "INT");}
	|arr_expr {}
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

void stackVar(string val, string type, bool isArr)
{
	StackOb sOb; 
	sOb.type = type; 
	sOb.val = val;
	sOb.isArr = isArr; 
	s.push(sOb);
	if(("ID" == type) && !isArr)
	{
		saveSymbol(sOb);
	}
}

void genAsm(string op, StackOb sOb1, StackOb sOb2, StackOb sOb3)
{	
	string line;
	line = "#Operation "+op+" for arguments: "+sOb1.val+" "+sOb2.val+"\n";
	asmCode.push_back(line);
	if(op != "assign")
	{
		string loadOp =  getAsmOpType(sOb1.type);
		line = loadOp +" $t0, "+ sOb1.val + "\n";
		asmCode.push_back(line);
	

		loadOp =  getAsmOpType(sOb2.type);
		line = loadOp +" $t1, "+ sOb2.val + "\n";
		asmCode.push_back(line);

		line =op+" $t0, $t0, $t1\n";
		asmCode.push_back(line);
		line ="sw $t0, "+ sOb3.val + "\n";
		asmCode.push_back(line);
	}
	else
	{
		string loadOp =  getAsmOpType(sOb1.type);
		line = loadOp +" $t0, "+ sOb1.val + "\n";
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

	for(auto it : arrayList)
	{
		sourceFile<<"\t"<<it.first<<":\t.word\t0:"<<it.second<<"\n";
	}

	sourceFile<<".text\n";
	for(auto it : asmCode)
	{
		sourceFile<<it;
	}	
}

void stdoutGenerator(string asmOp, int syscall_id, string reg)
{
	StackOb param = s.top(); 
	s.pop();
	string line;
	line = "#Printing value\n";
	asmCode.push_back(line);
	line = "li $v0, " + to_string(syscall_id) + " \n";
	asmCode.push_back(line);
	line = asmOp + " " + reg + ", " + param.val  + " \n";
	asmCode.push_back(line); 
	line = "syscall\n";
	asmCode.push_back(line); 
}

string createLabel()
{
	string label = "LBL"; 
	label.append(to_string(labelCounter)); 
	labelCounter++;
	return label; 
}

void genCondition(string asmOp, bool is_loop)
{
	string line;
	string loop_label; 
	if(is_loop)
	{
		loop_label = createLabel(); 
		line = loop_label +":\n";
		asmCode.push_back(line);
	}

	string out_label = createLabel(); 
	labelStack.push(out_label); 
	StackOb rhs = s.top(); 
	s.pop();
	StackOb lhs = s.top();
	s.pop();
	
	string op = getAsmOpType(lhs.type);
	line = op + " $t2, "+lhs.val + " \n";
	asmCode.push_back(line);  
	op = getAsmOpType(rhs.type);
	line = op + " $t3, "+rhs.val + " \n";
	asmCode.push_back(line);  

	line = asmOp + " $t2, $t3, " + out_label + " \n";
	asmCode.push_back(line);
	
	if(is_loop)
	{
		labelStack.push(loop_label);
	}

}

void genLabel()
{
	string line; 
	line = labelStack.top(); 
	labelStack.pop();
	line.append(":\n"); 
	asmCode.push_back(line); 
}

void genElseStatement()
{
	string label = "LBL"; 
	label.append(to_string(labelCounter));
	labelCounter++; 
	
	string line = "b " + label + " \n";
	asmCode.push_back(line); 
	genLabel(); 
	labelStack.push(label);
}

void stdinHandler(string symbol, int syscall_id)
{
	if(isSymbolDefined(symbol))
	{
		string line; 
		line = "li $v0, " + to_string(syscall_id) + " \n"; 
		asmCode.push_back(line);
		line = "syscall\n"; 
		asmCode.push_back(line); 
		line = "sw $v0, " + symbol + "\n";
		asmCode.push_back(line);  
	}
	else
	{
		cout<<"Undefined symbol " + symbol + "\n";
	}
	
}

bool isSymbolDefined(string symbol)
{
	bool retVal = false;
	auto res = symbols.find(symbol); 
	if(res != symbols.end()) retVal = true;
	return retVal;
}

void genUnconJump()
{
	string line = " b "+ labelStack.top() + "\n";
	labelStack.pop();
	asmCode.push_back(line); 
} 

string getAsmOpType(string argType)
{
	string retVal; 

	if("ID" == argType) retVal = "lw"; 
	else if("INT" == argType) retVal = "li";
	else if("DOUBLE" == argType) retVal ="l.s"; 

	return retVal; 
} 

void declArray(string name, int size)
{
	arrayList.push_back(make_pair(name, size));
}  

string translOp(string argType, string argOp)
{
	string retVal = argOp;
	if("DOUBLE" == argType) retVal.append(".s");
	return retVal;
} 
