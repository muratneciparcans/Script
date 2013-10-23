/*
Rhodeus Script (c) 2013 by Talha Zekeriya Durmuş <zekeriya@talhadurmus.com>

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/
module rhodeus.object.rfunction;

import rhodeus.object.memory;
import std.conv: to;
//import RhAssembler;
import std.stdio;

alias size_t label;

RhFunctionS* RhFunction(string val, out RhFunctionSM* outt){
	auto yy = new RhFunctionSM(val);
	outt = yy;

	auto data = smalloc!(RhFunctionS);
	*data = RhFunctionS(M_FUNCTION, 0, false, yy); 
	return data;
	/*	auto fnm = cast(RhFunctionSM*) GC.malloc((RhFunctionSM).sizeof);
	*fnm = RhFunctionSM(val, codes, parameters);
	auto ret = cast(RhFunctionS*) GC.malloc((RhFunctionS).sizeof);
	*ret = RhFunctionS(M_FUNCTION, fnm);
	return ret;*/
}
struct RhFunctionS{
	mixin rhdata;
	RhFunctionSM* main;
	RhData* sub;
}

struct RhFunctionSM{
	string name;
	size_t codes;
	variableManager* stm;
}

__gshared static this(){
	with(datatable[M_FUNCTION]){
		toString = &.toString;
		opCall = &.opCall;
		getSub = &.getSub;
	}
}
void opCall(ThreadMem* rhvm, int length){
 	RhFunctionS* self = *cast(RhFunctionS**) rhvm.finits;

	//writefln("opCall %s ,, %s -> %s", rhvm.EBP, rhvm.calls.varcount, rhvm.EBP[0..10]);
	rhvm.EBP += rhvm.calls.varcount;
	//writefln("opCall %s ,, %s -> %s", rhvm.EBP, rhvm.calls.varcount, rhvm.EBP[0..10]);

	rhvm.calls++;
	*rhvm.calls = RCALL(rhvm.cop + int.sizeof, self.main.stm.size, null, length, length);

	rhvm.cop = rhvm.cops + (cast(RhFunctionS*) self).main.codes;

	rhvm.EAX = None;
	rhvm.EAXP = &rhvm.EAX;
}

string toString(ThreadMem* rhvm,RhData* self){
	return "[Function: " ~ (cast(RhFunctionS*) self).main.name~"]";
}

RhData* getSub(string attr, ThreadMem* rhvm, RhData* self){
	auto main = (cast(RhFunctionS*) self).main;
	switch(attr){
		case "name": return RhString(main.name);
			//		case "opcodes": return RhString(to!string(*main.codes));
		default:
			throw new RhError(1002, main.name, attr);
	}
}