/**
Provides the rhodeus.vm.d API for the application.

Copyright: © 2013 Rhodeus Group
License: Subject to the terms of the Creative Commons license, as written in the included LICENSE.txt file.
Authors: Talha Zekeriya Durmuş
*/
module rhodeus.vm.d;

public import rhodeus.vm.opcodes;
import rhodeus.object.memory;
import rhodeus.vm.builtin;
import rhodeus.object.string;
import rhodeus.object.rfloat;
import rhodeus.object.number;
import rhodeus.parser.d;
import rhodeus.error;

public import std.stdio;
import std.string;
import std.traits;
import core.vararg;
import std.format;
import std.range;
import std.conv, std.string;
import core.memory;
import std.path;
import std.file;
import library.dini;

version(Win32)
import std.c.windows.windows;
else version(OSX)
private extern(C) int _NSGetExecutablePath(char* buf, uint* bufsize);
else
import std.c.linux.linux;

string getExec(){
	auto file = new char[4*1024];
	size_t filenameLength;
	version (Win32) filenameLength = GetModuleFileNameA(null, file.ptr, file.length-1);
	else version(OSX){
		filenameLength = file.length-1;
		_NSGetExecutablePath(file.ptr, &filenameLength);
	}else filenameLength = readlink(toStringz(selfExeLink), file.ptr, file.length-1);

	return to!string(file[0..filenameLength]);
}



version(unittest) version = unit_or_debug;
debug version = unit_or_debug;

shared{
	void*[OP.max + 1] Commands;
}

static this(){
	ThreadMem tm;
	run(tm);
}

string getF(string name, string v="EAXP"){
	if(v=="finits")
		return "(*cast(typeof(datatable[0]."~name~")*) ( cast(DT*) (cast(void*) datatable.ptr + sizes."~name~"*4) + (**tmem.finits).typ ) )";
	else if(v=="pushedAP")
		return "(*cast(typeof(datatable[0]."~name~")*) ( cast(DT*) (cast(void*) datatable.ptr + sizes."~name~"*4) + (**cast(RhData**) tmem.pushedA).typ ) )";
	else if(v=="EAXP")
		return "(*cast(typeof(datatable[0]."~name~")*) ( cast(DT*) (cast(void*) datatable.ptr + sizes."~name~"*4) + (**tmem.EAXP).typ ) )";
	else if(v=="ESP")
		return "(*cast(typeof(datatable[0]."~name~")*) ( cast(DT*) (cast(void*) datatable.ptr + sizes."~name~"*4) + (*tmem.ESP).typ ) )";
	else
		return "(*cast(typeof(datatable[0]."~name~")*) ( cast(DT*) (cast(void*) datatable.ptr + sizes."~name~"*4) + (cast(RhData*) tmem."~v~").typ ) )";
}
struct ARRAY{
	RhData** startp, curp;
}

struct RCALL{
	ubyte* cop;
	int varcount;
	RhData** stack;
	int stackExchange, stackExchangeT;
}

struct ThreadMem{
	OP op;
	ubyte* cop, cops;
	string output;
	string[] layers;
	/** Registers */
	RhData** EBP = void; /// Local variables, starting point: 100 variables;
	RhData** ESP = void; //
	RhData** finits = void; //
	RhData** EAXP; /// keeps variable pointer
	RhData* EAX;
	ARRAY array;
	ARRAY* arrayP;

	RhData*[string]* dictP;
	
	bool _cmp; /// keeps comparing results as boolean
	/** PushTemps */
	RhData* pushedA, pushedB, pushedC;

	RCALL* calls;

	this(int size = 100, int calls=1_000){
		dictP = (new RhData*[string][size]).ptr;

		ESP = (new RhData*[size]).ptr;
		this.calls = (new RCALL[calls]).ptr;
		EBP = (new RhData*[size]).ptr;
		arrayP = (new ARRAY[size]).ptr;
		finits = (new RhData*[size]).ptr;
	}
}

