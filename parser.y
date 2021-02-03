%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>

#include<vector>
#include "symbolTable.cpp"
#include "optimize.cpp"
//#define YYSTYPE SymbolInfo*

#define MAX_CHARS 50000

using namespace std;

extern FILE *yyin;

extern int lineNo;

FILE *inputFile;

FILE* scannerLog;
FILE* scannerToken;

FILE* parserLog;
FILE *parserError;

FILE* codeFile;

FILE* opCodeFile;

int parseErrors = 0;


string typeSpecified;



SymbolTable table(100);
vector<SymbolInfo*> parameters; //stores input parameters in a function definition to later insert to scope inside function body
int yylex(void);

//code gen start
//HANDLE CASE WHEN FUNCTION ARGUMENTS ARE ARRAY[sth]'s LATER
string currentScope = "";
string globalCode;
int labelCount = 0;
int tempCount = 0;
int scopeCount = 0;

vector<SymbolInfo*> variables;  //symbolInfo to store array info

vector<string> parameterNames;  //stores param names of functions

vector<string> procedures;

vector<SymbolInfo*> arguments;

string newLabel() {
    string temp;
    temp = "L";
    temp += to_string(labelCount);
    labelCount++;
    return temp;
}

string newTemp() {
    string temp;
    temp = "t";
    temp += to_string(tempCount);
    SymbolInfo* symbol = new SymbolInfo(temp, "ID");
    symbol -> setIsArray(false);
    variables.push_back(symbol);
    tempCount++;
    return temp;
}

//string newScope() {
//    string temp;
//    temp = "S";
//    temp += to_string(scopeCount);
//    scopeCount++;
//    return temp;
//}

//code gen end



void yyerror(char *s)
{
    fprintf(parserError,"ERROR AT LINE %d: %s\n", lineNo, s);
}



%}



%union {
    SymbolInfo* symbolInfo;
    char* text;
    
}

%token IF FOR INT ELSE FLOAT VOID WHILE CHAR DOUBLE RETURN PRINTLN <symbolInfo>CONST_INT <symbolInfo>CONST_FLOAT <symbolInfo>CONST_CHAR <symbolInfo>ADDOP <symbolInfo>MULOP <symbolInfo>INCOP ASSIGNOP <symbolInfo>RELOP <symbolInfo>LOGICOP <symbolInfo>BITOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON <symbolInfo>ID

%type<text>begin program unit var_declaration func_declaration func_definition type_specifier compound_statement statements declaration_list  statement


%type<symbolInfo> logic_expression rel_expression simple_expression term unary_expression factor variable expression_statement expression parameter_list argument_list arguments


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
        
        
        string temp = $1;
        
        //code gen start
        string code = ".DATA\n";
        
        while(!variables.empty()) {
            if(variables.back() -> getIsArray()) {
                code += variables.back() -> getName() + " DW " + to_string(variables.back() -> getSize()) + " DUP ?\n";
                
            }
            else {
                code += variables.back() -> getName() + " DW ?\n";
                
            }
            
            variables.pop_back();
        }
        
        code += ".CODE\n\n";
        
        code += temp;
        
        code += "PRINT PROC\n";
        //value to print is in dx
        //division: dx:ax / divisor(16 bit)
        
        code += "push ax\n";
        code += "push bx\n";
        code += "push cx\n";
        code += "push dx\n";
        
        code += "mov ax, dx\n";
        code += "mov cx, 0\n";
        code += "top: and dx, 0\n";  //clear dx
        code += "mov bx, 10\n";
        code += "div bx\n";
        //now dx stores reminder, ax stores quotient
        code += "push dx\n";
        code += "inc cx\n"; //cx stores num of digits
        code += "cmp ax, 0\n";
        code += "jg top\n";
        code += "mov ah,2\n";
        //pop stack and print, cx times
        code += "disp: pop dx\n";
        code += "add dx, 48\n";
        code += "int 21h\n";
        code += "loop disp\n";
        
        code += "mov ah, 2\n";
        code += "mov dl, 0DH\n";
        code += "int 21h\n";
        code += "mov dl, 0AH\n";
        code += "int 21h\n";
        
        
        code += "pop dx\n";
        code += "pop cx\n";
        code += "pop bx\n";
        code += "pop ax\n";
        code += "ret\n";
        code += "PRINT ENDP\n\n\n";
        
        while(!procedures.empty()) {
            code += procedures.back();
            procedures.pop_back();
        }




        
        //strcpy($$, $1);
        
        //code += "MAIN ENDP\n";
        
        
        
        code += "END MAIN\n";
        
        //optimize start
        
        string opCode = optimizeCode(code);
        
        //cout << opCode << endl;
        strcpy($$, code.c_str());
        
        
        
        
        fprintf(codeFile, "%s", $$);
        fprintf(opCodeFile, "%s", opCode.c_str());
        //code gen end
        
        fprintf(parserLog, "at line no: %d begin: program\n\n", lineNo);
        fprintf(parserLog,"%s\n\n", $1);
        
        fprintf(parserLog, "Symbol Table:  \n\n");
        table.printAllScopeTables(parserLog);
        
        fprintf(parserLog, "Total Line: %d\n", lineNo);
        fprintf(parserLog, "Total Errors: %d\n\n", parseErrors);
        fprintf(parserError, "Total Errors: %d\n\n", parseErrors);
        
        
        
        

    }
    ;

program: program unit
    {
        
            string str = $1;
            str.append(" ");
            str.append($2);
            $$ = new char[MAX_CHARS];
            strcpy($$,str.c_str());
            
            
            
            fprintf(parserLog, "at line no: %d program: program unit\n\n", lineNo);
            fprintf(parserLog,"%s\n\n", str.c_str());
    }
    | unit
    {
        
        $$ = new char[MAX_CHARS];
        strcpy($$,$1);
        
        fprintf(parserLog, "at line no: %d program: unit\n\n", lineNo);
        fprintf(parserLog,"%s\n\n", $1);
    }
	;
	
