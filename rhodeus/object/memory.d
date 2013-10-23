/*
Rhodeus Script (c) 2013 by Talha Zekeriya Durmuş <zekeriya@talhadurmus.com>

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/

module rhodeus.object.memory;
public import rhodeus.error;
public import rhodeus.vm.d;
public import rhodeus.memory.fda;

/// RhS objects
public {
	import rhodeus.object.dfunction;
	import rhodeus.object.rfunction;
	import rhodeus.object.array;
	import rhodeus.object.number;
	import rhodeus.object.rfloat;
	import rhodeus.object.string;
	import rhodeus.object.none;
	import rhodeus.object.rbool;
	import rhodeus.object.dictionary;
	import rhodeus.object.assovar;
}


public import core.memory;
import std.stdio;
import std.c.string : memset;
public import std.typetuple;
import std.conv: to;

///None
public{
	struct NONE{
		
	}
	const{
		RhData NoneC = RhData();
		_bool FalseC = _bool(M_BOOL, 0,false, false);
		_bool TrueC = _bool(M_BOOL, 0,false, true);
	}
	enum : RhData*{
		None = cast(RhData*) &NoneC,
		False = cast(RhData*) &FalseC,
		True = cast(RhData*) &TrueC
	}
	
}

/*public{
	import rhdfunction, rhfloat, rhstring;
	import rhbool, rharray, rhnone, rhint;
	import rhassovar, rhfunction, rhdictionary;
	import rhmodule, rhpackage;
	import rhcodearea;
}*/
private{
//	import ThreadMem*: ThreadMem*, rhtypes;
}

enum msize = 10_000;
struct Memory{
	RhData*[msize] memory;
	int index;
}
void** initMemory(){
	auto stack = cast(void**) GC.calloc((RhData*).sizeof * msize);
	return stack;
}

size_t biggestLength(T...)(){
    static if (T.length == 1) {
        return T[0].sizeof;
    }else{
        return max(T[0].sizeof, biggestLength!(T[1..$]));
    }
}



public{
	enum types = ["none", "bool", "int","float", "string", "array","dict", "dfunction", "function", "module", "module", "super", "codearea", "assovar", "package", "package", "sword"];
	enum data{ freeable, assigned, constant }
	enum typcount = 22;
	enum maxsize = 4;//biggestLength!(RhData);//bytes
	DT[typcount] datatable;

}
enum {
	M_NONE,
	M_BOOL, M_INT, M_FLOAT,
	M_STRING, M_ARRAY, M_DICT,
	M_DFUNCTION, M_FUNCTION,
	M_MODULE, M_MODULEC, M_SUPER,
	M_CODEAREA, M_ASSOVAR,
	M_PACKAGE, M_PACKAGEC,
	M_SWORD
}
struct DT{
	RhData* function(RhData*, ThreadMem*, RhData*) opMul = &.opMul;
	RhData* function(RhData*, ThreadMem*, RhData*) opMod = &.opMod;
	RhData* function(RhData*, ThreadMem*, RhData*) opDiv = &.opDiv;
	RhData* function(RhData*, ThreadMem*, RhData*) opAdd = &.opAdd;
	RhData* function(RhData*, ThreadMem*, RhData*) opSub = &.opSub;
	void function(ThreadMem*) inc = &.inc;
	void function(ThreadMem*) dec = &.dec;
	bool function(ThreadMem*) hasValue = &.hasValue;
	string function(ThreadMem*,RhData*) toString = &.toString;
	void function(ThreadMem*, int) opCall = &.opCall;
	RhData* function(string, ThreadMem*, RhData*) getSub = &.getSub;
	RhData* function(string, RhData*, ThreadMem*, RhData*) setSub = &.setSub;
	bool function(RhData*, ThreadMem*, RhData*) opLower = &.opLower;
	bool function(RhData*, ThreadMem*, RhData*) opLowerEquals = &.opLowerEquals;
	bool function(RhData*, ThreadMem*, RhData*) opGreater = &.opGreater;
	bool function(RhData*, ThreadMem*, RhData*) opGreaterEquals = &.opGreaterEquals;
	bool function(RhData*, ThreadMem*, RhData*) opEquals = &.opEquals;
	bool function(RhData*, ThreadMem*, RhData*) opNotEquals = &.opNotEquals;

	RhData** function(RhData*, ThreadMem*, RhData*) opIndex = &.opIndex;
	RhData* function(RhData*, RhData*, ThreadMem*, RhData*) opSlice = &.opSlice;

	RhData* function(RhData*, RhData*, ThreadMem*, RhData*) opIndexAssign = &.opIndexAssign;
	RhData* function(RhData*, RhData*, RhData*, ThreadMem*, RhData*) opSliceAssign = &.opSliceAssign;

