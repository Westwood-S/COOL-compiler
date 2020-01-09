/*
 *  63/63
 */
 
/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
 
 %{ 
 #include <cool-parse.h> 
 #include <stringtab.h> 
 #include <utilities.h> 
 #include <string>  
 #include <cstring>  
 
 /* The compiler assumes these identifiers. */ 
 #define yylval cool_yylval 
 #define yylex  cool_yylex  
 
 /* Max size of string constants */ 
 #define MAX_STR_CONST 1025 
 #define YY_NO_UNPUT   /* keep g++ happy */  
 
 extern FILE *fin; /* we read from this file */  
 /* define YY_INPUT so we read from the FILE fin:  
  * This change makes it possible to use this scanner in  
  * the Cool compiler.  
  */ 
 #undef YY_INPUT 
 #define YY_INPUT(buf,result,max_size) \
         if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \   
                 YY_FATAL_ERROR( "read() in flex scanner failed");  
           
char string_buf[MAX_STR_CONST]; /* to assemble string constants */ 
char *string_buf_ptr;  

extern int curr_lineno; 
extern int verbose_flag;  

extern YYSTYPE cool_yylval;  

/*  
 *  Add Your own definitions here  
 */  
 
int COMMENT_DEP=0;   

%}  

/*  
 * Define names for regular expressions here. 
 */  

%Start COMMENT 
%Start INLINE_COMMENT 
%Start STRING 
%Start STRING_ERROR

DARROW          =>  
LE              <=
ASSIGN          <- 
  
CLASS [Cc][Ll][Aa][Ss][Ss] 
ELSE [Ee][Ll][Ss][Ee] 
IF [Ii][Ff] 
FI [Ff][Ii] 
IN [Ii][Nn] 
INHERITS [Ii][Nn][Hh][Ee][Rr][Ii][Tt][Ss] 
LET [Ll][Ee][Tt] 
LOOP [Ll][Oo][Oo][Pp] 
POOL [Pp][Oo][Oo][Ll] 
THEN [Tt][Hh][Ee][Nn] 
WHILE [Ww][Hh][Ii][Ll][Ee] 
CASE [Cc][Aa][Ss][Ee] 
ESAC [Ee][Ss][Aa][Cc] 
OF [Oo][Ff] 
NEW [Nn][Ee][Ww] 
ISVOID [Ii][Ss][Vv][Oo][Ii][Dd] 
INTCONST [0-9]+ 
STRCONST \"[^"\n]*\"
BOOLCONST  t[Rr][Uu][Ee]|f[Aa][Ll][Ss][Ee]
TYPEID [A-Z][A-Za-z0-9_]* 
OBJECTID [a-z][a-zA-Z0-9_]* 
NOT [Nn][Oo][Tt] 

PARENSTAR "(*"
STARPAREN "*)"
HYPHEN --
SYMBOLS [-%|^.,:;+*\/><}{)(@=~]+ 
WHITESPACE [ \t\r\f\v]+  

%%ls    

/*   
 *  Nested comments   
 */  
 
{PARENSTAR} {   
  COMMENT_DEP=1;   
  BEGIN COMMENT; 
}  

{HYPHEN} {
  BEGIN INLINE_COMMENT; 
}  

{STARPAREN} {   
  cool_yylval.error_msg="Unmatched *)";   
  return ERROR; 
}  

<COMMENT>[^*()\n]*  ; 
<COMMENT>\([^*\n]*  ; 
<COMMENT>\*[^*)\n]*  ; 
<COMMENT>\)  ;  
<COMMENT>\n { curr_lineno++; }

<COMMENT><<EOF>> {   
  cool_yylval.error_msg="EOF in comment";  
  BEGIN 0;
  return ERROR; 
}  

<COMMENT>{PARENSTAR}  {   
  COMMENT_DEP++; 
}  

<COMMENT>{STARPAREN}  {   
  COMMENT_DEP--;   
  if (COMMENT_DEP==0) { BEGIN 0; } 
}  

