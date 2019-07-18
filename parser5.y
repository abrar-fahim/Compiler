%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include "symbolTable.cpp"
//#define YYSTYPE SymbolInfo*

#define MAX_CHARS 50000

using namespace std;

extern FILE *yyin;

extern int lineNo;

FILE *inputFile;

FILE* scannerLog;
FILE* scannerToken;

FILE* parserLog;
FILE *parserOut;

string typeSpecified;



SymbolTable table(100);
int yylex(void);


void yyerror(char *s)
{
    printf("ERROR AT LINE %d: %s\n", lineNo, s);
}



%}



%union {
    SymbolInfo* symbolInfo;
    char* text;
    
}

%token IF FOR INT ELSE FLOAT VOID WHILE CHAR DOUBLE RETURN PRINTLN <symbolInfo>CONST_INT <symbolInfo>CONST_FLOAT <symbolInfo>CONST_CHAR <symbolInfo>ADDOP <symbolInfo>MULOP <symbolInfo>INCOP ASSIGNOP <symbolInfo>RELOP <symbolInfo>LOGICOP <symbolInfo>BITOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON <symbolInfo>ID

%type<text>begin program unit var_declaration func_declaration func_definition type_specifier compound_statement statements declaration_list expression_statement statement arguments argument_list


%type<symbolInfo> logic_expression rel_expression simple_expression term unary_expression factor variable expression parameter_list


%left RELOP LOGICOP BITOP
%left ADDOP
%left MULOP
%nonassoc UNARY_OP
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE


%%
begin: program
    {
        $$ = new char[MAX_CHARS];
        strcpy($$, $1);
        
        fprintf(parserLog, "At Line no: %d: begin: program\n\n", lineNo);
        fprintf(parserLog,"%s\n\n", $1);
        
        table.printAllScopeTables(parserLog);
    }
    ;

program: program unit
    {
        
            string str = $1;
            str.append(" ");
            str.append($2);
            $$ = new char[MAX_CHARS];
            strcpy($$,$1);
            
            fprintf(parserLog, "At Line no: %d: program: program unit\n\n", lineNo);
            fprintf(parserLog,"%s %s\n\n", $1, $2);
    }
    | unit
    {
        
        $$ = new char[MAX_CHARS];
        strcpy($$,$1);
        
        fprintf(parserLog, "At Line no: %d: program: unit\n\n", lineNo);
        fprintf(parserLog,"%s\n\n", $1);
    }
	;
	
