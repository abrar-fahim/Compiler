%option noyywrap

%x SINGLE_QUOTE
%x STRING
%x COMMENT
%x MULTILINE_COMMENT

%{
#include "SymbolInfo.cpp"
#include <cstdlib>
#include <string>
#include<cstdio>
//#define YYSTYPE SymbolInfo*
#include "y.tab.h"


//y.tab.h is generated when compiling yacc file, this is needed so that flex and bison can agree on token names

extern YYSTYPE yylval;

using namespace std;

extern FILE *scannerLog;
extern FILE *scannerToken;

int lineNo = 1;
int errorNo = 0;

string inputString;

//SymbolTable st(10);

//yylval is a global variable
%}



%%

"if"	{
    return IF;

    }
"for"	{
    return FOR;
		}

"int"	{
    return INT;
		}

"float"  {
    return FLOAT;
    }

"void"	{
    return VOID;
    }


"else"	{
    return ELSE;
    }

"while"	{
    return WHILE;
}

"char"	{
    return CHAR;
}

"return" {
    return RETURN;
}

"println" {
    return PRINTLN;
}

[0-9]+	{
    yylval.symbolInfo = new SymbolInfo(yytext,"CONST_INT", "INT");
    return CONST_INT;
    }

[0-9]*\.[0-9]*\.[\.0-9]* {
    fprintf(scannerLog, "Error at line %d: Too many decimal points in %s.\n", lineNo, yytext);
    errorNo++;
}

[0-9]*[\.]?[0-9]+[Ee][0-9]*[\.][\.0-9]* {
    
    fprintf(scannerLog, "Error at line %d: Ill formed number %s.\n", lineNo, yytext);
    errorNo++;
}

[0-9]*[\.]?[0-9]+([Ee]?[0-9]+)?[a-zA-Z_]+[a-zA-Z0-9_] {
    
    fprintf(scannerLog, "Error at line %d: Invalid Suffix on numeric constant or invalid prefix on identifier %s.\n", lineNo, yytext);
    errorNo++;
}

[0-9]*[\.]?[0-9]+([Ee]?[0-9]+)? {
    yylval.symbolInfo = new SymbolInfo(yytext,"CONST_FLOAT", "FLOAT");
    //yylval.floatVal = atof(yytext);
    return CONST_FLOAT;
    
	}

[\'][\'] {
    fprintf(scannerLog, "Error at line %d: Empty Character Constant error ''.\n", lineNo);
    errorNo++;

        }

<SINGLE_QUOTE>\\[n] {
    
    return CONST_CHAR;
    //st.insert("\n", "CONST_CHAR");
    fprintf(scannerToken, "<CONST_CHAR, \n> ");
    fprintf(scannerLog, "Line No. %d: Token <CONST_CHAR> Lexeme \'\\n\' found\n", lineNo);
    
    //st.printAllScopeTables(scannerLog);
    
    
}

<SINGLE_QUOTE>\\[t] {
    return CONST_CHAR;

    fprintf(scannerToken, "<CONST_CHAR, \t> ");
    fprintf(scannerLog, "Line No. %d: Token <CONST_CHAR> Lexeme \'\\t\' found\n", lineNo);
    
    //st.printAllScopeTables(scannerLog);
    
    
}

<SINGLE_QUOTE>\\[\\] {
    return CONST_CHAR;
    //st.insert("\\", "CONST_CHAR");
    fprintf(scannerToken, "<CONST_CHAR, \\> ");
    fprintf(scannerLog, "Line No. %d: Token <CONST_CHAR> Lexeme \'\\\\' found\n", lineNo);
    
   // st.printAllScopeTables(scannerLog);
}



<SINGLE_QUOTE>\\[\'] {
    return CONST_CHAR;
    //st.insert("\'", "CONST_CHAR");
    fprintf(scannerToken, "<CONST_CHAR, \'> ");
    fprintf(scannerLog, "Line No. %d: Token <CONST_CHAR> Lexeme \'\\'\' found\n", lineNo);

    //st.printAllScopeTables(scannerLog);


}

<SINGLE_QUOTE>\\[a] {
    return CONST_CHAR;
   // st.insert("\a", "CONST_CHAR");
    fprintf(scannerToken, "<CONST_CHAR, \a> ");
    fprintf(scannerLog, "Line No. %d: Token <CONST_CHAR> Lexeme \'\\a\' found\n", lineNo);
    
   // st.printAllScopeTables(scannerLog);
    
    
}

