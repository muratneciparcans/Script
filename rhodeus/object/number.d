/*
Rhodeus Script (c) 2013 by Talha Zekeriya Durmuş <zekeriya@talhadurmus.com>

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/

module rhodeus.object.number;
import rhodeus.object.memory;

import std.conv : to;
 
dFunctionSM*[string] functions;

/*
	Creating new 'int' object.
*/
struct _int{
	mixin rhdata;
	int value;
}



RhData* RhInt(int value = 0){
	auto data = smalloc!(_int);
	*data = _int(M_INT, 0, false, value);
	return cast(RhData*) data;
}

bool hasValue(ThreadMem* rhvm){
	return cast(bool) (*cast(_int**) rhvm.EAXP).value;
}
/*
	This function changes default function for void data type.
*/

__gshared static this(){
	with(datatable[M_INT]){
		opLower = &.opLower;
		toString = &.toString;
		inc = &.inc;
		dec = &.dec;


		hasValue = &.hasValue;

		getSub = &.getSub;

		opAdd = &.opAdd;
		opMod = &.opMod;
		opMul = &.opMul;
		opDiv = &.opDiv;
		opSub = &.opSub;

		opLowerEquals = &.opLowerEquals;
		opGreater = &.opGreater;
		opGreaterEquals = &.opGreaterEquals;
		opEquals = &.opEquals;
		opNotEquals = &.opNotEquals;

		opEqualAdd = &.opEqualAdd;
		opEqualSub = &.opEqualSub;
		opEqualMul = &.opEqualMul;
		opEqualDiv = &.opEqualDiv;
		opEqualMod = &.opEqualMod;
	}

}

bool opLower(RhData* self, ThreadMem* rhvm, RhData* obj){
	if(obj.typ == M_INT)
		return (cast(_int*) self).value < (cast(_int*) obj).value;
	else if(obj.typ == M_FLOAT)
		return (cast(_int*) self).value < (cast(_float*) obj).value;
	else
		throw new RhError(1003, "<", self.type, obj.type);
}

string toString(ThreadMem* rhvm, RhData* self){
	return to!string((cast(_int*) self).value);
}
void inc(ThreadMem* rhvm){
	auto self = rhvm.EAXP;
	if((*self).refcount > 1){
		(*self).refcount--;
		*self = RhInt((cast(_int*) (*self)).value + 1);
		(*self).refcount++;
	}else{
		(cast(_int*) *self).value++;
	}
}

bool opLowerEquals(RhData* self, ThreadMem*, RhData* obj){
	
	if(obj.typ == M_INT)
		return (cast(_int*) self).value <= (cast(_int*) obj).value;
	else if(obj.typ == M_FLOAT)
		return (cast(_int*) self).value <= (cast(_float*) obj).value;
	else
		throw new RhError(1003, "<=", self.type, obj.type);
}
bool opGreater(RhData* self, ThreadMem*, RhData* obj){
	
	if(obj.typ == M_INT)
		return (cast(_int*) self).value > (cast(_int*) obj).value;
	else if(obj.typ == M_FLOAT)
		return (cast(_int*) self).value > (cast(_float*) obj).value;
	else
		throw new RhError(1003, ">", self.type, obj.type);
}
bool opGreaterEquals(RhData* self, ThreadMem*, RhData* obj){
	
	if(obj.typ == M_INT)
		return (cast(_int*) self).value >= (cast(_int*) obj).value;
	else if(obj.typ == M_FLOAT)
		return (cast(_int*) self).value >= (cast(_float*) obj).value;
	else
		throw new RhError(1003, ">=", self.type, obj.type);
}
bool opEquals(RhData* self, ThreadMem*, RhData* obj){
	
	if(obj.typ == M_INT)
		return (cast(_int*) self).value == (cast(_int*) obj).value;
	else if(obj.typ == M_FLOAT)
		return (cast(_int*) self).value == (cast(_float*) obj).value;
	else
		throw new RhError(1003, "==", self.type, obj.type);
}
bool opNotEquals(RhData* self, ThreadMem*, RhData* obj){
	
	if(obj.typ == M_INT)
		return (cast(_int*) self).value != (cast(_int*) obj).value;
	else if(obj.typ == M_FLOAT)
		return (cast(_int*) self).value != (cast(_float*) obj).value;
	else
		throw new RhError(1003, "!=", self.type, obj.type);
}
void dec(ThreadMem* rhvm){
	auto self = rhvm.EAXP;
	if((*self).refcount > 1){
		(*self).refcount--;
		*self = RhInt((cast(_int*) (*self)).value - 1);
		(*self).refcount++;
	}else{
		(cast(_int*) *self).value--;
	}
}
RhData* opSub(RhData* self, ThreadMem* rhvm, RhData* obj){
	
	if(obj.typ==M_INT){
		return RhInt((cast(_int*) self).value - (cast(_int*) obj).value);
	}else if(obj.typ==M_FLOAT){
		return RhFloat((cast(_int*) self).value - (cast(_float*) obj).value);
	}else
		throw new RhError(1003, "-", self.type, obj.type);
}

