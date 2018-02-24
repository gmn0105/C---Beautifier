%option noyywrap
%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include <assert.h>
	#define INDENT (4)
	int line = 1;
	int column = 4;
	int paren = 0;

	void indent();
	void write_html();
	void write_html_char(int);
	void write_string();
	void write_char();
	void write_oct();
	void write_hex();
	void write_int();
	void write_fp();
	void write_id();
	void write_begin();
	void write_end();
	void write_open();
	void write_close();
	void write_bopen();
	void write_bclose();
	void write_sep();
	void write_op();
	void write_inline();
	void write_comment();
	void write_directive();
	void error();

	#define MAXSYMBOLS 200
	struct entry{
		char *lexptr;
		int token;
	};
	struct entry symtable[MAXSYMBOLS];
	int lookup(char *lexeme);
	int insert(char *a, int token);
	void init(); 
	int ind = 0; 
	
%}

quote 		'
ditto   	\"
back    	\\
digit   	[0-9]
exp 		[eE]([+-]?)({digit}+)
hex 		[0-9a-fA-F]
alpha   	[a-zA-Z_]
ch  		[^\\'\"\n]

%%
{ditto}({back}{ch}|{back}{back}|{back}{quote}|{back}{ditto}|{ch}|{quote})*{ditto}   	{ write_string(); }
{quote}({back}{ch}|{back}{back}|{back}{quote}|{back}{ditto}|{ch}|{ditto}){quote}    	{ write_char(); }
0([0-7]+)   { write_oct();}
0[xX]({hex})+   { write_hex(); }
{digit}+    { write_int(); }
{digit}+"."({digit}*)({exp}?) { write_fp();  }
{alpha}({alpha}|{digit})*(" "|"\n")? { write_id();  }
"{" 	{ write_begin(); }
"}" 	{ write_end(); }
"(" 	{ write_open(); }
")" 	{ write_close(); }
"[" 	{ write_bopen(); }
"]" 	{ write_bclose(); }
";" 	{ write_sep(); }
(\.|\-\>|\+\+|\-\-|&|\*|\+|\-|~|!|\/|\%|\<\<|\>\>|\<|\>|=|==|"||"|"|"|\<=|\>=|!=|\^\||&&|\|\|\?|\*=|\/=|\%=|\+=|\-=|\<\<=|\>\>=|&=|\^=|\|=|,|#|##|;|:|\"|\.\.\.) { write_op(); }

"\/\/"[^\n]*    { write_inline(); }
"/*" { write_comment(); }
#[^\n]* { write_directive(); }

[ \t\v\n\r\f] ;
%%

void indent(){
	printf("\n%-*d",column,line++);
}

void write_string(){
    printf("<font color='#FF0000'>");
    write_html();
    printf("</font>");
}

void write_char(){
    printf("<font color='#00FFFF'><u>");
    write_html();
    printf("</u></font>");
}

void write_oct(){
    printf("<font color='#00FFFF'><i>");
    write_html();
    printf("</i></font>");
}

void write_hex(){
    printf("<font color='#00FFFF'><i>");
    write_html();
    printf("</i></font>");
}

void write_int(){
    printf("<font color='#00FFFF'><i>");
    write_html();
    printf("</i></font>");
}

void write_fp(){
    printf("<font color='#00FFFF'>");
    write_html();
    printf("</font>");
}

void write_id(){
    char *c = yytext;
	int mark=0;
	if(c[strlen(c)-1]==' ' || c[strlen(c)-1]=='\n'){
		mark=1;
		c[strlen(c)-1]='\0';
	}
    int x = lookup(c);
    if(x==-1) {
        insert(c, 1);
		if(mark==1)
        	printf("<font color='#0000FF'><a name=\"%s\">%s</a> ", c, c);
		else
			printf("<font color='#0000FF'><a name=\"%s\">%s</a>", c, c);
        printf("</font>");
    }
    else {
        if(symtable[x].token==0) {
            printf("<font color='#0000FF'><b>");
            while(*c)
                write_html_char(*c++);
					if(mark==1)
						write_html_char(' ');
            printf("</b></font>");
        }
        else {
			if(mark==1)
            	printf("<font color='#0000FF'><a href=\"#%s\">%s</a> ", c, c);
			else
				printf("<font color='#0000FF'><a href=\"#%s\">%s</a>", c, c);
            printf("</font>");
        }
    }
}


void write_begin(){
    indent();
    write_html();
    column += INDENT;
    indent();
}

void write_end(){
    column -= INDENT;
    indent();
    write_html();
    indent();
}

void write_open(){
    write_html();
    //putchar(' ');
    paren++;
}

void write_close(){
	write_html();
	//putchar(' ');
	paren--;
}

void write_bopen(){
    write_html();
}

void write_bclose(){
    write_html();
}

void write_sep(){
	write_html();
	if(!paren)
		indent();
	else
		putchar(' ');
}

void write_op(){
    printf("<b>");
    write_html();
    printf("</b>");
}

void write_inline(){
	printf("<font color='#00FF00'>");
	write_html();
	printf("</font>");
	indent();
}

void write_comment(){ 
	char c, c1;
	printf("<font color='#00FF00'>/*");
	loop:
	while ((c = input()) != '*' && c != 0)
	write_html_char(c);
	write_html_char('*');
	if ((c1 = input()) != '/' && c != 0){ 
		unput(c1);
		goto loop; 
	}
	if (c != 0)
		write_html_char(c1);
	printf("</font>");
	indent();
}

void write_directive(){
	printf("<font color='#FF00FF'><b>");
	write_html();
	printf("</b></font>");
	indent();
}


void write_html_char(int c){
	switch (c){
		case '<': printf("&lt;"); break;
		case '>': printf("&gt;"); break;
		case '"': printf("&quot;"); break;
		case '&': printf("&amp;"); break;
		default: putchar(c);
	}
}

void write_html(){
	char *s = yytext;
	while(*s)
		write_html_char(*s++);
}

int insert(char *a, int token){
	symtable[ind].lexptr = (char *)malloc(10 * sizeof(char));
	strcpy(symtable[ind].lexptr, a);
	symtable[ind].token = token;
	ind++;
	return ind-1;
}
int lookup(char *lexeme){
	int i;
	for(i=0;i<ind;i++)
	{
		if(strcmp(symtable[i].lexptr, lexeme) == 0)
		{
			return i;
		}
	}
	return -1;
}
void init(){
	char keywords[32][15] = {"auto", "double","int","struct","break","else","long","switch", "case","enum","register",
    	"typedef", "char", "extern", "return", "union","const","float","short","unsigned",
        "continue","for","signed","void", "default","goto","sizeof","volatile","do","if","static","while"};
    int i;
	for(i=0;i<32;i++)
	{
		insert(keywords[i], 0);
	}
}

int main()
{ 
	init();
	FILE *fp;
	fp = freopen("out.html", "w", stdout);
	printf("<html><pre>\n");
	indent();
	yyin = fopen("in.c", "r");
	yylex();
	printf("\n</pre></html>\n");
	fclose(yyin);
	fclose(fp);
	return 0;
}

