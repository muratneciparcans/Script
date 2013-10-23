/*
Rhodeus Script (c) 2013 by Talha Zekeriya Durmuş <zekeriya@talhadurmus.com>

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/

module rhodeus.object.rfloat;
import rhodeus.object.memory;

dFunctionSM*[string] functions;

struct _float{
	mixin rhdata;
	double value;
}
RhData* RhFloat(double value){
	auto data = smalloc!(_float);
	*data = _float(M_FLOAT, 0, false, value);
	return cast(RhData*) data;
}

__gshared static this(){
	with(datatable[M_FLOAT]){

		getSub = &.getSub;

		hasValue = &.hasValue;

		opAdd = &.opAdd;
		opMod = &.opMod;
		opMul = &.opMul;
		opDiv = &.opDiv;
		opSub = &.opSub;

		toString = &.toString;

		inc = &.inc;
		dec = &.dec;

		opLower = &.opLower;
		opLowerEquals = &.opLowerEquals;
		opGreater = &.opGreater;
		opGreaterEquals = &.opGreaterEquals;
		opEquals = &.opEquals;
		opNotEquals = &.opNotEquals;

		opEqualAdd = &.opEqualAdd;
		//opEqualSub = &.opEqualSub;
		//opEqualMul = &.opEqualMul;
		//opEqualDiv = &.opEqualDiv;
		//opEqualMod = &.opEqualMod;

	}
}


void opEqualAdd(RhData* obj, ThreadMem*, RhData** self){
	if(obj.typ==M_INT){
		if((*self).refcount > 1){
			(*self).refcount--;
			(*self) = RhFloat((*cast(_float**) self).value + (cast(_int*) obj).value);
			(*self).refcount++;
		}else{
			(*cast(_float**) self).value += (cast(_int*) obj).value;
		}
	}else if(obj.typ==M_FLOAT){
		if((*self).refcount > 1){
			(*self).refcount--;
			*self = RhFloat((*cast(_float**) self).value + (cast(_float*) obj).value);
			(*self).refcount++;
		}else{
			(*cast(_float**) self).value += (cast(_float*) obj).value;
		}
	}else
		throw new RhError(1003, "+=", (*self).type, obj.type);
}
void opEqualSub(RhData* obj, ThreadMem*, RhData** self){
	if(obj.typ==M_INT){
		if((*self).refcount > 1){
			(*self).refcount--;
			*self = RhFloat((*cast(_float**) self).value - (cast(_int*) obj).value);
			(*self).refcount++;
		}else{
			(*cast(_float**) self).value -= (cast(_int*) obj).value;
		}
	}else if(obj.typ==M_FLOAT){
		if((*self).refcount > 1){
			(*self).refcount--;
			*self = RhFloat((*cast(_float**) self).value - (cast(_float*) obj).value);
			(*self).refcount++;
		}else{
			(*cast(_float**) self).value -= (cast(_float*) obj).value;
		}
	}else
		throw new RhError(1003, "-=", (*self).type, obj.type);
}
void opEqualMod(RhData* obj, ThreadMem*, RhData** self){
	if(obj.typ==M_INT){
		if((*self).refcount > 1){
			(*self).refcount--;
			*self = RhFloat((*cast(_float**) self).value % (cast(_int*) obj).value);
			(*self).refcount++;
		}else{
			(*cast(_float**) self).value %= (cast(_int*) obj).value;
		}
	}else if(obj.typ==M_FLOAT){
		if((*self).refcount > 1){
			(*self).refcount--;
			*self = RhFloat((*cast(_float**) self).value % (cast(_float*) obj).value);
			(*self).refcount++;
		}else{
			(*cast(_float**) self).value %= (cast(_float*) obj).value;
		}
	}else
		throw new RhError(1003, "%=", (*self).type, obj.type);
}
void opEqualMul(RhData* obj, ThreadMem*, RhData** self){
	if(obj.typ==M_INT){
		if((*self).refcount > 1){
			(*self).refcount--;
			*self = RhFloat((*cast(_float**) self).value * (cast(_int*) obj).value);
			(*self).refcount++;
		}else{
			(*cast(_float**) self).value *= (cast(_int*) obj).value;
		}
	}else if(obj.typ==M_FLOAT){
		if((*self).refcount > 1){
			(*self).refcount--;
			*self = RhFloat((*cast(_float**) self).value * (cast(_float*) obj).value);
			(*self).refcount++;
		}else{
			(*cast(_float**) self).value *= (cast(_float*) obj).value;
		}
	}else
		throw new RhError(1003, "*=", (*self).type, obj.type);
}
void opEqualDiv(RhData* obj, ThreadMem*, RhData** self){
	if(obj.typ==M_INT){
		if((*self).refcount > 1){
			(*self).refcount--;
			*self = RhFloat((cast(_float*) self).value / (cast(_int*) obj).value);
			(*self).refcount++;
		}else{
			(*cast(_float**) self).value /= (cast(_int*) obj).value;
		}
	}else if(obj.typ==M_FLOAT){
		if((*self).refcount > 1){
			(*self).refcount--;
			*self = RhFloat((*cast(_float**) self).value / (cast(_float*) obj).value);
			(*self).refcount++;
		}else{
			(*cast(_float**) self).value /= (cast(_float*) obj).value;
		}
	}else
		throw new RhError(1003, "/=", (*self).type, obj.type);
}

bool opLower(RhData* obj, ThreadMem* rhvm, RhData* self){
	if(obj.typ == M_INT)
		return (cast(_float*) self).value < (cast(_int*) obj).value;
	else if(obj.typ == M_FLOAT)
		return (cast(_float*) self).value < (cast(_float*) obj).value;
	else
		throw new RhError(1003, "<", self.type, obj.type);
}
bool opLowerEquals(RhData* obj, ThreadMem*, RhData* self){
	if(obj.typ == M_INT)
		return (cast(_float*) self).value <= (cast(_int*) obj).value;
	else if(obj.typ == M_FLOAT)
		return (cast(_float*) self).value <= (cast(_float*) obj).value;
	else
		throw new RhError(1003, "<=", self.type, obj.type);
}

bool opGreater(RhData* obj, ThreadMem*, RhData* self){
	if(obj.typ == M_INT)
		return (cast(_float*) self).value > (cast(_int*) obj).value;
	else if(obj.typ == M_FLOAT)
		return (cast(_float*) self).value > (cast(_float*) obj).value;
	else
		throw new RhError(1003, ">", self.type, obj.type);
}
bool opGreaterEquals(RhData* obj, ThreadMem*, RhData* self){
	if(obj.typ == M_INT)
		return (cast(_float*) self).value >= (cast(_int*) obj).value;
	else if(obj.typ == M_FLOAT)
		return (cast(_float*) self).value >= (cast(_float*) obj).value;
	else
		throw new RhError(1003, ">=", self.type, obj.type);
}
bool opEquals(RhData* obj, ThreadMem*, RhData* self){
	if(obj.typ == M_INT)
		return (cast(_float*) self).value == (cast(_int*) obj).value;
	else if(obj.typ == M_FLOAT)
		return (cast(_float*) self).value == (cast(_float*) obj).value;
	else
		throw new RhError(1003, "==", self.type, obj.type);
}
bool opNotEquals(RhData* obj, ThreadMem*, RhData* self){
	if(obj.typ == M_INT)
		return (cast(_float*) self).value != (cast(_int*) obj).value;
	else if(obj.typ == M_FLOAT)
		return (cast(_float*) self).value != (cast(_float*) obj).value;
	else
		throw new RhError(1003, "!=", self.type, obj.type);
}

bool hasValue(ThreadMem* rhvm){
	return (*cast(_float**) rhvm.EAXP).value != 0;
}

void inc(ThreadMem* rhvm){
	auto self = rhvm.EAXP;
	if((*self).refcount > 1){
		(*self).refcount--;
		*self = RhFloat((cast(_float*) (*self)).value + 1);
		(*self).refcount++;
	}else{
		(cast(_float*) *self).value++;
	}
}
void dec(ThreadMem* rhvm){
	auto self = rhvm.EAXP;
	if((*self).refcount > 1){
		(*self).refcount--;
		*self = RhFloat((cast(_float*) (*self)).value - 1);
		(*self).refcount++;
	}else{
		(cast(_float*) *self).value--;
	}
}

int opNot(RhData* self){
	return (cast(_float*) self).value == 0;
}

bool opEquals(RhData* obj, RhData* self){
	self.refcount--;
	if(obj.typ==M_INT) return (cast(_float*) self).value == (cast(_int*) obj).value;
	else if(obj.typ==M_FLOAT) return (cast(_float*) self).value == (cast(_float*) obj).value;
	else return false;
}

string toString(ThreadMem* rhvm, RhData* self){
	return to!string((cast(_float*) self).value);
}
RhData* opMod(RhData* self,ThreadMem*, RhData* obj){
	self.refcount--;
	if(obj.typ==M_INT)
		return RhFloat((cast(_float*) self).value % (cast(_int*) obj).value);
	else if(obj.typ==M_FLOAT)
		return RhFloat((cast(_float*) self).value % (cast(_float*) obj).value);
	else
		throw new RhError(1003, "%", self.type, obj.type);
}
RhData* opAdd(RhData* self, ThreadMem*, RhData* obj){
	self.refcount--;
	if(obj.typ==M_INT)
		return RhFloat((cast(_float*) self).value + (cast(_int*) obj).value);
	else if(obj.typ==M_FLOAT)
		return RhFloat((cast(_float*) self).value + (cast(_float*) obj).value);
	else
		throw new RhError(1003, "+", self.type, obj.type);
}
RhData* opMul(RhData* self, ThreadMem*, RhData* obj){
	self.refcount--;
	if(obj.typ==M_INT)
		return RhFloat((cast(_float*) self).value * (cast(_int*) obj).value);
	else if(obj.typ==M_FLOAT)
		return RhFloat((cast(_float*) self).value * (cast(_float*) obj).value);
	else
		throw new RhError(1003, "*", self.type, obj.type);
}
RhData* opSub(RhData* self, ThreadMem*,RhData* obj){
	self.refcount--;
	if(obj.typ==M_INT)
		return RhFloat((cast(_float*) self).value - (cast(_int*) obj).value);
	else if(obj.typ==M_FLOAT)
		return RhFloat((cast(_float*) self).value - (cast(_float*) obj).value);
	else
		throw new RhError(1003, "-", self.type, obj.type);
}
RhData* opDiv(RhData* self, ThreadMem*,RhData* obj){
	self.refcount--;
	if(obj.typ==M_INT)
		return RhFloat((cast(_float*) self).value / (cast(_int*) obj).value);
	else if(obj.typ==M_FLOAT)
		return RhFloat((cast(_float*) self).value / (cast(_float*) obj).value);
	else
		throw new RhError(1003, "/", self.type, obj.type);
}
RhData* getSub(string attr, ThreadMem* rhvm, RhData* self){
	switch(attr){
		case "str": return RhString(self.toString());
		case "toint": return RhInt(cast(int) (cast(_float*) self).value);
		default:
			auto zx = attr in functions;
			if (zx){
				return cast(RhData*) new dFunctionS(M_DFUNCTION, 0, false, *zx, self);
			}else throw new RhError(1002, "float", attr);
	}
}