private static void run(ref ThreadMem tmemP, RIL oplist = null){
	int _EAX; ///
	ThreadMem tmem = tmemP;
	if(oplist !is null) goto start;

	/**
		Getting label addresses to access quickly to the operand codes.
	*/
	shared void* tmp;
	foreach(i, o; __traits(allMembers, OP) ){
		mixin("asm{call OP_" ~ o.toUpper()~";}");
		Commands[mixin("OP."~o)] = tmp;
	}
	return;
	with(OP){
		start:
		tmem.cops = tmem.cop = tmem.calls.cop;
	cont:
		asm{
			mov EAX, ThreadMem.cop.offsetof[tmem];
			movzx EAX,word ptr [EAX];
			mov EAX,dword ptr [EAX*4+Commands];
			jmp EAX;
		}
		final switch(tmem.op){
			case nop: OP_NOP: asm{call getAddress; ret;}
				tmem.op+=2;
			goto cont;
			case print: OP_PRINT: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				tmem.output ~= oplist.get!string(tmem.cop);
			goto cont;
			case echo: OP_ECHO: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				tmem.output ~= (*tmem.EAXP).toString();
			goto cont;

			case getSub: OP_GETSUB: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				tmem.EAX = mixin(getF("getSub"))(oplist.get!string(tmem.cop), &tmem, *tmem.EAXP);
				tmem.EAXP = &tmem.EAX;
			goto cont;

			case setSub: OP_SETSUB: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				tmem.EAX = mixin(getF("setSub", "pushedA"))(oplist.get!string(tmem.cop), *tmem.EAXP, &tmem, tmem.pushedA);
				tmem.EAXP = &tmem.EAX;
			goto cont;

			case getIndex: OP_GETINDEX: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				tmem.EAXP = mixin(getF("opIndex", "pushedA"))(tmem.pushedB, &tmem, tmem.pushedA);
			goto cont;

			case getSlice: OP_GETSLICE: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				tmem.EAX = mixin(getF("opSlice", "pushedA"))(tmem.pushedB, tmem.pushedC, &tmem, tmem.pushedA);
				tmem.EAXP = &tmem.EAX;
			goto cont;

			case setSlice: OP_SETSLICE: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				tmem.EAX = mixin(getF("opSliceAssign", "pushedA"))(tmem.pushedB, tmem.pushedC, *tmem.EAXP, &tmem, tmem.pushedA);
				tmem.EAXP = &tmem.EAX;
			goto cont;

			case setIndex: OP_SETINDEX: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				tmem.EAX = mixin(getF("opIndexAssign", "pushedA"))(tmem.pushedB, *tmem.EAXP, &tmem, tmem.pushedA);
				tmem.EAXP = &tmem.EAX;
			goto cont;

			case define: OP_DEFINE: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				auto ptr = (*cast(int*) tmem.cop + tmem.EBP);
				if(*ptr !is null){
					(*ptr).refcount--;
					if((*ptr).refcount < 1){
						collectGC(*ptr);
					}
				}
				(*tmem.EAXP).refcount++;
				*ptr = *tmem.EAXP;				
				tmem.cop += int.sizeof;
			goto cont;

			case paramcheck: OP_PARAMCHECK: asm{call getAddress; ret;}  tmem.cop += Operandsizes;
				if(*cast(int*)tmem.cop == 0)
				//if() throw new RhError(1008, name, to!string((*cast(int*)tmem.cop), to!string(given));
				tmem.cop += int.sizeof;
			goto cont;

			case defaultparam: OP_DEFAULTPARAM: asm{call getAddress; ret;} 
				if(tmem.calls.stackExchangeT > 0){
					tmem.cop += *cast(size_t*) (tmem.cop + 2);
				}else{
					tmem.cop += 6;
				}
			goto cont;

			case param: OP_PARAM: asm{call getAddress; ret;}
				//writefln("tmem.EBP[%s] = tmem.ESP[%s]", *cast(int*) (tmem.cop + 2), -tmem.calls.stackExchangeT);
				if(tmem.calls.stackExchangeT > 0){
					tmem.EBP[*cast(int*) (tmem.cop + 2)] = tmem.ESP[-tmem.calls.stackExchangeT];
					tmem.cop += 6;
					tmem.calls.stackExchangeT--;
				}else{
					throw new Exception("Parameter expected!");
				}
			goto cont;

			case param2: OP_PARAM2: asm{call getAddress; ret;}
				tmem.EBP[*cast(int*) (tmem.cop + 2)] = *tmem.EAXP;
				(*tmem.EAXP).refcount++;
				tmem.cop += 6 + 6; // + 6 is to pass next param instruction
			goto cont;

			case param3: OP_PARAM3: asm{call getAddress; ret;}
				RhData*[] arr;
				while(tmem.calls.stackExchangeT > 0){
					auto item = tmem.ESP[-tmem.calls.stackExchangeT];
					if(item.typ==M_ASSOVAR) break;
					else if(item.typ==M_CODEAREA) break;
					tmem.calls.stackExchangeT--;
					arr ~= item;
				}
				tmem.EBP[*cast(int*) (tmem.cop + 2)] = RhArray!1(arr);
				tmem.cop += 6;
			goto cont;

			case asso: OP_ASSO: asm{call getAddress; ret;} tmem.cop += 2;
				tmem.EAX = RhAssoVar(oplist.get!string(tmem.cop), *tmem.EAXP);
				tmem.EAXP = &tmem.EAX;
			goto cont;


			case param4: OP_PARAM4: asm{call getAddress; ret;}
				RhData*[string] arr;
				while(tmem.calls.stackExchangeT > 0){

					auto item = cast(_assovar*) tmem.ESP[-tmem.calls.stackExchangeT];
					if(item.typ!=M_ASSOVAR) break;

					arr[item.name] = item.value;
					tmem.calls.stackExchangeT--;
				}
				tmem.EBP[*cast(int*) (tmem.cop + 2)] = RhDictionary!1(arr);
				tmem.cop += 6;
			goto cont;

			case param5: OP_PARAM5: asm{call getAddress; ret;}
				tmem.EBP[*cast(int*) (tmem.cop + 2)] = *tmem.EAXP;
				(*tmem.EAXP).refcount++;
				tmem.cop += 6 + 6;
			goto cont;



			case addEqual: OP_ADDEQUAL: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				mixin(getF("opEqualAdd", "pushedAP"))(*tmem.EAXP, &tmem, cast(RhData**) tmem.pushedA);
				goto cont;
			case subEqual: OP_SUBEQUAL: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				mixin(getF("opEqualSub", "pushedA"))(*tmem.EAXP, &tmem, cast(RhData**) tmem.pushedA);
			goto cont;

			case divEqual: OP_DIVEQUAL: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				mixin(getF("opEqualDiv", "pushedA"))(*tmem.EAXP, &tmem, cast(RhData**) tmem.pushedA);
			goto cont;

			case mulEqual: OP_MULEQUAL: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				mixin(getF("opEqualMul", "pushedA"))(*tmem.EAXP, &tmem, cast(RhData**) tmem.pushedA);
			goto cont;

			case modEqual: OP_MODEQUAL: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				mixin(getF("opEqualMod", "pushedA"))(*tmem.EAXP, &tmem, cast(RhData**) tmem.pushedA);
			goto cont;

			case add: OP_ADD: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				tmem.ESP--;
				(*tmem.ESP).refcount--;
				tmem.EAX = mixin(getF("opAdd", "ESP"))(*tmem.ESP, &tmem, *tmem.EAXP);
				tmem.EAXP = &tmem.EAX;
			goto cont;
			case sub: OP_SUB: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				tmem.ESP--;
				(*tmem.ESP).refcount--;
				tmem.EAX = mixin(getF("opSub", "ESP"))(*tmem.ESP, &tmem, *tmem.EAXP);
				tmem.EAXP = &tmem.EAX;
				goto cont;
			case mul: OP_MUL: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				tmem.ESP--;
				(*tmem.ESP).refcount--;
				tmem.EAX = mixin(getF("opMul", "ESP"))(*tmem.ESP, &tmem, *tmem.EAXP);
				tmem.EAXP = &tmem.EAX;
				goto cont;
			case div: OP_DIV: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				tmem.ESP--;
				(*tmem.ESP).refcount--;
				tmem.EAX = mixin(getF("opDiv", "ESP"))(*tmem.ESP, &tmem, *tmem.EAXP);
				tmem.EAXP = &tmem.EAX;
			goto cont;
			case mod: OP_MOD: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				tmem.ESP--;
				(*tmem.ESP).refcount--;
				tmem.EAX = mixin(getF("opMod", "ESP"))(*tmem.ESP, &tmem, *tmem.EAXP);
				tmem.EAXP = &tmem.EAX;
			goto cont;

			case and: OP_AND: asm{call getAddress; ret;} 
				if(mixin(getF("hasValue"))(&tmem)) tmem.cop += 2 + size_t.sizeof;
				else tmem.cop += cast(int) *cast(size_t*) (tmem.cop + 2);
			goto cont;
			case or: OP_OR: asm{call getAddress; ret;}
				if(mixin(getF("hasValue"))(&tmem)) tmem.cop += cast(int) *cast(size_t*) (tmem.cop + 2);
				else tmem.cop += 2 + size_t.sizeof;
			goto cont;

			case jmp: OP_JMP: asm{call getAddress; ret;}
				tmem.cop += cast(int) *cast(size_t*) (tmem.cop + 2);
			goto cont;
			
			case jne: OP_JNE: asm{call getAddress; ret;}
				if(tmem._cmp) tmem.cop += 2 + size_t.sizeof;
				else tmem.cop += cast(int) *cast(size_t*) (tmem.cop + 2);
			goto cont;

			case je: OP_JE: asm{call getAddress; ret;}
				if(tmem._cmp) tmem.cop += cast(int) *cast(size_t*) (tmem.cop + 2);
				else tmem.cop += 2 + size_t.sizeof;
			goto cont;


			case var: OP_VAR: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				tmem.EAXP = (*cast(int*) tmem.cop + tmem.EBP);
				tmem.cop += int.sizeof;
			goto cont;

			case varc: OP_VARC: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				tmem.EAXP = (*cast(int*) tmem.cop + tmem.EBP);
				if(*tmem.EAXP is null){
					tmem.cop += int.sizeof;
					throw new RhError(1001, (*cast(char**) tmem.cop).cstr2dstr);
				}
				tmem.cop += int.sizeof*2;
			goto cont;

			case gvar: OP_GVAR: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				tmem.EAXP = cast(RhData**) tmem.cop;
				tmem.cop += int.sizeof;
			goto cont;

			case dict: OP_DICT: asm{call getAddress; ret;} tmem.cop += 2;
				tmem.EAX = cast(RhData*) smalloc!(_dict);
				*cast(_dict*)tmem.EAX = _dict(M_DICT, 0, false, *tmem.dictP);
				tmem.EAXP = &tmem.EAX;
				tmem.dictP--;
			goto cont;
			case array: OP_ARRAY: asm{call getAddress; ret;} tmem.cop += 2;
				tmem.EAX = cast(RhData*) smalloc!(rhodeus.object.array.array);
				*cast(rhodeus.object.array.array*)tmem.EAX = rhodeus.object.array.array(M_ARRAY, 0, false, *cast(int*) tmem.cop, tmem.array.startp);
				tmem.EAXP = &tmem.EAX;
				tmem.arrayP--;
				tmem.array = *tmem.arrayP;
				tmem.cop += int.sizeof;
			goto cont;
			case arrayInit: OP_ARRAYINIT: asm{call getAddress; ret;} tmem.cop += 2;
				*tmem.arrayP = tmem.array;
				tmem.arrayP++;
				if(*cast(int*) tmem.cop == 0){
					tmem.cop += int.sizeof;
					goto cont;
				}
				tmem.array.curp = tmem.array.startp = cast(RhData**) GC.malloc(*cast(int*) tmem.cop, GC.BlkAttr.NO_SCAN | GC.BlkAttr.APPENDABLE);
				GC.addRoot(cast(void*) tmem.array.startp);
				tmem.cop += int.sizeof;
			goto cont;
			case dictInit: OP_DICTINIT: asm{call getAddress; ret;} tmem.cop += 2 + int.sizeof;
				*tmem.dictP = null;
				tmem.dictP++;
			goto cont;

			case pushArray: OP_PUSHARRAY: asm{call getAddress; ret;} tmem.cop += 2;
				(*tmem.EAXP).refcount++;
				*tmem.array.curp = (*tmem.EAXP);
				tmem.array.curp++;
			goto cont;

			case writeDict: OP_WRITEDICT: asm{call getAddress; ret;} tmem.cop += 2;
				if(auto y = tmem.pushedA.toString() in *cast(RhData*[string]*) tmem.dictP){
					(*y).refcount--;
					(*tmem.EAXP).refcount++;
					*y = (*tmem.EAXP);
				}else{
					(*tmem.EAXP).refcount++;
					(*cast(RhData*[string]*) tmem.dictP)[tmem.pushedA.toString()] = (*tmem.EAXP);
				}
			goto cont;

			case initLayer: OP_INITLAYER: asm{call getAddress; ret;} tmem.cop += 2;
				tmem.layers ~= tmem.output;
				tmem.output = "";
			goto cont;

			case endLayer: OP_ENDLAYER: asm{call getAddress; ret;} tmem.cop += 2;
				tmem.EAX = RhString(tmem.output);
				tmem.EAXP = &tmem.EAX;
				tmem.output = tmem.layers[$-1];
				tmem.layers = tmem.layers[0..$-1];
			goto cont;

			case endFunc: OP_ENDFUNC: asm{call getAddress; ret;}
				tmem.cop = tmem.calls.cop;
				auto qwe = tmem.EBP;
				int y = tmem.calls.varcount;
				tmem.ESP -= tmem.calls.stackExchange;
				memset(tmem.ESP, 0, tmem.calls.stackExchange * int.sizeof);
				tmem.calls--;
				(*tmem.EAXP).refcount++;
				while(y--){
					if(!--(*qwe).refcount)
						collectGC(*qwe);
					qwe++;
				}
				tmem.EBP -= tmem.calls.varcount;
				(*tmem.EAXP).refcount--;
			goto cont;

			case push: OP_PUSH: asm{call getAddress; ret;} tmem.cop += 2;
				(*tmem.EAXP).refcount++;
				*tmem.ESP = *tmem.EAXP;
				tmem.ESP++;
			goto cont;

			case subaccess: OP_SUBACCESS: asm{call getAddress; ret;} 
				tmem.EAXP = &(tmem.calls - *cast(int*) (tmem.cop + 2)).stack[*cast(int*) (tmem.cop + 6)];
				tmem.cop+=int.sizeof * 2 + 2;
			goto cont;

			case pushAP: OP_PUSHAP: asm{call getAddress; ret;} tmem.cop += 2;
				tmem.pushedA = cast(RhData*) tmem.EAXP;
			goto cont;

			case pushA: OP_PUSHA: asm{call getAddress; ret;} tmem.cop += 2;
				tmem.pushedA = *tmem.EAXP;
			goto cont;
			case pushB: OP_PUSHB: asm{call getAddress; ret;} tmem.cop += 2;
				tmem.pushedB = *tmem.EAXP;
			goto cont;
			case pushC: OP_PUSHC: asm{call getAddress; ret;} tmem.cop += 2;
				tmem.pushedC = *tmem.EAXP;
			goto cont;

			case load: OP_LOAD: asm{call getAddress; ret;} tmem.cop += 2;
				tmem.EAXP = cast(RhData**) tmem.cop;
				tmem.cop += int.sizeof;
			goto cont;
			case inc: OP_INC: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				mixin(getF("inc"))(&tmem);
			goto cont;

			case dec: OP_DEC: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				mixin(getF("dec"))(&tmem);
			goto cont;

			case call: OP_CALL: asm{call getAddress; ret;} tmem.cop += Operandsizes;
				tmem.finits--;
				//self = *tmem.finits;
				mixin(getF("opCall", "finits"))(&tmem, *cast(int*) tmem.cop);
			goto cont;
			case finit: OP_FINIT: asm{call getAddress; ret;} tmem.cop += 2;
				*tmem.finits = *tmem.EAXP;
				tmem.finits++;
			goto cont;

			case cmpload: OP_CMPLOAD: asm{call getAddress; ret;} tmem.cop += 2;
				if(tmem._cmp) tmem.EAX = True;
				else tmem.EAX = False;
				tmem.EAXP = &tmem.EAX;
			goto cont;
			
			case isLower: OP_ISLOWER: asm{call getAddress; ret;}
				tmem.ESP--;
				(*tmem.ESP).refcount--;
				tmem._cmp = mixin(getF("opLower", "ESP"))(*tmem.ESP, &tmem, *tmem.EAXP);
				if(tmem._cmp) tmem.cop += Operandsizes + 4;
				else tmem.cop += cast(int) *cast(size_t*) (tmem.cop + 2);
			goto cont;
			case isEquals: OP_ISEQUALS: asm{call getAddress; ret;} 
				tmem.ESP--;
				(*tmem.ESP).refcount--;
				tmem._cmp = mixin(getF("opEquals", "ESP"))(*tmem.ESP, &tmem, *tmem.EAXP);
				if(tmem._cmp) tmem.cop += Operandsizes + 4;
				else tmem.cop += cast(int) *cast(size_t*) (tmem.cop + 2);
			goto cont;
			case isLowerEquals: OP_ISLOWEREQUALS: asm{call getAddress; ret;} 
				tmem.ESP--;
				(*tmem.ESP).refcount--;
				tmem._cmp = mixin(getF("opLowerEquals", "ESP"))(*tmem.ESP, &tmem, *tmem.EAXP);
				if(tmem._cmp) tmem.cop += Operandsizes + 4;
				else tmem.cop += cast(int) *cast(size_t*) (tmem.cop + 2);
			goto cont;
			case isGreaterEquals: OP_ISGREATEREQUALS: asm{call getAddress; ret;} 
				tmem.ESP--;
				(*tmem.ESP).refcount--;
				tmem._cmp = mixin(getF("opGreaterEquals", "ESP"))(*tmem.ESP, &tmem, *tmem.EAXP);
				if(tmem._cmp) tmem.cop += Operandsizes + 4;
				else tmem.cop += cast(int) *cast(size_t*) (tmem.cop + 2);
			goto cont;
			case isGreater: OP_ISGREATER: asm{call getAddress; ret;} 
				tmem.ESP--;
				(*tmem.ESP).refcount--;
				tmem._cmp = mixin(getF("opGreater", "ESP"))(*tmem.ESP, &tmem, *tmem.EAXP);
				if(tmem._cmp) tmem.cop += Operandsizes + 4;
				else tmem.cop += cast(int) *cast(size_t*) (tmem.cop + 2);
			goto cont;
			case isNotEquals: OP_ISNOTEQUALS: asm{call getAddress; ret;}
				tmem.ESP--;
				(*tmem.ESP).refcount--;
				tmem._cmp = mixin(getF("opNotEquals", "ESP"))(*tmem.ESP, &tmem, *tmem.EAXP);
				if(tmem._cmp) tmem.cop += Operandsizes + 4;
				else tmem.cop += cast(int) *cast(size_t*) (tmem.cop + 2);
			goto cont;
			case isin: OP_ISIN: asm{call getAddress; ret;} 
				tmem.ESP--;
				(*tmem.ESP).refcount--;
				tmem._cmp = mixin(getF("isIn", "ESP"))(*tmem.ESP, &tmem, *tmem.EAXP);
				if(tmem._cmp) tmem.cop += Operandsizes + 4;
				else tmem.cop += cast(int) *cast(size_t*) (tmem.cop + 2);
			goto cont;

			case hlt: OP_HLT: asm{call getAddress; ret;}
				auto qwe = tmem.EBP;
				if(tmem.EAXP !is null) (*tmem.EAXP).refcount++;
				for(int y = tmem.calls.varcount; y--; ){
					if(!--(*qwe).refcount)
						collectGC(*qwe);
					qwe++;
				}
				if(tmem.EAXP !is null) (*tmem.EAXP).refcount--;

				tmemP = tmem;
				return;
		}
	}
	/** There is no feature to get label address. That's an iasm hack to get the address.*/
getAddress:
	asm{
		pop EAX;
		mov tmp, EAX;
		inc tmp;
		jmp EAX;
	}
}

