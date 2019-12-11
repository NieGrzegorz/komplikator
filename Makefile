CPP=g++
CC=gcc
LEX=flex
YACC=bison

all:	komplikator

komplikator:	def.tab.o lex.yy.o
		$(CPP) -std=c++11 lex.yy.o def.tab.o -o komplikator -lfl

lex.yy.o:	lex.yy.c
		$(CC) -c lex.yy.c

lex.yy.c:	z1.l
		$(LEX) -d z1.l

def.tab.o:	def.tab.cc
		$(CPP) -std=c++11 -c def.tab.cc

def.tab.cc:	def.yy
		$(YACC) -d def.yy

clean:
		rm *.o komplikator
