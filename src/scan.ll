/* Header */
%option noinput nounput noyywrap

%{

#include <iostream>

#include "parse.hh"

//#define YY_DECL extern yy::parser::symbol_type yylex(yy::parser::semantic_type*)
#define YY_DECL extern yy::parser::symbol_type yylex()

%}

%x CINSTR_STATE

STR_PRE (u8|u|U|L)?
SPACE   [ \t\v\f]+
STR_ESC (\\(['"\?\\abfnrtv]|[0-7]{1,3}|x[a-fA-F0-9]+))

%%

SPACE    { continue; }
\n       { return yy::parser::make_EOL(); }

[0-9]+   { return yy::parser::make_NUMBER(strtol(yytext, nullptr, 0)); }

"=="     { return yy::parser::make_NUMOP(yytext); }
"!="     { return yy::parser::make_NUMOP(yytext); }
"<="     { return yy::parser::make_NUMOP(yytext); }
">="     { return yy::parser::make_NUMOP(yytext); }
"<"      { return yy::parser::make_NUMOP(yytext); }
">"      { return yy::parser::make_NUMOP(yytext); }

"&&"     { return yy::parser::make_BOOLOP(yytext); }
"||"     { return yy::parser::make_BOOLOP(yytext); }

"again"  { return yy::parser::make_AGAIN(); }
"defer"  { return yy::parser::make_DEFER(); }
"forget" { return yy::parser::make_FORGET(); }
"print"  { return yy::parser::make_PRINT(); }
"N"      { return yy::parser::make_N(); }
"read"   { return yy::parser::make_READ(); }

";"      { return yy::parser::make_SEMICOLON(); }
","      { return yy::parser::make_COMMA(); }
"#"      { return yy::parser::make_SHARP(); }
"("      { return yy::parser::make_LPAREN(); }
")"      { return yy::parser::make_RPAREN(); }
"+"      { return yy::parser::make_PLUS(); }
"-"      { return yy::parser::make_MINUS(); }
"*"      { return yy::parser::make_TIMES(); }
"/"      { return yy::parser::make_DIV(); }
"!"      { return yy::parser::make_BANG(); }

({STR_PRE}\"([^"\\\n]|{STR_ESC})*\"{SPACE}*)+ { return yy::parser::make_STRING(yytext); }

.       { std::cout << "Found '" << yytext << "' (" << static_cast<unsigned>(*yytext) << ")\n"; continue; /* BEGIN(CINSTR_STATE);*/ }

<CINSTR_STATE>
{
  ";" { BEGIN(INITIAL); return yy::parser::make_CINSTR(yytext); }
  .   {}
}

<<EOF>> { return yy::parser::make_END(); }

%%