struct Operand{
	OP ins;
	uint line;
	void* next;
}
enum Operandsizes = 4 + 4 + 2;

/// Virtual Machine class
public class RhVM{
	static string RhVersion = "0.0.3";
	static string RhRelease = "23 August 2013";
	static string executableDir = "./";
	static string language = "en-US";
	string confaddr = "rhs.conf";

	scope parser = new RhParser();
	scope oplist = new RIL();
	variableManager* variables;

	size_t ip() @property{
		return oplist.codes.freeLocated;
	}
	this(){
		parser.init();
		executableDir = dirName(getExec()) ~ dirSeparator;
		if(exists("rhs.conf")) confaddr="rhs.conf";
		else confaddr = buildPath(executableDir, "rhs.conf");
		auto ini = Ini.Parse(confaddr);
		language = ini["script"].getKey("language");
		rhodeus.error.link();

		variables = new variableManager(null);
	}
	~this(){
		destroy(oplist);
	}

	/**
		Console greeting message
	*/
	final void showGreeting(){
		writeln("Rhodeus Script (", RhVersion ,", ", RhRelease ,")");
	}

	void func(out size_t jmp, string name, uint line = __LINE__, string file = __FILE__){
		RhFunctionSM* ptr;
		load(cast(RhData*) RhFunction(name, ptr));//0,
		define(name);

		variableManager.newChild(variables);
		ptr.stm = variables;
		jmp = this.jmp();
		ptr.codes = ip();
	}

