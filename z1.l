%{
#include <stdlib.h>
#include <string.h>
#include "def.tab.hh"
#define INFILE_ERROR 1
#define OUTFILE_ERROR 2
extern int yylineno;
int yyerror(const char *msg, ...);
%}
%%
\+		{ fprintf(yyout,"+\n");return '+';}
\-		{return '-';}
\*		{fprintf(yyout,"*\n");return '*';}
\/		{return '/';}
\;		{return ';';}
\%		{return '%';}
\=		{fprintf(yyout,"=\n");return '=';}
\(		{fprintf(yyout,""); return '(';}
\)		{fprintf(yyout,")\n"); return ')';}
\=\=		{fprintf(yyout, "==\n"); return EQ;}
\<		{fprintf(yyout, "<\n"); return LT;}
\>		{fprintf(yyout, ">\n"); return GT;}
\<\=		{fprintf(yyout, "<=\n"); return LEQ;}
\>\=		{fprintf(yyout, ">=\n"); return GEQ;}
"int"		{fprintf(yyout, "int\n"); return INT;}
"double" 	{fprintf(yyout,"double\n"); return DOUBLE;}
"bool"		{fprintf(yyout,"bool\n"); return BOOL;}
"string"	{fprintf(yyout,"STRING\n"); return STRING;}
"char" 		{fprintf(yyout,"CHAR\n");return CHAR;}
"print"		{return STDOUT;}
"read"		{return STDIN;}
\-\>		{fprintf(yyout,"RET\n"); return RET;}
"fn"		{fprintf(yyout, "FN\n"); return FN;}
([1-9][0-9]*|0)[.][0-9]*	{yylval.dval = atof(yytext);  return LR;}
[1-9][0-9]*|0			{yylval.ival = atoi(yytext);  return LC;}
[a-z]*				{fprintf(yyout,"I %s\n ", yytext);yylval.text = strdup(yytext); return ID;}
%%
int yyerror(const char *msg,...)
{
	printf("%d: %s\n",yylineno, msg);
	exit(1);
}







