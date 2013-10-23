module rhodeus.parser.lexer;
/*
Rhodeus Script (c) 2013 by Talha Zekeriya Durmuş <zekeriya@talhadurmus.com>

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/

import rhodeus.error;

import std.file : read, exists;
import std.conv : to, parse;
import std.string: indexOf, lastIndexOf;
import std.algorithm: count;
import std.file: chdir;

import core.memory;
import std.stdio;

enum lx{
	NOP= 0, NUMBER , WORD, SWORD,STRING, NEWLINE, NONE,

	TRUE, FALSE,

	PRINT, 

	// Keywords
	DO, END,

	// COMMANDS
	BREAK, CONTINUE, RETURN,

	// Operators (+,-,*,/,%,|,&,^,<<,>>, ||, &&, !, <, <=, >, >=, ==, !=, in)
	PLUS, MINUS, TIMES, DIVIDE, MOD,
	OR, AND, XOR, LSHIFT, RSHIFT,
	LOR, LAND, LNOT,
	LT, LE, GT, GE, EQ, NE, K_IN,

	// Assignment (=, *=, /=, %=, +=, -=)
	EQUALS, TIMESEQUAL, DIVEQUAL, MODEQUAL, PLUSEQUAL, MINUSEQUAL,

	// Increment/decrement (++,--)
	PLUSPLUS, MINUSMINUS,

	// Mapping parameter (->)
	ARROW,

	// Ternary operator (?)
	TERNARY,

	// Delimeters ( ) [ ] { } , . ; :
	LPAREN, RPAREN,
	LBRACKET, RBRACKET,
	LBRACE, RBRACE,
	COMMA, PERIOD, SEMI, COLON,

	// Ellipsis (..)
	ELLIPSIS,

	// COMMENT /* */
	COMMENT,

	ELIF, ELSE
}

static enum chars = ['n': '\n', 't': '\t', 'r': '\r', 'a': '\a','f': '\f', 'b': '\b', 'v': '\v', '\"': '\"','?': '?', '\\': '\\', '\'': '\''];
static enum tokencount = lx.max + 1;
static lx[string] keywords;
static LexMap[char] lexmap;

static this(){
	keywords = [
		"none": lx.NONE,
		"in": lx.K_IN,
		"continue": lx.CONTINUE,
		"break": lx.BREAK,
		"return": lx.RETURN,
		"true": lx.TRUE,
		"false": lx.FALSE,
		"elif": lx.ELIF,
		"else": lx.ELSE,
	];
	lexmap = [
		'+': LexMap(lx.PLUS, [
			'+': LexMap(lx.PLUSPLUS),
			'=': LexMap(lx.PLUSEQUAL)
		]),
			'-': LexMap(lx.MINUS, [
				'-': LexMap(lx.MINUSMINUS),
				'>': LexMap(lx.ARROW),
				'=': LexMap(lx.MINUSEQUAL)
			]),
				'*': LexMap(lx.TIMES,[
					'=': LexMap(lx.TIMESEQUAL)
				]),
				'/': LexMap(lx.DIVIDE,[
					'=': LexMap(lx.DIVEQUAL),
					'*': LexMap(lx.NOP,"*/"),
					'/': LexMap(lx.NOP,"\n")
				]),
					'%': LexMap(lx.MOD,[
						'=': LexMap(lx.MODEQUAL)
					]),
					'<': LexMap(lx.LT,[
						'=': LexMap(lx.LE)
					]),
					'>': LexMap(lx.GT,[
						'=': LexMap(lx.GE)
					]),
					'=': LexMap(lx.EQUALS,[
						'=': LexMap(lx.EQ),
					]),
					'!': LexMap(lx.LNOT,[
						'=': LexMap(lx.NE),
					]),
					'|': LexMap(lx.OR,[
						'|': LexMap(lx.LOR)
					]),
					'&': LexMap(lx.AND,[
						'&': LexMap(lx.LAND)
					]),
					'?': LexMap(lx.TERNARY),
					'(': LexMap(lx.LPAREN),
					')': LexMap(lx.RPAREN),
					'[': LexMap(lx.LBRACKET),
					']': LexMap(lx.RBRACKET),
					'{': LexMap(lx.LBRACE),
					'}': LexMap(lx.RBRACE),
					',': LexMap(lx.COMMA),
					'.': LexMap(lx.PERIOD, [
						'.': LexMap(lx.ELLIPSIS)
					]),
					';': LexMap(lx.SEMI),
					':': LexMap(lx.COLON)
	];
}