	void endFunc(in size_t jmp, uint line = __LINE__, string file = __FILE__){
		oplist.loadEx(OP.endFunc);
		hookjmp(jmp, ip());
		variableManager.killChild(variables);
	}


	auto defaultParam(uint line = __LINE__, string file = __FILE__){
		auto ret = ip();
		oplist.loadEx(OP.defaultparam, 0);
		return ret;
	}
	auto param(bool showErr = true)(string varname, uint line = __LINE__, string file = __FILE__){
		auto ret = ip();
		int adr = void;
		if(auto z = variables.opBinary!"in"(varname)){
			if(showErr) throw new Exception("This parameter already defined");
			else adr = *z;
		}
		else adr = variables.reserve(varname);
		oplist.loadEx(OP.param, adr);
		return ret;
	}
	void param2(string varname, uint line = __LINE__, string file = __FILE__){
		int adr = void;
		if(auto z = variables.opBinary!"in"(varname)) throw new Exception("This parameter already defined");
		else adr = variables.reserve(varname);
		oplist.loadEx(OP.param2, adr);
	}
	void param3(string varname, uint line = __LINE__, string file = __FILE__){
		int adr = void;
		if(auto z = variables.opBinary!"in"(varname)) throw new Exception("This parameter already defined");
		else adr = variables.reserve(varname);
		oplist.loadEx(OP.param3, adr);
	}
	void param4(string varname, uint line = __LINE__, string file = __FILE__){
		int adr = void;
		if(auto z = variables.opBinary!"in"(varname)) throw new Exception("This parameter already defined");
		else adr = variables.reserve(varname);
		oplist.loadEx(OP.param4, adr);
	}
	void param5(string varname, uint line = __LINE__, string file = __FILE__){
		int adr = void;
		if(auto z = variables.opBinary!"in"(varname)) throw new Exception("This parameter already defined");
		else adr = variables.reserve(varname);
		oplist.loadEx(OP.param5, adr);
	}