	void function(RhData* obj, ThreadMem*, RhData** self) opEqualMul = &.opEqualMul;
	void function(RhData* obj, ThreadMem*, RhData** self) opEqualMod = &.opEqualMod;
	void function(RhData* obj, ThreadMem*, RhData** self) opEqualDiv = &.opEqualDiv;
	void function(RhData* obj, ThreadMem*, RhData** self) opEqualAdd = &.opEqualAdd;
	void function(RhData* obj, ThreadMem*, RhData** self) opEqualSub = &.opEqualSub;

	bool function(RhData*, ThreadMem*, RhData*) isIn = &.isIn;

	RhData* function(ThreadMem*, RhData*) opNot = &.opNot;
}
enum sizes : int{
	opMul, opMod, opDiv, opAdd, opSub, inc, dec, hasValue, toString, opCall, getSub, setSub, 

	opLower, opLowerEquals, opGreater, opGreaterEquals, opEquals, opNotEquals,

	opIndex, opSlice, opIndexAssign, opSliceAssign,

	opEqualMul, opEqualMod, opEqualDiv, opEqualAdd, opEqualSub,

	isIn, opNot
}

template rhdata(){
	int typ;
	int refcount;
	bool is_ref;
}
struct _rhdata{
	int typ;
	int	refcount;
	int is_ref;
	int a1,a2,a3,a4,a5,a6,a7,a8;//,a9,a10,a11,a12,a13
}
struct RhData{
	int typ;
	int	refcount;
	int is_ref;
	int a1,a2,a3,a4,a5,a6,a7,a8;//,a9,a10,a11,a12,a13
	string toString(ThreadMem* rhvm = null) {
		return datatable[typ].toString(rhvm, &this);
	}
	@property string type() {
		return types[typ];
	}
	bool opEquals(RhData* x) {
		return cast(bool) datatable[typ].opEquals(x, null, cast(RhData*) &this);
	}
}

struct robject{
	void* obj;
	void* destroy;
}

shared{
	void*[] saveFromGC;
}

void delFromSave(RhData* ptr){
	for(int i; i < saveFromGC.length; i++){
		if(saveFromGC[i] == ptr){
			if(i + 1 == saveFromGC.length){
				saveFromGC = saveFromGC[0..$-1];
			}else{
				saveFromGC[i] = saveFromGC[$-1];
				saveFromGC = saveFromGC[0..$-1];
			}
			break;
		}
	}
}

bool collectGC(bool dontclear = false)(RhData* self){
	if(self is null) return false;
	switch(self.typ){
		case M_ASSOVAR:
			(cast(_assovar*) self).value.refcount--;
			return false;
		case M_ARRAY:
			if(auto ptr = (cast(array*) self).ptrorg){
				for(int i = (cast(array*) self).length; i--; ){
					(*ptr).refcount--;
					if((*ptr).refcount < 1){
						collectGC(*ptr);
					}
					ptr++;
				}
				GC.removeRoot((cast(array*) self).ptrorg);
				GC.free((cast(array*) self).ptrorg);
			}
			break;
		case M_STRING:
			GC.removeRoot(cast(void*) (cast(_string*) self).value.ptr);
			GC.free(cast(void*) (cast(_string*) self).value.ptr);
			break;
		/*case M_FUNCTION:
			GC.free((cast(RhFunctionS*) self).main);
			break;
		case M_MODULE:
			GC.removeRoot((cast(RhModuleS*) self).main);
			GC.free((cast(RhModuleS*) self).main);
			break;
		case M_MODULEC:
			break;*/
		case M_INT, M_FLOAT:
			break;
		case M_NONE:
			return false;
		default:
			return false;
	}
	static if(!dontclear) rhodeus.memory.fda.free(self);
	return false;
}

struct variableManager{
	variableManager* root;
	int len;
	immutable(string)[] variables;
	int[string] variablepos; 

	static auto create(variableManager* root){
		auto sm = cast(variableManager*) GC.calloc((variableManager).sizeof);
		*sm = variableManager(root);
		return sm;
	}
/*		EAX.refcount++;
		for(int y = self.len - 2; y--; ){
			if(!--(*qwe).refcount)
				collectGC(*qwe);
			qwe++;
		}
		EAX.refcount--;
		memset(memory.memory.ptr + memory.index, 0, self.len * (RhData*).sizeof);*/