<SINGLE_QUOTE>\\[f] {
    return CONST_CHAR;
    //st.insert("\f", "CONST_CHAR");
    fprintf(scannerToken, "<CONST_CHAR, \f> ");
    fprintf(scannerLog, "Line No. %d: Token <CONST_CHAR> Lexeme \'\\f\' found\n", lineNo);
    
    //st.printAllScopeTables(scannerLog);
    
    
}

<SINGLE_QUOTE>\\[r] {
    return CONST_CHAR;
    //st.insert("\r", "CONST_CHAR");
    fprintf(scannerToken, "<CONST_CHAR, \r> ");
    fprintf(scannerLog, "Line No. %d: Token <CONST_CHAR> Lexeme \'\\r\' found\n", lineNo);
    //st.printAllScopeTables(scannerLog);
    
    
}

<SINGLE_QUOTE>\\[b] {
    return CONST_CHAR;
    //st.insert("\b", "CONST_CHAR");
    fprintf(scannerToken, "<CONST_CHAR, \b> ");
    fprintf(scannerLog, "Line No. %d: Token <CONST_CHAR> Lexeme \'\\b\' found\n", lineNo);
   // st.printAllScopeTables(scannerLog);
    
    
}

<SINGLE_QUOTE>\\[v] {
    return CONST_CHAR;
   // st.insert("\v", "CONST_CHAR");
    fprintf(scannerToken, "<CONST_CHAR, \v> ");
    fprintf(scannerLog, "Line No. %d: Token <CONST_CHAR> Lexeme \'\\t\' found\n", lineNo);
    
    //st.printAllScopeTables(scannerLog);
    
}

<SINGLE_QUOTE>\\[0] {
    return CONST_CHAR;
    //st.insert("\0", "CONST_CHAR");
    fprintf(scannerToken, "<CONST_CHAR, \0> ");
    fprintf(scannerLog, "Line No. %d: Token <CONST_CHAR> Lexeme \'\\0\' found\n", lineNo);
   // st.printAllScopeTables(scannerLog);
    
}



<SINGLE_QUOTE>\' {
    BEGIN INITIAL;
}



<SINGLE_QUOTE>[^\\\n].+[\'] {
    //first character is not escape or newline
    fprintf(scannerLog, "Error at line %d: Multi Character constant error in %s.\n", lineNo, yytext);
    errorNo++;
    BEGIN INITIAL;
}

<SINGLE_QUOTE>[\\][^ntb\\\'afrbv0].*[\'] {
    //first character is escape but second char is not valid escape letter

    fprintf(scannerLog, "Error at line %d: Multi Character constant error in %s.\n", lineNo, yytext);
    errorNo++;
    BEGIN INITIAL;
}
<SINGLE_QUOTE>[a-zA-Z0-9] {
    return CONST_CHAR;
    //st.insert(yytext, "CONST_CHAR");
    fprintf(scannerToken, "<CONST_CHAR, %s> ", yytext);
    
    fprintf(scannerLog, "Line No. %d: Token <CONST_CHAR> Lexeme %s found\n", lineNo, yytext);
    
    
}

<SINGLE_QUOTE>[^\'\n\r]*[\r]?[\n] {
    //no escape characters and no end quotes seen before newline
    fprintf(scannerLog, "Error at line %d: Unterminated Character %s.\n", lineNo, yytext);
    errorNo++;
    lineNo++;
    //yylval.lineNo = lineNo;
    BEGIN INITIAL;
}

<SINGLE_QUOTE>[\\][\'][\r]?[\n] {
    //scanned lexeme is '\'
    fprintf(scannerLog, "Error at line %d: Unterminated Character %s.\n", lineNo, yytext);
    errorNo++;
    lineNo++;
    //yylval.lineNo = lineNo;
    BEGIN INITIAL;
}

<SINGLE_QUOTE>. {
    fprintf(scannerLog, "Error at line %d: WEIRD Character %s.\n", lineNo, yytext);
}


[+-] {
    yylval.symbolInfo = new SymbolInfo(yytext,"ADDOP");
    //yylval.lexeme = yytext;
    return ADDOP;
	
		}

[\*/%] {
    yylval.symbolInfo = new SymbolInfo(yytext,"MULOP");
    return MULOP;
		
		}

"++"  | 
"--" {
    yylval.symbolInfo = new SymbolInfo(yytext,"INCOP");
    return INCOP;
		
		}


"=" {
    yylval.symbolInfo = new SymbolInfo(yytext,"ASSIGNOP");
    //yylval.lexeme = yytext;
    return ASSIGNOP;
		
		}

