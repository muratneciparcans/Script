/*
Rhodeus Script (c) 2013 by Talha Zekeriya Durmuş <zekeriya@talhadurmus.com>

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/

module rhodeus.parser.d;
import rhodeus.parser.lexer;
import rhodeus.error;
import rhodeus.vm.d;

import std.conv : to;
import std.stdio;


struct IL{
	enum x;
}

private{
	ubyte[lx] opLevels;
	OP[lx] operands;
	ubyte[lx] opos, mathtyps;
}

enum {
	undefined = 0,
	normal = 1,
	math = 2,
	condition = 3,
	logical = 4,
}
enum { infix , postfix}
shared static this(){
	mathtyps = [
		lx.PLUS: math, lx.TIMES: math, lx.MINUS: math, lx.DIVIDE: math,
		lx.MOD: math,
		lx.K_IN: condition,
		lx.EQ: condition, lx.NE: condition,
		lx.LT: condition, lx.LE: condition,
		lx.GT: condition, lx.GE: condition,
		lx.LAND: logical, lx.LOR: logical,
	];
	opos = [
		lx.PLUS: postfix, lx.TIMES: postfix, lx.MINUS: postfix, lx.DIVIDE: postfix,
		lx.MOD: postfix,
		lx.K_IN: postfix,
		lx.EQ: postfix, lx.NE: postfix,
		lx.LT: postfix, lx.LE: postfix,
		lx.GT: postfix, lx.GE: postfix,
		lx.LAND: infix, lx.LOR: infix,
	];
	opLevels = [
		lx.TIMES:10, lx.DIVIDE:10, lx.PLUS: 8, lx.MINUS: 8, lx.MOD: 6,
		lx.K_IN: 4,
		lx.EQ: 3, lx.NE: 3, lx.LT: 3, lx.LE: 3, lx.GT: 3, lx.GE: 3,
		lx.LAND: 2, lx.LOR: 2,
	];
	operands = [
		lx.PLUS: OP.add, lx.TIMES: OP.mul, lx.MINUS: OP.sub, lx.DIVIDE: OP.div,
		lx.MOD: OP.mod,
		lx.K_IN: OP.isin,
		lx.EQ: OP.isEquals, lx.NE: OP.isNotEquals,
		lx.LT: OP.isLower, lx.LE: OP.isLowerEquals,
		lx.GT: OP.isGreater, lx.GE: OP.isGreaterEquals,
		lx.LAND: OP.and, lx.LOR: OP.or,
	];
}


class RhParser : RhLexer{
private:
	int i;
	uint line = 1;
	size_t[] breaks, continues;
	int wbreak, wcontinue;


	void delegate()[string] wordFunctions;

public:

	void init(){
		wordFunctions = [
			"for": &p_for,
			"while": &p_while, 
			"loop": &p_loop,
			"layer": &p_layer,
			"if": &p_if,
			"fn": &p_function,
			"Fn": &p_function,
			"echo": &p_echo,
			//		"mod": &p_module,
			//		"Mod": &p_module,
		];

	}

	RhVM memory;
	version(none) void p_module(){
		i++;
		string name;
		bool[string] attrs;
		while (i<tokens.length){
			if (tokens[i].typ==lx.WORD){
				name = tokens[i].value;
				i++;
			}
			break;
		}
		Token test;
		if (name=="") throw new RhError(1041);

		string father;
		while(i<tokens.length){
			test = tokens[i];
			if(test.typ==lx.COLON){
				i++;
				if(i<tokens.length){
					test = tokens[i];
					if (test.typ==lx.WORD){
						father = test.value;
						i++;
					}
				}
				if (father=="") throw new RhError(1046);
				break;
			}else{
				break;
			}
		}
		memory.load(IL_CLASS, name, father);

		int mod;
		Token[] functions;
		bool kama=false;
		bool needline;
		Token item;
		while (i<tokens.length){
			item = tokens[i];
			if (mod==0 && item.typ==lx.LBRACE){
				mod=1;
				i++;
			}else if (mod==1 && item.typ==lx.RBRACE){
				mod=-1;
				i++;
				break;
			}else if (mod==1){
				switch(tokens[i].typ){
					case lx.PRINT:
						memory.print(tokens[i].value);
						i++;
						needline=false;
						continue;
					case lx.NEWLINE, lx.SEMI:
						i++;
						needline=false;
						continue;
					default:
						if(needline){
							throw new RhError(1025, tokens[i].value);
						}
						calcIt();
						needline=true;
						continue;
				}
			}else{
				break;
			}
		}
		if (mod == 0) throw new RhError(1021, "{");
		else if(mod != -1) throw new RhError(1021, "}");
		memory.load(IL_CLASS_END);

	}


	void p_echo(){
		i++;
		size_t[] jmps;
		calcIt(jmps);
		memory.echo();
	}
	void execParser(RhVM ril,string filename){
		memory = ril;
		i = 0;
		bool needline;
		try{
			while(i<tokens.length){
				switch(tokens[i].typ){
					case lx.CONTINUE:
						//memory.load(IL_CONTINUE);
						i++;
						continue;
					case lx.BREAK:
						//memory.load(IL_BREAK);
						i++;
						continue;
					case lx.PRINT:
						memory.print(tokens[i].value);
						i++;
						needline=false;
						continue;
					case lx.NEWLINE, lx.SEMI:
						i++;
						needline=false;
						continue;
					default:
						if(needline){
							throw new RhError(1025, tokens[i].value);
						}
						size_t[] jmps;
						calcIt(jmps);
						needline=true;
						continue;
				}
			}
			memory.hlt();
		}catch(RhError x){
			debug{
			}else{
				if(i< tokens.length)
					x.line = tokens[i].line;
				else
					x.line = tokens[$-1].line;
				x.file = filename;
			}
			throw x;
		}catch(Exception x){
			debug{
				throw x;
			}else{
				auto z =  new RhError(x.msg, tokens[i-1].line);
				if(i< tokens.length)
					z.line = tokens[i].line;
				else
					z.line = tokens[$-1].line;
				z.file = filename;
				throw z;
			}
		}
		memory = null;
	}

	int calcIt(ref size_t[] jmps, int styp = 0, int pOpLevel = 0){
		if(!(i < tokens.length) ) return 0;
		if(tokens[i].typ == lx.LPAREN){
			i++;
			calcIt(jmps, styp);
			if(tokens[i].typ!=lx.RPAREN) throw new RhError(1021, ")");
			i++;
			for(int last = -1; last != i; ){
				last = i;
				getSubFunction!false();
				getBrackets();
			}
		}else if(getIt(styp) == 0) return 0;
		Token token;
		lx operator, pOperator;
		int cOpLevel;
		bool other;
		size_t[] jmps2;
		while(i<tokens.length){
			if(auto opLevel = tokens[i].typ in opLevels){
				token = tokens[i];
				cOpLevel = *opLevel;
				operator = token.typ;
			}else break;
			if(cOpLevel <= pOpLevel) return 0;
			i++;
			if(operator == lx.LAND){
				if(pOperator != lx.NOP && mathtyps[pOperator]==condition){
					foreach(jmp;jmps) memory.hookjmp(jmp, memory.ip);
					jmps = null;
					memory.cmpload();
				}
				jmps ~= memory.and();
				other = true;
			}else if(operator == lx.LOR){
				if(pOperator != lx.NOP && mathtyps[pOperator]==condition){
					foreach(jmp;jmps) memory.hookjmp(jmp, memory.ip);
					jmps = null;
					memory.cmpload();
				}
				if(styp == 0) jmps ~= memory.or();
				else jmps2 ~= memory.or();
				other = true;
			}else memory.push(); 
			auto pc = jmps.length;
			calcIt(jmps, styp, cOpLevel);
//			writefln("styp = %s, operator = %s, pc %s == %s jmps.length ", styp, operator, pc, jmps.length);
			if(styp==1 && (operator == lx.LAND || operator == lx.LOR) && pc == jmps.length){
				jmps ~= memory.and();
			}
			if(!other){
				if(operator!=lx.NOP && mathtyps[operator]==condition){
					jmps ~= memory.operand(operands[operator], 0);
				}else memory.load(operands[operator], 0, null);
			}
			pOperator = operator;
		}
		if(styp==0){
			foreach(jmp;jmps) memory.hookjmp(jmp, memory.ip);
			jmps = null;
			if(operator!=lx.NOP && mathtyps[operator]==condition) memory.cmpload();
		}else{
			foreach(jmp;jmps2) memory.hookjmp(jmp, memory.ip);
		}
		return 0;
	}
	int getIt(int opt = 0){
		auto token = tokens[i];
		switch(token.typ){
			case lx.RETURN:
				i++;
				size_t[] jmps;
				calcIt(jmps);
				memory.returnf();
				return 0;
			case lx.LBRACKET, lx.LBRACE:
				getArray();
				goto getSub;
			case lx.MINUS:
				memory.load(0);
				memory.pushA();
				i++;
				getIt();
				memory.sub();
				return 1;
			case lx.NUMBER:
				if(token.value.indexOf(".")!=-1)
					memory.load(to!float(token.value));
				else
					memory.load(to!int(token.value));
				i++;
				goto getSub;
			case lx.STRING:
				memory.load(token.value);
				i++;
				goto getSub;
			case lx.NONE:
				memory.load();
				i++;
				goto getSub;
			case lx.TRUE:
				memory.load(true);
				i++;
				goto getSub;
			case lx.FALSE:
				memory.load(false);
				i++;
				goto getSub;
			case lx.WORD:
				if(auto wf = token.value in wordFunctions) {(*wf)(); return 0;}
				i++;
				lx ityp;
				/*if(getPlusPlus(ityp)) {
					memory.var(token.value);
					if(ityp==lx.PLUSPLUS) memory.inc();
					else memory.dec();
					goto getSub;
				}else*/if (getEqualVal(ityp)){
					if(ityp==lx.EQUALS) {
						size_t[] jmps;
						calcIt(jmps);
						memory.define(token.value);
					}
					goto getSub;
				}
				else memory.var(token.value); 
				for(int last = -1; last != i; ){
					last = i;
					if(getSubFunction() == 2) break;
					if(getBrackets(true) == 2) break;
				}
				goto getSub;
			default:
				break;
		}
		goto next;
	getSub:
		for(int last = -1; last != i; ){
			last = i;
			getSubFunction();
			getPlusPlus();
			getBrackets();
			getParams();
		}
		return 1;
	next:
		return 0;
	}
	bool getParams(int mod=0, int param=-1, bool pc=true){
		uint line;
		string pname;
		int pcount;
		with(lx){
			bool comma = false;
			Token item;
			while (i<tokens.length){
				item = tokens[i];
				if (mod==0 && item.typ == LPAREN){
					line = item.line;
					mod=1;
					i++;
					memory.finit(); 
				}else if (mod==1 && item.typ == RPAREN){
					mod=-1;
					i++;
					break;
				}else if (mod==1 && item.typ == NEWLINE){
					i++;
					continue;
				}else if (mod==1){
					if(comma==true){
						if(item.typ==COMMA) {comma = false; i++;}
						else throw new RhError(1021, ",");
					}else{
						if(item.typ==WORD && tokens.length > i + 2 && tokens[i+1].typ==ARROW){
							pname = tokens[i].value;
							i+=2;
						}
						size_t[] jmps;
						calcIt(jmps);

						if(pname!="") memory.asso(pname);
						memory.push();
						pcount++;
						pname = "";
						comma = true;
					}
				}else break;
			}
			if (mod == 0) return false;
			else if(mod != -1) throw new RhError(1044);
			if(pc) {
				/// memory.load(IL_PARACODES); bug
				if(getParacodes(true)){
					pcount++;
					/// memory.load(IL_PARACODES_LOAD); bug
					/// memory.load(IL_PUSH); bug
				}//else memory.load(IL_PARACODES_END); bug
			}
			memory.call(pcount);
			return true;
		}
	}
	bool getEqualVal(out lx ityp){
		if(i < tokens.length){
			ityp = tokens[i].typ;
			size_t[] jmps;
			with(lx) switch(ityp){
				case TIMESEQUAL, DIVEQUAL, MINUSEQUAL, MODEQUAL, PLUSEQUAL, EQUALS:
					i++;
					return true;
				default: return false;
			}
		}
		return false;
	}
	//a.y = 1
	ushort getSubFunction(bool equalri = true)(){
		if(i < tokens.length && tokens[i].typ == lx.PERIOD) i++;
		else return false;
		Token item;
		size_t[] jmps;

		while (i < tokens.length){
			item = tokens[i];
			if(item.typ == lx.WORD){
				i++;
				lx ityp;
				static if(equalri){
					if(getEqualVal(ityp)){
						final switch(cast(int) ityp){
							case lx.TIMESEQUAL:
								memory.getSub(item.value); memory.pushAP(); calcIt(jmps); memory.mulEqual();
								break;
							case lx.PLUSEQUAL:
								memory.getSub(item.value); memory.pushAP(); calcIt(jmps); memory.addEqual();
								break;
							case lx.DIVEQUAL:
								memory.getSub(item.value); memory.pushAP(); calcIt(jmps); memory.divEqual();
								break;
							case lx.MINUSEQUAL:
								memory.getSub(item.value); memory.pushAP(); calcIt(jmps); memory.subEqual();
								break;
							case lx.MODEQUAL:
								memory.getSub(item.value); memory.pushAP(); calcIt(jmps); memory.modEqual();
								break;
							case lx.EQUALS:
								memory.pushA(); calcIt(jmps); memory.setSub(item.value);
								break;
						}
						return 2;
					}else{
						memory.getSub(item.value);
						return 1;
					}
				}else{
					memory.getSub(item.value);
					return 1;
				}
			}else throw new RhError(1040, ".", "word");
		}
		return 0;
	}
	void getPlusPlus(){
		if(i<tokens.length) switch(tokens[i].typ){
			case lx.PLUSPLUS: memory.inc();i++; return;
			case lx.MINUSMINUS: memory.dec();i++; return;
			default: return;
		}
	}
	ushort getBrackets(bool eqc = false){
		lx ityp;
		size_t[] jmps;
		int max=-1;
		if(i<tokens.length && tokens[i].typ==lx.LBRACKET)
			i++;
		else
			return 0;
		memory.pushA(); 
		if(i<tokens.length){
			if(tokens[i].typ==lx.ELLIPSIS){
				memory.load();
				memory.pushB();
				i++;
			}else{
				int ti = i;
				calcIt(jmps);
				memory.pushB(); 
				if(i<tokens.length){
					if(tokens[i].typ==lx.ELLIPSIS) i++;
					else{
						if(ti == i) throw new RhError(1023);
						if(tokens[i].typ==lx.RBRACKET){
							i++;

							if(getEqualVal(ityp)){
								final switch(cast(int) ityp){
									case lx.TIMESEQUAL:
										memory.getIndex(); memory.pushAP(); calcIt(jmps); memory.mulEqual();
										return 2;
									case lx.PLUSEQUAL:
										memory.getIndex(); memory.pushAP(); calcIt(jmps); memory.addEqual();
										return 2;
									case lx.DIVEQUAL:
										memory.getIndex(); memory.pushAP(); calcIt(jmps); memory.divEqual();
										return 2;
									case lx.MINUSEQUAL:
										memory.getIndex(); memory.pushAP(); calcIt(jmps); memory.subEqual();
										return 2;
									case lx.MODEQUAL:
										memory.getIndex(); memory.pushAP(); calcIt(jmps); memory.modEqual();
										return 2;
									case lx.EQUALS:
										calcIt(jmps); memory.setIndex();
										return 2;
								}
							}else{
								memory.getIndex();
								return 1;
							}
						}else throw new RhError(1021, "]");
					}
				}
			}
		}else throw new RhError(1023);


		if(i<tokens.length){
			if(tokens[i].typ==lx.RBRACKET){
				i++;
				memory.load();
				memory.pushC();
				if (getEqualVal(ityp)){
					final switch(cast(int) ityp){
						case lx.MODEQUAL, lx.TIMESEQUAL, lx.PLUSEQUAL, lx.DIVEQUAL, lx.MINUSEQUAL:
							throw new RhError(1025, to!string(ityp));
						case lx.EQUALS:
							calcIt(jmps); memory.setSlice();
							return 2;
					}
				}else{
					memory.getSlice();
					return 1;
				}
			}else{
				calcIt(jmps);
				memory.pushC();
				if(i<tokens.length){
					if(tokens[i].typ==lx.RBRACKET){
						i++;
						if (getEqualVal(ityp)){
							final switch(cast(int) ityp){
								case lx.MODEQUAL, lx.TIMESEQUAL, lx.PLUSEQUAL, lx.DIVEQUAL, lx.MINUSEQUAL:
									throw new RhError(1025, to!string(ityp));
								case lx.EQUALS:
									calcIt(jmps); memory.setSlice();
									return 2;
							}
						}else{
							memory.getSlice();
							return 1;
						}
					}else throw new RhError(1021, "]");
				}else throw new RhError(1021, "]");
			}
		}else throw new RhError(1023);
	}


	bool getParacodes(bool zx = false){
		if(zx){
			if(i<tokens.length && tokens[i].typ==lx.LBRACE){
				i++;
			}else{
				return false;
			}
			goto atla2;
		}
	atla:
		if(i<tokens.length && tokens[i].typ==lx.NEWLINE){
			i++;
			goto atla;
		}
		if(i<tokens.length && tokens[i].typ==lx.LBRACE){
			i++;
		}else{
			if(i>=tokens.length) throw new RhError(1023);
			size_t[] jmps;
			calcIt(jmps);

			return true;
		}
	atla2:
		bool needline;
		for(;i<tokens.length;){
			switch(tokens[i].typ){
				case lx.PRINT:
					memory.print(tokens[i].value);
					i++;
					needline=false;
					break;
				case lx.CONTINUE:
					if(!wcontinue) goto default;
					continues ~= memory.jmp();
					i++;
					continue;
				case lx.BREAK:
					if(!wbreak) goto default;
					breaks ~= memory.jmp();
					i++;
					continue;
				case lx.RBRACE:
					i++;
					return true;
				case lx.NEWLINE, lx.SEMI:
					i++;
					needline=false;
					break;
				default:
					if(needline)
						throw new RhError(1022);
					size_t[] jmps;
					calcIt(jmps);

					needline=true;
					break;
			}
		}
		return false;
	}

	void getArray(){
		if (!(i<tokens.length))
			throw new RhError(1021, "[");

		auto arr = memory.arrayInit();


		bool kama=false;
		int itemcount;
		int colon = 1;
		auto wait = tokens[i].typ + 1;
		Token item;
		if (tokens[i].typ==lx.LBRACE){
			colon = 0;
			i++;
			goto dict;
		}else if (tokens[i].typ!=lx.LBRACKET)
			throw new RhError(1021, "]");
		i++;
		while (i < tokens.length){
			item = tokens[i];
			if(item.typ==lx.NEWLINE){
				i++;
			}else if (item.typ==wait){
				i++;
				memory.array(itemcount); 
				memory.hookint(arr, itemcount * (void*).sizeof);
				return;
			}else{
				if(kama==true){
					if(item.typ==lx.COMMA){
						kama = false; i++;
					}else if(item.typ==lx.COLON){
						goto dict;
					}else throw new RhError(1025, item.value);
				}else{
					size_t[] jmps;
					calcIt(jmps);
					memory.pushArray();
					itemcount++;
					kama = true;
				}
			}
		}
		goto end;
	dict:
		memory.hookoperand(arr, OP.dictInit);
		itemcount = 0;
		while (i < tokens.length){
			item = tokens[i];
			if(item.typ==lx.NEWLINE){
				i++;
			}else if (item.typ==wait){
				if(colon!=0)
					throw new RhError(1025, item.value);
				i++;
				memory.dict();
				memory.hookint(arr, itemcount * (void*).sizeof);
				return;
			}else{
				if(kama==true && item.typ==lx.COMMA){
					kama = false; i++;
				}else if(colon == 1 && item.typ==lx.COLON){
					kama = false; i++; colon = 2;
				}else if(colon == 2){
					size_t[] jmps;
					calcIt(jmps);

					memory.writeDict(); 
					itemcount++;
					kama = true;
					colon = 0;
				}else if(colon == 0){
					size_t[] jmps;
					calcIt(jmps);
					memory.pushA(); 
					colon = 1;
				}else{
					throw new RhError(1025, item.value);
				}
			}
		}
	end: throw new RhError(1021, "]");
	}


	void p_while(){
		wbreak++;
		wcontinue++;

		i++;
		size_t[] jmps, jmps2;
		auto start = memory.ip;
		calcIt(jmps, 1);
		if(jmps.length==0){
			jmps ~= memory.and();
		}
	atla:
		if(i<tokens.length && (tokens[i].typ!=lx.LBRACE )){
			if(i<tokens.length){
				if(tokens[i].typ==lx.NEWLINE){
					i++;
					goto atla;
				}	
				calcIt(jmps2);
				memory.jmp(start);
				foreach(jmp;jmps) memory.hookjmp(jmp, memory.ip);
				return;
			}
		}

		if (!getParacodes()) throw new RhError(1021, "{");
		memory.jmp(start);
		foreach(jmp;jmps) memory.hookjmp(jmp, memory.ip);

	
		foreach(jmp;breaks) memory.hookjmp(jmp, memory.ip);
		breaks = null;
		foreach(jmp;continues) memory.hookjmp(jmp, start);
		continues = null;

		wbreak--;
		wcontinue--;
	}
	void p_loop(){
		wbreak++;
		wcontinue++;
		i++;
		auto start = memory.ip;
		if (!getParacodes()) throw new RhError(1021, "{");
		memory.jmp(start);

		foreach(jmp;breaks) memory.hookjmp(jmp, memory.ip);
		breaks = null;
		foreach(jmp;continues) memory.hookjmp(jmp, start);
		continues = null;

		wbreak--;
		wcontinue--;

	}
	void p_for(){
		i++;
		wbreak++;
		wcontinue++;

		bool parenvar;
		size_t[] jmps;
		if(tokens[i].typ==lx.LPAREN){
			parenvar=true;
			i++;
		}
		switch(tokens[i].typ){
			case lx.SEMI: i++; break;
			default:
				calcIt(jmps);
				if(tokens[i].typ==lx.SEMI){ i++; break; }
				throw new RhError(1021, ";");
		}
		auto start = memory.ip;
		switch(tokens[i].typ){
			case lx.SEMI: i++; break;
			default:
				calcIt(jmps, 1);
				if(jmps.length==0){
					jmps ~= memory.and();
				}
				if(tokens[i].typ==lx.SEMI){ i++; break; }
				throw new RhError(1021, ";");
		}
		auto old = memory.oplist.codes;
		auto newm = new MEM(16); 
		memory.oplist.codes = newm; 
		size_t[] jmps2;
		if(parenvar) calcIt(jmps2);
		else 
			switch(tokens[i].typ){
				case lx.SEMI: i++; break;
				default:
					calcIt(jmps2);
					if(tokens[i].typ==lx.SEMI){ i++; break; }
					throw new RhError(1021, ";");
			}

		memory.oplist.codes = old; 

		if(parenvar && tokens[i].typ==lx.RPAREN){
			i++;
			parenvar = false;
		}
		if(parenvar) throw new RhError(1021, ")");
		if (!getParacodes()) throw new RhError(1021, "{");
		auto intermediate = memory.ip;
		memory.oplist.loadMEM(newm);
		newm.destroy(); 
		memory.jmp(start);
		foreach(jmp;jmps)  memory.hookjmp(jmp, memory.ip);

		foreach(jmp;breaks) memory.hookjmp(jmp, memory.ip);
		breaks = null;
		foreach(jmp;continues) memory.hookjmp(jmp, intermediate);
		continues = null;

		wbreak--;
		wcontinue--;

		//memory.load(IL_LOOPEND);
	}
	void p_layer(){
		i++;
		memory.initLayer();
		if (!getParacodes()) throw new RhError(1021, "{");
		memory.endLayer();
	}

	void p_if(){
		auto l = tokens[i].line;
		i++;
		size_t[] jmps, ends;

		calcIt(jmps, 1);
		if(jmps.length==0){
			jmps ~= memory.and();
		}
		if (!getParacodes()) throw new RhError(1023);
		ends ~= memory.jmp();
		Token test;
		int deli;
		while(i<tokens.length){
			test = tokens[i];
			if (test.typ==lx.ELIF){
				foreach(jmp;jmps)  memory.hookjmp(jmp, memory.ip);
				jmps = null;
				deli=0;
				i++;
				int pc = jmps.length;
				calcIt(jmps, 1);
				if(jmps.length==pc){
					jmps ~= memory.and();
				}

				if (!getParacodes()) throw new RhError(1021, "{");
				ends ~= memory.jmp();
			}else if (test.typ==lx.ELSE){
				foreach(jmp;jmps)  memory.hookjmp(jmp, memory.ip);
				jmps = null;
				deli=0;
				i++;
				if (!getParacodes()) throw new RhError(1021, "{");
				break;
			}else if(test.typ==lx.NEWLINE){
				i++;
				deli++;
			}else{
				i-=deli;
				break;
			}
		}
		foreach(jmp;jmps) memory.hookjmp(jmp, memory.ip);
		foreach(jmp;ends) memory.hookjmp(jmp, memory.ip);
	}

	void p_function(){
		i++;
		Token test;
		string name;
		if(i < tokens.length){
			if (tokens[i].typ==lx.WORD){
				name = tokens[i].value;
				i++;
			}
		}
		if (name=="") throw new RhError(1043);
		size_t next_ins;
		memory.func(next_ins, name);
		//auto xx = memory.getLast();
		if (i < tokens.length){
			test = tokens[i];
			i++;
		}
		if(test.typ != lx.LPAREN) throw new RhError (1021, "(");

		bool kama=false;
		size_t[] jmps;
		int[string] tevars;
		string defIt;
		int lev, lev2;
		int asteriks;
		int lastlevel;

		int paramcount;
		int positional;


		while(i < tokens.length){
			test = tokens[i];
			if (test.typ==lx.RPAREN){
				i++;
				break;
			}
			if(kama==false){
				if(test.typ == lx.WORD){
					i++;
					if(asteriks==0){
						if(i<tokens.length && tokens[i].typ == lx.EQUALS){
							if(lev>1)
								throw new RhError(1047, test.value);
							i++;
							lev2=1;
							auto dp = memory.defaultParam();
							calcIt(jmps);
							memory.param2(test.value);
							memory.hookjmp(dp, memory.ip);
							memory.param!false(test.value);
							paramcount++;
							positional++;
						}else{
							if(lev!=0)
								throw new RhError(1048, test.value);
							lev2 = 0;
							memory.param(test.value);
							paramcount++;
							positional++;
						}
					}else if(asteriks<4){
						lev2=asteriks+1;
						if(lev>=lev2)
							throw new RhError(1047, test.value);
						if(lev2 == 2) memory.param3(test.value);
						else if(lev2 == 3) memory.param4(test.value);
						else if(lev2 == 4) memory.param5(test.value);

						if(lev2 == 4) positional++;
						paramcount++;
					}
					else throw new RhError(1025, "*");
					lev = lev2;
					kama = true;
				}else if(test.typ == lx.TIMES){
					asteriks++;
					i++;
				}else{
					throw new RhError(1021, "word");
				}
			}else{
				if(test.typ==lx.COMMA){
					kama = false;
					asteriks=0;
					i++;
				}else{
					throw new RhError(1021, ",");
				}
			}
		}
		Token[] pc;
		//memory.paramcheck(positional);
		if (!getParacodes()) throw new RhError(1021, "{");
		memory.endFunc(next_ins);
	}

}