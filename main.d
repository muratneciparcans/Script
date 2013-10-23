/*
Rhodeus Script (c) 2013 by Talha Zekeriya Durmuş <zekeriya@talhadurmus.com>

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/

module app;
import std.stdio;
import std.path;
import std.c.stdlib;
import std.file;
import std.process;
import std.string;
import arsd.web;
import core.runtime;
import core.time;
import core.thread;
import std.utf;
import std.datetime;
import rhodeus.vm.d;
import std.encoding;
import std.utf;


version(Windows)
{
	import std.c.windows.windows : SetConsoleCP, SetConsoleOutputCP;
	static this()
	{
		SetConsoleCP(65001);
		SetConsoleOutputCP(65001);
	}
}

struct opcache{
	RhVM rhs;
	SysTime timeLastModified;
}

opcache[string] caches;

versions vers;
void handler(Cgi cgi) {
	RhVM rhs;
	auto cf = cgi.scriptFileName in caches;
	if(cf){
		if(timeLastModified(cgi.scriptFileName) != cf.timeLastModified) {
			destroy(cf.rhs);
			cf = null;
			rhs = new RhVM();
			caches[cgi.scriptFileName] = opcache(rhs, timeLastModified(cgi.scriptFileName));
		}else{
			rhs = cf.rhs;
		}
	}else{
		rhs = new RhVM();
		caches[cgi.scriptFileName] = opcache(rhs, timeLastModified(cgi.scriptFileName));
	}
	Session session;
	//	session = new Session(cgi);
	//	scope(exit) session.commit();
	if(!exists(cgi.scriptFileName)){
		cgi.setResponseStatus("404 File Not Found"); 
		cgi.write("File %s not found.".format(cgi.scriptFileName));
		return;
	}
	//rhs.loadGET(cgi.get);
	//rhs.loadPOST(cgi.post);
	//if(session !is null) rhs.loadSESSION(session.data);
	string output;
	try{
		output = rhs.runFile(cgi.scriptFileName);//cgi.scriptFileName, dur!"seconds"(3), vers == versions.cgi, cf !is null
	/*}catch(ExitException){
		if(rhs.redirect!=""){
			cgi.setResponseLocation(rhs.redirect);
			return;
		}
	*/
	}catch(Throwable x){
		cgi.setResponseStatus("500 Internal Error"); 
		int i;
		while(i<output.length/1024){
			cgi.write(output[i*1024..(i+1)*1024]);
			i++;
		}
		cgi.write(output[i*1024..$]);
		cgi.write("Error: "~x.msg~"<br>");
		cgi.write("Line: "~to!string(x.line)~"<br>");
		cgi.write("File: "~x.file);
		return;
	}
	version(none){ if(session !is null)
		foreach( name, value; (cast(_dict*) rhs.global["SESSION"]).value ){
			session.set(name, value.toString());
		}
	foreach(ref cookie; rhs.cookies){
		cgi.setCookie(cookie.name, cookie.data, cookie.expiresIn, cookie.path, cookie.domain, cookie.httpOnly, cookie.secure);
	}
	foreach(key, val; rhs.headers){
		cgi.header(key~": "~val);
	}
	}
	int i;
	for(; i<output.length/1024; i++){
		cgi.write(output[i*1024..(i+1)*1024]);
	}
	cgi.write(output[i*1024..$]);
	//	destroy(rhs);
}

enum versions {
	console, 
	cgi, fastcgi, scgi, 
	embedded_httpd_threads
}