	/// to overwrite a jump instruction
	void hookjmp(size_t adr, size_t val){
		*cast(size_t*) (&oplist.codes.memory[adr + 2]) = val - adr;
	}
	void hookjmpN(size_t adr, size_t val, size_t pos){
		*cast(size_t*) (&oplist.codes.memory[adr + 2 + pos]) = val - adr;
	}
	void hookoperand(size_t adr, OP val){
		*cast(OP*) (&oplist.codes.memory[adr]) = val;
	}
	void hookint(size_t adr, int val){
		*cast(int*) (&oplist.codes.memory[adr + 2]) = val;
	}
	void hookintsub(size_t adr, int val){
		*cast(int*) (&oplist.codes.memory[adr + 2]) = *cast(int*) (&oplist.codes.memory[adr + 2]) - val;
	}
	/// print is skipped. Jumping address identified later.
unittest{
RhVM rhvm = new RhVM();
auto jmp = rhvm.jmp();
rhvm.print("Hello Virtual-World!");
rhvm.hookjmp(jmp, rhvm.ip);
rhvm.run;
}

/++ 
+ Jumps to an instruction.
+ 
+ Example:
+ ---
+ RhVM rhvm = new RhVM();
+ auto jmp = rhvm.ip;
+ rhvm.print("Hello Virtual-World!");
+ rhvm.jmp(jmp);
+ rhvm.run;
+ ---
+/
auto jmp(size_t adr = 0){
	auto ret = ip();
	oplist.loadEx(OP.jmp, adr - ip() );
	return ret;
}

auto operand(OP a, size_t adr = 0, uint line = __LINE__, string file = __FILE__){
	auto ret = ip();
	oplist.loadEx(a, adr - ip(), line, null);
	return ret;
}
auto or(size_t adr = 0){
	auto ret = ip();
	oplist.loadEx(OP.or, adr - ip());
	return ret;
}
auto and(size_t adr = 0){
	auto ret = ip();
	oplist.loadEx(OP.and, adr - ip());
	return ret;
}

auto jne(size_t adr = 0){
	auto ret = ip();
	oplist.loadEx(OP.jne, adr - ip());
	return ret;
}

auto je(size_t adr = 0){
	auto ret = ip();
	oplist.loadEx(OP.je, adr - ip() );
	return ret;
}

/++ 
+ Outputs to console.
+ 
+ Example:
+ ---
+ RhVM rhvm = new RhVM();
+ rhvm.print("Hello Virtual-World!");
+ rhvm.run;
+ ---
+/
	void isLower(uint line = __LINE__, string file = __FILE__){
		oplist.load(OP.isLower, line, null);
	}
	void cmpload(uint line = __LINE__, string file = __FILE__){
		oplist.loadEx(OP.cmpload);
	}

