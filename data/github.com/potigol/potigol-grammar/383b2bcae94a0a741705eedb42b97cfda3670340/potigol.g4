/*  Potigol - Grammar
    Copyright (C) 2014  Leonardo Lucena

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

/*
    _____      _   _             _
   |  __ \    | | (_)           | |
   | |__) |__ | |_ _  __ _  ___ | |
   |  ___/ _ \| __| |/ _` |/ _ \| |
   | |  | (_) | |_| | (_| | (_) | |
   |_|   \___/ \__|_|\__, |\___/|_|
                      __/ |
                     |___/
 */


grammar potigol;

// Parser

prog: inst* ;

inst: decl | expr | bloco | cmd;

// Comando
cmd : 'escreva' expr                  # escreva
    | 'imprima' expr                  #imprima
    | id1 ':=' expr                   # atrib_simples
    | id2 ':=' expr2                  # atrib_multipla
    | expr'['expr']' ('='|':=') expr  # set_vetor
    ;

// Declaracao
decl: decl_valor | decl_funcao | decl_tipo | decl_uso;

decl_valor:
      id1 '=' expr                    # valor_simples
    | id2 '=' expr2                   # valor_multiplo
    | 'var' id1 (':='| '=') expr      # decl_var_simples
    | 'var' id2 (':='| '=') expr2     # decl_var_multipla
    ;

decl_funcao:
      ID '(' dcls ')' (':' tipo)? '=' expr        # def_funcao
    | ID '(' dcls ')' (':' tipo)? exprlist 'fim'  # def_funcao_corpo
    ;

decl_tipo:
      'tipo' ID '=' tipo                  # alias
    | 'tipo' ID (dcl|decl_funcao)* 'fim'  # classe
    ;
    
decl_uso: 'use' STRING ;

dcl: id1 ':' tipo ;
dcls: (dcl (',' dcl)* )? ;

dcl1: ID
    | '(' expr2 ')'
    | '(' dcls ')'
    ;

tipo: ID                                  # tipo_simples
    | '(' tipo2 ')'                       # tipo_tupla
    | ID '[' tipo ']'                     # tipo_generico
    | tipo '=>' tipo                      # tipo_funcao
    ;

// Expressao
expr:
	  literal                             # lit
    | expr '.' ID ('(' expr1 ')')?        # chamada_metodo
    | expr '(' expr1? ')'                 # chamada_funcao
    | expr '[' expr ']'                   # get_vetor
    | <assoc=right> expr '^' expr         # expoente
    | <assoc=right> expr '::' expr        # cons
    | expr 'formato' expr                 # formato
    | ('+'|'-') expr                      # mais_menos_unario
    | expr ('*'|'/'|'div'|'mod') expr     # mult_div
    | expr ('+'|'-') expr                 # soma_sub
    | expr ('>'|'>='|'<'|'<='|'=='|'<>') expr   # comparacao
    | ('nao'|'n\u00e3o') expr             # nao_logico
    | expr 'e' expr                       # e_logico
    | expr 'ou' expr                      # ou_logico
    | dcl1 '=>' inst+                     # lambda
	| decisao							  # decis
	| repeticao							  # laco
    | '(' expr ')'                        # paren
    | '(' expr2 ')'                       # tupla
    | '[' expr1? ']'                      # lista
    ;
    
literal:
      ID                                  # id
    | STRING                              # texto
    | INT                                 # inteiro
    | FLOAT                               # real
    | CHAR                                # char
    | BOOLEANO                            # booleano
    ;
    
    
// Decisao
decisao: se | escolha ;

se: 'se' expr entao senaose* senao? 'fim' ;
entao:   ('entao'  |'ent\u00e3o'  )? exprlist;
senaose: ('senaose'|'sen\u00e3ose')  expr entao;
senao:   ('senao'  |'sen\u00e3o'  )  exprlist;

escolha: 'escolha' expr caso+ 'fim' ;
caso: 'caso' expr ('se' expr)? '=>' exprlist;

// Repeticao    
repeticao: para_faca | para_gere | enquanto ;

para_faca: 'para' faixas ('se' expr)? bloco;
para_gere: 'para' faixas ('se' expr)? 'gere' exprlist 'fim' ;
enquanto: 'enquanto' expr bloco ;

faixa: ID 'em' expr
     | ID 'de' expr ('ate'|'at\u00e9') expr ('passo' expr)?
     ;

faixas: faixa (',' faixa)*;

bloco: ('faca' | 'fa\u00e7a') exprlist 'fim' ;

// Outros
expr1: expr (',' expr)* ;
expr2: expr (',' expr)+ ;
id1 : ID (',' ID)* ;
id2 : ID (',' ID)+ ;

tipo2 : tipo (',' tipo)+ ;

exprlist: inst* ;

// Lexer
ID: (ALPHA|ACENTO) (ALPHA|ACENTO|DIGIT)* ;

fragment
ALPHA: 'a' .. 'z' | 'A' .. 'Z'| '_' ;
fragment
ACENTO : '\u00a1' .. '\ufffc' ;

INT : DIGIT+ ;

FLOAT
    : DIGIT+ '.' DIGIT*
    |        '.' DIGIT+
    ;
fragment
DIGIT: '0'..'9' ;

STRING : '"' (ESC | .) *? '"' ;
CHAR : '\''.'\'';

BOOLEANO: 'verdadeiro' | 'falso' ;

fragment
ESC : '\\"' | '\\\\' ;

COMMENT : '#' .*? '\r'? '\n' -> skip ;
WS : (' '|'\t'|'\r'|'\n')+ -> skip ;

NL : '\r\n' | '\n' ;