"<"   |
"<="  |
">="  |
>     |
"=="  |
"!=" {
   yylval.symbolInfo = new SymbolInfo(yytext,"RELOP");
    //yylval.lexeme = yytext;
    return RELOP;
		
		}


"&&"  |
"||" {
    yylval.symbolInfo = new SymbolInfo(yytext,"LOGICOP");
    //yylval.lexeme = yytext;
    return LOGICOP;
		
		}

&    |
\|   |
\^    |
"<<" |
">>" {
    yylval.symbolInfo = new SymbolInfo(yytext,"BITOP");
    //yylval.lexeme = yytext;
    return BITOP;
		
		}

'!' {
    //yylval.lexeme = yytext;
    return NOT;
		
		}

[(] {
    return LPAREN;
		
		}

[)] {
    return RPAREN;
		
		}

[{] {
    return LCURL;
		
		}

[}] {
    return RCURL;
		
		}
[\[] {
    return LTHIRD;
    }

[\]] {
    return RTHIRD;
		
		}
[,] {
    return COMMA;

		}
[;] {
    return SEMICOLON;

    }

[a-zA-Z_][a-zA-Z0-9_]* {
    
    SymbolInfo* symbolInfo = new SymbolInfo(yytext, "ID");
    
    yylval.symbolInfo = symbolInfo;
    return ID;

}


<STRING>\" {
return STRING;
fprintf(scannerToken, "<STRING, %s> ", inputString.c_str());
fprintf(scannerLog, "Line No. %d: Token <STRING> Lexeme %s found.\n", lineNo, inputString.c_str());
inputString.clear();
BEGIN INITIAL;

}

<STRING>[\n] {
    fprintf(scannerLog, "Error at line %d: Unfinished String %s.\n", lineNo, inputString.c_str());
    lineNo++;
    //yylval.lineNo = lineNo;
    errorNo++;
    inputString.clear();
    BEGIN INITIAL;;
}

<STRING>[\\][\r]?[\n] {
    //inputString.push_back('\\');
    //inputString.push_back('\n');
    lineNo++;
    //yylval.lineNo = lineNo;
    
}



<STRING>[\\][t] {
    inputString.push_back('\t');
}

<STRING>[\\][r] {
    inputString.push_back('\r');
    
}

<STRING>. {
    
    inputString.append(yytext);
    
}
"//" {
		BEGIN COMMENT;
    
		}

<COMMENT>\\[\n] {
    inputString.push_back('\\');
    inputString.push_back('\n');
		BEGIN MULTILINE_COMMENT;
}

<COMMENT>"\n" {
    fprintf(scannerLog, "Line No. %d: Token <COMMENT> Lexeme %s found\n", lineNo, inputString.c_str());
    
    inputString.clear();

		BEGIN INITIAL;
		}

<COMMENT>. {
    inputString.append(yytext);
		//fprintf(scannerLog, "%s", yytext);
		}
"/*" {
		BEGIN MULTILINE_COMMENT;
		}
  
<MULTILINE_COMMENT><<EOF>> {
    
    fprintf(scannerLog, "Error at line %d: unfinished comment %s.\n", lineNo, inputString.c_str());
    errorNo++;
    fprintf(scannerLog, "Total Lines: %d\n", lineNo);
    fprintf(scannerLog, "Total Errors: %d\n", errorNo);
    return 0;
}

<MULTILINE_COMMENT>"*/" {
    fprintf(scannerLog, "Line No. %d: Token <COMMENT> Lexeme %s found\n", lineNo, inputString.c_str());
    
    inputString.clear();
		BEGIN INITIAL;
		}

<MULTILINE_COMMENT>[\n] {
    inputString.append(yytext);
    lineNo++;
    //yylval.lineNo = lineNo;
        }

<MULTILINE_COMMENT>. {
    
    inputString.append(yytext);

		//fprintf(scannerLog, "%s", yytext);
		
		}

[ \t]+ {}



"\n"        {
    lineNo++;
}


<<EOF>>  {
    fprintf(scannerLog, "\n");
    
    //st.printAllScopeTables(scannerLog);
    fprintf(scannerLog, "\n");
    
    fprintf(scannerLog, "Total Lines: %d\n", lineNo);
    fprintf(scannerLog, "Total Errors: %d\n", errorNo);
    
    return 0;
        }
  
. {
    
    fprintf(scannerLog, "Error at line %d: Unrecognized character %s.\n", lineNo, yytext);
    
    errorNo++;
    
        }


%%