unit : var_declaration
    {
        fprintf(parserLog, "At Line no: %d: unit : var_declaration\n\n", lineNo);
        fprintf(parserLog, "%s;\n\n", $1);
        
        $$ = new char[1000];
        strcpy($$, $1);
    }
     | func_declaration
    {
    
        fprintf(parserLog, "At Line no: %d: unit : func_declaration\n\n", lineNo);
         fprintf(parserLog, "%s;\n\n", $1);
         $$ = new char[1000];
         strcpy($$, $1);
    }
     | func_definition
    {
        fprintf(parserLog, "At Line no: %d: unit : func_definition\n\n", lineNo);
        fprintf(parserLog, "%s;\n\n", $1);
        $$ = new char[MAX_CHARS];
        strcpy($$, $1);
    }
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
    {
            string str = $1;
            str.append(" ");
            str.append($2 -> getName());
            str.append("(");
            str.append(" ");
            str.append($4);
            str.append(" ");
            str.append(")");
            str.append(";");
            $$ = new char[1000];

            strcpy($$,str.c_str());
            
            fprintf(parserLog, "At Line no: %d: func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n", lineNo);
            
            //fprintf(parserLog, "%s %s(%s);\n\n", $1, $2 -> getName().c_str(), $4);
            fprintf(parserLog, "%s\n\n", str.c_str());

            if(!table.lookUpInCurrentScope($2 -> getName())) {
                table.insert($2);
        }
        else {
            printf("symbol already in table\n");
        }
    }
    | type_specifier ID LPAREN RPAREN SEMICOLON
    {
        

        string str = $1;
        str.append(" ");
        str.append($2 -> getName());    //id
        str.append("(");
        str.append(")");
        str.append(";");
        
        $$ = new char[1000];

        strcpy($$,str.c_str());
        
        fprintf(parserLog, "At Line no: %d: func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n", lineNo);
        
        //fprintf(parserLog, "%s %s();\n\n", $1, $2 -> getName().c_str());
        fprintf(parserLog, "%s\n\n", str.c_str());


        if(!table.lookUpInCurrentScope($2 -> getName())) {
            table.insert($2);
        }
        else {
            printf("symbol already in table\n");
        }
    }
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement
    {
         string str = $1;
         str.append(" ");
         str.append($2 -> getName());    //id
         str.append("(");
         str.append($4);
         str.append(")");
         str.append($6);
         
         $$ = new char[MAX_CHARS];

         strcpy($$,str.c_str());
         
         fprintf(parserLog, "At Line no: %d: func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n", lineNo);
         //fprintf(parserLog, "%s %s(%s) $s;\n\n", $1, $2, $4, $6);
         fprintf(parserLog, "%s\n\n", str.c_str());
         
         
        if(!table.lookUpInCurrentScope($2 -> getName())) {
            $2 -> setIsFunction(true);
            
            table.insert($2);
        }
        else {
            fprintf(parserLog, "symbol already in table\n");
        }
    }

    | type_specifier ID LPAREN RPAREN compound_statement
    {
         string str = $1;
         str.append(" ");
         str.append($2 -> getName());    //id
         str.append("(");
         str.append(")");
         
         str.append($5);
         
         $$ = new char[MAX_CHARS];
         
         strcpy($$,str.c_str());
         
         fprintf(parserLog, "At Line no: %d: func_definition : type_specifier ID LPAREN RPAREN compound_statement\n\n", lineNo);
         //fprintf(parserLog, "%s %s() %s;\n\n", $1, $2 -> getName().c_str(), $5);
         
         fprintf(parserLog, "%s\n\n", str.c_str());
         


        if(!table.lookUpInCurrentScope($2 -> getName())) {
            table.insert($2);
        }
        else {
            printf("symbol already in table\n");
        }
    }
 		;				


parameter_list  : parameter_list COMMA type_specifier ID
    {
        
        //here, typeSpecified global variable stores type_specifier contents
       

        string str = $1;
        str.append(", ");
        str.append($3);
        str.append(" ");
        str.append($4 -> getName());
        
        $$ = new SymbolInfo(str, "PARAMETER_LIST");

        
        $$ -> addParameter(typeSpecified);
        
        
        fprintf(parserLog, "At Line no: %d: parameter_list  : parameter_list COMMA type_specifier ID\n\n",lineNo);
        fprintf(parserLog, "%s\n\n", str.c_str());


    }
		| parameter_list COMMA type_specifier
    {
        
        string str = $1;
        str.append(", ");
        str.append($3);
        
        $$ = new SymbolInfo(str, "PARAMETER_LIST");
        
        $$ -> addParameter(typeSpecified);


        fprintf(parserLog, "At Line no: %d: parameter_list  : parameter_list COMMA type_specifier\n\n", lineNo);
        //fprintf(parserLog, "%s, $s;\n\n", $1, $3);
        fprintf(parserLog, "%s\n\n", str.c_str());
    }
 		| type_specifier ID
    {
        
        string str = $1;
        str.append(" ");
        str.append($2 -> getName());
        
        $$ = new SymbolInfo(str, "PARAMETER_LIST");
        $$ -> addParameter(typeSpecified);

        fprintf(parserLog, "At Line no: %d: parameter_list  : type_specifier ID\n\n", lineNo);
        fprintf(parserLog, "%s %s;\n\n", $1, $2);
    }
		| type_specifier
    {
        
        string str = $1;
        $$ = new char[10];
        
        strcpy($$,str.c_str());

        fprintf(parserLog, "At Line no: %d: parameter_list  : type_specifier\n\n", lineNo);
        //fprintf(parserLog, "%s;\n\n", $1);
        fprintf(parserLog, "%s\n\n", str.c_str());
    }
 		;

 		
