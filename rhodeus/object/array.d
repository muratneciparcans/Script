/*
Rhodeus Script (c) 2013 by Talha Zekeriya Durmuş <zekeriya@talhadurmus.com>

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/
module rhodeus.object.array;

import rhodeus.object.memory;
import std.conv : to;
import std.random : randomSample;
import std.algorithm: reverse;
/*
Creating new 'array' object.
*/
RhData* RhArray(int count = 0)(RhData*[] z){
	auto arr = smalloc!(arrayP);
	auto y = z.dup;
	*arr = arrayP(M_ARRAY, count, false, y, y.ptr);
	GC.addRoot(cast(void*) y.ptr);
	return cast(RhData*) arr;
}

struct array{
	mixin rhdata;
	int length;
	RhData** ptr;
	RhData** ptrorg;
}
struct arrayP{
	mixin rhdata;
	RhData*[] ptr;
	RhData** ptrorg;
}


/* array sub functions */
dFunctionSM*[string] functions;

__gshared static this(){
	with(datatable[M_ARRAY]){
		opSliceAssign = &.opSliceAssign;
		opSlice = &.opSlice;
		opIndex = &.opIndex;
		opIndexAssign = &.opIndexAssign;
		isIn = &.isIn;
		opAdd = &.opAdd;
		getSub = &.getSub;
		toString = &.toString;
		opEquals = &.opEquals;
		opNotEquals = &.opNotEquals;
	}
	functions = [
		"append": RhDfunctionS("append", &append, args.unlimited),
		"join": RhDfunctionS("join", &join, 1),
		"getRandom": RhDfunctionS("getRandom", &getRandom, args.unlimited),
		"combine": RhDfunctionS("combine", &combine, 1),
		"search": RhDfunctionS("search", &search, 1),
		//"each": &each
	];

}
RhData** opIndex(RhData* key, ThreadMem*, RhData* self){
	int start;
	if(key.typ == M_INT)
		start = (cast(_int*) key).value;
	else if(key.typ != M_NONE)
		throw new RhError(1027);

	if(start < 0){
		if((cast(int) (cast(array*) self).length) + start < 0) start = 0;
		else start += (cast(array*) self).length;
	}else if(start > (cast(array*) self).length - 1) start = (cast(array*) self).length - 1;
	if(start > (cast(int) (cast(array*) self).length) - 1 || start<0) throw new RhError(1020);
	return &(cast(array*) self).ptr[start];
}

bool opEquals(RhData* obj, ThreadMem*, RhData* self){
	return self.toArray() == obj.toArray();
}
bool opNotEquals(RhData* obj, ThreadMem*, RhData* self){
	return self.toArray() != obj.toArray();
}

RhData* opSlice(RhData* fromx, RhData* tox, ThreadMem* rhvm, RhData* self){
	int start, end;
	if(fromx.typ == M_INT)
		start = (cast(_int*) fromx).value;
	else if(fromx.typ != M_NONE)
		throw new RhError(1024);
	auto arr = cast(array*) self;
	if(tox.typ == M_INT)
		end = (cast(_int*) tox).value;
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
	foreach(elm;arr.ptr[start..end]){
		elm.refcount++;
	}
	return RhArray(arr.ptr[start..end]);
}
RhData* opIndexAssign(RhData* key, RhData* value, ThreadMem*, RhData* self){
	auto arr = (cast(array*) self);
	int start;
	if(key.typ == M_INT)
		start = (cast(_int*) key).value;
	else if(key.typ != M_NONE)
		throw new RhError(1027);

	if(start < 0){
		if((arr.length) + start < 0) start = 0;
		else start += arr.length;
	}else if(start > arr.length) start = arr.length - 1;
	if(start > (cast(int) arr.length) - 1) throw new RhError(1020);
	arr.ptr[start].refcount--;
	value.refcount++;
	arr.ptr[start] = value;
	return value;
}
/*
RhData each(ref RhData aktiv, ref rparam[] params){
RhData stack;
switch(params.length){
case 2:
if(params[0].v.typ!=M_SWORD)
goto default;
if(params[1].v.typ!=M_CODEAREA)
goto default;
string vn = params[0].v.toString();
auto ca = (cast(RhCodeArea*) params[1].v.val);
ca.dM.root=RhVM.rhvm.curdM[$-1];
foreach(ref x; aktiv.toArray()){
ca.dM[vn] = x;
if(RhVM.rhvm.interpret(ca.codes, ca.dM, stack)==1) break;
}
return RhNone();
default:
throw new Exception("Hatalı fonksiyon çağırımı!");
}
}
*/