<INLINE_COMMENT>\n {   
  curr_lineno++;   
  BEGIN 0; 
}  

<INLINE_COMMENT>[^\n]* ;   

/*   
 *  The multiple-character operators.   
 */  
 
 
{DARROW}    { return (DARROW); }  
{LE}        { return (LE); } 
{ASSIGN}    { return (ASSIGN); }  

/*   
 * Keywords are case-insensitive except for the values true and false,   
 * which must begin with a lower-case letter.   
 */   
 
{CLASS}     { return (CLASS); } 
{ELSE}      { return (ELSE); } 
{FI}        { return (FI); } 
{IF}        { return (IF); } 
{IN}        { return (IN); } 
{INHERITS}  { return (INHERITS); } 
{LET}       { return (LET); } 
{LOOP}      { return (LOOP); } 
{POOL}      { return (POOL); } 
{THEN}      { return (THEN); } 
{WHILE}     { return (WHILE); } 
{CASE}      { return (CASE); } 
{ESAC}      { return (ESAC); } 
{OF}        { return (OF); } 
{NEW}       { return (NEW); } 
{ISVOID}    { return (ISVOID); } 
{NOT}       { return (NOT); } 

{INTCONST} {   
  cool_yylval.symbol=inttable.add_string(yytext);   
  return INT_CONST; 
}  

{SYMBOLS} {   
  return (int)yytext[0]; 
}   

{WHITESPACE} ;  

{TYPEID} {   
  cool_yylval.symbol=idtable.add_string(yytext);   
  return (TYPEID); 
}  

{OBJECTID} {   
  cool_yylval.symbol=idtable.add_string(yytext);   
  return (OBJECTID); 
}  

{BOOLCONST} {
  for (int i=0; yytext[i]; i++) {
    yytext[i]=tolower(yytext[i]);
  }
  if (strcmp("true", yytext)==0) { cool_yylval.boolean=true; }
  else { cool_yylval.boolean=false; }
  return BOOL_CONST;
}

. {   
  cool_yylval.error_msg=yytext;   
  return ERROR; 
}  

\n { curr_lineno++; }    

/*   
 *  String constants (C syntax)   
 *  Escape sequence \c is accepted for all characters c. Except for    
 *  \n \t \b \f, the result is c.   
 *   
 */  
 
\" { 
  string_buf_ptr=string_buf;
  BEGIN STRING; 
}  

<STRING>\" {   
  BEGIN 0;   
  *string_buf_ptr='\0';   
  if (string_buf_ptr >= string_buf + MAX_STR_CONST) {     
    cool_yylval.error_msg="String constant too long";     
    return ERROR;   
  }   
  else {     
    cool_yylval.symbol=stringtable.add_string(string_buf);     
    return STR_CONST;   
  } 
}  

<STRING>\\b { *string_buf_ptr++ = '\b';} 
<STRING>\\t { *string_buf_ptr++ = '\t';} 
<STRING>\\n { *string_buf_ptr++ = '\n';} 
<STRING>\\f { *string_buf_ptr++ = '\f';}  
<STRING>\\\0 { BEGIN STRING_ERROR;}
<STRING>\\(.|\n) { *string_buf_ptr++ = yytext[1]; }
<STRING>[^"\\\0\n]* {   
  if (string_buf_ptr + sizeof(char)*strlen(yytext)<string_buf + MAX_STR_CONST) {     
    strcpy(string_buf_ptr,yytext);   
  }   
  string_buf_ptr+=sizeof(char)*strlen(yytext); 
}  

<STRING><<EOF>> {    
  BEGIN 0;    
  cool_yylval.error_msg="EOF in string constant";    
  return ERROR; 
}  

<STRING>\n {   
  BEGIN 0;   
  curr_lineno++;
  cool_yylval.error_msg="Unterminated string constant";    
  return ERROR; 
}   

<STRING_ERROR>\" {
  cool_yylval.error_msg= "String contains null character";
  BEGIN 0;
  return ERROR;
}

%%