compound_statement : LCURL {table.enterScope();} statements RCURL {table.printAllScopeTables(parserLog); table.exitScope();}
{
    

    string str = "{ ";
    str.append($3);
    str.append(" }");
    
    $$ = new char[MAX_CHARS];
    
    strcpy($$,str.c_str());

    fprintf(parserLog, "At Line no: %d: compound_statement : LCURL statements RCURL\n\n", lineNo);
    //fprintf(parserLog, "{ %s }\n\n", $3);
    fprintf(parserLog, "%s\n\n", str.c_str());
}
 		    | LCURL RCURL
{
    
    string str = "{ }";
    $$ = new char[5];
    strcpy($$,str.c_str());

    fprintf(parserLog, "At Line no: %d: compound_statement : LCURL RCURL\n\n", lineNo);
    //fprintf(parserLog, "{}\n\n");
    fprintf(parserLog, "%s\n\n", str.c_str());
}
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
{

    string str = $1;
    str.append(" ");
    str.append($2);
    str.append(";");

    $$ = new char[1000];

    strcpy($$,str.c_str());

    fprintf(parserLog, "At Line no: %d: var_declaration : type_specifier declaration_list SEMICOLON\n\n", lineNo);
    //fprintf(parserLog, "%s %s;\n\n", $1, $3);
    fprintf(parserLog, "%s\n\n", str.c_str());
    typeSpecified = "none";
}

          ;

type_specifier	: INT
{
    
    string str = "int";
    typeSpecified = "INT";
    
    $$ = new char[10];
    
    strcpy($$, str.c_str());
    
    fprintf(parserLog, "At Line no: %d: type_specifier : INT\n\n", lineNo);
    //fprintf(parserLog, "int \n\n");
    fprintf(parserLog, "%s\n\n", str.c_str());

}
        | FLOAT
{
    
    string str = "float";
    typeSpecified = "FLOAT";
    $$ = new char[10];
    
    strcpy($$, str.c_str());

    fprintf(parserLog, "At Line no: %d: type_specifier : FLOAT\n\n", lineNo);
   //fprintf(parserLog, "float \n\n");
   fprintf(parserLog, "%s\n\n", str.c_str());
}
 		| VOID
{
    
    string str = "void";
    typeSpecified = "VOID";
    $$ = new char[10];
    
    strcpy($$, str.c_str());

    fprintf(parserLog, "At Line no: %d: type_specifier : VOID\n\n", lineNo);
    //fprintf(parserLog, "void \n\n");
    fprintf(parserLog, "%s\n\n", str.c_str());
}
 		;
 		
