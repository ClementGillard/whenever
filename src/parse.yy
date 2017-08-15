%language "C++"

%define parse.error verbose
%define parse.trace

%define api.value.type variant
%define api.token.constructor

%parse-param {std::stringstream& output} {std::vector<int>& funcs}

%{
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include "parse.hh"

#define YY_DECL extern yy::parser::symbol_type yylex()
YY_DECL;
extern FILE* yyin;
%}

%token<std::string> BOOLOP "Boolean operator"
%token<std::string> NUMOP "numeric operator"
%token<std::string> CINSTR "C instruction"
%token END 0 "end-of-file"
%token EOL
%token<int> NUMBER
%token<std::string> STRING

%token AGAIN
%token DEFER
%token FORGET
%token PRINT
%token N
%token READ

%token SEMICOLON ';'
%token COMMA ','
%token SHARP '#'
%token LPAREN '('
%token RPAREN ')'
%token PLUS '+'
%token MINUS '-'
%token TIMES '*'
%token DIV '/'
%token BANG '!'

%left PLUS MINUS TIMES DIV

%start program

%type<std::string> statement
%type<std::string> boolean boolean2
%type<std::string> printable printable2
%type<std::string> a_number formula not_a_number
%type<std::string> lineop lineops
%type<int> lineno

%%

program:
  %empty
| line EOL program
;

line:
  lineno statement SEMICOLON
  {
    output << "\n"
              "#undef LINENO\n"
              "#define LINENO " << $1 << "\n"
              "void line" << $1 << "()\n"
              "{\n"
           << $2
           << "\nremove(" << $1 << ");\n"
                "}\n";
    funcs.push_back($1);
  }
;

lineno:
  NUMBER { $$ = $1; }
;

statement:
  lineops { $$ = $1; }
/* defer : if condition, do not execute, do not remove from list */
| DEFER LPAREN boolean RPAREN statement
  { $$ = "if (" + $3 + ") return;\n" + $5; }
/* again : execute ; if condition, do not remove from list */
| AGAIN LPAREN boolean RPAREN statement
  { $$ = $5 + "if (" + $3 + ") return;\n"; }
/* forget : if condition, do not execute ; remove */
| FORGET LPAREN boolean RPAREN statement
  {
    std::clog << "\"forget\" compound statements are DEPRECATED.\n";
    $$ = "if (" + $3 + ") { remove(LINENO); return; }\n" + $5;
  }
| PRINT LPAREN printable RPAREN { $$ = "std::cout << " + $3 + " << '\\n';\n"; }
| CINSTR { $$ = $1 + ";\n"; }
;

lineops:
  lineop { $$ = $1; }
| lineops COMMA lineop { $$ = $1 + $3; }
;

lineop:
  lineno
  {
    if ($1)
      $$ = "add(" + std::to_string($1) + ");\n";
  }
| MINUS lineno
  {
    if ($2)
      $$ = "remove(" + std::to_string($2) + ");\n";
  }
| lineno SHARP NUMBER
  {
    if ($1 && $3)
      $$ = "add(" + std::to_string($1) + ", " + std::to_string($3) + ");\n";
  }
| MINUS lineno SHARP NUMBER
  {
    if ($2 && $4)
      $$ = "remove(" + std::to_string($2) + ", " + std::to_string($4) + ");\n";
  }
| lineno SHARP MINUS NUMBER
  {
    if ($1 && $4)
      $$ = "remove(" + std::to_string($1) + ", " + std::to_string($4) + ");\n";
  }
| MINUS lineno SHARP MINUS NUMBER
  {
    if ($2 && $5)
      $$ = "add(" + std::to_string($2) + ", " + std::to_string($5) + ");\n";
  }
| lineno SHARP not_a_number
  {
    if ($1)
      $$ = "{\n"
            "  int count = (" + $3 + ");\n"
            "  if (count < 0)\n"
            "    remove(" + std::to_string($1) + ", -count);\n"
            "  if (count > 0)\n"
            "    add(" + std::to_string($1) + ", count);\n"
            "}\n";
  }
| MINUS lineno SHARP not_a_number
  {
    if ($2)
      $$ = "{\n"
            "  int count = -(" + $4 + ");\n"
            "  if (count < 0)\n"
            "    remove(" + std::to_string($2) + ", -count);\n"
            "  if (count > 0)\n"
            "    add(" + std::to_string($2) + ", count);\n"
            "}\n";
  }
| lineno SHARP MINUS not_a_number
  {
    if ($1)
      $$ = "{\n"
            "  int count = -(" + $4 + ");\n"
            "  if (count < 0)\n"
            "    remove(" + std::to_string($1) + ", -count);\n"
            "  if (count > 0)\n"
            "    add(" + std::to_string($1) + ", count);\n"
            "}\n";
  }
| MINUS lineno SHARP MINUS not_a_number
  {
    if ($2)
      $$ = "{\n"
            "  int count = (" + $5 + ");\n"
            "  if (count < 0)\n"
            "    remove(" + std::to_string($2) + ", -count);\n"
            "  if (count > 0)\n"
            "    add(" + std::to_string($2) + ", count);\n"
            "}\n";
  }
;

boolean:
  boolean2 { $$ = $1; }
| boolean BOOLOP boolean2 { $$ = $1 + $2 + $3; }
;

boolean2:
  lineno { $$ = "(!!N(" + std::to_string($1) + "))"; }
| not_a_number { $$ = "(!!(" + $1 + "))"; }
| BANG boolean2 { $$ = '!' + $2; }
| LPAREN boolean RPAREN { $$ = '(' + $2 + ')'; }
| a_number NUMOP a_number { $$ = $1 + $2 + $3; }
;

printable:
  printable2 { $$ = $1; }
| printable PLUS printable2 { $$ = $1 + " << " + $3; }
;

printable2:
  STRING { $$ = $1; }
| not_a_number { $$ = $1; }
;

a_number:
  NUMBER { $$ = std::to_string($1); }
| not_a_number { $$ = $1; }
| formula { $$ = $1; }
;

formula:
  MINUS a_number { $$ = '-' + $2; }
| a_number PLUS a_number { $$ = $1 + '+' + $3; }
| a_number MINUS a_number { $$ = $1 + '-' + $3; }
| a_number TIMES a_number { $$ = $1 + '*' + $3; }
| a_number DIV a_number { $$ = $1 + '/' + $3; }
| LPAREN formula RPAREN { $$ = '(' + $2 + ')'; }
;

not_a_number:
  READ LPAREN RPAREN { $$ = "read()"; }
| N LPAREN a_number RPAREN { $$ = "N(" + $3 + ')'; }
| PLUS a_number { $$ = $2; }
;

%%

void yy::parser::error(const std::string& msg) {
  std::cout << std::endl;
  std::clog << msg << '\n';
}

std::string parse_whenever()
{
  std::stringstream output;
  std::vector<int> funcs;
  yy::parser parser(output, funcs);

  while (!feof(yyin))
    parser.parse();

  std::stringstream funclist, namelist;

  funclist << "func funcs[] = {";
  namelist << "int names[] = {";

  if (!funcs.empty())
  {
    funclist << "line" << funcs[0];
    namelist << funcs[0];
    for (auto it = std::next(funcs.begin()); it != funcs.end(); ++it)
    {
      funclist << ", line" << *it;
      namelist << ", " << *it;
    }
  }

  funclist << "};\n";
  namelist << "};\n";

  output << "\n"
            "unsigned nfuncs = " << funcs.size() << ";\n";
  return output.str() + funclist.str() + namelist.str();
}