class RhLexer{
private:
	immutable(char)* size;
	string file;
	int line = 1;
	bool loaded;
public:
	Token[] tokens;
	string codes;

	~this(){
		clean();
	}

	void clean(){
		GC.free(cast(void*) codes.ptr);
		GC.free(cast(void*) tokens.ptr);
		tokens = null;
		return;
	}

	void load(inout(string) _file){
		auto file = std.array.replace(_file, "\\", "/");
		if(!exists(file)) throw new RhError(1017, cast(string) file);
		this.file = cast(string) file;
		codes = cast(string) read(cast(string) file);
		size = codes.ptr + codes.length;

		auto dir = file.lastIndexOf('/') == -1 ? "./" : file[0..file.lastIndexOf('/')];
		chdir(dir);
		line = 1;

	}
	void loadCodes(inout(char[]) codes){
		this.file = "<console>";
		this.codes = cast(string) codes;
		size = this.codes.ptr + this.codes.length;

		line = 1;
		tokens = null;
	}
	void lexy(bool html = false)(){
		try{
			bool mustclose; //That is for controlling that is tags are opened?
			auto c = codes.ptr;
			auto cpos(){
				return (c-codes.ptr);
			}
			int im;
			string tmp;

		rhstag:
			static if(html){
				im = indexOf(codes[cpos()..$], "<|");
				if (im==-1){
					addToken(lx.PRINT, codes[cpos()..$]);
					return;
				}else{
					string mx = codes[cpos()..cpos()+im];
					line += count(mx, "\n");
					addToken(lx.PRINT, mx);
					c+=im+2;
					mustclose = true;
				}
			}


			while (c < size) with(lx){
				if (*c=='\r'){
					addToken(NEWLINE);
					line++;
				}else if(*c=='\n'){
					if(c + 1<size && *(c+1)=='\r')  c++;
					addToken(NEWLINE);
					line++;
				}else if(*c=='\t' || *c == ' '){
				}else if (*c == '\"' || *c == '\''){
					tmp = "";
					int tmpf = 0;
					char wait = *c;
					c++;
				stringStart:
					while (c < size){
						if (*c == wait){
							c++;
							goto stringEnd;
						}
						else if (*c == '\\') {c++; goto stringSlash;}
						else tmp ~= *c;
						c++;
					}
					goto stringError;

				stringSlash:
					if (c < size){
						int ii = 0, iim = 3;
						if (*c == 'u'){
							iim = 4;
							c++;
						}else if (*c == 'x'){
							iim = 2;
							c++;
						}else if (*c == 'U') { iim = 8; c++; }
						else if (*c in chars){
							tmp ~= chars[*c];
							c++;
							goto stringStart;
						}else{
							tmpf = 0;
							c++;
							tmp ~= *c;
							goto stringStart;
						}
						string tmp2 = "";
						while (c < size && ii < iim){
							if (!(
								  /* isHex */
								  (*c >= 48 && *c <= 57) /* 0-9 */ || 
								  (*c >= 65 && *c <= 70) /* A-F */ ||
								  (*c >= 97 && *c <= 102) /* a-f */
								  )) goto stringStart;
							tmp2 ~= *c;
							c++;
							ii++;
						}
						if (ii != iim) throw new RhError(1035, to!string(iim-ii));
						if (iim == 3) tmp ~= parse!int(tmp2, 8);
						else tmp ~= parse!int(tmp2, 16);
						goto stringStart;
					}

				stringError:
					throw new RhError(1021, "\"");
				stringEnd:
					addToken(STRING, tmp);
					continue;
				rawString:
					tmp = "";
					char rwait = *c;
					c++;
					while (c < size){
						if (*c == rwait){
							c++;
							goto stringEnd;
						}
						else if (*c == '\\') {
							tmp~="\\\\";
							if(*(c+1) == rwait){
								tmp ~= rwait;
								c++;
							}
						}
						else tmp ~= *c;
						c++;
					}
					goto stringError;			
 				}else if (html && *c == '|' && c+1<size && *(c+1) == '>'){
					mustclose=false;
					c+=2;
					goto rhstag;
					/* isWord*/
    			}else if (
						  (*c >= 65 && *c <= 90) /* A-Z */ || 
						  (*c >= 97 && *c <= 122) /* a-z */ || 
						  (*c>127 && *c<255) || *c=='_'
						  ){
							  if (*c=='r' && c+1<size && (*c=='\'' || *(c+1)=='"' ) ){
								  c++;
								  goto rawString;
							  }
							  auto ws = c; c++;
							  int wsi = 1;
							  while (c < size){
								  if (
									  (*c >= 48 && *c <= 57) /* 0-9 */ || 
									  (*c >= 65 && *c <= 90) /* A-Z */ || 
									  (*c >= 97 && *c <= 122) /* a-z */ || 
									  (*c>127 && *c<255) || *c=='_'
									  ){
										  c++;
										  wsi++;
									  }else break;
							  }
							  auto keyword = ws[0..wsi] in keywords;
							  if(keyword) addToken(*keyword, ws[0..wsi]);
							  else addToken(WORD, ws[0..wsi]);
							  continue;
						  }else if ((*c >= 48 && *c <= 57) /* 0-9 */){
							  if ((c+1 < size) && *(c+1) == 'x'){
								  c+=2;
								  goto HexD;
							  }
							  tmp = "";
							  bool dot, e;
							  while (c < size){
								  if ((*c >= 48 && *c <= 57) /* 0-9 */){
									  tmp ~= *c;
									  c++;
								  }else if ('.' == *c && !dot && (*(c+1) >= 48 && (*(c+1)) <= 57) /* 0-9 */ ){
									  dot = true;
									  tmp ~= *c;
									  c++;
								  }else if ('_' == *c){
									  c++;
								  }
								  /*						else if (*c == 'e' && !e){
								  c++;
								  e = true;
								  tmp ~= *c;
								  if(*c=='-'){
								  tmp ~= *c;
								  c++;
								  }
								  }*/
								  else break;
							  }
							  addToken(NUMBER, tmp);
							  continue;
						  }else{
							  tmp = "";
							  LexMap* z = *c in lexmap;
							  if(z is null){
								  throw new RhError(1034, to!string(*c));
							  }else{
							  sl:
								  if(z.finish !is null){
									  c++;
									  auto ws = c;
									  int wsi;
								  atla:
									  while(c < size){
										  foreach(i,l; z.finish){
											  if(*(c+i) != l) {wsi++; c++; goto atla;}
										  }
										  c+=z.finish.length-1;
										  break;
									  }
									  if(z.name !=NOP)
										  addToken(z.name, ws[0..wsi]);
									  else{
										  line+=count(ws[0..wsi], "\n");
										  addToken(NEWLINE);
									  }
								  }else{
									  tmp ~= *c;
									  LexMap* b= *(c+1) in z.map;
									  if(b is null) addToken(z.name,tmp);
									  else{
										  z = b;
										  c++;
										  goto sl;
									  }
								  }
							  }
						  }
				c++;
				continue;
			HexD:
				auto ws = c;
				int wsi;
				while (c < size &&
					   /* isHex */
					   (*c >= 48 && *c <= 57) /* 0-9 */ || 
					   (*c >= 65 && *c <= 70) /* A-F */ ||
					   (*c >= 97 && *c <= 102) /* a-f */
					   ){
						   wsi++; c++;
					   }
				try{
					string ttt = cast(string) ws[0..wsi];
					addToken(NUMBER, to!string(parse!int(ttt, 16)));
				}catch(Throwable x){
					throw new RhError(1033, x.msg);
				}
				c++;
			}
			if(mustclose)
				throw new RhError(1032, "|>");
		}catch(Exception x){
			x.line = line;
			x.file = file;
			throw x;
		}
	}
	void addToken(lx type, inout(string) val = null){
		this.tokens ~= Token(line, type, val);
	}

}



struct Token{
	uint line;
	lx typ;
	string value;
}

struct LexMap{
	lx name;
	LexMap[char] map;
	string finish;
	this(lx name,  LexMap[char] map = null){
		this.name = name;
		this.map = map;
	}
	this(lx name, string finish){
		this.name = name;
		this.finish = finish;
	}
}