	void sub(uint line = __LINE__, string file = __FILE__){
		oplist.load(OP.sub, line, null);
	}

	void setSub(string str, uint line = __LINE__, string file = __FILE__){
		oplist.load(OP.setSub, line, null, str);
	}
	void getIndex(uint line = __LINE__, string file = __FILE__){
		oplist.load(OP.getIndex, line, null);
	}
	void getSlice(uint line = __LINE__, string file = __FILE__){
		oplist.load(OP.getSlice, line, null);
	}
	void setIndex(uint line = __LINE__, string file = __FILE__){
		oplist.load(OP.setIndex, line, null);
	}
	void setSlice(uint line = __LINE__, string file = __FILE__){
		oplist.load(OP.setSlice, line, null);
	}

	void getSub(string str, uint line = __LINE__, string file = __FILE__){
		oplist.load(OP.getSub, line, null, str);
	}

	void load(OP op, uint line = __LINE__, string file = __FILE__){
		oplist.load(op, line, null);
	}

	void inc(uint line = __LINE__, string file = __FILE__){
		oplist.load(OP.inc, line, null);
	}
	void dec(uint line = __LINE__, string file = __FILE__){
		oplist.load(OP.dec, line, null);
	}
	void hlt(){
		oplist.loadEx(OP.hlt);
	}
	void paramcheck(int val, uint line = __LINE__, string file = __FILE__){
		oplist.loadEx(OP.paramcheck, line, null, val);
	}
	void call(int arg, uint line = __LINE__, string file = __FILE__){
		oplist.load(OP.call, line, null, arg);
	}
	void print(string str, uint line = __LINE__, string file = __FILE__){
		oplist.load(OP.print, line, null, str);
	}
	void asso(string str, uint line = __LINE__, string file = __FILE__){
		oplist.loadEx(OP.asso, str);
	}
	void finit(){
		oplist.loadEx(OP.finit);
	}
	auto arrayInit(int y = 0){
		auto ret = ip();
		oplist.loadEx(OP.arrayInit, y);
		return ret;
	}
	auto array(int y = 0){
		auto ret = ip();
		oplist.loadEx(OP.array, y);
		return ret;
	}
	auto returnf(){
		oplist.loadEx(OP.endFunc);
	}
	auto dict(){
		auto ret = ip();
		oplist.loadEx(OP.dict);
		return ret;
	}
	void push(){
		oplist.loadEx(OP.push);
	}
	void initLayer(){
		oplist.loadEx(OP.initLayer);
	}
	void endLayer(){
		oplist.loadEx(OP.endLayer);
	}
	void writeDict(){
		oplist.loadEx(OP.writeDict);
	}
	void pushArray(){
		oplist.loadEx(OP.pushArray);
	}
	void addEqual(uint line = __LINE__, string file = __FILE__){
		oplist.load(OP.addEqual, line, null);
	}
	void divEqual(uint line = __LINE__, string file = __FILE__){
		oplist.load(OP.divEqual, line, null);
	}
	void modEqual(uint line = __LINE__, string file = __FILE__){
		oplist.load(OP.modEqual, line, null);
	}
	void subEqual(uint line = __LINE__, string file = __FILE__){
		oplist.load(OP.subEqual, line, null);
	}
	void mulEqual(uint line = __LINE__, string file = __FILE__){
		oplist.load(OP.mulEqual, line, null);
	}
	void pushAP(){
		oplist.loadEx(OP.pushAP);
	}
	void pushA(){
		oplist.loadEx(OP.pushA);
	}
	void pushB(){
		oplist.loadEx(OP.pushB);
	}
	void pushC(){
		oplist.loadEx(OP.pushC);
	}
	void echo(uint line = __LINE__, string file = __FILE__){
		oplist.load(OP.echo, line, null);
	}

	void loadArr(T...)(T arr, uint line = __LINE__, string file = __FILE__){
		foreach(a; arr){
			load(a, __LINE__, __FILE__);
			push();
		}
		oplist.load(OP.array, line, null);
	}


	void load(int var){
		auto a = RhInt(var);
		a.refcount++;
		oplist.loadEx(OP.load, a);
	}
	void load(RhData* var){
		var.refcount++;
		oplist.loadEx(OP.load, var);
	}

	void load(bool var){
		oplist.loadEx(OP.load, var? True : False);
	}

	void load(NONE var){
		oplist.loadEx(OP.load, None);
	}
	void load(){
		oplist.loadEx(OP.load, None);
	}

	void load(string var){
		auto str = RhString(var);
		str.refcount++;
		oplist.loadEx(OP.load, str);
	}
	void load(float var){
		auto fl = RhFloat(var);
		fl.refcount++;
		oplist.loadEx(OP.load, fl);
	}

	/++
	+ Get a variable.
	+ 
	+ variable
	+/
	void var(string varname, uint line = __LINE__, string file = __FILE__){
		if(auto z = variables.opBinary!"in"(varname)){
			oplist.load(OP.var, line, null, *z);
		}else {
			auto tmpdm = variables.root;
			int xs = 2;
			while(tmpdm !is null){
				auto var2 = tmpdm.opBinary!"in"(varname);
				if(var2 !is null){
					oplist.loadEx(OP.subaccess, xs, *var2);
					return;
				}
				tmpdm = tmpdm.root;
				xs++;
			}
			if(auto z = varname in global) oplist.load(OP.gvar, line, null, *z);
			else oplist.load(OP.varc, line, null, variables.reserve(varname), varname.toStringz());
		}
	}


	/++
	 + Defining a variable.
	 + 
	 + a = b = 1_000
	+/
	int define(string varname, uint line = __LINE__, string file = __FILE__){
		int adr = void;
		if(auto z = variables.opBinary!"in"(varname)) 
			adr = *z;
		else 
			adr = variables.reserve(varname);
		oplist.load(OP.define, line, null, adr);
		return adr;
	}
	/// 
unittest{
auto rhvm = new RhVM();
rhvm.load(1_000);
rhvm.define("a");
rhvm.define("b");
rhvm.echo();
rhvm.run;
}