unit : var_declaration
    {
        fprintf(parserLog, "at line no: %d unit : var_declaration\n\n", lineNo);
        fprintf(parserLog, "%s\n\n", $1);
        
        $$ = new char[1000];
        strcpy($$, $1);
    }
     | func_declaration
    {
    
        fprintf(parserLog, "at line no: %d unit : func_declaration\n\n", lineNo);
         fprintf(parserLog, "%s\n\n", $1);
         $$ = new char[1000];
         strcpy($$, $1);
    }
     | func_definition
    {
        fprintf(parserLog, "at line no: %d unit : func_definition\n\n", lineNo);
        fprintf(parserLog, "%s\n\n", $1);
        $$ = new char[MAX_CHARS];
        strcpy($$, $1);
    }
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
    {
            string str = $1;
//            str.append(" ");
//            str.append($2 -> getName());
//            str.append("(");
//            str.append(" ");
//            str.append($4 -> getName());
//            str.append(" ");
//            str.append(")");
//            str.append(";");
            $$ = new char[1000];

            strcpy($$,"");

            
            
            
            fprintf(parserLog, "at line no: %d func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n", lineNo);
            fprintf(parserLog, "%s\n\n", str.c_str());

            if(!table.lookUpInCurrentScope($2 -> getName())) {
                $2 -> setDataType($1);
                $2 -> setIsFunction(true);
                $2 -> setIsDeclaration(true);
                $2 -> setParameters($4 -> getParameters());
                table.insert($2);
        }
        else {
            fprintf(parserError," ERROR at line no %d: Function already declared in scope!!\n", lineNo);
            parseErrors++;
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

        //strcpy($$,str.c_str());
        strcpy($$,"");
        
        fprintf(parserLog, "at line no: %d func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n", lineNo);
        
        fprintf(parserLog, "%s\n\n", str.c_str());


        if(!table.lookUpInCurrentScope($2 -> getName())) {
            $2 -> setDataType($1);
            $2 -> setIsFunction(true);
            $2 -> setIsDeclaration(true);
            table.insert($2);
        }
        else {
            fprintf(parserError ,"ERROR at line no %d: Function already declared in scope!!\n", lineNo);
            parseErrors++;
        }
    }
		;
		 
func_definition : type_specifier ID  LPAREN parameter_list RPAREN {currentScope = $2 -> getName();} compound_statement
    {
        //here, parameter_list variables need to be inserted in scope table of the function, not in the global scope table
        
//        int f(int a, int b) {
//            return  a + b;
//        }

         string str = $1;
//         str.append(" ");
//         str.append($2 -> getName());    //id
//         str.append("(");
//         str.append($4 -> getName());
//         str.append(")");
//         str.append($6);

         $$ = new char[MAX_CHARS];
         
         //code gen start
         
         
         string code = $2 -> getName() + " PROC\n";
         if($2 -> getName() == "main") {
             code += ";init ds\n";
             code += "mov ax, @DATA\n";
             code += "mov ds,ax\n\n";
             code += $7;
             code += "mov ah, 4CH\n";
             code += "int 21h\n";
             code += $2 -> getName() + " ENDP\n";
             
             strcpy($$,code.c_str());
         }
         else {
             code += $7;
             code += $2 -> getName() + " ENDP\n";
             procedures.push_back(code);
             
         }
         
         
         
         
         //code gen end


         
         fprintf(parserLog, "at line no: %d func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n", lineNo);
         fprintf(parserLog, "%s\n\n", str.c_str());
         
         SymbolInfo* inTable =table.lookUpInCurrentScope($2 -> getName());
         
         
        if(!inTable) {
            $2 -> setDataType($1);
            $2 -> setIsFunction(true);
            $2 -> setIsDeclaration(false);
            $2 -> setParameters($4 -> getParameters());
            table.insert($2);
        }
        else {
            
            if(inTable -> getIsDeclaration()) {
                //function with same name is previously declared but not defined
                
                //so, check if parameters given here is consistent with previous declaration parameters
                if(inTable -> getParameters() == $4 -> getParameters() && inTable -> getDataType() == $1) {
                    inTable -> setIsDeclaration(false);
                }
                else {
                    fprintf(parserError ,"ERROR at line no %d: Function declaration and definitions dont match!!\n", lineNo);
                    parseErrors++;
                }
                
            }
            else {
                fprintf(parserError ,"ERROR at line no %d: Function already declared in scope!!\n", lineNo);
                parseErrors++;
            }
        }
    }

    | type_specifier ID LPAREN RPAREN {currentScope = $2 -> getName();} compound_statement
    {
         string str = $1;
//         str.append(" ");
//         str.append($2 -> getName());    //id
//         str.append("(");
//         str.append(")");
//
//         str.append($5);

         $$ = new char[MAX_CHARS];
         
         //strcpy($$,str.c_str());
         
         //code gen start
         
         
         string code = $2 -> getName() + " PROC\n";
         if($2 -> getName() == "main") {
             code += ";init ds\n";
             code += "mov ax, @DATA\n";
             code += "mov ds,ax\n\n";
             code += $6;
             
             code += "mov ah, 4CH\n";
             code += "int 21h\n";
             code += $2 -> getName() + " ENDP\n";
             strcpy($$,code.c_str());
         }
         else {
             
             code += $6;
             code += $2 -> getName() + " ENDP\n";
             procedures.push_back(code);
             
         }
         
         
         
         
         currentScope = "";
         //code gen end
         
         
//         strcpy($$,$5);

         fprintf(parserLog, "at line no: %d func_definition : type_specifier ID LPAREN RPAREN compound_statement\n\n", lineNo);
         
         fprintf(parserLog, "%s\n\n", str.c_str());
         
         
         
        SymbolInfo* inTable = table.lookUpInCurrentScope($2 -> getName());

        if(!inTable) {
            $2 -> setDataType($1);
            $2 -> setIsFunction(true);
            $2 -> setIsDeclaration(false);
            table.insert($2);
        }
        else {
            if(inTable -> getIsDeclaration()) {
                //function with same name is previously declared but not defined
                
                //so, check if parameters given here is consistent with previous declaration parameters
                if(inTable -> getParameters().empty() && inTable -> getDataType() == $1) {
                    inTable -> setIsDeclaration(false);
                    table.insert($2);
                }
                else {
                    parseErrors++;
                    fprintf(parserError, "ERROR at line no %d: function definition parameters dont match function declaration parameters!!\n\n", lineNo);
                }
                
            }
            else {
                fprintf(parserError ,"ERROR at line no %d: Function already declared in scope!!\n", lineNo);
                parseErrors++;
            }
        }
    }
 		;				


parameter_list  : parameter_list COMMA type_specifier ID
    {
        //here, typeSpecified global variable stores type_specifier contents
    
        string str = $1 -> getName();
        str.append(", ");
        str.append($3);
        str.append(" ");
        str.append($4 -> getName());
        
        $4 -> setDataType($3);
        $$ = new SymbolInfo(str, "PARAMETER_LIST");
        //code gen start
        parameterNames.push_back($4 -> getName());
        $$ -> code = "";
    
        //code gen end
        parameters.push_back($4);
        
        
        $$ -> setParameters($1 -> getParameters());
        $$ -> addParameter(typeSpecified);
        
        
        fprintf(parserLog, "at line no: %d parameter_list  : parameter_list COMMA type_specifier ID\n\n",lineNo);
        fprintf(parserLog, "%s\n\n", str.c_str());


    }
		| parameter_list COMMA type_specifier
    {
        
        string str = $1 -> getName();
        str.append(", ");
        str.append($3);
        
        $$ = new SymbolInfo(str, "PARAMETER_LIST");
        
        $$ -> code = "";
        $$ -> setParameters($1 -> getParameters());
        $$ -> addParameter(typeSpecified);


        fprintf(parserLog, "at line no: %d parameter_list  : parameter_list COMMA type_specifier\n\n", lineNo);
        //fprintf(parserLog, "%s, $s;\n\n", $1, $3);
        fprintf(parserLog, "%s\n\n", str.c_str());
    }
 		| type_specifier ID
    {
        
        string str = $1;
        str.append(" ");
        str.append($2 -> getName());
        
        $$ = new SymbolInfo(str, "PARAMETER_LIST");
        //code gen  start
        
        $$ -> code = "";
        parameterNames.push_back($2 -> getName());
        //code gen end
        
        
        $2 -> setDataType($1);
        parameters.push_back($2);
        
        
        $$ -> addParameter(typeSpecified);

        fprintf(parserLog, "at line no: %d parameter_list  : type_specifier ID\n\n", lineNo);
        fprintf(parserLog, "%s\n\n", str.c_str());
    }
		| type_specifier
    {
        
        string str = $1;
        $$ = new SymbolInfo(str, "PARAMETER_LIST");
        
        $$ -> addParameter(typeSpecified);

        fprintf(parserLog, "at line no: %d parameter_list  : type_specifier\n\n", lineNo);
        fprintf(parserLog, "%s\n\n", str.c_str());
    }
 		;

 		
compound_statement : LCURL {
    //only place where globalCode is written to
    //parameterNames = parameters;
    table.enterScope();
    //code gen start
    //string code;
    //string scope = newScope();
    
    if(!parameterNames.empty()) {
        SymbolInfo* var = new SymbolInfo(currentScope + "_" + parameterNames.back(), "ID");
        var -> setIsArray(false);
        variables.push_back(var);

        globalCode += "mov " + currentScope + "_" + parameterNames.back() + ", ax\n";
        parameterNames.pop_back();
    }
    
    if(!parameterNames.empty()) {
        
        SymbolInfo* var = new SymbolInfo(currentScope + "_" + parameterNames.back(), "ID");
        var -> setIsArray(false);
        variables.push_back(var);
        
        globalCode += "mov " + currentScope + "_" + parameterNames.back() + ", bx\n";
        parameterNames.pop_back();
    }
    
    if(!parameterNames.empty()) {
        
        SymbolInfo* var = new SymbolInfo(currentScope + "_" + parameterNames.back(), "ID");
        var -> setIsArray(false);
        
        variables.push_back(var);
        globalCode += "mov " + currentScope + "_" + parameterNames.back() + ", cx\n";
        parameterNames.pop_back();
    }
    
    if(!parameterNames.empty()) {
        
        SymbolInfo* var = new SymbolInfo(currentScope + "_" + parameterNames.back(), "ID");
        var -> setIsArray(false);
        variables.push_back(var);
        
        globalCode += "mov " + currentScope + "_" + parameterNames.back() + ", dx\n";
        parameterNames.pop_back();
    }
    //code gen end
    while(!parameters.empty()) {
        table.insert(parameters.back());
        parameters.pop_back();
}
/*parameters is empty now*/} statements RCURL
{
    
    
    string str = "{ ";
    str.append($3);
    str.append(" }");
    
    $$ = new char[MAX_CHARS];
    
    //code gen start
    //compound statement
    string code = globalCode;   //only place where globalCode is read from
    code += $3;
    globalCode = "";
    strcpy($$,code.c_str());
    currentScope = "";
    //code gen end

    fprintf(parserLog, "at line no: %d compound_statement : LCURL statements RCURL\n\n", lineNo);
    //fprintf(parserLog, "{ %s }\n\n", $3);
    fprintf(parserLog, "%s\n\n", str.c_str());
    
    table.printAllScopeTables(parserLog);
    table.exitScope();
    
}
 		    | LCURL RCURL
{
    //insert parameters in the empty function body's scope
    table.enterScope();
    while(!parameters.empty()) {
        table.insert(parameters.back());
        parameters.pop_back();
    }

    string str = "{ }";
    $$ = new char[5];
    strcpy($$, "");

    fprintf(parserLog, "at line no: %d compound_statement : LCURL RCURL\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
    
    table.printAllScopeTables(parserLog);
    table.exitScope();
}
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
{
    string str = $1;
    str.append(" ");
    str.append($2);
    str.append(";");

    $$ = new char[1000];

    //strcpy($$,str.c_str());
    strcpy($$, "");

    fprintf(parserLog, "at line no: %d var_declaration : type_specifier declaration_list SEMICOLON\n\n", lineNo);
    //fprintf(parserLog, "%s %s;\n\n", $1, $3);
    fprintf(parserLog, "%s\n\n", str.c_str());
    typeSpecified = "none";
}

          ;

type_specifier	: INT
{
    
    string str = "int";
    typeSpecified = "int";
    
    $$ = new char[10];
    
    strcpy($$, str.c_str());
    
    fprintf(parserLog, "at line no: %d type_specifier : INT\n\n", lineNo);
    //fprintf(parserLog, "int \n\n");
    fprintf(parserLog, "%s\n\n", str.c_str());

}
        | FLOAT
{
    
    string str = "float";
    typeSpecified = "float";
    $$ = new char[10];
    
    strcpy($$, str.c_str());

    fprintf(parserLog, "at line no: %d type_specifier : FLOAT\n\n", lineNo);
   //fprintf(parserLog, "float \n\n");
   fprintf(parserLog, "%s\n\n", str.c_str());
}
 		| VOID
{
    
    string str = "void";
    typeSpecified = "void";
    $$ = new char[10];
    
    strcpy($$, str.c_str());

    fprintf(parserLog, "at line no: %d type_specifier : VOID\n\n", lineNo);
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
        //strcpy($$,str.c_str());
        
        //code gen start
        SymbolInfo* symbol = new SymbolInfo(currentScope + "_" + $3 -> getName(), "ID");
        symbol -> setIsArray(false);
        variables.push_back(symbol);
        
        strcpy($$,"");
        //code gen end

        fprintf(parserLog, "at line no: %d declaration_list : declaration_list COMMA ID\n\n", lineNo);

        fprintf(parserLog, "%s\n\n", str.c_str());
        if(!table.lookUpInCurrentScope($3 -> getName())) {
            $3 -> setDataType(typeSpecified);
            $3 -> setIsArray(false);
            table.insert($3);
        }
        else {
            parseErrors++;
            fprintf(parserError, "ERROR at line no: %d Variable already declared in this scope!\n\n", lineNo);
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
        
        //code gen start
        SymbolInfo* symbol = new SymbolInfo(currentScope + "_" + $3 -> getName(), "ID");
        symbol -> setIsArray(true);
        symbol -> setSize(stoi($5 -> getName()));
        variables.push_back(symbol);
        strcpy($$,"");
        //code gen end
        
        //strcpy($$,str.c_str());

        fprintf(parserLog, "at line no: %d declaration_list : COMMA ID LTHIRD CONST_INT RTHIRD\n\n",lineNo);
       // fprintf(parserLog, "%s, %s[%s] \n\n", $1, $3 -> getName().c_str(), $5);
       fprintf(parserLog, "%s\n\n", str.c_str());
        
        if(!table.lookUpInCurrentScope($3 -> getName())) {
            $3 -> setDataType(typeSpecified);
            $3 -> setSize(atoi($4 -> getName().c_str())); //sets array size
            $3 -> setIsArray(true);
            table.insert($3);
        }
        else {
            parseErrors++;
            fprintf(parserError, "ERROR at line no: %d Variable already declared in scope!\n\n", lineNo);
        }
    }

    | ID
    {
        
    
        string str = $1 -> getName();
        
        $$ = new char[100];


        //code gen start
        SymbolInfo* symbol = new SymbolInfo(currentScope + "_" + $1 -> getName(), "ID");
        symbol -> setIsArray(false);
        variables.push_back(symbol);
        strcpy($$,"");
        //code gen end
        //strcpy($$,str.c_str());

        fprintf(parserLog, "at line no: %d declaration_list : ID\n\n",lineNo);
        fprintf(parserLog, "%s \n\n", $1 -> getName().c_str());
        if(!table.lookUpInCurrentScope($1 -> getName())) {
            $1-> setDataType(typeSpecified);
            $1 -> setIsArray(false);
            table.insert($1);
            
        }
        else {
            parseErrors++;
            fprintf(parserError, "ERROR at line no: %d Variable already declared in scope!\n\n", lineNo);
        }

    }

    | ID LTHIRD CONST_INT RTHIRD
    {
        
        
        
        string str = $1 -> getName();
        str.append("[");
        str.append($3 -> getName());
        str.append("]");

        $$ = new char[100];
        
        //code gen start
        SymbolInfo* symbol = new SymbolInfo(currentScope + "_" + $1 -> getName(), "ID");
        symbol -> setIsArray(true);
        symbol -> setSize(stoi($3 -> getName()));
        variables.push_back(symbol);
        strcpy($$,"");
        //code gen end
        
        
        //strcpy($$,str.c_str());

        fprintf(parserLog, "at line no: %d declaration_list : ID LTHIRD CONST_INT RTHIRD\n\n", lineNo);
        
        fprintf(parserLog, "%s\n\n", str.c_str());
        if(!table.lookUpInCurrentScope($1 -> getName())) {
            $1 -> setDataType(typeSpecified);
            $1 -> setSize(atoi($3 -> getName().c_str())); //sets array size
            $1 -> setIsArray(true);
            table.insert($1);
        }
        else {
            parseErrors++;
            fprintf(parserError, "ERROR at line no: %d Variable already declared in scope!\n\n", lineNo);
        }
    }
 		  ;
 		  
statements : statement
{
    string str = $1;
    
    $$ = new char[MAX_CHARS];

    strcpy($$,str.c_str());

    fprintf(parserLog, "at line no: %d statements : statement\n\n", lineNo);
    fprintf(parserLog, "%s \n\n", $1);
}
	   | statements statement
{
    
    string str = $1;
    str.append(" ");
    str.append($2);

    $$ = new char[MAX_CHARS];
    strcpy($$,str.c_str());

    fprintf(parserLog, "at line no: %d statements : statements statement\n\n", lineNo);
    //fprintf(parserLog, "%s %s\n\n", $1, $2);
    fprintf(parserLog, "%s\n\n", str.c_str());
}
	   ;
	   
statement : var_declaration
{
    
    string str = $1;
    $$ = new char[1000];
    strcpy($$,str.c_str());


    fprintf(parserLog, "at line no: %d statement : var_declaration\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", $1);
}
	  | expression_statement
{
    string str = $1 -> code;
    $$ = new char[1000];
    strcpy($$,str.c_str());
    
    


    fprintf(parserLog, "at line no: %d statement: expression_statement\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
}
	  | compound_statement
{
    string str = $1;
    $$ = new char[MAX_CHARS];
    strcpy($$,str.c_str());


    fprintf(parserLog, "at line no: %d statement : compound_statement\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
}
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
{
    
    //for(i = 0; i < 5; i++)
    string str = "for(";
    str.append($3 -> getName());
    str.append(" ");
    str.append($4 -> getName());
    str.append(" ");
    str.append($5 -> getName());
    str.append(")");
    str.append($7);
    
    
    $$ = new char[MAX_CHARS];
    
    //code gen start
    string code = $3 -> code;
    
    string label1 = newLabel();
    string label2 = newLabel();
    
    code += label1 + ":\n";
    code += $4 -> code;
    code += "mov ax, " + $4 -> getName() + "\n";
    code += "cmp ax, 0\n";
    code += "je " + label2 + "\n";
    code += $7;
    code += $5 -> code;
    code += "jmp " + label1 + "\n";
    code += label2 + ":\n";
    strcpy($$,code.c_str());
    //code gen end
    


    fprintf(parserLog, "at line no: %d statement: FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
    
    
}
      | IF LPAREN expression RPAREN statement   %prec LOWER_THAN_ELSE
{
    string str = "if(";

    str.append($3 -> getName());
    str.append(")");
    str.append($5);
    
    $$ = new char[MAX_CHARS];
    
    //code gen start
    
    string code = $3 -> code;
    //$3 evaluates to either 0 or 1
    code += "mov ax, " + $3 -> getName() + "\n";
    code += "cmp ax, 0\n";
    string label = newLabel();
    code += "je " + label + "\n";   //if false, then jump to label
    code += $5;
    code += label + ":\n";
    //strcpy($$,str.c_str());
    strcpy($$,code.c_str());
    
    //code gen end

    fprintf(parserLog, "at line no: %d statement : IF LPAREN expression RPAREN statement\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
    
    if($3 -> getDataType() == "void") {
        parseErrors++;
        fprintf(parserError, "ERROR at line no: %d expression evaluates to void!!\n\n", lineNo);
        
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
    
    //code gen start
    
    string code = $3 -> code;
    //$3 evaluates to either 0 or 1
    code += "mov ax, " + $3 -> getName() + "\n";
    code += "cmp ax, 0\n";
    string label = newLabel();
    code += "je " + label + "\n";   //if expression is false, then jump to label
    code += $5;
    string label1 = newLabel();
    code += "jmp " + label1 + "\n";
    code += label + ":\n";
    code += $7;
    code += label1 + ":\n";
    //strcpy($$,str.c_str());
    strcpy($$,code.c_str());
    
    //code gen end


    fprintf(parserLog, "at line no: %d statement :IF LPAREN expression RPAREN statement ELSE statement\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
    
    if($3 -> getDataType() == "void") {
        parseErrors++;
        fprintf(parserError, "ERROR at line no: %d expression evaluates to void!!\n\n", lineNo);
        
    }
}
	  | WHILE LPAREN expression RPAREN statement
{
    string str = "while(";
    str.append($3 -> getName());
    str.append(") ");
    str.append($5);
    
    $$ = new char[MAX_CHARS];
    
    //code gen start
    
    string label1 = newLabel();
    string label2 = newLabel();
    string code = label2 + ":\n";
    code += $3 -> code;
    code += "mov ax, " + $3 -> getName() + "\n";
    code += "cmp ax, 0\n";
    
    code += "je " + label1 + "\n";     //if expression false, then escape loop sequence
    code += $5;
    code += "jmp " + label2 + "\n";
    code += label1 + ":\n";
    strcpy($$,code.c_str());
    //code gen end




    fprintf(parserLog, "at line no: %d statement : WHILE LPAREN expression RPAREN statement\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
    
    if($3 -> getDataType() == "void") {
        parseErrors++;
        fprintf(parserError, "ERROR at line no: %d expression evaluates to void!!\n\n", lineNo);
        
    }
}
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
{
    string str = "println(";
    str.append($3 -> getName());
    str.append(");");
    
    //code gen start
    string code = "mov dx, " + currentScope + "_" + $3 -> getName() + "\n";
    code += "call print\n";
    $$ = new char[1000];

    strcpy($$,code.c_str());
    
    //code gen end


    fprintf(parserLog, "at line no: %d statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
}
	  | RETURN expression SEMICOLON
{
    string str = "return ";
    str.append($2 -> getName());
    str.append(";");
    
    $$ = new char[1000];
    //code gen start
    string code = $2 -> code;
    //code += "push " + $2 -> getName() + "\n";  //pushing return value to top of stack
    if(currentScope != "main") {
        code += "mov dx, " +  $2 -> getName() + "\n";
        code += "RET\n";
    }
    
    //code gen end
    strcpy($$,code.c_str());
    
    


    fprintf(parserLog, "at line no: %d statement : RETURN expression SEMICOLON\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
    
    if($2 -> getDataType() == "void") {
        parseErrors++;
        fprintf(parserError, "ERROR at line no: %d expression evaluates to void!!\n\n", lineNo);
        
    }
}
	  ;
	  
expression_statement : SEMICOLON
{
    
    $$ = new SymbolInfo(";", "SEMICOLON");
    
    //strcpy($$,";");


    fprintf(parserLog, "at line no: %d expression_statement : SEMICOLON\n\n", lineNo);
    fprintf(parserLog, ";\n\n");
}
			| expression SEMICOLON
{
    
    
    
    
    //code gen start
    //for code gen, just bubbling up code segment of SymbolInfo*
    
    //str.append(";");
    
    string str = $1 -> code;
    //$$ = new char[1000];
    $$ = new SymbolInfo($1);
    
    //strcpy($$,str.c_str());
    //code gen end
    
    
    fprintf(parserLog, "at line no: %d expression_statement : expression SEMICOLON\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
}
			;
	  
variable : ID
    {
        
        string str = currentScope + "_" + $1 -> getName();
        
        //code gen start
        $$ = new SymbolInfo(str, "ID");
        $$ -> setIsArray(false);
        
        //code gen end

        fprintf(parserLog, "at line no: %d variable : ID\n\n",lineNo);
        
        fprintf(parserLog, "%s\n\n", $1 -> getName().c_str());
        
        SymbolInfo* inTable = table.lookUp($1 -> getName());
        if(!inTable) {
            parseErrors++;
            fprintf(parserError,"ERROR: At Line no: %d,  variable %s not declared in scope\n\n",lineNo,  $1 -> getName().c_str());
            //$$ = new SymbolInfo($1);
        }
        else {
            
            
            
            if(inTable -> getIsArray()) {
                parseErrors++;
                fprintf(parserError,"ERROR: At Line no: %d, %s is an array!\n\n",lineNo, $1 -> getName().c_str());
            }
            if(inTable -> getIsFunction()) {
                parseErrors++;
                fprintf(parserError,"ERROR: At Line no: %d,%s is an function!\n\n",lineNo, $1 -> getName().c_str());
            }
            //$$ = new SymbolInfo(inTable);
        }
    }

    | ID LTHIRD expression RTHIRD
    {
        
        string str = $1 -> getName();
        str.append("[");
        str.append($3 -> getName());
        str.append("]");


        fprintf(parserLog, "at line no: %d variable : ID LTHIRD expression RTHIRD\n\n",lineNo);
        fprintf(parserLog, "%s\n\n", str.c_str());
        
        SymbolInfo* inTable = table.lookUp($1 -> getName());
        
        if(!inTable) {
            parseErrors++;
            fprintf(parserError, "ERROR at line no: %d variable %s not declared in scope\n\n", lineNo, $1 -> getName().c_str());
            
            $$ = new SymbolInfo(str, "EXPRESSION", "NONE");
        }
        else {
            
            $$ = new SymbolInfo(inTable);
            $$ -> setName(str);
            
            if(!inTable -> getIsArray()) {
                parseErrors++;
                fprintf(parserError, "ERROR AT LINE %d: %s is not an array!\n\n", lineNo, $1 -> getName().c_str());
            }
            
            if(inTable -> getIsFunction()) {
                parseErrors++;
                fprintf(parserError,"ERROR: At Line no: %d, %s is a function!\n\n",lineNo, $1 -> getName().c_str());
            }
            if($3 -> getDataType() != "int") {
                parseErrors++;
                fprintf(parserError, "ERROR AT LINE %d: non integer array index (%s)\n\n", lineNo, $3 -> getDataType().c_str());
            }
            
        
            
        }
        $$ = new SymbolInfo();
        
        //code gen start
        string code = $3 -> code;
        //string temp = newTemp();
        
        code += "mov bx, " + $3 -> getName() + "\n";
        code += "add bx, bx\n"; //double bx to convert byte addressing to word addressing
        
        //code += "mov ax, " + $1 -> getName() + "\n";    //ax stores array start
        //            code += "add ax, bx\n";
        //            code += "mov " + temp + ", [ax]";
        
        $$ -> code = code;
        $$ -> setName(currentScope + "_" + $1 -> getName());
        
        $$ -> setIsArray(true);
        
        //code gen end
        
    }
	 ;
	 
 expression : logic_expression
{
    
    //fprintf(code, $1 -> code.c_str());
    
    string str = $1 -> getName();
    //$$ = new SymbolInfo(str, "EXPRESSION", $1 -> getDataType());
    
    $$ = new SymbolInfo($1);
    
    fprintf(parserLog, "at line no: %d expression : logic_expression\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
}


	   | variable ASSIGNOP logic_expression
{
    
    
    string str = $1 -> getName();
    str.append(" = ");
    str.append($3 -> getName());
    
    
    $$ = new SymbolInfo(str, "EXPRESSION", $1 -> getDataType());
    
    //code gen start
    string code  = $3 -> code + $1 -> code;
    code += "mov ax, " + $3 -> getName() + "\n";
    
    if(!$1 -> getIsArray()) {
        
        code += "mov " + $1 -> getName()  + ", ax\n";
    }
    else {
        //verify later
        
        //bx has offset address of array
        
        code+= "mov " + $1->getName() + "[bx], ax\n";
        
        //variable($1) is array
    }
    
    $$ -> code = code;
    //code gen end
    
    

    if($1 -> getDataType() != $3 -> getDataType() && $1 -> getDataType() != "none" && $3 -> getDataType() != "none") {
        
        if($1 -> getDataType() == "int" && $3 -> getDataType() == "float") {
            
            parseErrors++;
            
            fprintf(parserError, "WARNING at line no: %d assigning float to int value will result in loss of precision!\n\n", lineNo);
        }
        
        else if($1 -> getDataType() == "float" && $3 -> getDataType() == "int") {
            
            parseErrors++;
            
            fprintf(parserError, "WARNING at line no: %d assigning int to float value\n\n", lineNo);
        }
        
        else {
            
            parseErrors++;
            fprintf(parserError, "ERROR at line no: %d LHS and RHS of assignment have different data types! (%s = %s)\n\n", lineNo, $1 -> getDataType().c_str(), $3 -> getDataType().c_str());
        }
        
        
    }
    
    if($3 -> getDataType() == "none" || $3 -> getDataType() == "void" ) {
        parseErrors++;
         fprintf(parserError, "ERROR at line no: %d RHS is %s\n\n", lineNo,$3 -> getDataType().c_str());
    }
    
    fprintf(parserLog, "at line no: %d expression :variable ASSIGNOP logic_expression\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
    
}
	   ;



			
logic_expression : rel_expression
{
    string str = $1 -> getName();
    
   $$ = new SymbolInfo($1);
   
    fprintf(parserLog, "at line no: %d logic_expression : rel_expression\n\n", lineNo);
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
    
    $$ = new SymbolInfo(str, "EXPRESSION", "int");  //result is always int here
    
    //code gen start
    string code = $1 -> code + $3 -> code;
    string temp = newTemp();
    
    code += "mov ax, " + $1 -> getName() + "\n";
    
    if($2 -> getName() == "&&") {
        code += "and ax, " + $3 -> getName() + "\n";
    }
    else {
        //"||"
        code += "or ax, " + $3 -> getName() + "\n";
    }
    code += "mov " + temp + ", ax\n";
    $$ -> code = code;
    $$ -> setName(temp);
    //code gen end


    fprintf(parserLog, "at line no: %d logic_expression : rel_expression LOGICOP rel_expression\n\n", lineNo);

    fprintf(parserLog, "%s\n\n", str.c_str());
}
		 ;
			
rel_expression	: simple_expression
{
    string str = $1 -> getName();
    

    $$ = new SymbolInfo($1);

    fprintf(parserLog, "at line no: %d rel_expression : simple_expression\n\n", lineNo);
fprintf(parserLog, "%s\n\n", str.c_str());
}
		| simple_expression RELOP simple_expression
{
    string str = $1 -> getName();
    str.append(" ");
    str.append($2 -> getName());
    str.append(" ");
    str.append($3 -> getName());


    $$ = new SymbolInfo(str, "EXPRESSION", "int"); //result is always int
    
    //code gen start
    string temp = newTemp();
    string label1 = newLabel();
    string label2 = newLabel();
    
    string code = $1 -> code;
    code += $3 -> code;
    code += "mov ax, " + $1 -> getName() + "\n";
    code += "cmp ax, " + $3 -> getName() + "\n";
    
    //basically set value of $$'s name to 0 if false and 1 if true
    if($2 -> getName() == "<") {
        code += "jl " + label1 + "\n";
    }
    else if($2 -> getName() == "<=") {
        code += "jle " + label1 + "\n";
    }
    else if($2 -> getName() == ">=") {
        code += "jge " + label1 + "\n";
    }
    else if($2 -> getName() == ">") {
        code += "jg " + label1 + "\n";
    }
    else if($2 -> getName() == "==") {
        code += "je " + label1 + "\n";
    }
    else {
        //"!="
        code += "jne " + label1 + "\n";
    }
    code += "mov " + temp + ", 0\n";
    code += "jmp " + label2 + "\n";
    
    code += label1 + ": mov " + temp + ", 1\n";
    code += label2 + ": \n";
    $$ -> code = code;
    $$ -> setName(temp);
    //code gen end
    fprintf(parserLog, "at line no: %d rel_expression : simple_expression RELOP simple_expression\n\n", lineNo);
fprintf(parserLog, "%s\n\n", str.c_str());
}
		;
				
simple_expression : term
{
    string str = $1 -> getName();
    
    $$ = new SymbolInfo($1);

    fprintf(parserLog, "at line no: %d simple_expression : term\n\n", lineNo);
fprintf(parserLog, "%s\n\n", str.c_str());

}
		  | simple_expression ADDOP term
{
    
    string str = $1 -> getName();
    str.append(" ");
    str.append($2 -> getName());
    str.append(" ");
    str.append($3 -> getName());
    
    $$ = new SymbolInfo(str, "EXPRESSION");
    
    
    //code gen start
    string code = $3 -> code + $1 -> code;
    code += "mov bx, " + $1 -> getName() + "\n";
    if($2 -> getName() == "+") {
        code += "add bx, " + $3 -> getName()+ "\n";
        
    }
    else {
        code += "sub bx, " + $3 -> getName()+ "\n";
    }
    
    string temp = newTemp();
    code += "mov " + temp + ", bx;\n";
    
    
    $$ -> code = code;
    $$ -> setName(temp); //so, in assignop, we know which variable the result of this operation is stored in
    
    //code gen end
    
    if($1 -> getDataType() == "int" && $3 -> getDataType() == "float") {
        parseErrors++;
        fprintf(parserError, "WARNING at line no: %d implicit type casting result to float\n\n", lineNo);
        $$ -> setDataType("float");
    }
    
    if($1 -> getDataType() == "float" && $3 -> getDataType() == "int") {
        parseErrors++;
        fprintf(parserError, "WARNING at line no: %d implicit type casting result to float\n\n", lineNo);
        $$ -> setDataType("float");
    }
    
    if($1 -> getDataType() == "void" || $3 -> getDataType() == "void") {
        parseErrors++;
        fprintf(parserError, "ERROR at line no: %d void function used in expression!!\n\n", lineNo);
        $$ -> setDataType("void");
    }
    
    

    fprintf(parserLog, "at line no: %d simple_expression : simple_expression ADDOP term\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
}
		  ;
					
term :	unary_expression
{
    string str = $1 -> getName();
    
    $$ = new SymbolInfo($1);

    fprintf(parserLog, "at line no: %d term : unary_expression\n\n", lineNo);
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
    
    //code gen start
    string code = $3 -> code;
    code += $1 -> code;
    code += "mov ax, " + $1 -> getName() + "\n";
    string temp = newTemp();
    if($2 -> getName() == "*") {
        code += "mov bx, " + $3 -> getName() + "\n";
        code += "mul bx\n";
        //result is double word stored in dx:ax
        code += "mov " + temp + ", ax\n";
    }
    else if($2 -> getName() == "/") {
        //dx:ax divided by 16 bit divisor
        
        
        code += "and dx, 0;\n";  //clear dx
        
        code += "mov bx, " + $3 -> getName() + "\n";
        code += "div bx\n";
        code += "mov " + temp + ", ax\n";
    }
    else {
        //modulus
        
        //dx:ax divided by 16 bit divisor
        
        
        code += "and dx, 0;\n";  //clear dx
        
        code += "mov bx, " + $3 -> getName() + "\n";
        code += "div bx\n";
        code += "mov " + temp + ", dx\n";
    }
    
    $$ -> setName(temp);
    $$ -> code = code;
    //code gen end
    
    
    if($1 -> getDataType() == "void" || $3 -> getDataType() == "void") {
        parseErrors++;
        fprintf(parserError, "ERROR at line no: %d void function used in expression!!\n\n", lineNo);
        $$ -> setDataType("void");
    }
    
    
    if($1 -> getDataType() == "float" || $3 -> getDataType() == "float" ) {
        $$ -> setDataType("float");
    }
    
    else {
        $$ -> setDataType("int");
    }
    
    


    fprintf(parserLog, "at line no: %d term : term MULOP unary_expression\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
    
    if($2 -> getName() == "%") {
        if($1 -> getDataType() != "int" || $3 -> getDataType() != "int") {
            parseErrors++;
            fprintf(parserError, "ERROR at line no: %d operands to mod operator are not integers!!\n\n", lineNo);
        }
        else {
            $$ -> setDataType("int");
        }
    }
    
    
}
     ;

unary_expression : ADDOP unary_expression   %prec UNARY_OP
{
    string str = $1 -> getName();
    str.append(" ");
    str.append($2 -> getName());
    
    
    $$ = new SymbolInfo(str, "EXPRESSION", $2 -> getDataType());
    
    //code gen start
    string code;
    if($1 -> getName() == "-") {
        //string temp = newTemp();
        code = $2 -> code;
        //code += "mov ax, " + $2 -> getName() + "\n";
        code += "neg  " + $2 -> getName() + "\n";
        //code += "mov " + temp + ", ax\n";
        
        //$$ -> setName(temp);
        
    } else {
        code = $2 -> code;
    }
    
    $$ -> code = code;
    //code gen end



    fprintf(parserLog, "at line no: %d unary_expression : ADDOP unary_expression\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
}
		 | NOT unary_expression     %prec UNARY_OP
{
    string str = "!";
    str.append($2 -> getName());
    

    $$ = new SymbolInfo(str, "EXPRESSION", $2 -> getDataType());
    
    //code gen
    string code = $2 -> code;
//    string temp = newTemp();

//    code += "mov ax, " + $2 -> getName() + "\n";
//    code += "not ax\n";
//    code += "mov " + temp + ", ax\n";

    code += "neg  " + $2 -> getName() + "\n";
//    $$ -> setName(temp);
    $$ -> code = code;
    //code gen end
    

    fprintf(parserLog, "at line no: %d unary_expression : NOT unary_expression  %prec UMINUS\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
}
		 | factor
{
    string str = $1 -> getName();
    
    $$ = new SymbolInfo($1);


    fprintf(parserLog, "at line no: %d unary_expression : factor\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());

}
		 ;
	
factor	: variable
{
    string str = $1 -> getName();
    
    $$ = new SymbolInfo($1);
    
    //code gen start
    if($1 -> getIsArray()) {
        string temp = newTemp();
        string code = "mov ax, " + $1 -> getName() + "[bx]\n";
        //bx has offset address of array
        code += "mov " + temp + ", ax\n";
        
        $$->setName(temp);
        $$ -> code += code;
    }
    else {
        
    }
    
    //code gen end


    fprintf(parserLog, "at line no: %d factor : variable\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", $1 -> getName().c_str());
}
    | ID LPAREN argument_list RPAREN
{
    //function call, so $$'s data type is functions return data type
    string str = $1 -> getName();
    str.append("(");
    str.append($3 -> getName());
    str.append(")");
    
    
    $$ = new SymbolInfo(str, "EXPRESSION");
    

    //code gen start
    
    //HANDLE CASE WHEN ARGUMENTS ARE ARRAY[5]'S LATER
    string code;
    //argument list is a symbolinfo*, contains parameters list of data types
    //will change parameters to contain names of temp variables
    
    code += $3 -> code;
    //cout << $3 -> code << endl;
    code += "push ax\n";
    code += "push bx\n";
    code += "push cx\n";
    code += "push dx\n";

    //vector<string> arguments = $3 -> getParameters();
    
    if(!arguments.empty()) {
        
        //remove if block here and test
//        if(arguments.back() -> getIsArray()) {
//            code += "mov dx, bx\n"; //because bx will be modified later (bx stores array offset)
//            code +=  "mov ax, " + currentScope + "_" + arguments.back() -> getName() + "[dx]\n";
//
//        }
        //else {
            code += "mov ax, " + arguments.back() -> getName() + "\n";
       // }
        
        arguments.pop_back();
    }
    
    if(!arguments.empty()) {
        
//        if(arguments.back() -> getIsArray()) {
//            code += "mov dx, bx\n"; //because bx will be modified later (bx stores array offset)
//            code +=  "mov ax, " + currentScope + "_" + arguments.back() -> getName() + "[dx]\n";
//
//        }
       // else {
            code += "mov bx, " + arguments.back() -> getName() + "\n";
       // }
        
        arguments.pop_back();
    }
    
    if(!arguments.empty()) {
        
//        if(arguments.back() -> getIsArray()) {
//            code += "mov dx, bx\n"; //because bx will be modified later (bx stores array offset)
//            code +=  "mov ax, " + currentScope + "_" + arguments.back() -> getName() + "[dx]\n";
//
//        }
//        else {
        code += "mov cx, " + currentScope + "_" + arguments.back() -> getName() + "\n";
//        }

        arguments.pop_back();
    }
    
//    if(!arguments.empty()) {
//        code += "mov dx, " + arguments.back() + "\n";
//        arguments.pop_back();
//    }

    code += "CALL " + $1 -> getName()  + "\n";
    
    string temp1 = newTemp();
    //code += "pop " + temp1 + "\n";  //proc pushes return value to stack top before returning by design
    
    
    
    //code += "pop dx\n";
    
    code += "mov " + temp1 + ", dx\n";  //or use dx for return value
    
    code += "pop dx\n";
    code += "pop cx\n";
    
    code += "pop bx\n";
    
    code += "pop ax\n";
    
    
    
    $$ -> code = code;
    
    $$ -> setName(temp1);
    

    //code gen end
    
    fprintf(parserLog, "at line no: %d factor : ID LPAREN argument_list RPAREN \n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
    
    SymbolInfo* inTable = table.lookUp($1 -> getName());

    if(!inTable) {
        parseErrors++;
        fprintf(parserError,"ERROR at line No: %d function %s not declared in scope\n\n",lineNo, $2 -> getName().c_str());
    }
    else {
        
        if(!inTable -> getIsFunction()) {
            parseErrors++;
            fprintf(parserError,"ERROR at line no %d: %s is not a function!\n\n", lineNo,inTable -> getName().c_str());
        }
        else {
            if(inTable -> getIsDeclaration()) {
                parseErrors++;
                fprintf(parserError, "ERROR at line no %d: function only declared, not defined!\n\n", lineNo);
            }
            //retrieve func info here and assign to $$
            if(inTable -> getParameters() == $3 -> getParameters()) {
                
                $$ -> setDataType(inTable -> getDataType());
            }
            else {
                parseErrors++;
                fprintf(parserError, "ERROR at line no %d: function call doesnt match parameters in func definition!\n\n", lineNo);
            }
        }
        
    }

}
    | LPAREN expression RPAREN
{
    string str = "(";
    str.append($2 -> getName());
    str.append(")");
    

    $$ = new SymbolInfo(str, "EXPRESSION", $2 -> getDataType());
    
    //code gen start
    $$ -> setName($2 -> getName());
    $$ -> code = $2 -> code;
    
    //code gen end


    fprintf(parserLog, "at line no: %d factor : LPAREN expression RPAREN\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
}
	| CONST_INT
{
    
    $$ = new SymbolInfo($1);

    fprintf(parserLog, "At Line no: %d factor : CONST_INT\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", $1 -> getName().c_str());
}
	| CONST_FLOAT
{

    $$ = new SymbolInfo($1);


    fprintf(parserLog, "at line no: %d factor : CONST_FLOAT\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", $1 -> getName().c_str());
    //fprintf(parserLog, "%s\n\n", str.c_str());
}
	| variable INCOP
{
    string str = $1 -> getName();
    str.append(" ");
    str.append($2 -> getName());
    
    $$ = new SymbolInfo(str, "EXPRESSION", $1 -> getDataType());
    
    //code gen start
    
    
    //TASK: store result in temp and propagate
    // what does "perform incop depending on whether the varaible is an array or not" mean?
    string code = $1 -> code;
    
    //string temp = newTemp();
    if($1 -> getIsArray()) {
        //bx has offset address
           if($2 -> getName() == "++") {
               code = "inc " + $1 -> getName() + "[bx]\n";
           }
           else {
               code = "dec " + $1 -> getName() + "[bx]\n";
           }
           
           string temp = newTemp();
           
           code += "mov ax, " + $1 -> getName() + "[bx]\n";
           code += "mov " + temp + ", ax\n";
           
           $$ -> setName(temp);
    }
    else {
        if($2 -> getName() == "++") {
            code = "inc " + $1 -> getName() + "\n";
        }
        else {
            code = "dec " + $1 -> getName() + "\n";
        }
        
        $$ -> setName($1 -> getName());

    }
    
    $$ -> code = code;
    
    //code gen end
    

    fprintf(parserLog, "at line no: %d factor : variable INCOP\n\n", lineNo);
    fprintf(parserLog, "%s %s\n\n", $1 -> getName().c_str(), $2 -> getName().c_str());
}
	;
	
argument_list : arguments
{
    string str = $1 -> getName();
    
    $$ = new SymbolInfo(str, "ARGUMENTS");
    
    $$ -> setParameters($1 -> getParameters());
    
    //code gen
    $$ -> code = $1 -> code;


    fprintf(parserLog, "at line no: %d argument_list : arguments\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
}
    |
{
    
    
    
    $$ = new SymbolInfo("", "ARGUMENTS");
    fprintf(parserLog, "at line no: %d argument_list : <empty>\n\n", lineNo);
    fprintf(parserLog, "\n\n");
}
			  ;
	
arguments : arguments COMMA logic_expression
{
    
    string str = $1 -> getName();
    str.append(", ");
    str.append($3 -> getName());
    
    $$ = new SymbolInfo(str, "ARGUMENTS");
    
    
    
    //$$ -> addParameter($3 -> getDataType());
    
    //code gen start
    string code = $1 -> code + $3 -> code;
    cout << "comma " + $3 -> code << endl;
    $$ -> setParameters($1 -> getParameters());
    $$ -> addParameter($1 -> getDataType());
    $$ -> code = code;
    
    arguments.push_back($3);
    //code gen end


    fprintf(parserLog, "at line no: %d arguments : arguments COMMA logic_expression\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
}
	      | logic_expression
{
    string str = $1 -> getName();
    
    $$ = new SymbolInfo(str, "ARGUMENTS");
    
    //$$ -> addParameter($1 -> getDataType());
    
    //code gen start
    
    cout << "alone " + $1 -> code << endl;
    $$ -> code = $1 -> code;
    $$ -> addParameter($1 -> getDataType());
    arguments.push_back($1);
    //code gen end
    
    
    
    fprintf(parserLog, "at line no: %d arguments : logic_expression\n\n", lineNo);
    fprintf(parserLog, "%s\n\n", str.c_str());
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
    codeFile = fopen("code.asm", "w");
    opCodeFile = fopen("optimizedCode.asm", "w");

    parserLog=fopen(argv[2],"w");
    parserError=fopen(argv[3],"w");
 

    yyin=inputFile;
    yyparse();

    fclose(parserLog);
    fclose(parserError);
    
    fclose(scannerToken);
    fclose(scannerLog);
    fclose(yyin);
    fclose(codeFile);
    return 0;
}

