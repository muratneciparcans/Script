/*
Rhodeus Script (c) 2013 by Talha Zekeriya Durmuş <zekeriya@talhadurmus.com>

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/

module rhodeus.error;

import std.conv;
import library.dini;
import std.format;
import std.array;
import std.stdio;
import std.path;
import std.string;
import rhodeus.object.memory;



shared string[uint] messages;
void link(){
	Ini errcodes;
	try{
		errcodes = Ini.Parse(RhVM.executableDir ~ "resources/lang/" ~ RhVM.language ~ "/errors.conf");
		foreach(key, val; errcodes._keys){
			messages[to!uint(key)] = val;
		}
	}catch{
	//	throw new RhError("Error file cannot be found on "~RhVirtualMachine.executableDir~"resources/lang/"~RhVirtualMachine.language~"/errors.conf"~". \n");
	}

}

class RhError : Exception{
	uint err;
	
	this(string msg, uint line = -1, string file = "Unknown"){
		super(msg);
		this.line = line;
		this.file = file;
	}
	RhError set(uint line = -1){
		this.line = line;
		return this;
	}
	this(uint err){
		auto m = err in messages;
		this.err = err;
		if(m is null) super("Error message was not found");
		else super(*m);
	}
	
	this(uint err, string[] strl...){//uint line = __LINE__, string file = __FILE__
		string message;
		auto m = err in messages;
		if(m is null){
			message = "Error message ("~to!string(err)~") was not found";
			super(message);
		}else{
			message = *m;

			auto format = FormatSpec!char(message);
			auto app = appender!string();
	 
			while (format.writeUpToNextSpec(app)) {
				formatValue(app, strl.front, format);
				strl.popFront();
			}			
			super(app.data);
		}
		this.err = err;
	}

}


class ExitException : Exception{
	int exitcode;
	this(int code){
		exitcode = code;
		super("exit "~text(code));
	}
}