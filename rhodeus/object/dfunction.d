/*
Rhodeus Script (c) 2013 by Talha Zekeriya Durmuş <zekeriya@talhadurmus.com>

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/

module rhodeus.object.dfunction;
import rhodeus.object.memory;
import std.format: format;
import std.conv: to;

enum args : byte {
	none, unlimited, limited
	//, dfn
}
struct dFunctionS{
	mixin rhdata;
	dFunctionSM* main;
	RhData* sub;
}

struct dFunctionSM{
	void* fn;
	string name;
	args argt;
	int length;
}

/*
	Creating new 'D Function' object.
*/
/*RhData* RhDfunction(string name, int rettyp, RhData* fn, RhData* arr = null){
	return new dFunctionS(M_DFUNCTION, name.dup, fn, args.dfn, rettyp, arr);
}*/
RhData* RhDfunction(string name, void* fn){
	return cast(RhData*) new dFunctionS(M_DFUNCTION, 0, false, new dFunctionSM(fn, cast(string) name.dup, args.none), null);
}
auto RhDfunctionS(string name, void* fn){
	return new dFunctionSM(fn, cast(string)name.dup, args.none);
}
RhData* RhDfunction(string name, void* fn, args argt){
	return cast(RhData*) new dFunctionS(M_DFUNCTION, 0, false, new dFunctionSM(fn, cast(string) name.dup, argt), null);
}
auto RhDfunctionS(string name, void* fn, args argt){
	return new dFunctionSM(fn, cast(string) name.dup, argt);
}
RhData* RhDfunction(string name, void* fn, int length){
	return cast(RhData*) new dFunctionS(M_DFUNCTION, 0, false, new dFunctionSM(fn, cast(string) name.dup, args.limited, cast(RhData*) length), null);
}
auto RhDfunctionS(string name, void* fn, int length){
	return new dFunctionSM(fn, cast(string)name.dup, args.limited, cast(RhData*) length);
}

/*
	This function changes default function for codearea data type.
*/
shared static this(){
	with(datatable[M_DFUNCTION]){
		opCall = &.opCall;
		toString = &.toString;
	}
}

void opCall(ThreadMem* rhvm, int length){
	dFunctionS* self = *cast(dFunctionS**) rhvm.finits;
	if((cast(dFunctionS*) self).main.argt == args.none){
		if(length!=0)
			throw new RhError(1008, (cast(dFunctionS*) self).main.name, to!string((cast(dFunctionS*) self).main.length), to!string(length));
		auto fna = (cast(dFunctionS*) self).main.fn;
		asm{
			mov EAX, self;
			mov ECX, fna;
			leave;
			pop EDX;//Get EIP
			pop EBX;//Get length
			push EDX;//Set EIP
			jmp ECX;
		}
/*	}else if( (cast(dFunctionS*) self).argt == args.dfn){
		RhData** ptrx;
		argarray args = argarray(null, length);
		asm{ mov ptrx, EBP;}
		args.ptr = ptrx + length + 2;
		int[] wpush;
		for(int i; i < args.length; i++){
			switch((*cast(int*) args[i])){
				case M_INT:
					wpush ~= (cast(_int*) args[i]).value;
					break;
				case M_STRING:
					wpush ~= cast(int) (cast(_string*) args[i]).ptr;
					wpush ~= (cast(_string*) args[i]).length;
					break;
				default:
					break;
			}
		}
		writeln(wpush);
		RhData* point = wpush.ptr;
		for(int i; i < args.length + 1; i++){
			asm{
				mov EAX, dword ptr [point];
				push dword ptr [EAX];
			}
			point++;
		}
		(cast(void function()) (cast(dFunctionS*) self).fn)();
		string val = void;
		asm{
/*			mov ECX,dword ptr [self];
			mov EDX,dword ptr [ECX+14h];
			cmp EDX,d;
			jne cout;
			cout:
*//*
		}
		if((cast(dFunctionS*) self).length == M_STRING){
			asm{
				mov dword ptr [val], EAX;
				mov dword ptr [val - 0x4], EDX;
			}
			writeln(val);
		}*/
	}else if( (cast(dFunctionS*) self).main.argt == args.limited){
		if(length!=cast(int) (cast(dFunctionS*) self).main.length)
			throw new RhError(1008, (cast(dFunctionS*) self).main.name, to!string((cast(dFunctionS*) self).main.length), to!string(length));
		auto fna = (cast(dFunctionS*) self).main.fn;
		asm{
			mov EAX, self;
			mov ECX, fna;
			leave;
			pop EDX;//Get EIP
			pop EBX;//Get length
			push EDX;//Set EIP
			jmp ECX;
		}
	}else{
		rhvm.EAX = (cast(RhData* function(dFunctionS*, ThreadMem*, RhData** , int )) (cast(dFunctionS*) self).main.fn)(self, rhvm, rhvm.ESP - length, length);
		rhvm.EAXP = &rhvm.EAX;
		for(int i = *cast(int*) rhvm.cop; i; i--){
			rhvm.ESP--;
			(*rhvm.ESP).refcount--;
		}
		rhvm.cop += int.sizeof;

	}
}
string toString(ThreadMem* rhvm, RhData* self){
	return (cast(dFunctionS*) self).main.name;
}