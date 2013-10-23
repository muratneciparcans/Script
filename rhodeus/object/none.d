/*
Rhodeus Script (c) 2013 by Talha Zekeriya Durmuş <zekeriya@talhadurmus.com>

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/

module rhodeus.object.none;
import rhodeus.object.memory;

/*
This function changes default function for codearea data type.
*/
import std.stdio;
__gshared static this(){
	with(datatable[M_NONE]){
		hasValue = &.hasValue;

		getSub = &.getSub;
		toString = &.toString;
	}
}


private{
	/* none sub functions */
	dFunctionSM*[string] functions;

	/* accessing sub function */
	RhData* getSub(string attr, ThreadMem*, RhData* self){
		switch(attr){
			case "str": return RhString(self.toString());
			default:
				auto zx = attr in functions;
				if (zx){
					return cast(RhData*) *zx;
				}else throw new RhError(1002, "string", attr);
		}
	}

	bool hasValue(ThreadMem*){
		return false;
	}

	string toString(ThreadMem* rhvm, RhData* self){
		return "none";
	}
}