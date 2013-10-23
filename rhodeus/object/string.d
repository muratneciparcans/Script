/*
Rhodeus Script (c) 2013 by Talha Zekeriya Durmuş <zekeriya@talhadurmus.com>

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/
module rhodeus.object.string;
import rhodeus.object.memory;

import std.conv : to;
import std.string;
import std.format;
import std.array;
static import std.array;

__gshared dFunctionSM*[string] functions;


struct _string{
	mixin rhdata;
	string value;
}
private struct _string2{
	mixin rhdata;
	int length;
	char* ptr;
}
RhData* RhString(int count = 0)(string z){
	auto a1 = cast(char*) GC.malloc(char.sizeof*z.length, GC.BlkAttr.NO_SCAN | GC.BlkAttr.APPENDABLE );
	a1[0..z.length] = cast(char[]) z.dup[];
	GC.addRoot(cast(void*) a1);

	auto a2 = smalloc!(_string2);
	*a2 = _string2(M_STRING, count, false, z.length, a1);
	return cast(RhData*) a2;
}
/*
RhData* RhString(char z){
	return cast(RhData*) new _string(M_STRING, cast(string) [z]);
}*/
__gshared static this(){
	functions["replace"] = RhDfunctionS("replace", &.replace, 2);
	functions["split"] = RhDfunctionS("split", &.splitx, 2);
	functions["indexOf"] = RhDfunctionS("indexOf", &.indexOfx, args.unlimited);
	functions["format"] = RhDfunctionS("format", &.format_, 2);
	
	with(datatable[M_STRING]){
		opSlice = &.opSlice;
		opIndex = &.opIndex;
		hasValue = &.hasValue;
		
		isIn = &.isIn;
		opEquals = &.opEquals;
		opNotEquals = &.opNotEquals;

		toString = &.toString;
		opMul = &.opMul;
		opAdd = &.opAdd;
		getSub = &.getSub;

		opEqualAdd = &.opEqualAdd;

	}
}

bool hasValue(ThreadMem* rhvm){
	return (*cast(_string**) rhvm.EAXP).value.length != 0;
}

RhData* replace(RhData* arg1, RhData* arg2, ThreadMem* rhvm, dFunctionS* self){
	return RhString(std.array.replace(self.sub.toString(), arg1.toString(), arg2.toString()));
}

RhData* format_(dFunctionS* self, ThreadMem* rhvm, RhData*[] args){
	auto pattr = FormatSpec!char(self.sub.toString());
	auto appn = appender!string();
	string[] strl = new string[args.length];
	for(int i; i < args.length; i++){
		strl[i] ~= args[i].toString();
	}
	foreach (i, value; strl) {
		if(!pattr.writeUpToNextSpec(appn)) throw new RhError(1037, to!string(strl[i..$]));
		formatValue(appn, value, pattr);
	}
	if(pattr.writeUpToNextSpec(appn)){
		throw new RhError(1038);
	}
	return RhString(appn.data);
}

void opEqualAdd(RhData* self, ThreadMem*, RhData** obj){
	if((*obj).typ==M_STRING){
		(cast(_string*) self).value ~= (*obj).toString();
	}else
		throw new RhError(1003, "+", self.type, (*obj).type);
}

bool isIn(RhData* name, ThreadMem*, RhData* self){
	return self.toString().indexOf(name.toString()) == -1 ? false : true ;
}

string toString(ThreadMem* rhvm, RhData* self){
	return (cast(_string*) self).value;
}

RhData* getSub(string attr, ThreadMem* rhvm,RhData* self){
	switch(attr){
		case "str": return self;
		case "toint": return RhInt(to!int((cast(_string*) self).value));
		case "length": return RhInt((cast(_string*) self).value.length);
		case "lower": return RhString(self.toString().toLower());
		case "upper": return RhString(self.toString().toUpper());
		case "capitalize": return RhString(self.toString().capitalize());
		case "strip": return RhString(self.toString().strip());
		case "stripLeft": return RhString(self.toString().stripLeft());
		case "stripRight": return RhString(self.toString().stripRight());
		default:
			auto zx = attr in functions;
			if (zx){
				return cast(RhData*) new dFunctionS(M_DFUNCTION, 0, false, *zx, self);
			}else throw new RhError(1002, "string", attr);
	}
}

