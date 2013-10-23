/*
Rhodeus Script (c) 2013 by Talha Zekeriya Durmuş <zekeriya@talhadurmus.com>

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/
module rhodeus.object.dictionary;

import rhodeus.object.memory;
import std.conv : to;
import std.random : randomSample;

struct _dict{
	mixin rhdata;
	RhData*[string] value;
}
struct _dict2{
	mixin rhdata;
	void* value;
}

/*
Creating new 'dictionary' object.
*/
RhData* RhDictionary(int count = 0)(RhData*[string] z){
	return cast(RhData*) new _dict(M_DICT, count,false, z);
}

/*
This function changes default function for codearea data type.
*/
__gshared static this(){
	with(datatable[M_ASSOVAR]){
		toString = &rhodeus.object.assovar.toString;
	}	
	with(datatable[M_DICT]){
		opAdd = &.opAdd;

		hasValue = &.hasValue;

		getSub = &.getSub;
		opIndex = &.opIndex;
		opIndexAssign = &.opIndexAssign;
		isIn = &.isIn;

		toString = &.toString;
	}	
}

bool hasValue(ThreadMem* rhvm){
	return (*cast(_dict**) rhvm.EAXP).value.length == 0 ? true: false;
}

/* codearea sub functions */
void*[string] functions;

/* accessing sub function */
RhData* getSub(string attr, ThreadMem* rhvm, RhData* self){
	switch(attr){
		case "str": return RhString(self.toString());
		case "length": return RhInt((cast(_dict*) self).value.length);
		case "keys": 
			RhData*[] arr;
			foreach(key; (cast(_dict*) self).value.keys){
				arr ~= RhString!1(key);
			}
			return RhArray(arr);
		case "values": 
			foreach(val; (cast(_dict*) self).value.values){
				val.refcount++;
			}
			return RhArray((cast(_dict*) self).value.values);
		default:
			if (auto zx = attr in functions)
				return cast(RhData*) *zx;
			else 
				throw new RhError(1002, "dictionary", attr);
	}
}

RhData** opIndex(RhData* key, ThreadMem*, RhData* self){
	auto x = key.toString() in (cast(_dict*) self).value;
	if(x is null) throw new Exception(key.toString()~" kitaplık içerisinde bulunamadı!");
	return x;
}
RhData* opIndexAssign(RhData* key, RhData* value, ThreadMem*, RhData* self){
	auto str = key.toString();
	if(auto y = str in (cast(_dict*) self).value){
		(*y).refcount--;
		*y = value;
		value.refcount++;
	}else{
		(cast(_dict*) self).value[str] = value;
		value.refcount++;
	}
	return value;
}
bool isIn(RhData* name, ThreadMem*, RhData* self){
	auto x = name.toString() in (cast(_dict*) self).value;
	if(x is null) return false;
	return true;
}
string toString(ThreadMem* rhvm, RhData* self){
	string val;
	bool i;
	foreach(key, valm; (cast(_dict*) self).value){
		if(valm.typ==M_STRING)
			val ~= '\"'~key ~ "\": \"" ~ valm.toString()~"\", ";
		else
			val ~= '\"'~key ~ "\": " ~ valm.toString()~", ";
		i=true;
	}
	if(i!=0) val = val[0..$-2];
	return "{"~val~"}";
}


RhData* opAdd(RhData* obj, ThreadMem*, RhData* self){
	if(obj.typ==M_DICT){
		RhData*[string] ne;
		foreach(k, v;(cast(_dict*) self).value){
			v.refcount++;
			ne[k] = v;
		}
		foreach(k, v;(cast(_dict*) obj).value){
			v.refcount++;
			ne[k] = v;
		}
		return RhDictionary(ne);
	}else
		throw new RhError(1003, "+", self.type, obj.type);
}