	auto runFile(int count = 1)(string filename){
		parser.load(filename);
		parser.lexy!true();
		parser.execParser(this, filename);
		static if(count == 1) return run();
		else if(count < 1) return oplist.disAssembly();
		else{
			foreach(i; 0..count) run.writeln;
			return "";
		}
	}
	private{
		ThreadMem tmem;
		bool tmemb = true;
	}
	auto run(int count = 1)(string codes){
		if(tmemb) {tmem = ThreadMem(100); tmemb =false;}
		oplist.memory.freeLocated = 0;
		oplist.codes.freeLocated = 0;
		parser.loadCodes(codes);
		parser.lexy!false();
		parser.execParser(this, "<console>");
		static if(count == 1){
			auto str = run(tmem);
			if(tmem.EAXP !is null){
				if(str != "") str ~= "\n"~(*tmem.EAXP).toString();
				else str = (*tmem.EAXP).toString();
			}
			tmem.output = "";
			return str;
		}
		else if(count < 1) return oplist.disAssembly();
		else{
			foreach(i; 0..count) run.writeln;
			return "";
		}
	}


///Runs the virtual machine.
	private string run(int count = 1)() @property{
		ThreadMem tmem = 100;
		*tmem.calls = RCALL(oplist.codes.memory.ptr, variables.size, tmem.EBP, 0);
		.run(tmem, oplist);
		return tmem.output;
	}
	private string run(int count = 1)(ref ThreadMem tmem) @property{
		*tmem.calls = RCALL(oplist.codes.memory.ptr, variables.size, tmem.EBP, 0);
		.run(tmem, oplist);
		return tmem.output;
	}
}
///
unittest{
auto rhvm = new RhVM();
rhvm.print("Hello Virtual-World!");
rhvm.run;
}


class RIL{
	MEM memory;
	MEM codes;
	this(){
		memory = new MEM(256);
		codes = new MEM(256);
	}
	~this(){
		destroy(memory);
		destroy(codes);
	}
	final void loadMEM(MEM www){
		codes.load(www.memory[0..www.freeLocated]);
	}
	final auto getLast(){
		return memory.freeLocated;
	}
	final auto setID(T)(T y, int place){
		*(cast(T*) (&memory.memory[place - T.sizeof] )) = y;
	}

	final void load(T...)(OP operand, uint line, void* next, T ts){
		codes.load(operand);
		codes.load(line);
		codes.load(next);
		foreach(arg; ts) {
			static if(isArray!(typeof(arg))){
				static if(isArray!(ElementEncodingType!(T))){
					throw new Exception("Invalid type!");
				}else{
					codes.load(memory.load(arg));
				}
			}else{
				codes.load(arg);
			}
		}
	}
	final void loadEx(T...)(OP operand, T ts){
		codes.load(operand);
		foreach(arg; ts) {
			static if(isArray!(typeof(arg))){
				static if(isArray!(ElementEncodingType!(T))){
					throw new Exception("Invalid type!");
				}else{
					codes.load(memory.load(arg));
				}
			}else{
				codes.load(arg);
			}
		}
	}
	final auto get(T)(ref ubyte* ptr) if (!isArray!T){
		scope(exit) ptr+=int.sizeof;
		return *cast(T*) &memory.memory[*cast(int*) ptr];
	}
    final auto get(T)(ref ubyte* ptr) if (isArray!T){
		auto mem = &memory.memory[*cast(int*) ptr];
		auto len = *cast(typeof(T.length)*) mem;
		mem += typeof(T.length).sizeof;
		scope(exit) ptr+=int.sizeof;
		return cast(T) (cast(ElementEncodingType!(T)*) mem)[0..len];
	}

	string disAssembly(){ 
		with(OP){
			string result;
			auto mbp = codes.memory.ptr;
		startp:
			//writeln(*cast(OP*) mbp, mbp);
			switch(*cast(OP*) mbp){
				case print:	mbp+=Operandsizes;
					string text = get!string(mbp);
					if(text!="") result ~= "print %s\n".format(text);
					goto startp;
				case gvar: mbp += Operandsizes;
					result ~= "load %s\n".format(**cast(RhData**) mbp);
					mbp += (void*).sizeof;
					goto startp;
				case call: mbp += Operandsizes;
					result ~= "call %s\n".format(*cast(int*) mbp);
					mbp += (void*).sizeof;
					goto startp;
				case load: mbp+=2; 
					if((*cast(RhData**) mbp).typ == M_STRING)
						result ~= "load \"%s\"\n".format(**cast(RhData**) mbp);
					else
						result ~= "load %s\n".format(**cast(RhData**) mbp);
					mbp+=(void*).sizeof;
					goto startp;
				case or, and, add, sub, mul, div, mod: 
					result ~= "%s\n".format( *cast(OP*)mbp);
					mbp+=Operandsizes;
					goto startp;
				case getSub:
					mbp += Operandsizes;
					result ~= "%s %s\n".format("getsub", get!string(mbp));
					goto startp;

				/*case OP.PARAMETER: mbp++;
					get!byte(mbp);
					get!int(mbp);
					result ~= "Parameter %s \n".format(get!string(mbp));
					goto startp;
				case OP.FCALL, OP.INT, OP.ARRAY, OP.DICT, OP.PARAMCHECK:
					result ~= "%s %s \n".format(*mbp in names? names[*mbp] : to!string(*mbp), get!int(++mbp));
					goto startp;
				case OP.FLOAT: mbp++;
					result ~= "load %s\n".format(get!float(mbp));
					goto startp;
				case OP.BOOL: mbp++;
					result ~= "load %s\n".format(get!bool(mbp) ? "true": "false");
					goto startp;
				case OP.GETSUB, OP.SETSUB, OP.LOADVAR, OP.STRING, OP.ASSO:
					result ~= "%s %s\n".format(*mbp in names? names[*mbp] : to!string(*mbp), get!string(++mbp));
					goto startp;
				case OP.DEFINE:
					mbp++;
					result ~= "define %s %s\n".format(get!int(mbp), get!string(mbp));
					goto startp;
				case OP.FUNCTION:
					mbp++;
					result ~= "print %s %s\n".format(get!string(mbp), get!int(mbp));
					goto startp;
				case OP.CLASS:
					result ~= "%s %s : %s\n".format(*mbp in names? names[*mbp] : to!string(*mbp), get!string(++mbp), get!string(mbp));
					goto startp;*/
				case OP.hlt:
					break;
					/*case OP.MATHSTART, OP.MATHEND:
					mbp++;
					goto startp;*/
				default:
					result ~= "%s\n".format( *cast(OP*)mbp);
					mbp+=2;
					goto startp;
			}
			return result;
		}
	}
}