RhData* splitx(RhData* param1, ThreadMem* rhvm, dFunctionS* self){
	RhData*[] array;
	foreach(string xx; split(self.sub.toString(), param1.toString())){
		array ~= RhString(xx);
	}
	return null;//rhvm.RhArray(array);
}

RhData* indexOfx(dFunctionS* self, ThreadMem* rhvm, RhData*[] params){
	if(params.length == 0 || params.length > 2)
		throw new RhError(1014, (cast(dFunctionS*) self).main.name, "1", "2", to!string(params.length));
	CaseSensitive boo = CaseSensitive.yes;
	if (params.length == 2 ){
		if(params[1].typ!=M_BOOL) throw new RhError(1006, self.main.name, "2", "BOOL", params[1].type);
		if(params[1]==False) boo = CaseSensitive.no;
	}
	return RhInt(self.sub.toString().indexOf(params[0].toString(), boo));
}
RhData* opAdd(RhData* self, ThreadMem* rhvm, RhData* obj){
	if(obj.typ==M_STRING){
		return RhString(self.toString() ~ obj.toString());
	}
	else throw new RhError(1003, "+", self.type, obj.type);
}
RhData* opMul(RhData* self, ThreadMem*, RhData* obj){
/*	if(obj.typ==M_INT)
		return RhString(std.array.replicate(self.toString(), (cast(RhInt*) obj).value < 0? 0: (cast(RhInt*) obj).value));
	else if(obj.typ==M_FLOAT) return RhString(std.array.replicate(self.toString(), cast(int) (cast(_float*) obj).value < 0? 0: cast(int) (cast(RhInt*) obj).value));
	else*/
		throw new RhError(1003, "*", self.type, obj.type);
}

bool opEquals(RhData* obj, ThreadMem*, RhData* self){
	return self.toString() == obj.toString();
}
bool opNotEquals(RhData* obj, ThreadMem*, RhData* self){
	return self.toString() != obj.toString();
}

RhData** opIndex(RhData* key, ThreadMem*, RhData* self){
	return null;/*
	auto arr = (cast(_string*) self).value;
	int start = (cast(RhInt*) key).value;
	if(start < 0){
		if((cast(int) arr.length) + start < 0) start = 0;
		else start += arr.length;
	}else if(start > arr.length) start = arr.length - 1;
	if(start > (cast(int) arr.length) - 1 || start<0) throw new RhError(1020);
	auto y = RhString([arr.ptr[start]]);
	auto m = &y;
	return cast(RhData**) cast(int) m;
	*/
}
RhData* opSlice(RhData* fromx, RhData* tox, ThreadMem*, RhData* self){
/*	int start, end;
	if(fromx.typ == M_INT)
		start = (cast(RhInt*) fromx).value;
	else if(fromx.typ != M_NONE)
		throw new RhError(1024);

	auto arr = (cast(_string*) self).value;
	if(tox.typ == M_INT)
		end = (cast(RhInt*) tox).value;
	else if(tox.typ == M_NONE)
		end = arr.length;
	else
		throw new RhError(1024);
	if(start < 0){
		if((cast(int) arr.length) + start < 0) start = 0;
		else start += arr.length;
	}else if(start > arr.length) start = arr.length - 1;

	if(end < 0){
		if((cast(int) arr.length) + end < 0) end = 0;
		else end += arr.length;
	}else if(end > arr.length) end = arr.length;
	if(end<start) end = start;
	if(start!=end && start > (cast(int) arr.length) - 1 || start<0) throw new RhError(1020);

	return RhString(cast(string) arr.ptr[start..end]);*/
	return null;
}
