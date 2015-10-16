
/* Bison specification for DoC221 language 
   ------------------------------------------------------------------------- 
   http://www.gnu.org/software/bison/manual/bison.html
*/

/* BISON PROLOGUE --------------------------------------------------------- */

%{

#include "astnode.h"
#include <cstdio>
#include <cstdlib>

extern int yylex();  /* Lexical analyser generated by flex */

void yyerror(const char *message) {  /* action on encountering an error */
  std::printf("Error: %s\n", message);
  std::exit(1); 
}
	
StatSeq *ast;     /* Pointer to root of Abstract Syntax Tree */

%}

/* BISON DECLARATIONS  ---------------------------------------------------- */

/* Define all possible syntactic values */
/* %define api.value.type variant - need if  proper C++ typing is used */

%union {
  int           token;
  std::string   *string;

  Identifier 		*id;
  StatSeq 		*statseq;
  Statement 		*statement;
  Expression 		*expression;
  ExpressionList 	*exprlist;
  VariableList   	*varlist;
  VariableDeclaration 	*vardec;
  FunctionDeclaration 	*fundec;
}

%token <token>  BEGINN END IF THEN ELSE WHILE DO REPEAT UNTIL READ WRITE
%token <token>  BECOMES EQUALS LESSTHAN PLUS MINUS STAR SLASH 
%token <token>  LPAREN RPAREN SEMICOLON COMMA ERROR
%token <string> INTEGER  IDENTIFIER

%type <id>	   identifier
%type <statseq>    program statement_sequence  
%type <statement>  statement begin_statement assign_statement  
%type <statement>  if_statement while_statement 
%type <statement>  repeat_statement read_statement write_statement
%type <expression> expression  number
%type <exprlist>   actual_parameters
%type <varlist>    formal_parameters
%type <token>	   comparator
%type <vardec>	   variable_declaration
%type <fundec>     function_declaration

/* Precedence of operators */
%left PLUS MINUS STAR SLASH 

/* Start symbol. If omitted will default to first non-terminal symbol */
%start program 

%% /* BISON GRAMMAR RULES ------------------------------------------------- */

/* Basic form a grammar rule is:
  
   non-terminal: 
     alternative1 {action1}
   | alternative2 {action2}
     ...
   | alternativeN {actionN}
   ;
  
   Alternative is a sequence of terminals and non-terminals. 
   Action is a piece of C/C++/Java code that is executed when alternative is 
   recognised. Within the code $1,$2,$N refer to the first, second..., Nth 
   symbol on the RHS. $$ refers to the  non-terminal (LHS). 
*/   

program: 					  /* program */
  statement_sequence END
  { ast = $1; } 
;

statement_sequence:                               /* statement_sequence */ 
  statement 
  { $$ = new StatSeq(); 
    $$->statements.push_back($1);
  }
| statement_sequence SEMICOLON statement
  { $1->statements.push_back($3); 
  }
;

statement:                                        /* statement */ 
  begin_statement 
  { $$ = $1; }                                        
| if_statement 
  { $$ = $1; }
| while_statement 
  { $$ = $1; }
| repeat_statement 
  { $$ = $1; }
| read_statement   
  { $$ = $1; }
| write_statement  
  { $$ = $1; }
| assign_statement 
  { $$ = $1; }                                       
| variable_declaration
  { $$ = $1; }
| function_declaration
  { $$ = $1; }
| error            
  { $$ = NULL; }
;
     
begin_statement:                                  /* begin_statement */
  BEGINN statement_sequence END
  { $$ = $2; }
;

assign_statement:                                 /* assignment_statement */
  identifier BECOMES expression
  { $$ = new Assignment(*$1, *$3); }
;

if_statement:                                     /* if_statement */
  IF expression THEN statement_sequence END
  { $$ = new IfStatement(*$2, *$4); }
| IF expression THEN statement_sequence ELSE statement_sequence END
  { $$ = new IfStatement(*$2, *$4, $6); }
;

while_statement:                                  /* while_statement */
  WHILE expression DO statement_sequence END
  { $$ = new WhileStatement(*$2, *$4); }
;
                                                           
repeat_statement:                                 /* repeat_statement */
  REPEAT statement_sequence UNTIL expression
  { $$ = new RepeatStatement(*$2, *$4); }
;

read_statement:                                   /* read_statement */
  READ identifier
  { $$ = new ReadStatement(*$2); }
;

write_statement:                                  /* write_statement */
  WRITE expression 
  { $$ = new WriteStatement(*$2); }
;

expression:                                       /* expression */
  identifier 
  { $$ = $1; }
| number
  { $$ = $1; }
| expression STAR expression 
  { $$ = new Operator(*$1, $2, *$3); }
| expression SLASH expression 
  { $$ = new Operator(*$1, $2, *$3); }
| expression PLUS expression 
  { $$ = new Operator(*$1, $2, *$3); }
| expression MINUS expression 
  { $$ = new Operator(*$1, $2, *$3); }
| expression comparator expression 
  { $$ = new Operator(*$1, $2, *$3); }
| LPAREN expression RPAREN 
  { $$ = $2; }
| identifier LPAREN actual_parameters RPAREN 
  { $$ = new FunctionCall(*$1, *$3); 
    delete $3; 
  }
;

identifier:                                      /* identifier */
  IDENTIFIER 
  { $$ = new Identifier(*$1); 
    delete $1; 
  }
;

number:                                		/* number */
  INTEGER 
  { $$ = new Number(atol($1->c_str())); 
    delete $1; 
  }
;

comparator:                                     /* comparator */  
  EQUALS 
| LESSTHAN
;


/* EXTRAS ---------------------------------------------------------------- */
	
variable_declaration: 
  identifier identifier 
  { $$ = new VariableDeclaration(*$1, *$2); }
| identifier identifier EQUALS expression 
  { $$ = new VariableDeclaration(*$1, *$2, $4); }
;

function_declaration: 
  identifier identifier LPAREN formal_parameters RPAREN statement_sequence
  { $$ = new FunctionDeclaration(*$1, *$2, *$4, *$6); 
    delete $4; 
  }
;
	
formal_parameters: 
  /* empty */  
  { $$ = new VariableList(); }
| variable_declaration 
  { $$ = new VariableList(); 
    $$->push_back($1); 
  }
| formal_parameters COMMA variable_declaration 
  { $1->push_back($3); 
  }
;

actual_parameters: 
  /* empty */  
  { $$ = new ExpressionList(); }
| expression 
  { $$ = new ExpressionList(); 
    $$->push_back($1); 
  }
| actual_parameters COMMA expression  
  { $1->push_back($3); }
;


%% /* BISON EPILOGUE ------------------------------------------------------ */

/* Empty :-( */