RhData* opSliceAssign(RhData* fromx, RhData* tox, RhData* value, ThreadMem*, RhData* self){
	int start, end;
	auto arr = cast(array*) self;
	if(fromx.typ == M_INT)
		start = (cast(_int*) fromx).value;
	else if(fromx.typ != M_NONE)
		throw new RhError(1024);
	if(tox.typ == M_INT)
		end = (cast(_int*) tox).value;
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

	auto oldarray = (cast(array*) self).ptr[0..(cast(array*) self).length];
	auto willadd = (cast(array*) value).ptr[0..(cast(array*) value).length];

	auto newarray = oldarray[0..start]~willadd~oldarray[end..$];

	arr.length = newarray.length;

	arr.ptr = cast(RhData**) GC.realloc(arr.ptr, newarray.length * (RhData*).sizeof);
	arr.ptr[0..arr.length] = newarray[];

	return self;
}

bool isIn(RhData* name, ThreadMem*, RhData* self){
	auto arr = cast(array*) self;
	auto tmp = &name.opEquals;
	foreach(ref x; arr.ptr[0..arr.length]){
		if( tmp(x) )
			return true;
	}
	return false;
}
RhData* opAdd(RhData* item, ThreadMem* rhvm, RhData* self){
	if(item.typ==M_ARRAY){
		auto arr = self.toArray() ~ item.toArray();
		foreach(elm; arr){
			elm.refcount++;
		}
		return RhArray(arr);
	}else
		throw new RhError(1003, "+", self.type, item.type);
}


/* accessing sub function */
RhData* getSub(string attr, ThreadMem* rhvm,RhData* self){
	switch(attr){
		case "str": return RhString(self.toString());
		case "length": return RhInt((cast(array*) self).length);
		case "reverse":
			auto t = (cast(array*) self).ptr[0..(cast(array*) self).length].dup;
			reverse(t);
			foreach(lm; (cast(array*) self).ptr[0..(cast(array*) self).length]){
				lm.refcount++;
			}
			return RhArray(t);
		case "pop": 
			if((cast(array*) self).length<1)
				throw new RhError(1010, "pop");
			(cast(array*) self).length--;
			(cast(array*) self).ptr[(cast(array*) self).length].refcount--;
			return (cast(array*) self).ptr[(cast(array*) self).length];
		case "shift":
			if((cast(array*) self).length<1)
				throw new RhError(1010, "shift");
			auto x = (cast(array*) self).ptr[0];
			x.refcount--;
			(cast(array*) self).ptr++;
			(cast(array*) self).length--;
			return x;
		default:
			auto zx = attr in functions;
			if (zx){
				auto df = smalloc!(dFunctionS);
				*df = dFunctionS(M_DFUNCTION, 0, false, *zx, self);
				return cast(RhData*) df;
			}else throw new RhError(1002, "array", attr);

	}
}
string toString(ThreadMem* rhvm, RhData* self){
	string val;
	auto ptr = (cast(array*) self).ptr;
	int i;
	for(; i<(cast(array*) self).length; i++, ptr++){
		if((*ptr).typ==M_STRING)
			val ~= '\"'~(*ptr).toString()~"\", ";
		else
			val ~= (*ptr).toString()~", ";
	}
	if(i!=0) val = val[0..$-2];
	return "["~val~"]";
}