RhData* opAdd(RhData* self, ThreadMem* rhvm, RhData* obj){
	if(obj.typ==M_INT){
		return RhInt((cast(_int*) self).value + (cast(_int*) obj).value);
	}else if(obj.typ==M_FLOAT){
		return RhFloat((cast(_int*) self).value + (cast(_float*) obj).value);
	}else
		throw new RhError(1003, "+", self.type, obj.type);
}
void opEqualAdd(RhData* obj, ThreadMem*, RhData** self){
 	if(obj.typ==M_INT){
		if((*self).refcount > 1){
			(*self).refcount--;
			(*self) = RhInt((cast(_int*) (*self)).value + (cast(_int*) obj).value);
			(*self).refcount++;
		}else{
			(*cast(_int**) self).value += (cast(_int*) obj).value;
		}
	}else if(obj.typ==M_FLOAT){
		(*self).refcount--;
		*self = RhFloat((*cast(_int**) self).value + (cast(_float*) obj).value);
		(*self).refcount++;
	}else
		throw new RhError(1003, "+=", (*self).type, obj.type);
}
void opEqualSub(RhData* obj, ThreadMem*, RhData** self){
	if(obj.typ==M_INT){
		if((*self).refcount > 1){
			(*self).refcount--;
			(*self) = RhInt((*cast(_int**) self).value - (cast(_int*) obj).value);
			(*self).refcount++;
		}else{
			(*cast(_int**) self).value -= (cast(_int*) obj).value;
		}
	}else if(obj.typ==M_FLOAT){
		(*self).refcount--;
		(*self) = RhFloat((*cast(_int**) self).value - (cast(_float*) obj).value);
		(*self).refcount++;
	}else
		throw new RhError(1003, "-=", (*self).type, obj.type);
}
void opEqualMod(RhData* obj, ThreadMem*, RhData** self){
	if(obj.typ==M_INT){
		if((*self).refcount > 1){
			(*self).refcount--;
			*self = RhInt((*cast(_int**) self).value % (cast(_int*) obj).value);
			(*self).refcount++;
		}else{
			(*cast(_int**) self).value %= (cast(_int*) obj).value;
		}
	}else if(obj.typ==M_FLOAT){
		(*self).refcount--;
		*self = RhFloat((*cast(_int**) self).value % (cast(_float*) obj).value);
		(*self).refcount++;
	}else
		throw new RhError(1003, "%=", (*self).type, obj.type);
}
void opEqualMul(RhData* obj, ThreadMem*, RhData** self){
	if(obj.typ==M_INT){
		if((*self).refcount > 1){
			(*self).refcount--;
			*self = RhInt((*cast(_int**) self).value * (cast(_int*) obj).value);
			(*self).refcount++;
		}else{
			(*cast(_int**) self).value *= (cast(_int*) obj).value;
		}
	}else if(obj.typ==M_FLOAT){
		(*self).refcount--;
		*self = RhFloat((*cast(_int**) self).value * (cast(_float*) obj).value);
		(*self).refcount++;
	}else
		throw new RhError(1003, "*=", (*self).type, obj.type);
}
void opEqualDiv(RhData* obj, ThreadMem*, RhData** self){
	if(obj.typ==M_INT){
		(*self).refcount--;
		*self = RhFloat(cast(double) (*cast(_int**) self).value / (cast(_int*) obj).value);
		(*self).refcount++;
	}else if(obj.typ==M_FLOAT){
		(*self).refcount--;
		*self = RhFloat((*cast(_int**) self).value / (cast(_float*) obj).value);;
		(*self).refcount++;
	}else
		throw new RhError(1003, "/=", (*self).type, obj.type);
}
RhData* opMod(RhData* self, ThreadMem* rhvm,RhData* obj){
	if(obj.typ==M_INT){
		return RhInt((cast(_int*) self).value % (cast(_int*) obj).value);
	}else if(obj.typ==M_FLOAT){
		return RhFloat((cast(_int*) self).value % (cast(_float*) obj).value);
	}else
		throw new RhError(1003, "%", self.type, obj.type);
}
RhData* opMul(RhData* self, ThreadMem* rhvm, RhData* obj){
	if(obj.typ==M_INT){
		return RhInt((cast(_int*) self).value * (cast(_int*) obj).value);
	}else if(obj.typ==M_FLOAT){
		return RhFloat((cast(_int*) self).value * (cast(_float*) obj).value);
	}else
		throw new RhError(1003, "*", self.type, obj.type);
}
RhData* opDiv(RhData* self, ThreadMem* rhvm, RhData* obj){
	if(obj.typ==M_INT){
		return RhFloat(cast(double) (cast(_int*) self).value / (cast(_int*) obj).value);
	}else if(obj.typ==M_FLOAT){
		return RhFloat((cast(_int*) self).value / (cast(_float*) obj).value);
	}else throw new RhError(1003, "/", self.type, obj.type);
}
RhData* getSub(string attr, ThreadMem* rhvm, RhData* self){
	switch(attr){
		case "str": return RhString(self.toString());
		default:
			auto zx = attr in functions;
			if (zx){
				return cast(RhData*) new dFunctionS(M_DFUNCTION, 0, false, *zx, self);
			}else throw new RhError(1002, "int", attr);
	}
}