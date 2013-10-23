module rhodeus.memory.fda;
import rhodeus.object.memory;

shared{
	RhData** freep, frees;
	int freec;

	RhData** usedp, used;
	int usedc;

	int gctime;
}

__gshared static this(){
	int i = 4096;
	freec += i;

	used = cast(shared RhData**) GC.malloc(i * (RhData*).sizeof, GC.BlkAttr.NO_SCAN);
	usedp = used;

	frees = cast(shared RhData**) GC.malloc(i * (RhData*).sizeof, GC.BlkAttr.NO_SCAN);
	freep = frees;
	auto rhdatas = cast(RhData*) GC.calloc(i * (RhData).sizeof, GC.BlkAttr.NO_SCAN);
	for( ; i; i--){
		*freep = cast(shared) rhdatas;
		rhdatas++;
		freep++;
	}
	freep = frees + 4096;
}

void free(T)(T* ptr){
	//	ptr.refcount = 0;
	for(int i; i < usedc; i++){
		if(ptr is cast(RhData*) used[i]){
			if(i + 1 == usedc){
				usedc--;
			}else{
				used[i] = used[usedc-1];
				usedc--;
			}
			*freep = cast(shared RhData*) ptr;
			freep++;
			freec++;
			return;
		}
	}
	writeln(ptr.toString());
	writeln("Bak şimdi böyle bir object yoook aslında :) yada belkide 2 kere free edilmiştir ha? :D");
	while(1){}
}


T* smalloc(T)(){
	if(usedc>0) if(used[usedc-1].refcount < 1){
		collectGC!true(cast(RhData*) used[usedc-1]);
		return cast(T*) used[usedc-1];
	}

	if(gctime++ > 20){
		for(int i; i < usedc; i++){
			if((cast(RhData*) used[i]).refcount < 1){
				collectGC!true(cast(RhData*) used[i]);
				*freep = cast(shared RhData*) used[i];
				freec++;
				freep++;
				if(i + 1 == usedc){
					usedc--;
				}else{
					used[i] = used[usedc-1];
					usedc--;
				}
			}
		}
		gctime = 0;
	}
	if(freec){
		freec--;
		freep--;
		used[usedc] = *freep;
		usedc++;
		return cast(T*) *freep;
	}else{
		throw new Exception("This feature is not available yet.");
	}
}