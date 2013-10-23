/*
Rhodeus Script (c) 2013 by Talha Zekeriya Durmuş <zekeriya@talhadurmus.com>

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/
module rhodeus.object.assovar;

import rhodeus.object.memory;

struct _assovar{
	mixin rhdata;
	string name;
	RhData* value;
}

/*
Creating new 'dictionary' object.
*/
RhData* RhAssoVar(int count = 0)(string z, RhData* value){
	auto arr = smalloc!(_assovar);
	value.refcount++;
	*arr = _assovar(M_ASSOVAR, count, false, z, value);
	return cast(RhData*) arr;
}
string toString(ThreadMem* rhvm, RhData* self){
	if((cast(_assovar*) self).value.typ == M_STRING) return "[\"%s\" -> \"%s\"]".format((cast(_assovar*) self).name, (cast(_assovar*) self).value.toString());
	else return "[\"%s\" -> %s]".format((cast(_assovar*) self).name, (cast(_assovar*) self).value.toString());
}