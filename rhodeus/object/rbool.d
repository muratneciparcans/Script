/*
Rhodeus Script (c) 2013 by Talha Zekeriya Durmuş <zekeriya@talhadurmus.com>

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/

module rhodeus.object.rbool;
import rhodeus.object.memory;


/*
Creating new 'bool' object.
*/
struct _bool{
	mixin rhdata;
	bool value;
}
__gshared{
	_bool _true = _bool(M_BOOL, 1,false, true);
	_bool _false = _bool(M_BOOL, 1,false, false);
}
RhData* RhBool(bool z){
	if(z) return cast(RhData*) &_true;
	return cast(RhData*) &_false;
}

/*
This function changes default function for codearea data type.
*/
__gshared static this(){
	with(datatable[M_BOOL]){
		hasValue = &.hasValue;
		opNot = &.opNot;

		opEquals = &.opEquals;
		opNotEquals = &.opNotEquals;


		//		getSub = &.getSub;
		toString = &.toString;
	}
}

bool opEquals(RhData* obj, ThreadMem*, RhData* self){
	if(obj.typ==M_INT){
		return (cast(_bool*) self).value == cast(bool) (cast(_int*) obj).value;
	}else if(obj.typ==M_FLOAT){
		return (cast(_bool*) self).value == cast(bool) (cast(_float*) obj).value;
	}
	return (cast(_bool*) self).value == (cast(_bool*) obj).value;
}
bool  opNotEquals(RhData* obj, ThreadMem*, RhData* self){
	if(obj.typ==M_INT){
		return (cast(_bool*) self).value != cast(bool) (cast(_int*) obj).value;
	}else if(obj.typ==M_FLOAT){
		return (cast(_bool*) self).value != cast(bool) (cast(_float*) obj).value;
	}
	return (cast(_bool*) self).value != (cast(_bool*) obj).value;
}

bool hasValue(ThreadMem* rhvm){
	return (*cast(_bool**) rhvm.EAXP).value;
}

string toString(ThreadMem* rhvm, RhData* self){
	return (cast(_bool*) self).value ? "true" : "false";
}
RhData* getSub(string* attr, ThreadMem*, RhData* self){
	switch(*attr){
		case "str": return RhString((cast(_bool*) self).value ? "true" : "false");
		default:
			throw new Exception("Alt işlev bulunamadı!");
	}
}
RhData* opNot(ThreadMem*, RhData* self){
	return RhBool(!(cast(_bool*) self).value);
}