RhData*[] toArray(RhData* self){
	if(self.typ != M_ARRAY) throw new Exception("Array expected!");
	return (cast(array*) self).ptr[0..(cast(array*) self).length];
}

RhData* append(dFunctionS* aktiv, ThreadMem* rhvm, RhData*[] params){
	if(aktiv.sub.typ==M_ARRAY){
		auto arr = cast(array*) aktiv.sub;
		typeof(arr.ptr) x = void;
		if(arr.ptr is null){
			arr.ptr = cast(RhData**) GC.malloc(params.length * (RhData*).sizeof, GC.BlkAttr.NO_SCAN | GC.BlkAttr.APPENDABLE);
			version(useRooting){
				GC.addRoot(cast(void*) arr.ptr);
			}else{
				saveFromGC ~= cast(shared) arr.ptr;
			}
			x = arr.ptr;
		}else{
			if(arr.length + params.length > arr.ptr[0..0].capacity){
				//	writeln("new space ", arr.ptr[0..0].capacity, " needed:", arr.length + params.length);
				auto newp = cast(RhData**) GC.realloc(arr.ptr, (arr.length + params.length) * (RhData*).sizeof);
				GC.removeRoot(arr.ptr);
				GC.addRoot(cast(void*) newp);
				arr.ptr = newp;
				newp[0..arr.length] = arr.ptr[0..arr.length];
				x = newp + arr.length;
				for(int i; i < params.length; i++){
					auto y = params[i];
					*x = y;
					y.refcount++;
					x++;
				}
			}else{
				//	writeln("old space use: ", arr.ptr[0..0].capacity);
				x = arr.ptr + arr.length;
				for(int i; i < params.length; i++){
					auto y = params[i];
					*x = y;
					y.refcount++;
					x++;
				}
			}
		}
		arr.length += params.length;
	} 
	else throw new Exception("Sadece array türü üzerinde bu işlemi yapabilirsiniz.");
	return aktiv.sub;
}

RhData* join(RhData* arg1, ThreadMem* rhvm, dFunctionS* aktiv){
	if(arg1.typ != M_STRING) throw new RhError(1006, aktiv.main.name, "1", "STRING", arg1.type);
	string[] result;
	auto arr = cast(array*) aktiv.sub;
	foreach(x; arr.ptr[0..arr.length])
		result ~= x.toString();
	return RhString(std.string.join(result, arg1.toString()));
}
RhData* search(RhData* arg1, ThreadMem* rhvm, dFunctionS* self){
	auto opEquals = &arg1.opEquals;
	foreach(i, ref val; (cast(array*) self.sub).ptr[0..(cast(array*) self.sub).length]){
		if(opEquals(val)) return RhInt(i);
	}
	return RhInt(-1);
}
RhData* getRandom(dFunctionS* aktiv, ThreadMem* rhvm, RhData*[] params){
	if(params.length > 1) throw new RhError(1014, "getRandom", "0", "1", to!string(params.length));
	auto arr = cast(array*) aktiv.sub;
	int cur = 1;
	if(params.length == 1){
		if(params[0].typ != M_INT) throw new RhError(1006, "getRandom", "1", "INT", params[0].type);
		else cur = (cast(_int*) params[0]).value;
		if(cur < 1) throw new Exception("");
		else if(cur > arr.length) throw new Exception("");
	}
	RhData*[] liz;
	foreach(elm; randomSample(arr.ptr[0..arr.length], cur)){
		liz ~= elm;
		elm.refcount++;
	}
	return RhArray(liz);
}
RhData* combine(RhData* arg1, ThreadMem* rhvm, dFunctionS* aktiv){
	if(arg1.typ != M_ARRAY) throw new RhError(1006, "combine", "1", "ARRAY", arg1.type);
	auto arr = cast(array*) aktiv.sub;
	RhData*[string] temp;
	auto mx = (cast(array*) arg1).ptr;
	foreach(i, val; (cast(RhData**) arr.ptr)[0..arr.length]){
		temp[val.toString()] = mx[i];
		mx[i].refcount++;
	}
	return RhDictionary(temp);
}