/**
	Organizes memory processes. It keeps datas in it.
*/
class MEM{
public:
    ubyte[] memory;	/// keeps datas
    size_t freeLocated; /// used memory
	size_t memSize; /// capacity of allocated memory

    immutable int byteSize = 8; 

	/**
		Initializes the class and creates ubyte array that will keep datas;
	*/
    this(size_t minSize = 256) {
        size_t isOverload = minSize % byteSize;
        memory = new ubyte[](minSize - isOverload);
        memSize = memory.length;
    }

	/**
		Writes datas that isn't an array into the memory;
	*/
	final auto load(T)(T data) if (!isArray!T){
		auto ret = freeLocated;
		auto mem = cast(T*) malloc(data.sizeof);
		*mem = data;
		return ret;
	}
	/+
	+ Writes arrays like string into the memory. Keeps array values next to array length and returns array origin.
	+ Example:
 	+ ---
	+ auto mem = new MEM(24);
	+ mem.load(cast(byte[]) "World");
	+ writeln(mem);
	+ ---
	+ If you look output there will be 5 255 255 255 before World because of it keeps array length.
	+/
    final auto load(T)(T data) if (isArray!T && !is(ElementType!T == ubyte)){
		auto ret = freeLocated;
		static if(isArray!(ElementEncodingType!(T))){
			throw new Exception("Invalid type!");
		}else{
			auto mem = cast(Unqual!(ElementEncodingType!(T))*) malloc(data.length * ElementEncodingType!(T).sizeof + typeof(T.length).sizeof);
			*(cast(typeof(T.length)*)mem) = cast(typeof(T.length)) data.length;
			mem[typeof(T.length).sizeof..data.length+typeof(T.length).sizeof] = data;
		}
		return ret;
	}
	/++
	+ Writes bytes into the memory. It doesn't write array length unlike the previous load array function.
	+ 
	+ If you want to add a byte array please cast to byte[] rescue from ubyte[] form.
	+ Example:
 	+ ---
	+ auto mem = new MEM(24);
	+ mem.load(cast(ubyte[]) "Hello");
	+ writeln(mem);
	+ ---
	+ In output there is no array length because it passed as ubyte.
	+/
    final auto load(T)(T data) if (isArray!T && is(ElementType!T == ubyte)){
		auto ret = freeLocated;
		auto mem = cast(ElementEncodingType!(T)*) malloc(data.length);
		mem[0..data.length] = data;
		return ret;
	}
	/++
	 + That extends memory length by using D features.
	+/
    private void extendMem() {
        memory.length += memSize * 2;
        memSize = memory.length;
    }

	/++
		Gives intended size memory space.
	+/
    final void* malloc(size_t size) {
        while(memSize  < freeLocated + size) {
            extendMem();
        } 
        scope(exit) freeLocated += size;
        return &memory[freeLocated];
    }

	/++
 + It writes a string into the memory without string length.
	+ Example:
 	+ ---
	+ auto mem = new MEM(24);
	+ mem.memWrite("Hello ");
	+ mem.memWrite("Rhodeus!");
	+ writeln(mem);
	+ ---
	+/
    final void memWrite(inout(string) data) @property {
        auto mem = cast(char*) malloc(data.length);
        mem[0..data.length] = data;
    }
    final uint memReserveAddress() {
        scope(exit) malloc(int.sizeof);
        return freeLocated;
    }
    final void memSetAddress(uint adrl) {
        *cast(uint*) &memory[adrl] = memory.length;
    }

	/++
	+ It dumps memory.
	+ Notes:
	+ All \0 chars converted into 255 to get rid of string end char \0, 
	+ Example:
 	+ ---
	+ auto mem = new MEM(24);
	+ mem.memWrite("Hello ");
	+ mem.memWrite("Rhodeus!");
	+ writeln(mem);
	+ ---
	+ Output:
<pre>
>Total 24 bytes<
DECIMAL MEMORY DUMP             ASCII
&#45;---------------------------------------
72  101 108 108 111  32  82 104 Hello Rh
111 100 101 117 115  33 255 255 odeus!  
255 255 255 255 255 255 255 255         
>Total 24 bytes<
</pre>
	+/
	version(unit_or_debug) override string toString() const{
        import std.range : repeat;
        string memImage  = "       DECIMAL MEMORY DUMP        ASCII  \n";
        memImage ~= format("%s\n", repeat('-', memImage.length)) ;

        for(int i; i < memory.length; i += byteSize) {
            auto row = memory[i..i + byteSize].dup;
            foreach(ref ubyte address; row) {
                if(address == 0){
                    address = 0xFF;
                    memImage ~= " ";
                }else if(address < 10) memImage ~= "   ";
                else if(address < 100) memImage ~= "  ";
                else if(address < 256) memImage ~= " ";
                memImage ~= to!string(address);
            }
            memImage ~= " ";
            foreach(c; row){
                memImage ~= c;
            }
            memImage ~= "\n";
        }
        writeln(format("%s>Total %s bytes<\n", repeat(' ', 10), memory.length));
        return memImage ~ format("%s>Total %s bytes<\n", repeat(' ', 10), memory.length);
    }
}

import core.stdc.string: strlen;
auto cstr2dstr(inout(char)* cstr){
    return cast(string) (cstr ? cstr[0 .. strlen(cstr)] : "");
}