declaration_list : declaration_list COMMA ID
    {
        
        string str = $1;
        str.append(", ");
        str.append($3 -> getName());

        $$ = new char[1000];
        strcpy($$,str.c_str());

        fprintf(parserLog, "At Line no: %d: declaration_list : declaration_list COMMA ID\n\n", lineNo);
        //fprintf(parserLog, "%s,%s\n\n", $1, $3 -> getName().c_str());
        fprintf(parserLog, "%s\n\n", str.c_str());
        if(!table.lookUpInCurrentScope($3 -> getName())) {
            $3 -> setDataType(typeSpecified);
            $3 -> setIsArray(false);
            table.insert($3);
        }
        else {
            fprintf(parserLog, "ERROR at line no: %d:Variable already declared in scope!\n", lineNo);
        }
    }

    | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
    {
        
        string str = $1;
        str.append(", ");
        str.append($3 -> getName());
        str.append("[");
        str.append($4 -> getName());
        str.append("]");


        $$ = new char[1000];
        strcpy($$,str.c_str());

        fprintf(parserLog, "At Line no: %d: declaration_list : COMMA ID LTHIRD CONST_INT RTHIRD\n\n",lineNo);
       // fprintf(parserLog, "%s, %s[%s] \n\n", $1, $3 -> getName().c_str(), $5);
       fprintf(parserLog, "%s\n\n", str.c_str());
        
        if(!table.lookUpInCurrentScope($3 -> getName())) {
            $3 -> setDataType(typeSpecified);
            $3 -> setSize(atoi($4 -> getName().c_str())); //sets array size
            $3 -> setIsArray(true);
            table.insert($3);
        }
        else {
            fprintf(parserLog, "ERROR at line no: %d:Variable already declared in scope!\n", lineNo);
        }
    }

    | ID
    {
        
        string str = $1 -> getName();
        
        $$ = new char[100];

        strcpy($$,str.c_str());

        fprintf(parserLog, "At Line no: %d: declaration_list : ID\n\n",lineNo);
        fprintf(parserLog, "%s \n\n", $1 -> getName().c_str());
        if(!table.lookUpInCurrentScope($1 -> getName())) {
            $1-> setDataType(typeSpecified);
            $1 -> setIsArray(false);
            table.insert($1);
        }
        else {
            fprintf(parserLog, "ERROR at line no: %d: Variable already declared in scope!\n", lineNo);
        }

    }

    | ID LTHIRD CONST_INT RTHIRD
    {
        
        string str = $1 -> getName();
        str.append("[");
        str.append($3 -> getName());
        str.append("]");

        $$ = new char[100];
        strcpy($$,str.c_str());

        fprintf(parserLog, "At Line no: %d: declaration_list : ID LTHIRD CONST_INT RTHIRD\n\n", lineNo);
        
        fprintf(parserLog, "%s\n\n", str.c_str());
        if(!table.lookUpInCurrentScope($1 -> getName())) {
            $1 -> setDataType(typeSpecified);
            $1 -> setSize(atoi($3 -> getName().c_str())); //sets array size
            $1 -> setIsArray(true);
            table.insert($1);
        }
        else {
            fprintf(parserLog, "ERROR at line no: %d:Variable already declared in scope!\n", lineNo);
        }
    }
 		  ;
 		  
statements : statement
{
    
    string str = $1;
    
    $$ = new char[MAX_CHARS];
    strcpy($$,str.c_str());

    fprintf(parserLog, "At Line no: %d: statements : statement\n\n", lineNo);
    fprintf(parserLog, "%s \n\n", $1);
}
	   | statements statement
{
    
    string str = $1;
    str.append(" ");
    str.append($2);

    $$ = new char[MAX_CHARS];
    strcpy($$,str.c_str());

    fprintf(parserLog, "At Line no: %d: statements : statements statement\n\n", lineNo);
    //fprintf(parserLog, "%s %s\n\n", $1, $2);
    fprintf(parserLog, "%s\n\n", str.c_str());
}
	   ;
	   