void main(string[] args) {
	// we support command line thing for easy testing everywhere
	// it needs to be called ./app method uri [other args...]
	if(args.length >= 3 && isCgiRequestMethod(args[1])) {
		vers = versions.cgi;
		Cgi cgi = new Cgi(args);
		scope(exit) cgi.dispose();
		handler(cgi);
		cgi.close();
		return;
	}
	auto fun = &handler;
	long maxContentLength = defaultMaxContentLength;
	ushort listeningPort(ushort def) {
		bool found = false;
		foreach(arg; args) {
			if(found)
				return to!ushort(arg);
			if(arg == "--port" || arg == "-p" || arg == "/port" || arg == "--listening-port")
				found = true;
		}
		return def;
	}
	versions listeningType(versions def) {
		bool found = false;
		foreach(arg; args) {
			if(found)
				return to!versions(arg);
			if(arg == "--stype" || arg == "-s")
				found = true;
		}
		return def;
	}
	vers = listeningType(versions.fastcgi);

	final switch(vers){
		case versions.console:
			//GC.disable();
			RhVM rhs = new RhVM();
			rhs.showGreeting();
			write(">>>");
			string buf;
			while (std.stdio.stdin.readln(buf)){
				if(buf.strip()=="exit"){
					writeln("Please use exit(), ctrl-z plus enter or press ctrl-c to exit");
					write(">>>");
					continue;
				}else if(buf.strip()==""){
					write(">>>");
					continue;
				}
				string output;
				try{
					output = rhs.run!1(buf);
					if(output!="") writeln(output);
				/*}catch(ExitException x){
					std.c.stdlib.exit(x.exitcode);*/
				}catch(Throwable x){
					writeln("Error: ", x.msg);
				}
				write(">>>");
			}
			break;
		case versions.embedded_httpd_threads:
			auto manager = new ListeningConnectionManager(listeningPort(80), &doThreadHttpConnection!(Cgi, handler));
			manager.listen();
			break;
		case versions.scgi:
			import std.exception;
			import al = std.algorithm;
			auto manager = new ListeningConnectionManager(listeningPort(4000), &doThreadHttpConnection!(Cgi, handler));

			// this threads...
			foreach(connection; manager) {
				// and now we can buffer
				scope(failure)
					connection.close();

				size_t size;

				string[string] headers;

				auto range = new BufferedInputRange(connection);
			more_data:
				auto chunk = range.front();
				// waiting for colon for header length
				auto idx = indexOf(cast(string) chunk, ':');
				if(idx == -1) {
					range.popFront();
					goto more_data;
				}

				size = to!size_t(cast(string) chunk[0 .. idx]);
				chunk = range.consume(idx + 1);
				// reading headers
				if(chunk.length < size)
					range.popFront(0, size + 1);
				// we are now guaranteed to have enough
				chunk = range.front();
				assert(chunk.length > size);

				idx = 0;
				string key;
				string value;
				foreach(part; al.splitter(chunk, '\0')) {
					if(idx & 1) { // odd is value
						value = cast(string)(part.idup);
						headers[key] = value; // commit
					} else
						key = cast(string)(part.idup);
					idx++;
				}

				enforce(chunk[size] == ','); // the terminator

				range.consume(size + 1);
				// reading data
				// this will be done by Cgi

				const(ubyte)[] getScgiChunk() {
					// we are already primed
					auto data = range.front();
					if(data.length == 0 && !range.sourceClosed) {
						range.popFront(0);
						data = range.front();
					}

					return data;
				}

				void writeScgi(const(ubyte)[] data) {
					sendAll(connection, data);
				}

				void flushScgi() {
					// I don't *think* I have to do anything....
				}

				Cgi cgi;
				try {
					cgi = new Cgi(maxContentLength, headers, &getScgiChunk, &writeScgi, &flushScgi);
				} catch(Throwable t) {
					sendAll(connection, plainHttpError(true, "400 Bad Request", t));
					connection.close();
					continue; // this connection is dead
				}
				assert(cgi !is null);
				scope(exit) cgi.dispose();
				try {
					fun(cgi);
					cgi.close();
				} catch(Throwable t) {
					// no std err
					if(!handleException(cgi, t)) {
						connection.close();
						continue;
					}
				}
			}
			break;
		case versions.fastcgi:
			//         SetHandler fcgid-script
			FCGX_Stream* input, output, error;
			FCGX_ParamArray env;



			const(ubyte)[] getFcgiChunk() {
				const(ubyte)[] ret;
				while(FCGX_HasSeenEOF(input) != -1)
					ret ~= cast(ubyte) FCGX_GetChar(input);
				return ret;
			}

			void writeFcgi(const(ubyte)[] data) {
				FCGX_PutStr(data.ptr, data.length, output);
			}

			void doARequest() {
				string[string] fcgienv;

				for(auto e = env; e !is null && *e !is null; e++) {
					string cur = to!string(*e);
					auto idx = cur.indexOf("=");
					string name, value;
					if(idx == -1)
						name = cur;
					else {
						name = cur[0 .. idx];
						value = cur[idx + 1 .. $];
					}

					fcgienv[name] = value;
				}

				void flushFcgi() {
					FCGX_FFlush(output);
				}

				Cgi cgi;
				try {
					cgi = new Cgi(maxContentLength, fcgienv, &getFcgiChunk, &writeFcgi, &flushFcgi);
				} catch(Throwable t) {
					FCGX_PutStr(cast(ubyte*) t.msg.ptr, t.msg.length, error);
					writeFcgi(cast(const(ubyte)[]) plainHttpError(true, "400 Bad Request", t));
					return; //continue;
				}
				assert(cgi !is null);
				scope(exit) cgi.dispose();
				try {
					fun(cgi);
					cgi.close();
				} catch(Throwable t) {
					// log it to the error stream
					FCGX_PutStr(cast(ubyte*) t.msg.ptr, t.msg.length, error);
					// handle it for the user, if we can
					if(!handleException(cgi, t))
						return; // continue;
				}
			}

			auto lp = listeningPort(0);
			FCGX_Request request;
			if(lp) {
				// if a listening port was specified on the command line, we want to spawn ourself
				// (needed for nginx without spawn-fcgi, e.g. on Windows)
				FCGX_Init();
				auto sock = FCGX_OpenSocket(toStringz(":" ~ to!string(lp)), 12);
				if(sock < 0)
					throw new Exception("Couldn't listen on the port");
				FCGX_InitRequest(&request, sock, 0);
				while(FCGX_Accept_r(&request) >= 0) {
					input = request.inStream;
					output = request.outStream;
					error = request.errStream;
					env = request.envp;
					doARequest();
				}
			} else {
				// otherwise, assume the httpd is doing it (the case for Apache, IIS, and Lighttpd)
				// using the version with a global variable since we are separate processes anyway
				while(FCGX_Accept(&input, &output, &error, &env) >= 0) {
					doARequest();
				}
			}
			break;
		case versions.cgi:
			// standard CGI is the default version
			Cgi cgi;
			try {
				cgi = new Cgi(maxContentLength);
			} catch(Throwable t) {
				stderr.writeln(t.msg);
				// the real http server will probably handle this;
				// most likely, this is a bug in Cgi. But, oh well.
				stdout.write(plainHttpError(true, "400 Bad Request", t));
				return;
			}
			assert(cgi !is null);
			scope(exit) cgi.dispose();

			try {
				fun(cgi);
				cgi.close();
			} catch (Throwable t) {
				stderr.writeln(t.msg);
				if(!handleException(cgi, t))
					return;
			}
			break;
	}
}
