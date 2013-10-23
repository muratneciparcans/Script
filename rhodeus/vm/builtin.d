module rhodeus.vm.builtin;
import rhodeus.object.memory;
import rhodeus.object.dfunction;

import std.datetime;

RhData*[string] global;

__gshared static this(){
	global["print"] = RhDfunction("print", &print, args.unlimited);
	global["apptime"] = RhDfunction("apptime", &apptime, args.unlimited);
	global["GC"] = RhDfunction("GC", &gc, args.unlimited);
}


RhData* print(dFunctionS* self, ThreadMem* rhvm, RhData** argptr, int len){
	auto output = &rhvm.output;
	for(int i; i < len; i++){
		*output ~= argptr[i].toString(rhvm);
	}
	return None;
}
RhData* apptime(dFunctionS* self, ThreadMem* rhvm, RhData** argptr, int len){
	return RhInt(cast(int) Clock.currAppTick().usecs());;
}
RhData* gc(dFunctionS* self, ThreadMem* rhvm, RhData** argptr, int len){
	string ret = "<h2>free count: [%s]</h2>".format(rhodeus.memory.fda.freec);
	ret ~= "<h2>object list: [%s]</h2>".format(rhodeus.memory.fda.usedc);
	foreach(obj; rhodeus.memory.fda.used[0..rhodeus.memory.fda.usedc]){
		ret ~= "typ: %s, val: %s = %s<br>".format((cast(RhData*)obj).type, (cast(RhData*) obj).toString(),to!string(*cast(_rhdata*)obj));
	}
	return RhString(ret);
}