statement : var_declaration
{
    
    string str = $1;
    $$ = new char[1000];
    strcpy($$,str.c_str());


    fprintf(parserLog, "At Line no: %d: statement : var_declaration\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", $1);
}
	  | expression_statement
{
    string str = $1;
    $$ = new char[1000];
    strcpy($$,str.c_str());


    fprintf(parserLog, "At Line no: %d: statement: expression_statement\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", $1);
}
	  | compound_statement
{
    string str = $1;
    $$ = new char[MAX_CHARS];
    strcpy($$,str.c_str());


    fprintf(parserLog, "At Line no: %d: statement : compound_statement\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", $1);
}
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
{
    string str = "for(";
    str.append($3);
    str.append(" ");
    str.append($4);
    str.append(" ");
    str.append($5 -> getName());
    str.append(")");
    str.append($7);
    $$ = new char[MAX_CHARS];

    strcpy($$,str.c_str());


    fprintf(parserLog, "At Line no: %d: statement: FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
    
    
}
      | IF LPAREN expression RPAREN statement   %prec LOWER_THAN_ELSE
{
    string str = "if(";

    str.append($3 -> getName());
    str.append(")");
    str.append($5);
    
    $$ = new char[MAX_CHARS];

    strcpy($$,str.c_str());

    fprintf(parserLog, "At Line no: %d: statement : IF LPAREN expression RPAREN statement\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
    
    if($3 -> getDataType() == "VOID") {
        fprintf(parserLog, "ERROR At Line no: %d: expression evaluates to VOID!!\n\n", lineNo);
        
    }
}
      | IF LPAREN expression RPAREN statement ELSE statement
{
    string str = "if(";
    str.append($3 -> getName());
    str.append(") ");
    str.append($5);
    str.append(" else ");
    str.append($7);
    
    $$ = new char[MAX_CHARS];

    strcpy($$,str.c_str());


    fprintf(parserLog, "At Line no: %d: statement :IF LPAREN expression RPAREN statement ELSE statement\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
    
    if($3 -> getDataType() == "VOID") {
        fprintf(parserLog, "ERROR At Line no: %d: expression evaluates to VOID!!\n\n", lineNo);
        
    }
}
	  | WHILE LPAREN expression RPAREN statement
{
    string str = "while(";
    str.append($3 -> getName());
    str.append(") ");
    str.append($5);
    
    $$ = new char[MAX_CHARS];

    strcpy($$,str.c_str());


    fprintf(parserLog, "At Line no: %d: statement : WHILE LPAREN expression RPAREN statement\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
    
    if($3 -> getDataType() == "VOID") {
        fprintf(parserLog, "ERROR At Line no: %d: expression evaluates to VOID!!\n\n", lineNo);
        
    }
}
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
{
    string str = "println(";
    str.append($3 -> getName());
    str.append(");");
    
    $$ = new char[1000];

    strcpy($$,str.c_str());


    fprintf(parserLog, "At Line no: %d: statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n", lineNo);
    //fprintf(parserLog, "println(%s);\n\n", $3 -> getName().c_str());
    fprintf(parserLog, "%s\n\n", str.c_str());
}
	  | RETURN expression SEMICOLON
{
    string str = "return ";
    str.append($2 -> getName());
    str.append(";");
    
    $$ = new char[1000];

    strcpy($$,str.c_str());


    fprintf(parserLog, "At Line no: %d: statement : RETURN expression SEMICOLON\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
    
    if($2 -> getDataType() == "VOID") {
        fprintf(parserLog, "ERROR At Line no: %d: expression evaluates to VOID!!\n\n", lineNo);
        
    }
}
	  ;
	  
expression_statement : SEMICOLON
{
    
    $$ = new char[3];
    
    strcpy($$,";");


    fprintf(parserLog, "At Line no: %d: expression_statement : SEMICOLON\n\n", lineNo);
    fprintf(parserLog, ";\n\n");
}
			| expression SEMICOLON
{
    string str = $1 -> getName();
    str.append(";");
    
    $$ = new char[1000];

    strcpy($$,str.c_str());


    fprintf(parserLog, "At Line no: %d: expression_statement : expression SEMICOLON\n\n", lineNo);
    //fprintf(parserLog, "%s;\n\n", $1);
    fprintf(parserLog, "%s\n\n", str.c_str());
}
			;
	  
variable : ID
    {
        
        string str = $1 -> getName();

        fprintf(parserLog, "At Line no: %d: variable : ID\n\n",lineNo);
        
        fprintf(parserLog, "%s\n\n", $1 -> getName().c_str());
        
        SymbolInfo* inTable = table.lookUpInCurrentScope($1 -> getName());
        if(!inTable) {
            fprintf(parserLog,"ERROR: At Line no: %d,  variable %s not declared in scope\n",lineNo,  $1 -> getName().c_str());
            $$ = new SymbolInfo($1);
        }
        else {
            
            if(inTable -> getIsArray()) {
                fprintf(parserLog,"ERROR: At Line no: %d, variable %s is an array!\n",lineNo, $1 -> getName().c_str());
            }
            $$ = new SymbolInfo(inTable);
        }
    }

    | ID LTHIRD expression RTHIRD
    {
        string str = $1 -> getName();
        str.append("[");
        str.append($3 -> getName());
        str.append("]");


        fprintf(parserLog, "At Line no: %d: variable : ID LTHIRD expression RTHIRD\n\n",lineNo);
        fprintf(parserLog, "%s\n\n", str.c_str());
        
        SymbolInfo* inTable = table.lookUpInCurrentScope($1 -> getName());
        
        if(!inTable) {
            fprintf(parserLog, "ERROR at line no: %d: variable %s not declared in scope\n", lineNo, $1 -> getName().c_str());
            
            $$ = new SymbolInfo(str, "EXPRESSION", "NONE");
        }
        else {
            
            $$ = new SymbolInfo(inTable);
            $$ -> setName(str);
            
            if(!inTable -> getIsArray()) {
                fprintf(parserLog, "ERROR AT LINE %d: variable %s is not an array!\n\n", lineNo, $1 -> getName().c_str());
            }
            if($3 -> getDataType() != "INT") {
                fprintf(parserLog, "ERROR AT LINE %d: non integer array index (%s)\n\n", lineNo, $3 -> getDataType().c_str());
            }
        }
        
    }
	 ;
	 
 expression : logic_expression
{
    
    string str = $1 -> getName();
    $$ = new SymbolInfo(str, "EXPRESSION", $1 -> getDataType());
    
    fprintf(parserLog, "At Line no: %d: expression : logic_expression\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
}


	   | variable ASSIGNOP logic_expression
{
    
    string str = $1 -> getName();
    str.append(" = ");
    str.append($3 -> getName());
    
    $$ = new SymbolInfo(str, "EXPRESSION", $1 -> getDataType());
    

    if($1 -> getDataType() != $3 -> getDataType()) {
        if($1 -> getDataType() == "INT" && $3 -> getDataType() == "FLOAT") {
            
            fprintf(parserLog, "WARNING At Line no: %d: assigning float to int value will result in loss of precision!\n\n", lineNo);
        }
        
        else if($1 -> getDataType() == "FLOAT" && $3 -> getDataType() == "INT") {
            
            fprintf(parserLog, "WARNING At Line no: %d: assigning int to float value\n\n", lineNo);
        }
        
        else {
            fprintf(parserLog, "ERROR At Line no: %d: LHS and RHS of assignment have different data types! (%s = %s)\n\n", lineNo, $1 -> getDataType().c_str(), $3 -> getDataType().c_str());
        }
        
        
    }
    
    if($3 -> getDataType() == "NONE" || $3 -> getDataType() == "VOID" ) {
         fprintf(parserLog, "ERROR At Line no: %d: RHS is %s\n\n", lineNo,$3 -> getDataType().c_str());
    }
    
    fprintf(parserLog, "At Line no: %d: expression :variable ASSIGNOP logic_expression\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
    
}
	   ;



			
logic_expression : rel_expression
{
    string str = $1 -> getName();
    
   $$ = new SymbolInfo($1);
    
    


    fprintf(parserLog, "At Line no: %d: logic_expression : rel_expression\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
}
		 | rel_expression LOGICOP rel_expression
{
    //assuming both have same data types, here, we return data type of $1
    string str = $1 -> getName();
    str.append(" ");
    str.append($2 -> getName());
    str.append(" ");
    str.append($3 -> getName());
    
    //$$ = new SymbolInfo(str, "EXPRESSION", $1 -> getDataType());
    
    $$ = new SymbolInfo(str, "EXPRESSION", "INT");  //result is always int here


    fprintf(parserLog, "At Line no: %d: logic_expression : rel_expression LOGICOP rel_expression\n\n", lineNo);
    //fprintf(parserLog, "%s %s %s\n\n", $1, $2 -> getName().c_str(), $3);
    fprintf(parserLog, "%s\n\n", str.c_str());
}
		 ;
			
rel_expression	: simple_expression
{
    string str = $1 -> getName();
    
//    $$ = new char[1000];
//
//    strcpy($$, $1);

    //$$ = new SymbolInfo(str, "EXPRESSION", $1 -> getDataType());
    //cout << "blah";
    $$ = new SymbolInfo($1);

    fprintf(parserLog, "At Line no: %d: rel_expression : simple_expression\n\n", lineNo);
//    fprintf(parserLog, "%s\n\n", $1);
fprintf(parserLog, "%s\n\n", str.c_str());
}
		| simple_expression RELOP simple_expression
{
    //assuming both have same data types, here, we return data type of $1
    string str = $1 -> getName();
    str.append(" ");
    str.append($2 -> getName());
    str.append(" ");
    str.append($3 -> getName());


    //$$ = new SymbolInfo(str, "EXPRESSION", $1 -> getDataType());
    $$ = new SymbolInfo(str, "EXPRESSION", "INT"); //result is always int



    fprintf(parserLog, "At Line no: %d: rel_expression : simple_expression RELOP simple_expression\n\n", lineNo);
fprintf(parserLog, "%s\n\n", str.c_str());
}
		;
				
simple_expression : term
{
    string str = $1 -> getName();
    
    $$ = new SymbolInfo($1);

    fprintf(parserLog, "At Line no: %d:simple_expression : term\n\n", lineNo);
fprintf(parserLog, "%s\n\n", str.c_str());

}
		  | simple_expression ADDOP term
{
    
    //assuming both have same data types, here, we return data type of $1
    string str = $1 -> getName();
    str.append(" ");
    str.append($2 -> getName());
    str.append(" ");
    str.append($3 -> getName());
    
//    $$ = new char[1000];
//
//
//    strcpy($$,str.c_str());

    $$ = new SymbolInfo(str, "EXPRESSION", $1 -> getDataType());


    fprintf(parserLog, "At Line no: %d: simple_expression : simple_expression ADDOP term\n\n", lineNo);
    //fprintf(parserLog, "%s %s %s \n\n", $1, $2 -> getName().c_str(), $3);
    fprintf(parserLog, "%s\n\n", str.c_str());
}
		  ;
					
term :	unary_expression
{
    string str = $1 -> getName();
    
    $$ = new SymbolInfo($1);

    fprintf(parserLog, "At Line no: %d: term : unary_expression\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", $1 -> getName().c_str());
}
     |  term MULOP unary_expression
{
    
    //assuming both have same data types, here, we return data type of $1
    string str = $1 -> getName();
    str.append(" ");
    str.append($2 -> getName());
    str.append(" ");
    str.append($3 -> getName());
    
    
    $$ = new SymbolInfo(str, "EXPRESSION", $1 -> getDataType());
    


    fprintf(parserLog, "At Line no: %d: term : term MULOP unary_expression\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
    
    if($2 -> getName() == "%") {
        if($1 -> getDataType() != "INT" || $3 -> getDataType() != "INT") {
            fprintf(parserLog, "ERROR At Line no: %d: operands to mod operator are not integers!!\n\n", lineNo);
        }
    }
    
    
}
     ;

unary_expression : ADDOP unary_expression   %prec UNARY_OP
{
    string str = $1 -> getName();
    str.append(" ");
    str.append($2 -> getName());
    

    
    //$$ = new char[1000];
    
    $$ = new SymbolInfo(str, "EXPRESSION", $2 -> getDataType());
    

   // strcpy($$,str.c_str());


    fprintf(parserLog, "At Line no: %d:unary_expression : ADDOP unary_expression\n\n", lineNo);
    //fprintf(parserLog, "%s %s\n\n", $1 -> getName().c_str(), $2 -> getName().c_str());
    fprintf(parserLog, "%s\n\n", str.c_str());
}
		 | NOT unary_expression     %prec UNARY_OP
{
    string str = "!";
    str.append($2 -> getName());
    
    
    //$$ = new char[1000];
    $$ = new SymbolInfo(str, "EXPRESSION", $2 -> getDataType());
    

    //strcpy($$,str.c_str());


    fprintf(parserLog, "At Line no: %d: unary_expression : NOT unary_expression  %prec UMINUS\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
}
		 | factor
{
    string str = $1 -> getName();
    
    $$ = new SymbolInfo($1);


    fprintf(parserLog, "At Line no: %d: unary_expression : factor\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());

}
		 ;
	
factor	: variable
{
    string str = $1 -> getName();
    
    //$$ = new char[100];
    //$$ = new SymbolInfo(str, "EXPRESSION", $1 -> getDataType());
    $$ = new SymbolInfo($1);
    
    //strcpy($$, $1);


    fprintf(parserLog, "At Line no: %d: factor : variable\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", $1 -> getName().c_str());
}
    | ID LPAREN argument_list RPAREN
{
    //function call, so $$'s data type is functions return data type
    string str = $1 -> getName();
    str.append("(");
    str.append($3);
    str.append(")");
    
   $$ = new SymbolInfo(str, "EXPRESSION", "NONE"); //change NONE later to functions return data type



    fprintf(parserLog, "At Line no: %d: factor : ID LPAREN argument_list RPAREN \n\n", lineNo);
    fprintf(parserLog, "%s(%s)\n\n", $1 -> getName().c_str(), $3);

    if(!table.lookUpInCurrentScope($1 -> getName())) {
        fprintf(parserLog,"ERROR at line No: %dfunction %s not declared in scope\n",lineNo, $2 -> getName().c_str());
    }
    else {
        //retrieve func info here and assign to $$
    }

}
    | LPAREN expression RPAREN
{
    string str = "(";
    str.append($2 -> getName());
    str.append(")");
    
    //$$ = new char[1000];

    $$ = new SymbolInfo(str, "EXPRESSION", $2 -> getDataType());
    //strcpy($$,str.c_str());


    fprintf(parserLog, "At Line no: %d: factor : LPAREN expression RPAREN\n\n", lineNo);
    //fprintf(parserLog, "(%s)\n\n", $2 -> getName().c_str());
    fprintf(parserLog, "%s\n\n", str.c_str());
}
	| CONST_INT
{
    
    $$ = new SymbolInfo($1);

    fprintf(parserLog, "At Line no: %d : factor : CONST_INT\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", $1 -> getName().c_str());
}
	| CONST_FLOAT
{

    $$ = new SymbolInfo($1);


    fprintf(parserLog, "At Line no: %d:factor : CONST_FLOAT\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", $1 -> getName().c_str());
    //fprintf(parserLog, "%s\n\n", str.c_str());
}
	| variable INCOP
{
    string str = $1 -> getName();
    str.append(" ");
    str.append($2 -> getName());
    
    $$ = new SymbolInfo(str, "EXPRESSION", $1 -> getDataType());
    

    fprintf(parserLog, "At Line no: %d: factor : variable INCOP\n\n", lineNo);
    fprintf(parserLog, "%s %s\n\n", $1 -> getName().c_str(), $2 -> getName().c_str());
}
	;
	
argument_list : arguments
{
    string str = $1;
    
    $$ = new char[1000];
    
    strcpy($$, $1);


    fprintf(parserLog, "At Line no: %d: argument_list : arguments\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", $1);
}
    |
{
    
    $$ = new char[2];
    
    strcpy($$, "");
    fprintf(parserLog, "At Line no: %d: argument_list : <empty>\n\n", lineNo);
    fprintf(parserLog, "\n\n");
}
			  ;
	
arguments : arguments COMMA logic_expression
{
    string str = $1;
    str.append(", ");
    str.append($3 -> getName());
    
    $$ = new char[1000];

    strcpy($$,str.c_str());


    fprintf(parserLog, "At Line no: %d: arguments : arguments COMMA logic_expression\n\n", lineNo);
    fprintf(parserLog, "%s, %s\n\n", $1, $3 -> getName().c_str());
}
	      | logic_expression
{
    string str = $1 -> getName();
    
    $$ = new char[100];
    
    strcpy($$, str.c_str());
    
    
    fprintf(parserLog, "At Line no: %d: arguments : logic_expression\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", $1 -> getName().c_str());
    
}
	      ;
 

%%
int main(int argc,char *argv[])
{
   

    if((inputFile=fopen(argv[1],"r"))==NULL)
    {
        printf("Cannot Open Input File.\n");
        exit(1);
    }
    
    scannerLog = fopen("scannerLog.txt", "w");
    scannerToken = fopen("scannerToken.txt", "w");

    parserLog=fopen(argv[2],"w");
    //fclose(parserLog);
    parserOut=fopen(argv[3],"w");
    //fclose(parserOut);

    //parserLog= fopen(argv[2],"a");
    //parserOut= fopen(argv[3],"a");

    yyin=inputFile;
    yyparse();

    fclose(parserLog);
    fclose(parserOut);
    
    fclose(scannerToken);
    fclose(scannerLog);
    fclose(yyin);
    return 0;
}