	public final int* opBinary(string op)(string key) if (op == "in") {
		return key in variablepos;
	}
	public final void* memoryGet(void** memory, int id){
		return cast(void*) memory[id];
	}
	final auto reserve(string name){
		variablepos[name] = variables.length;
		scope(exit) variables ~= name;
		return variables.length;
	}
	void opIndexAssign(RhData** memory, RhData* x, string name){
		if(auto lx = name in variablepos) memory[*lx] = x;
		else{
			variables ~= name;
			variablepos[name] = variables.length;
			memory[variables.length] = x;
		}
	}
	final static void newChild(ref variableManager* dM){
		dM = variableManager.create(dM);
	}
	final static void killChild(ref variableManager* dM){
		dM = dM.root;
	}
	final @property auto size(){
		return variables.length;
	}
}
private{
	bool isIn(RhData* obj, ThreadMem*, RhData* self){
		throw new RhError(1003, "in", self.type, obj.type);
	}
	void opEqualAdd(RhData* obj, ThreadMem*, RhData** self){
		throw new RhError(1003, "+=", (*self).type, obj.type);
	}
	void opEqualMul(RhData* obj, ThreadMem*, RhData** self){
		throw new RhError(1003, "*=", (*self).type, obj.type);
	}
	void opEqualMod(RhData* obj, ThreadMem*, RhData** self){
		throw new RhError(1003, "%=", (*self).type, obj.type);
	}
	void opEqualDiv(RhData* obj, ThreadMem*, RhData** self){
		throw new RhError(1003, "/=", (*self).type, obj.type);
	}
	void opEqualSub(RhData* obj, ThreadMem*, RhData** self){
		throw new RhError(1003, "-=", (*self).type, obj.type);
	}
	RhData copy(ref RhData self){
		return self;
	}
	bool hasValue(ThreadMem*){
		return false;
	}
	RhData* getSub(string attr, ThreadMem*, RhData* self){
		throw new RhError(1002, self.type, attr);
	}
	RhData* setSub(string attr, RhData* value, ThreadMem*, RhData* self){
		throw new RhError(1002, self.type, attr);
	}
	RhData** opIndex(RhData*, ThreadMem*, RhData* ){
		throw new Exception("opindex not defined");
	}
	RhData* opSlice(RhData* obj, RhData* obj2, ThreadMem*, RhData* self){
		throw new Exception("opindex not defined");
	}
	RhData* opIndexAssign(RhData*, RhData* , ThreadMem*, RhData*){
		throw new Exception("opindex not defined");
	}
	RhData* opSliceAssign(RhData*, RhData*, RhData*, ThreadMem*, RhData*){
		throw new Exception("opindex not defined");
	}
	bool opLower(RhData* obj, ThreadMem* rhvm, RhData* self){
		throw new RhError(1003, "<", self.type, obj.type);
	}
	bool opLowerEquals(RhData* obj, ThreadMem*, RhData* self){
		throw new RhError(1003, "<=", self.type, obj.type);
	}
	bool opGreater(RhData* obj, ThreadMem*, RhData* self){
		throw new RhError(1003, ">", self.type, obj.type);
	}
	bool opGreaterEquals(RhData* obj, ThreadMem*, RhData* self){
		throw new RhError(1003, "<", self.type, obj.type);
	}
	bool opEquals(RhData* obj, ThreadMem*, RhData* self){
		throw new RhError(1003, "<", self.type, obj.type);
	}
	bool opNotEquals(RhData* obj, ThreadMem*, RhData* self){
		throw new RhError(1003, "<", self.type, obj.type);
	}
	void inc(ThreadMem* rhvm){
		throw new RhError(1030, (*rhvm.EAXP).type);
	}



	void dec(ThreadMem* rhvm){
		throw new RhError(1031, (*rhvm.EAXP).type);
	}
	RhData* opNot(ThreadMem*, RhData* self){
		throw new RhError(1049, self.type);
	}
	string toString(ThreadMem*, RhData* self){
		throw new RhError(1029, self.type);
	}
	RhData* opDiv(RhData* self, ThreadMem*, RhData* obj){
		throw new RhError(1003, "/", self.type, obj.type);
	}
	RhData* opMul(RhData* self, ThreadMem*, RhData* obj){
		throw new RhError(1003, "*", self.type, obj.type);
	}
	RhData* opSub(RhData* self, ThreadMem*, RhData* obj){
		throw new RhError(1003, "-", self.type, obj.type);
	}
	RhData* opAdd(RhData* self, ThreadMem*, RhData* obj){
		throw new RhError(1003, "+", self.type, self.type);
	}
	void opAddAssign(RhData* self, ThreadMem*, RhData* obj){
		throw new RhError(1003, "+=", self.type, self.type);
	}
	RhData* opMod(RhData* self, ThreadMem*, RhData* obj){
		throw new RhError(1003, "%", self.type, obj.type);
	}
	void opCall(ThreadMem* rhvm, int){
		throw new RhError(1028, (*rhvm.EAXP).type);
	}
}