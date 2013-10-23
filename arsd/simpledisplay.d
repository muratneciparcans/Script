module simpledisplay;

// CHANGE FROM LAST VERSION: the window background is no longer fixed, so you might want to fill the screen with a particular color before drawing.

/*
	Biggest FIXME:
		make sure the key event numbers match between X and Windows OR provide symbolic constants on each system

		clean up opengl contexts when their windows close

		fix resizing the bitmaps/pixmaps
*/

// BTW on Windows:
// -L/SUBSYSTEM:WINDOWS:5.0
// to dmd will make a nice windows binary w/o a console if you want that.

/*
	Stuff to add:

	use multibyte functions everywhere we can

	OpenGL windows
	more event stuff
	extremely basic windows w/ no decoration for tooltips, splash screens, etc.


	resizeEvent
		and make the windows non-resizable by default,
		or perhaps stretched (if I can find something in X like StretchBlt)

	take a screenshot function!

	Pens and brushes?
	Maybe a global event loop?

	Mouse deltas
	Key items
*/

/*
From MSDN:

 You can also use the GET_X_LPARAM or GET_Y_LPARAM macro to extract the x- or y-coordinate.

Important  Do not use the LOWORD or HIWORD macros to extract the x- and y- coordinates of the cursor position because these macros return incorrect results on systems with multiple monitors. Systems with multiple monitors can have negative x- and y- coordinates, and LOWORD and HIWORD treat the coordinates as unsigned quantities.

*/

version(html5) {} else {
	version(linux)
		version = X11;
	version(OSX) {
		version(OSXCocoa) {}
		else { version = X11; }
	}
		//version = OSXCocoa; // this was written by KennyTM
	version(FreeBSD)
		version = X11;
	version(Solaris)
		version = X11;
}

// being phobos-free keeps the size WAY down
private const(char)* toStringz(string s) { return (s ~ '\0').ptr; }
private string[] split(string a, char c) {
		string[] ret;
		size_t previous = 0;
		foreach(i, char ch; a) {
			if(ch == c) {
				ret ~= a[previous .. i];
				previous = i + 1;
			}
		}
		if(previous != a.length)
			ret ~= a[previous .. $];
		return ret;
	}

version(Windows) {
	// Since opengl32.lib isn't provided by default with dmd yet, OpenGL on Windows is opt in
	// rather than opt out, so simpledisplay.d just works with a stock dmd.
	version(with_opengl) {}
	else version = without_opengl;
}

version(without_opengl) {
	enum OpenGlOptions {
		no,
	}
} else {
	enum OpenGlOptions {
		no,
		yes,
	}

	version(X11) {
		pragma(lib, "GL");
		pragma(lib, "GLU");
	} else version(Windows) {
		pragma(lib, "opengl32");
		pragma(lib, "glu32");
	} else
		static assert(0, "OpenGL not supported on your system yet. Try -version=X11 if you have X Windows available, or -version=without_opengl to go without.");
}

enum Resizablity {
	fixedSize, // on Windows, it may allow them to resize anyway, and just stretch. or something. idk really
	allowResizing,
	// automaticallyScale // this isn't implemented because Xlib doesn't have StretchBlt.
}

enum MouseEventType : int {
	motion = 0,
	buttonPressed = 1,
	buttonReleased = 2,
}

enum MouseButton : int {
	left = 1,
	right = 2,
	middle = 4,
	wheelUp = 8,
	wheelDown = 16,
}


enum TextAlignment : uint {
	Left = 0,
	Center = 1,
	Right = 2,

	VerticalTop = 0,
	VerticalCenter = 4,
	VerticalBottom = 8,
}

public import arsd.color; // no longer stand alone... :-( but i need a common type for this to work with images easily.

struct Point {
	int x;
	int y;
}

struct Size {
	int width;
	int height;
}


struct KeyEvent {
	/// see table below. Always use the symbolic names, even for ASCII characters, since the actual numbers vary across platforms.
	Key key;
	uint hardwareCode;
	bool pressed; // note: released events aren't always sent...

	dchar character;

	// state:
	// 1 == shift
	// 8 == alt
	// 4 == ctrl
	uint modifierState;

	SimpleWindow window;
}

version(X11) {
	// FIXME: match ASCII whenever we can. Most of it is already there,
	// but there's a few exceptions and mismatches with Windows

	enum Key {
		Escape = 0xff1b,
		F1 = 0xffbe,
		F2 = 0xffbf,
		F3 = 0xffc0,
		F4 = 0xffc1,
		F5 = 0xffc2,
		F6 = 0xffc3,
		F7 = 0xffc4,
		F8 = 0xffc5,
		F9 = 0xffc6,
		F10 = 0xffc7,
		F11 = 0xffc8,
		F12 = 0xffc9,
		PrintScreen = -1, // FIXME
		ScrollLock = -2, // FIXME
		Pause = -3, // FIXME
		Grave = 0x60,
		// number keys across the top of the keyboard
		N1 = 0x31,
		N2 = 0x32,
		N3 = 0x33,
		N4 = 0x34,
		N5 = 0x35,
		N6 = 0x36,
		N7 = 0x37,
		N8 = 0x38,
		N9 = 0x39,
		N0 = 0x30,
		Dash = 0x2d,
		Equals = 0x3d,
		Backslash = 0x5c,
		Backspace = 0xff08,
		Insert = 0xff63,
		Home = 0xff50,
		PageUp = 0xff55,
		Delete = 0xffff,
		End = 0xff57,
		PageDown = 0xff56,
		Up = 0xff52,
		Down = 0xff54,
		Left = 0xff51,
		Right = 0xff53,

		Tab = 0xff09,
		Q = 0x71,
		W = 0x77,
		E = 0x65,
		R = 0x72,
		T = 0x74,
		Y = 0x79,
		U = 0x75,
		I = 0x69,
		O = 0x6f,
		P = 0x70,
		LeftBracket = 0x5b,
		RightBracket = 0x5d,
		CapsLock = 0xffe5,
		A = 0x61,
		S = 0x73,
		D = 0x64,
		F = 0x66,
		G = 0x67,
		H = 0x68,
		J = 0x6a,
		K = 0x6b,
		L = 0x6c,
		Semicolon = 0x3b,
		Apostrophe = 0x27,
		Enter = 0xff0d,
		Shift = 0xffe1,
		Z = 0x7a,
		X = 0x78,
		C = 0x63,
		V = 0x76,
		B = 0x62,
		N = 0x6e,
		M = 0x6d,
		Comma = 0x2c,
		Period = 0x2e,
		Slash = 0x2f,
		Shift_r = 0xffe2, // Note: this isn't sent on all computers, sometimes it just sends Shift, so don't rely on it
		Ctrl = 0xffe3,
		Windows = -4, // FIXME
		Alt = 0xffe9,
		Space = 0x20,
		Alt_r = 0xffea, // ditto of shift_r
		Windows_r = -5, // FIXME
		Menu = 0xff67,
		Ctrl_r = 0xffe4,

		NumLock = 0xff7f,
		Divide = 0xffaf,
		Multiply = 0xffaa,
		Minus = 0xffad,
		Plus = 0xffab,
		PadEnter = -6, // FIXME
		Pad1 = 0xff9c,
		Pad2 = 0xff99,
		Pad3 = 0xff9b,
		Pad4 = 0xff96,
		Pad5 = 0xff9d,
		Pad6 = 0xff98,
		Pad7 = 0xff95,
		Pad8 = 0xff97,
		Pad9 = 0xff9a,
		Pad0 = 0xff9e,
		PadDot = 0xff9f,
	}
} else version(Windows) {
	// the character here is for en-us layouts and for illustration only
	// if you actually want to get characters, wait for character events
	// (the argument to your event handler is simply a dchar)
	// those will be converted by the OS for the right locale.

	enum Key {
		Escape = 0x1b,
		F1 = 0x70,
		F2 = 0x71,
		F3 = 0x72,
		F4 = 0x73,
		F5 = 0x74,
		F6 = 0x75,
		F7 = 0x76,
		F8 = 0x77,
		F9 = 0x78,
		F10 = 0x79,
		F11 = 0x7a,
		F12 = 0x7b,
		PrintScreen = 0x2c,
		ScrollLock = -2, // FIXME
		Pause = -3, // FIXME
		Grave = 0xc0,
		// number keys across the top of the keyboard
		N1 = 0x31,
		N2 = 0x32,
		N3 = 0x33,
		N4 = 0x34,
		N5 = 0x35,
		N6 = 0x36,
		N7 = 0x37,
		N8 = 0x38,
		N9 = 0x39,
		N0 = 0x30,
		Dash = 0xbd,
		Equals = 0xbb,
		Backslash = 0xdc,
		Backspace = 0x08,
		Insert = 0x2d,
		Home = 0x24,
		PageUp = 0x21,
		Delete = 0x2e,
		End = 0x23,
		PageDown = 0x22,
		Up = 0x26,
		Down = 0x28,
		Left = 0x25,
		Right = 0x27,

		Tab = 0x09,
		Q = 0x51,
		W = 0x57,
		E = 0x45,
		R = 0x52,
		T = 0x54,
		Y = 0x59,
		U = 0x55,
		I = 0x49,
		O = 0x4f,
		P = 0x50,
		LeftBracket = 0xdb,
		RightBracket = 0xdd,
		CapsLock = 0x14,
		A = 0x41,
		S = 0x53,
		D = 0x44,
		F = 0x46,
		G = 0x47,
		H = 0x48,
		J = 0x4a,
		K = 0x4b,
		L = 0x4c,
		Semicolon = 0xba,
		Apostrophe = 0xde,
		Enter = 0x0d,
		Shift = 0x10,
		Z = 0x5a,
		X = 0x58,
		C = 0x43,
		V = 0x56,
		B = 0x42,
		N = 0x4e,
		M = 0x4d,
		Comma = 0xbc,
		Period = 0xbe,
		Slash = 0xbf,
		Shift_r = -4, // FIXME Note: this isn't sent on all computers, sometimes it just sends Shift, so don't rely on it
		Ctrl = 0x11,
		Windows = 0x5b,
		Alt = -5, // FIXME
		Space = 0x20,
		Alt_r = 0xffea, // ditto of shift_r
		Windows_r = -6, // FIXME
		Menu = 0x5d,
		Ctrl_r = -7, // FIXME

		NumLock = 0x90,
		Divide = 0x6f,
		Multiply = 0x6a,
		Minus = 0x6d,
		Plus = 0x6b,
		PadEnter = -8, // FIXME
		// FIXME for the rest of these:
		Pad1 = 0xff9c,
		Pad2 = 0xff99,
		Pad3 = 0xff9b,
		Pad4 = 0xff96,
		Pad5 = 0xff9d,
		Pad6 = 0xff98,
		Pad7 = 0xff95,
		Pad8 = 0xff97,
		Pad9 = 0xff9a,
		Pad0 = 0xff9e,
		PadDot = 0xff9f,
	}

	// I'm keeping this around for reference purposes
	// ideally all these buttons will be listed for all platforms,
	// but now now I'm just focusing on my US keyboard
	version(none)
	enum Key {
		LBUTTON = 0x01,
		RBUTTON = 0x02,
		CANCEL = 0x03,
		MBUTTON = 0x04,
		//static if (_WIN32_WINNT > =  0x500) {
		XBUTTON1 = 0x05,
		XBUTTON2 = 0x06,
		//}
		BACK = 0x08,
		TAB = 0x09,
		CLEAR = 0x0C,
		RETURN = 0x0D,
		SHIFT = 0x10,
		CONTROL = 0x11,
		MENU = 0x12,
		PAUSE = 0x13,
		CAPITAL = 0x14,
		KANA = 0x15,
		HANGEUL = 0x15,
		HANGUL = 0x15,
		JUNJA = 0x17,
		FINAL = 0x18,
		HANJA = 0x19,
		KANJI = 0x19,
		ESCAPE = 0x1B,
		CONVERT = 0x1C,
		NONCONVERT = 0x1D,
		ACCEPT = 0x1E,
		MODECHANGE = 0x1F,
		SPACE = 0x20,
		PRIOR = 0x21,
		NEXT = 0x22,
		END = 0x23,
		HOME = 0x24,
		LEFT = 0x25,
		UP = 0x26,
		RIGHT = 0x27,
		DOWN = 0x28,
		SELECT = 0x29,
		PRINT = 0x2A,
		EXECUTE = 0x2B,
		SNAPSHOT = 0x2C,
		INSERT = 0x2D,
		DELETE = 0x2E,
		HELP = 0x2F,
		LWIN = 0x5B,
		RWIN = 0x5C,
		APPS = 0x5D,
		SLEEP = 0x5F,
		NUMPAD0 = 0x60,
		NUMPAD1 = 0x61,
		NUMPAD2 = 0x62,
		NUMPAD3 = 0x63,
		NUMPAD4 = 0x64,
		NUMPAD5 = 0x65,
		NUMPAD6 = 0x66,
		NUMPAD7 = 0x67,
		NUMPAD8 = 0x68,
		NUMPAD9 = 0x69,
		MULTIPLY = 0x6A,
		ADD = 0x6B,
		SEPARATOR = 0x6C,
		SUBTRACT = 0x6D,
		DECIMAL = 0x6E,
		DIVIDE = 0x6F,
		F1 = 0x70,
		F2 = 0x71,
		F3 = 0x72,
		F4 = 0x73,
		F5 = 0x74,
		F6 = 0x75,
		F7 = 0x76,
		F8 = 0x77,
		F9 = 0x78,
		F10 = 0x79,
		F11 = 0x7A,
		F12 = 0x7B,
		F13 = 0x7C,
		F14 = 0x7D,
		F15 = 0x7E,
		F16 = 0x7F,
		F17 = 0x80,
		F18 = 0x81,
		F19 = 0x82,
		F20 = 0x83,
		F21 = 0x84,
		F22 = 0x85,
		F23 = 0x86,
		F24 = 0x87,
		NUMLOCK = 0x90,
		SCROLL = 0x91,
		LSHIFT = 0xA0,
		RSHIFT = 0xA1,
		LCONTROL = 0xA2,
		RCONTROL = 0xA3,
		LMENU = 0xA4,
		RMENU = 0xA5,
		//static if (_WIN32_WINNT > =  0x500) {
		BROWSER_BACK = 0xA6,
		BROWSER_FORWARD = 0xA7,
		BROWSER_REFRESH = 0xA8,
		BROWSER_STOP = 0xA9,
		BROWSER_SEARCH = 0xAA,
		BROWSER_FAVORITES = 0xAB,
		BROWSER_HOME = 0xAC,
		VOLUME_MUTE = 0xAD,
		VOLUME_DOWN = 0xAE,
		VOLUME_UP = 0xAF,
		MEDIA_NEXT_TRACK = 0xB0,
		MEDIA_PREV_TRACK = 0xB1,
		MEDIA_STOP = 0xB2,
		MEDIA_PLAY_PAUSE = 0xB3,
		LAUNCH_MAIL = 0xB4,
		LAUNCH_MEDIA_SELECT = 0xB5,
		LAUNCH_APP1 = 0xB6,
		LAUNCH_APP2 = 0xB7,
		//}
		OEM_1 = 0xBA,
		//static if (_WIN32_WINNT > =  0x500) {
		OEM_PLUS = 0xBB,
		OEM_COMMA = 0xBC,
		OEM_MINUS = 0xBD,
		OEM_PERIOD = 0xBE,
		//}
		OEM_2 = 0xBF,
		OEM_3 = 0xC0,
		OEM_4 = 0xDB,
		OEM_5 = 0xDC,
		OEM_6 = 0xDD,
		OEM_7 = 0xDE,
		OEM_8 = 0xDF,
		//static if (_WIN32_WINNT > =  0x500) {
		OEM_102 = 0xE2,
		//}
		PROCESSKEY = 0xE5,
		//static if (_WIN32_WINNT > =  0x500) {
		PACKET = 0xE7,
		//}
		ATTN = 0xF6,
		CRSEL = 0xF7,
		EXSEL = 0xF8,
		EREOF = 0xF9,
		PLAY = 0xFA,
		ZOOM = 0xFB,
		NONAME = 0xFC,
		PA1 = 0xFD,
		OEM_CLEAR = 0xFE,
	}

}

// FIXME: mouse move should be distinct from presses+releases, so we can avoid subscribing to those events in X unnecessarily
/// Listen for this on your event listeners if you are interested in mouse
struct MouseEvent {
	int type; // movement, press, release, double click

	int x;
	int y;

	int button;
	int buttonFlags;

	SimpleWindow window;
}

/// This gives a few more options to drawing lines and such
struct Pen {
	Color color; /// the foreground color
	int width = 1; /// width of the line
	Style style; // FIXME: not implemented
/+
// From X.h

#define LineSolid		0
#define LineOnOffDash		1
#define LineDoubleDash		2
       LineDou-        The full path of the line is drawn, but the
       bleDash         even dashes are filled differently from the
                       odd dashes (see fill-style) with CapButt
                       style used where even and odd dashes meet.



/* capStyle */

#define CapNotLast		0
#define CapButt			1
#define CapRound		2
#define CapProjecting		3

/* joinStyle */

#define JoinMiter		0
#define JoinRound		1
#define JoinBevel		2

/* fillStyle */

#define FillSolid		0
#define FillTiled		1
#define FillStippled		2
#define FillOpaqueStippled	3


+/
	enum Style {
		Solid,
		Dashed
	}
}


final class Image {
	this(int width, int height) {
		this.width = width;
		this.height = height;

		impl.createImage(width, height);
	}

	this(Size size) {
		this(size.width, size.height);
	}

	~this() {
		impl.dispose();
	}

	final void putPixel(int x, int y, Color c) {
		if(x < 0 || x >= width)
			return;
		if(y < 0 || y >= height)
			return;

		impl.setPixel(x, y, c);
	}

	final void opIndexAssign(Color c, int x, int y) {
		putPixel(x, y, c);
	}

	/// this is here for interop with arsd.image. where can be a TrueColorImage's data member
	/// if you pass in a buffer, it will put it right there. length must be width*height*4 already
	/// if you pass null, it will allocate a new one.
	ubyte[] getRgbaBytes(ubyte[] where = null) {
		if(where is null)
			where = new ubyte[this.width*this.height*4];
		convertToRgbaBytes(where);
		return where;
	}

	/// this is here for interop with arsd.image. from can be a TrueColorImage's data member
	void setRgbaBytes(in ubyte[] from ) {
		assert(from.length == this.width * this.height * 4);
		setFromRgbaBytes(from);
	}

	// FIXME: make properly cross platform by getting rgba right

	/// warning: this is not portable across platforms because the data format can change
	ubyte* getDataPointer() {
		return impl.rawData;
	}

	/// for use with getDataPointer
	final int bytesPerLine() const pure @safe nothrow {
		version(Windows)
			return ((cast(int) width * 3 + 3) / 4) * 4;
		else version(X11)
			return 4 * width;
		else version(OSXCocoa)
			return 4 * width;
		else version(html5)
			return 4 * width;
		else static assert(0);
	}

	/// for use with getDataPointer
	final int bytesPerPixel() const pure @safe nothrow {
		version(Windows)
			return 3;
		else version(X11)
			return 4;
		else version(OSXCocoa)
			return 4;
		else version(html5)
			return 4;
		else static assert(0);
	}

	immutable int width;
	immutable int height;
    private:
	mixin NativeImageImplementation!() impl;
}

void displayImage(Image image, SimpleWindow win = null) {
	if(win is null) {
		win = new SimpleWindow(image);
		{
			auto p = win.draw;
			p.drawImage(Point(0, 0), image);
		}
		win.eventLoop(0,
			(KeyEvent ev) {
				win.close();
			} );
	} else {
		win.image = image;
	}
}

/// Most functions use the outlineColor instead of taking a color themselves.
struct ScreenPainter {
	SimpleWindow window;
	this(SimpleWindow window, NativeWindowHandle handle) {
		this.window = window;
		if(window.activeScreenPainter !is null) {
			impl = window.activeScreenPainter;
			impl.referenceCount++;
		//	writeln("refcount ++ ", impl.referenceCount);
		} else {
			impl = new ScreenPainterImplementation;
			impl.window = window;
			impl.create(handle);
			impl.referenceCount = 1;
			window.activeScreenPainter = impl;
		//	writeln("constructed");
		}
	}

	~this() {
		impl.referenceCount--;
		//writeln("refcount -- ", impl.referenceCount);
		if(impl.referenceCount == 0) {
			//writeln("destructed");
			impl.dispose();
			window.activeScreenPainter = null;
		}
	}

	// @disable this(this) { } // compiler bug? the linker is bitching about it beind defined twice

	this(this) {
		impl.referenceCount++;
		//writeln("refcount ++ ", impl.referenceCount);
	}

	int fontHeight() {
		return impl.fontHeight();
	}

	@property void pen(Pen p) {
		impl.pen(p);
	}

	@property void outlineColor(Color c) {
		impl.outlineColor(c);
	}

	@property void fillColor(Color c) {
		impl.fillColor(c);
	}

	void transform(ref Point p) {
		p.x += originX;
		p.y += originY;
	}

	int originX;
	int originY;

	void updateDisplay() {
		// FIXME
	}

	void clear() {
		fillColor = Color(255, 255, 255);
		drawRectangle(Point(0, 0), window.width, window.height);
	}

	void drawPixmap(Sprite s, Point upperLeft) {
		transform(upperLeft);
		impl.drawPixmap(s, upperLeft.x, upperLeft.y);
	}

	void drawImage(Point upperLeft, Image i) {
		transform(upperLeft);
		impl.drawImage(upperLeft.x, upperLeft.y, i);
	}

	void drawText(Point upperLeft, string text, Point lowerRight = Point(0, 0), uint alignment = 0) {
		transform(upperLeft);
		if(lowerRight.x != 0 || lowerRight.y != 0)
			transform(lowerRight);
		impl.drawText(upperLeft.x, upperLeft.y, lowerRight.x, lowerRight.y, text, alignment);
	}

	void drawPixel(Point where) {
		transform(where);
		impl.drawPixel(where.x, where.y);
	}


	void drawLine(Point starting, Point ending) {
		transform(starting);
		transform(ending);
		impl.drawLine(starting.x, starting.y, ending.x, ending.y);
	}

	void drawRectangle(Point upperLeft, int width, int height) {
		transform(upperLeft);
		impl.drawRectangle(upperLeft.x, upperLeft.y, width, height);
	}

	/// Arguments are the points of the bounding rectangle
	void drawEllipse(Point upperLeft, Point lowerRight) {
		transform(upperLeft);
		transform(lowerRight);
		impl.drawEllipse(upperLeft.x, upperLeft.y, lowerRight.x, lowerRight.y);
	}

	void drawArc(Point upperLeft, int width, int height, int start, int finish) {
		transform(upperLeft);
		impl.drawArc(upperLeft.x, upperLeft.y, width, height, start, finish);
	}

	void drawPolygon(Point[] vertexes) {
		foreach(vertex; vertexes)
			transform(vertex);
		impl.drawPolygon(vertexes);
	}


	// and do a draw/fill in a single call maybe. Windows can do it... but X can't, though it could do two calls.

	//mixin NativeScreenPainterImplementation!() impl;


	// HACK: if I mixin the impl directly, it won't let me override the copy
	// constructor! The linker complains about there being multiple definitions.
	// I'll make the best of it and reference count it though.
	ScreenPainterImplementation* impl;
}

	// HACK: I need a pointer to the implementation so it's separate
	struct ScreenPainterImplementation {
		SimpleWindow window;
		int referenceCount;
		mixin NativeScreenPainterImplementation!();
	}

// FIXME: i haven't actually tested the sprite class on MS Windows

/**
	Sprites are optimized for fast drawing on the screen, but slow for direct pixel
	access. They are best for drawing a relatively unchanging image repeatedly on the screen.

	You create one by giving a window and an image. It optimizes for that window,
	and copies the image into it to use as the initial picture. Creating a sprite
	can be quite slow (especially over a network connection) so you should do it
	as little as possible and just hold on to your sprite handles after making them.

	Then you can use sprite.drawAt(painter, point); to draw it, which should be
	a fast operation - much faster than drawing the Image itself every time.

	FIXME: you are supposed to be able to draw on these similarly to on windows.
*/
class Sprite {
	// FIXME: we should actually be able to draw upon these, same as windows
	//ScreenPainter drawUpon();

	this(SimpleWindow win, Image i) {
		this.width = i.width;
		this.height = i.height;

		version(X11) {
			auto display = XDisplayConnection.get();
			handle = XCreatePixmap(display, cast(Drawable) win.window, width, height, 24);
			XPutImage(display, cast(Drawable) handle, DefaultGC(display, DefaultScreen(display)), i.handle, 0, 0, 0, 0, i.width, i.height);
		} else version(Windows) {
			BITMAPINFO infoheader;
			infoheader.bmiHeader.biSize = infoheader.bmiHeader.sizeof;
			infoheader.bmiHeader.biWidth = width;
			infoheader.bmiHeader.biHeight = height;
			infoheader.bmiHeader.biPlanes = 1;
			infoheader.bmiHeader.biBitCount = 24;
			infoheader.bmiHeader.biCompression = BI_RGB;

			ubyte* rawData;

			// FIXME: this should prolly be a device dependent bitmap...
			handle = CreateDIBSection(
				null,
				&infoheader,
				DIB_RGB_COLORS,
				cast(void**) &rawData,
				null,
				0);

			if(handle is null)
				throw new Exception("couldn't create pixmap");

			auto itemsPerLine = ((cast(int) width * 3 + 3) / 4) * 4;
			auto arrLength = itemsPerLine * height;
			rawData[0..arrLength] = i.rawData[0..arrLength];
		} else version(OSXCocoa) {
			// FIXME: I have no idea if this is even any good
			ubyte* rawData;
        
			auto colorSpace = CGColorSpaceCreateDeviceRGB();
			context = CGBitmapContextCreate(null, width, height, 8, 4*width,
                                            colorSpace,
                                            kCGImageAlphaPremultipliedLast
                                                   |kCGBitmapByteOrder32Big);
            		CGColorSpaceRelease(colorSpace);
            		rawData = CGBitmapContextGetData(context);

			auto rdl = (width * height * 4);
			rawData[0 .. rdl] = i.rawData[0 .. rdl];
		} else version(html5) {
			handle = nextHandle;
			nextHandle++;
			Html5.createImage(handle, i);
		} else static assert(0);
	}

	void dispose() {
		version(X11)
			XFreePixmap(XDisplayConnection.get(), handle);
		else version(Windows)
			DeleteObject(handle);
		else version(OSXCocoa)
			CGContextRelease(context);
		else version(html5)
			Html5.freeImage(handle);
		else static assert(0);

	}

	int width;
	int height;
	version(X11)
		Pixmap handle;
	else version(Windows)
		HBITMAP handle;
	else version(OSXCocoa)
		CGContextRef context;
	else version(html5) {
		static int nextHandle;
		int handle;
	}
	else static assert(0);

	void drawAt(ScreenPainter painter, Point where) {
		painter.drawPixmap(this, where);
	}
}

class SimpleWindow {
	// maps native window handles to SimpleWindow instances, if there are any
	// you shouldn't need this, but it is public in case you do in a native event handler or something
	public static SimpleWindow[NativeWindowHandle] nativeMapping;

	int width;
	int height;

	// HACK: making the best of some copy constructor woes with refcounting
	private ScreenPainterImplementation* activeScreenPainter;

	/// Creates a window based on the given image. It's client area
	/// width and height is equal to the image. (A window's client area
	/// is the drawable space inside; it excludes the title bar, etc.)
	this(Image image, string title = null) {
		this(image.width, image.height, title);
		this.image = image;
	}

	this(Size size, string title = null, OpenGlOptions opengl = OpenGlOptions.no) {
		this(size.width, size.height, title, opengl);
	}

	this(int width, int height, string title = null, OpenGlOptions opengl = OpenGlOptions.no, Resizablity resizable = Resizablity.fixedSize) {
		this.width = width;
		this.height = height;
		this.openglMode = opengl;
		impl.createWindow(width, height, title is null ? "D Application" : title, opengl);
	}

	OpenGlOptions openglMode;

	version(without_opengl) {} else {
		/// Makes all gl* functions target this window until changed.
		void setAsCurrentOpenGlContext() {
			assert(openglMode == OpenGlOptions.yes);
			version(X11) {
				if(glXMakeCurrent(display, impl.window, impl.glc) == 0)
					throw new Exception("glXMakeCurrent");
			} else version(Windows) {
        			wglMakeCurrent(ghDC, ghRC); 
			}
		}

		/// simpledisplay always uses double buffering, this swaps the OpenGL buffers.
		void swapOpenGlBuffers() {
			assert(openglMode == OpenGlOptions.yes);
			version(X11) {
				glXSwapBuffers(XDisplayConnection.get, impl.window);
			} else version(Windows) {
        			SwapBuffers(ghDC);
			}
		}

		/// Put your code in here that you want to be drawn automatically when your window is uncovered
		void delegate() redrawOpenGlScene;

		/// call this to invoke your delegate. It automatically sets up the context and flips the buffer.
		void redrawOpenGlSceneNow() {
			this.setAsCurrentOpenGlContext();

			if(redrawOpenGlScene !is null)
				redrawOpenGlScene();

			this.swapOpenGlBuffers();

		}
	}

	@property void title(string title) {
		impl.setTitle(title);
	}

	~this() {
		impl.dispose();
	}

	/// Closes the window and terminates it's event loop.
	void close() {
		impl.closeWindow();
	}

	/// Sets your event handlers, without entering the event loop. Useful if you
	/// have multiple windows - set the handlers on each window, then only do eventLoop on your main window.
	void setEventHandlers(T...)(T eventHandlers) {
		// FIXME: add more events
		foreach(handler; eventHandlers) {
			static if(__traits(compiles, handleKeyEvent = handler)) {
				handleKeyEvent = handler;
			} else static if(__traits(compiles, handleCharEvent = handler)) {
				handleCharEvent = handler;
			} else static if(__traits(compiles, handlePulse = handler)) {
				handlePulse = handler;
			} else static if(__traits(compiles, handleMouseEvent = handler)) {
				handleMouseEvent = handler;
			} else static assert(0, "I can't use this event handler " ~ typeof(handler).stringof ~ "\nNote: if you want to capture keycode events, this recently changed to (KeyEvent event) instead of the old (int code) and second draft, (int code, bool pressed), key, character, and pressed are members of KeyEvent.");
		}
	}

	/// The event loop automatically returns when the window is closed
	/// pulseTimeout is given in milliseconds.
	final int eventLoop(T...)(
		long pulseTimeout,    /// set to zero if you don't want a pulse. Note: don't set it too big, or user input may not be processed in a timely manner. I suggest something < 150.
		T eventHandlers) /// delegate list like std.concurrency.receive
	{
		setEventHandlers(eventHandlers);
		return impl.eventLoop(pulseTimeout);
	}

	ScreenPainter draw() {
		return impl.getPainter();
	}

	@property void image(Image i) {
		version(Windows) {
			BITMAP bm;
			HDC hdc = GetDC(hwnd);
			HDC hdcMem = CreateCompatibleDC(hdc);
			HBITMAP hbmOld = SelectObject(hdcMem, i.handle);

			GetObject(i.handle, bm.sizeof, &bm);

			BitBlt(hdc, 0, 0, bm.bmWidth, bm.bmHeight, hdcMem, 0, 0, SRCCOPY);

			SelectObject(hdcMem, hbmOld);
			DeleteDC(hdcMem);
			DeleteDC(hwnd);

			/*
			RECT r;
			r.right = i.width;
			r.bottom = i.height;
			InvalidateRect(hwnd, &r, false);
			*/
		} else
		version(X11) {
			if(!destroyed)
			XPutImage(display, cast(Drawable) window, gc, i.handle, 0, 0, 0, 0, i.width, i.height);
		} else
		version(OSXCocoa) {
           		draw().drawImage(Point(0, 0), i);
			setNeedsDisplay(view, true);
		} else version(html5) {
			// FIXME html5
		} else static assert(0);
	}

	/// What follows are the event handlers. These are set automatically
	/// by the eventLoop function, but are still public so you can change
	/// them later. wasPressed == true means key down. false == key up.

	/// Handles a low-level keyboard event
	void delegate(KeyEvent ke) handleKeyEvent;

	/// Handles a higher level keyboard event - c is the character just pressed.
	void delegate(dchar c) handleCharEvent;

	void delegate() handlePulse;

	void delegate(MouseEvent) handleMouseEvent;

	void delegate() paintingFinished; // use to redraw child widgets if you use system apis to add stuff
	void delegate(int width, int height) windowResized;

	/** Platform specific - handle any native messages this window gets.
	  *
	  * Note: this is called *in addition to* other event handlers, unless you return zero indicating that you handled it.

	  * On Windows, it takes the form of int delegate(HWND,UINT, WPARAM, LPARAM).

	  * On X11, it takes the form of int delegate(XEvent).

	  * It is static because it is called on the global message loop.
	**/
	static NativeEventHandler handleNativeEvent;

//  private:
	mixin NativeSimpleWindowImplementation!() impl;
}

/* Additional utilities */


Color fromHsl(real h, real s, real l) {
	return arsd.color.fromHsl([h,s,l]);
}



/* ********** What follows is the system-specific implementations *********/
version(Windows) {

	alias int delegate(HWND, UINT, WPARAM, LPARAM) NativeEventHandler;
	alias HWND NativeWindowHandle;

	extern(Windows)
	int WndProc(HWND hWnd, UINT iMessage, WPARAM wParam, LPARAM lParam) nothrow {
	    try {
			if(SimpleWindow.handleNativeEvent !is null) {
				// it returns zero if the message is handled, so we won't do anything more there
				// do I like that though?
				auto ret = SimpleWindow.handleNativeEvent(hWnd, iMessage, wParam, lParam);
				if(ret == 0)
					return ret;
			}

            if(auto window = hWnd in SimpleWindow.nativeMapping) {
                return (*window).windowProcedure(hWnd, iMessage, wParam, lParam);
            } else {
                return DefWindowProc(hWnd, iMessage, wParam, lParam);
            }
	    } catch (Exception e) {
            assert(false, "Exception caught in WndProc");
	    }
	}

	mixin template NativeScreenPainterImplementation() {
		HDC hdc;
		HWND hwnd;
		//HDC windowHdc;
		HBITMAP oldBmp;

		void create(NativeWindowHandle window) {
			auto buffer = this.window.impl.buffer;
			hwnd = window;
			auto windowHdc = GetDC(hwnd);

			hdc = CreateCompatibleDC(windowHdc);

			ReleaseDC(hwnd, windowHdc);

			oldBmp = SelectObject(hdc, buffer);

			// X doesn't draw a text background, so neither should we
			SetBkMode(hdc, TRANSPARENT);
		}

		// just because we can on Windows...
		//void create(Image image);

		void dispose() {
			// FIXME: this.window.width/height is probably wrong
			// BitBlt(windowHdc, 0, 0, this.window.width, this.window.height, hdc, 0, 0, SRCCOPY);
			// ReleaseDC(hwnd, windowHdc);

			// FIXME: it shouldn't invalidate the whole thing in all cases... it would be ideal to do this right
			InvalidateRect(hwnd, cast(RECT*)null, false); // no need to erase bg as the whole thing gets bitblt'd ove

			if(originalPen !is null)
				SelectObject(hdc, originalPen);
			if(currentPen !is null)
				DeleteObject(currentPen);
			if(originalBrush !is null)
				SelectObject(hdc, originalBrush);
			if(currentBrush !is null)
				DeleteObject(currentBrush);

			SelectObject(hdc, oldBmp);

			DeleteDC(hdc);

			if(window.paintingFinished !is null)
				window.paintingFinished();
		}

		HPEN originalPen;
		HPEN currentPen;

		Pen _activePen;

		@property void pen(Pen p) {
			_activePen = p;

			HPEN pen;
			if(p.color.a == 0) {
				pen = GetStockObject(NULL_PEN);
			} else {
				pen = CreatePen(PS_SOLID, p.width, RGB(p.color.r, p.color.g, p.color.b));
			}
			auto orig = SelectObject(hdc, pen);
			if(originalPen is null)
				originalPen = orig;

			if(currentPen !is null)
				DeleteObject(currentPen);

			currentPen = pen;

			// the outline is like a foreground since it's done that way on X
			SetTextColor(hdc, RGB(p.color.r, p.color.g, p.color.b));

		}

		@property void outlineColor(Color c) {
			_activePen.color = c;
			pen = _activePen;
		}

		HBRUSH originalBrush;
		HBRUSH currentBrush;
		@property void fillColor(Color c) {
			HBRUSH brush;
			if(c.a == 0) {
				brush = GetStockObject(HOLLOW_BRUSH);
			} else {
				brush = CreateSolidBrush(RGB(c.r, c.g, c.b));
			}
			auto orig = SelectObject(hdc, brush);
			if(originalBrush is null)
				originalBrush = orig;

			if(currentBrush !is null)
				DeleteObject(currentBrush);

			currentBrush = brush;

			// background color is NOT set because X doesn't draw text backgrounds
			//   SetBkColor(hdc, RGB(255, 255, 255));
		}

		void drawImage(int x, int y, Image i) {
			BITMAP bm;

			HDC hdcMem = CreateCompatibleDC(hdc);
			HBITMAP hbmOld = SelectObject(hdcMem, i.handle);

			GetObject(i.handle, bm.sizeof, &bm);

			BitBlt(hdc, x, y, bm.bmWidth, bm.bmHeight, hdcMem, 0, 0, SRCCOPY);

			SelectObject(hdcMem, hbmOld);
			DeleteDC(hdcMem);
		}

		void drawPixmap(Sprite s, int x, int y) {
			BITMAP bm;

			HDC hdcMem = CreateCompatibleDC(hdc);
			HBITMAP hbmOld = SelectObject(hdcMem, s.handle);

			GetObject(s.handle, bm.sizeof, &bm);

			BitBlt(hdc, x, y, bm.bmWidth, bm.bmHeight, hdcMem, 0, 0, SRCCOPY);

			SelectObject(hdcMem, hbmOld);
			DeleteDC(hdcMem);
		}

		void drawText(int x, int y, int x2, int y2, string text, uint alignment) {
			if(x2 == 0 && y2 == 0)
				TextOut(hdc, x, y, text.ptr, text.length);
			else {
				RECT rect;
				rect.left = x;
				rect.top = y;
				rect.right = x2;
				rect.bottom = y2;

				uint mode = DT_LEFT;
				if(alignment & TextAlignment.Center)
					mode = DT_CENTER;

				// FIXME: vcenter on windows only works with single line, but I want it to work in all cases
				if(alignment & TextAlignment.VerticalCenter)
					mode |= DT_VCENTER | DT_SINGLELINE;

				DrawText(hdc, text.ptr, text.length, &rect, mode);
			}

			/*
			uint mode;

			if(alignment & TextAlignment.Center)
				mode = TA_CENTER;

			SetTextAlign(hdc, mode);
			*/
		}

		int fontHeight() {
			TEXTMETRIC metric;
			if(GetTextMetricsW(hdc, &metric)) {
				return metric.tmHeight;
			}

			return 16; // idk just guessing here, maybe we should throw
		}

		void drawPixel(int x, int y) {
			SetPixel(hdc, x, y, RGB(_activePen.color.r, _activePen.color.g, _activePen.color.b));
		}

		// The basic shapes, outlined

		void drawLine(int x1, int y1, int x2, int y2) {
			MoveToEx(hdc, x1, y1, null);
			LineTo(hdc, x2, y2);
		}

		void drawRectangle(int x, int y, int width, int height) {
			Rectangle(hdc, x, y, x + width, y + height);
		}

		/// Arguments are the points of the bounding rectangle
		void drawEllipse(int x1, int y1, int x2, int y2) {
			Ellipse(hdc, x1, y1, x2, y2);
		}

		void drawArc(int x1, int y1, int width, int height, int start, int finish) {
			// FIXME: start X, start Y, end X, end Y
			Arc(hdc, x1, y1, x1 + width, y1 + height, 0, 0, 0, 0);
		}

		void drawPolygon(Point[] vertexes) {
			POINT[] points;
			points.length = vertexes.length;

			foreach(i, p; vertexes) {
				points[i].x = p.x;
				points[i].y = p.y;
			}

			Polygon(hdc, points.ptr, points.length);
		}
	}


	// Mix this into the SimpleWindow class
	mixin template NativeSimpleWindowImplementation() {
		ScreenPainter getPainter() {
			return ScreenPainter(this, hwnd);
		}

		HBITMAP buffer;
		static bool classRegistered;

		void setTitle(string title) {
			SetWindowTextA(hwnd, toStringz(title));
		}

		version(without_opengl) {} else {
			HGLRC ghRC;
			HDC ghDC;
		}

		void createWindow(int width, int height, string title, OpenGlOptions opengl) {
			const char* cn = "DSimpleWindow";

			HINSTANCE hInstance = cast(HINSTANCE) GetModuleHandle(null);

			if(!classRegistered) {
				WNDCLASS wc;

				wc.cbClsExtra = 0;
				wc.cbWndExtra = 0;
				wc.hbrBackground = cast(HBRUSH) (COLOR_WINDOW+1); // GetStockObject(WHITE_BRUSH);
				wc.hCursor = LoadCursor(null, IDC_ARROW);
				wc.hIcon = LoadIcon(hInstance, null);
				wc.hInstance = hInstance;
				wc.lpfnWndProc = &WndProc;
				wc.lpszClassName = cn;
				wc.style = CS_HREDRAW | CS_VREDRAW;
				if(!RegisterClass(&wc))
					throw new Exception("RegisterClass");
				classRegistered = true;
			}

			hwnd = CreateWindow(cn, toStringz(title), WS_OVERLAPPEDWINDOW,
				CW_USEDEFAULT, CW_USEDEFAULT, width, height,
				null, null, hInstance, null);

			SimpleWindow.nativeMapping[hwnd] = this;

			HDC hdc = GetDC(hwnd);


			version(without_opengl) {}
			else {
				ghDC = hdc;

				if(opengl == OpenGlOptions.yes) {
					PIXELFORMATDESCRIPTOR pfd; 

					pfd.nSize = PIXELFORMATDESCRIPTOR.sizeof; 
					pfd.nVersion = 1; 
					pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL |  PFD_DOUBLEBUFFER; 
					pfd.dwLayerMask = PFD_MAIN_PLANE; 
					pfd.iPixelType = PFD_TYPE_RGBA; 
					pfd.cColorBits = 24; 
					pfd.cDepthBits = 8; 
					pfd.cAccumBits = 0; 
					pfd.cStencilBits = 0; 

					auto pixelformat = ChoosePixelFormat(hdc, &pfd); 

					if ((pixelformat = ChoosePixelFormat(hdc, &pfd)) == 0) 
						throw new Exception("ChoosePixelFormat");

					if (SetPixelFormat(hdc, pixelformat, &pfd) == 0) 
						throw new Exception("SetPixelFormat");
				}
				 
				ghRC = wglCreateContext(ghDC); 
			}

			if(opengl == OpenGlOptions.no) {
				buffer = CreateCompatibleBitmap(hdc, width, height);

				auto hdcBmp = CreateCompatibleDC(hdc);
				// make sure it's filled with a blank slate
				auto oldBmp = SelectObject(hdcBmp, buffer);
				auto oldBrush = SelectObject(hdcBmp, GetStockObject(WHITE_BRUSH));
				Rectangle(hdcBmp, 0, 0, width, height);
				SelectObject(hdcBmp, oldBmp);
				SelectObject(hdcBmp, oldBrush);
				DeleteDC(hdcBmp);

				ReleaseDC(hwnd, hdc); // we keep this in opengl mode since it is a class member now
			}

			// We want the window's client area to match the image size
			RECT rcClient, rcWindow;
			POINT ptDiff;
			GetClientRect(hwnd, &rcClient);
			GetWindowRect(hwnd, &rcWindow);
			ptDiff.x = (rcWindow.right - rcWindow.left) - rcClient.right;
			ptDiff.y = (rcWindow.bottom - rcWindow.top) - rcClient.bottom;
			MoveWindow(hwnd,rcWindow.left, rcWindow.top, width + ptDiff.x, height + ptDiff.y, true);

			ShowWindow(hwnd, SW_SHOWNORMAL);
		}


		void dispose() {
			if(buffer)
				DeleteObject(buffer);
		}

		void closeWindow() {
			DestroyWindow(hwnd);
		}

		// returns zero if it recognized the event
		static int triggerEvents(HWND hwnd, uint msg, WPARAM wParam, LPARAM lParam, int offsetX, int offsetY, SimpleWindow wind) nothrow {
		try {
			MouseEvent mouse;

			void mouseEvent() {
				mouse.x = LOWORD(lParam) + offsetX;
				mouse.y = HIWORD(lParam) + offsetY;
				mouse.buttonFlags = wParam;
				mouse.window = wind;

				if(wind.handleMouseEvent)
					wind.handleMouseEvent(mouse);
			}


			switch(msg) {
				case WM_CHAR:
					wchar c = cast(wchar) wParam;
					if(wind.handleCharEvent)
						wind.handleCharEvent(cast(dchar) c);
				break;
				case WM_KEYDOWN:
				case WM_KEYUP:
					KeyEvent ev;
					ev.key = cast(Key) wParam;
					ev.pressed = msg == WM_KEYDOWN;
					// FIXME
					// ev.modifierState = 
					ev.window = wind;
					if(wind.handleKeyEvent)
						wind.handleKeyEvent(ev);
				break;
				case 0x020a /*WM_MOUSEWHEEL*/:
					mouse.type = 1;
					mouse.button = (HIWORD(wParam) > 120) ? 16 : 8;
					mouseEvent();
				break;
				case WM_MOUSEMOVE:
					mouse.type = 0;
					mouseEvent();
				break;
				case WM_LBUTTONDOWN:
				case WM_LBUTTONDBLCLK:
					mouse.type = 1;
					mouse.button = 1;
					mouseEvent();
				break;
				case WM_LBUTTONUP:
					mouse.type = 2;
					mouse.button = 1;
					mouseEvent();
				break;
				case WM_RBUTTONDOWN:
				case WM_RBUTTONDBLCLK:
					mouse.type = 1;
					mouse.button = 2;
					mouseEvent();
				break;
				case WM_RBUTTONUP:
					mouse.type = 2;
					mouse.button = 2;
					mouseEvent();
				break;
				case WM_MBUTTONDOWN:
				case WM_MBUTTONDBLCLK:
					mouse.type = 1;
					mouse.button = 4;
					mouseEvent();
				break;
				case WM_MBUTTONUP:
					mouse.type = 2;
					mouse.button = 4;
					mouseEvent();
				break;
				default: return 1;
			}
			return 0;
			} catch(Exception e) {
				return 0;
			}
		}

		HWND hwnd;

		// the extern(Windows) wndproc should just forward to this
		int windowProcedure(HWND hwnd, uint msg, WPARAM wParam, LPARAM lParam) {
			assert(hwnd is this.hwnd);

			if(triggerEvents(hwnd, msg, wParam, lParam, 0, 0, this))
			switch(msg) {
				case WM_CLOSE:
					DestroyWindow(hwnd);
				break;
				case WM_DESTROY:
					SimpleWindow.nativeMapping.remove(hwnd);
					if(SimpleWindow.nativeMapping.keys.length == 0)
						PostQuitMessage(0);
				break;
				case WM_SIZE:
					auto width = LOWORD(lParam);
					auto height = HIWORD(lParam);
					// FIXME: do something else here
					// fire resizeEvent at least
					if(windowResized !is null)
						windowResized(width, height);
				break;
				case WM_PAINT: {
					BITMAP bm;
					PAINTSTRUCT ps;

					HDC hdc = BeginPaint(hwnd, &ps);

					if(openglMode == OpenGlOptions.no) {

						HDC hdcMem = CreateCompatibleDC(hdc);
						HBITMAP hbmOld = SelectObject(hdcMem, buffer);

						GetObject(buffer, bm.sizeof, &bm);

						BitBlt(hdc, 0, 0, bm.bmWidth, bm.bmHeight, hdcMem, 0, 0, SRCCOPY);

						SelectObject(hdcMem, hbmOld);
						DeleteDC(hdcMem);
						EndPaint(hwnd, &ps);
					} else {
						EndPaint(hwnd, &ps);
						redrawOpenGlSceneNow();
					}
				} break;
				  default:
					return DefWindowProc(hwnd, msg, wParam, lParam);
			}
			 return 0;

		}

		int eventLoop(long pulseTimeout) {
			MSG message;
			int ret;

			import core.thread;

			if(pulseTimeout) {
				bool done = false;
				while(!done) {
					if(PeekMessage(&message, null, 0, 0, PM_NOREMOVE)) {
						ret = GetMessage(&message, null, 0, 0);
						if(ret == 0)
							done = true;

						TranslateMessage(&message);
						DispatchMessage(&message);
					}

					if(!done && handlePulse !is null)
						handlePulse();
					Thread.sleep(dur!"msecs"(pulseTimeout));
				}
			} else {
				while((ret = GetMessage(&message, null, 0, 0)) != 0) {
					if(ret == -1)
						throw new Exception("GetMessage failed");
					TranslateMessage(&message);
					DispatchMessage(&message);
				}
			}

			return message.wParam;
		}
	}

	mixin template NativeImageImplementation() {
		HBITMAP handle;
		ubyte* rawData;

		void setPixel(int x, int y, Color c) {
			auto itemsPerLine = ((cast(int) width * 3 + 3) / 4) * 4;
			// remember, bmps are upside down
			auto offset = itemsPerLine * (height - y - 1) + x * 3;

			rawData[offset + 0] = c.b;
			rawData[offset + 1] = c.g;
			rawData[offset + 2] = c.r;
		}

		void convertToRgbaBytes(ubyte[] where) {
			assert(where.length == this.width * this.height * 4);

			auto itemsPerLine = ((cast(int) width * 3 + 3) / 4) * 4;
			int idx = 0;
			int offset = itemsPerLine * (height - 1);
			// remember, bmps are upside down
			for(int y = height - 1; y >= 0; y--) {
				auto offsetStart = offset;
				for(int x = 0; x < width; x++) {
					where[idx + 0] = rawData[offset + 2]; // r
					where[idx + 1] = rawData[offset + 1]; // g
					where[idx + 2] = rawData[offset + 0]; // b
					where[idx + 3] = 255; // a
					idx += 4; 
					offset += 3;
				}

				offset = offsetStart - itemsPerLine;
			}
		}

		void setFromRgbaBytes(in ubyte[] what) {
			assert(what.length == this.width * this.height * 4);

			auto itemsPerLine = ((cast(int) width * 3 + 3) / 4) * 4;
			int idx = 0;
			int offset = itemsPerLine * (height - 1);
			// remember, bmps are upside down
			for(int y = height - 1; y >= 0; y--) {
				auto offsetStart = offset;
				for(int x = 0; x < width; x++) {
					rawData[offset + 2] = what[idx + 0]; // r
					rawData[offset + 1] = what[idx + 1]; // g
					rawData[offset + 0] = what[idx + 2]; // b
					//where[idx + 3] = 255; // a
					idx += 4; 
					offset += 3;
				}

				offset = offsetStart - itemsPerLine;
			}
		}


		void createImage(int width, int height) {
			BITMAPINFO infoheader;
			infoheader.bmiHeader.biSize = infoheader.bmiHeader.sizeof;
			infoheader.bmiHeader.biWidth = width;
			infoheader.bmiHeader.biHeight = height;
			infoheader.bmiHeader.biPlanes = 1;
			infoheader.bmiHeader.biBitCount = 24;
			infoheader.bmiHeader.biCompression = BI_RGB;

			handle = CreateDIBSection(
				null,
				&infoheader,
				DIB_RGB_COLORS,
				cast(void**) &rawData,
				null,
				0);
			if(handle is null)
				throw new Exception("create image failed");

		}

		void dispose() {
			DeleteObject(handle);
		}
	}

	enum KEY_ESCAPE = 27;
}
version(X11) {

	alias int delegate(XEvent) NativeEventHandler;
	alias Window NativeWindowHandle;

	enum KEY_ESCAPE = 9;

	mixin template NativeScreenPainterImplementation() {
		Display* display;
		Drawable d;
		Drawable destiny;

		// FIXME: should the gc be static too so it isn't recreated every time draw is called?
		GC gc;

		static XFontStruct* font;
		static bool fontAttempted;

		void create(NativeWindowHandle window) {
			this.display = XDisplayConnection.get();

    			auto buffer = this.window.impl.buffer;

			this.d = cast(Drawable) buffer;
			this.destiny = cast(Drawable) window;

			auto dgc = DefaultGC(display, DefaultScreen(display));

			this.gc = XCreateGC(display, d, 0, null);

			XCopyGC(display, dgc, 0xffffffff, this.gc);

			if(!fontAttempted) {
				font = XLoadQueryFont(display, "-bitstream-bitstream vera sans-medium-r-*-*-12-*-*-*-*-*-*-*".ptr);
				// bitstream is a pretty nice font, but if it fails, fixed is pretty reliable and not bad either
				if(font is null)
					font = XLoadQueryFont(display, "-*-fixed-medium-r-*-*-12-*-*-*-*-*-*-*".ptr);

				fontAttempted = true;
			}

			if(font) {
				XSetFont(display, gc, font.fid);
			}
		}

		void dispose() {
    			auto buffer = this.window.impl.buffer;

			// FIXME: this.window.width/height is probably wrong

			// src x,y     then dest x, y
			XCopyArea(display, d, destiny, gc, 0, 0, this.window.width, this.window.height, 0, 0);

			XFreeGC(display, gc);

			version(none) // we don't want to free it because we can use it later
			if(font)
				XFreeFont(display, font);
			XFlush(display);

			if(window.paintingFinished !is null)
				window.paintingFinished();
		}

		bool backgroundIsNotTransparent = true;
		bool foregroundIsNotTransparent = true;

		Pen _pen;

		Color _outlineColor;
		Color _fillColor;

		@property void pen(Pen p) {
			_pen = p;
			_outlineColor = p.color;

			XSetLineAttributes(display, gc, p.width, 0, 0, 0);

			if(p.color.a == 0) {
				foregroundIsNotTransparent = false;
				return;
			}

			foregroundIsNotTransparent = true;

			XSetForeground(display, gc,
				cast(uint) p.color.r << 16 |
				cast(uint) p.color.g << 8 |
				cast(uint) p.color.b);
		}

		@property void outlineColor(Color c) {
			_pen.color = c;
			pen = _pen;
		}

		@property void fillColor(Color c) {
			_fillColor = c;
			if(c.a == 0) {
				backgroundIsNotTransparent = false;
				return;
			}

			backgroundIsNotTransparent = true;

			XSetBackground(display, gc,
				cast(uint) c.r << 16 |
				cast(uint) c.g << 8 |
				cast(uint) c.b);

		}

		void swapColors() {
			auto tmp = _fillColor;
			fillColor = _outlineColor;
			outlineColor = tmp;
		}

		void drawImage(int x, int y, Image i) {
			// source x, source y
			XPutImage(display, d, gc, i.handle, 0, 0, x, y, i.width, i.height);
		}

		void drawPixmap(Sprite s, int x, int y) {
			XCopyArea(display, s.handle, d, gc, 0, 0, s.width, s.height, x, y);
		}

		int fontHeight() {
			if(font)
				return font.max_bounds.ascent + font.max_bounds.descent;
			return 12; // pretty common default...
		}

		void drawText(in int x, in int y, in int x2, in int y2, in string text, in uint alignment) {
			int textHeight = 12;

			// FIXME: should we clip it to the bounding box?

			if(font) {
				textHeight = font.max_bounds.ascent + font.max_bounds.descent;
			}

			auto lines = text.split('\n');

			auto lineHeight = textHeight;
			textHeight *= lines.length;

			int cy = y;

			if(alignment & TextAlignment.VerticalBottom) {
				assert(y2);
				auto h = y2 - y;
				if(h > textHeight) {
					cy += h - textHeight;
					cy -= lineHeight / 2;
				}
			} else if(alignment & TextAlignment.VerticalCenter) {
				assert(y2);
				auto h = y2 - y;
				if(textHeight < h) {
					cy += (h - textHeight) / 2;
					cy -= lineHeight / 4;
				}
			}

			foreach(line; text.split('\n')) {
				int textWidth;
				if(font)
					textWidth = XTextWidth( font, line.ptr, cast(int) line.length);
				else
					textWidth = 12 * cast(int) line.length;

				int px = x, py = cy;

				if(alignment & TextAlignment.Center) {
					assert(x2);
					auto w = x2 - x;
					if(w > textWidth)
						px += (w - textWidth) / 2;
				} else if(alignment & TextAlignment.Right) {
					assert(x2);
					auto pos = x2 - textWidth;
					if(pos > x)
						px = pos;
				}

				XDrawString(display, d, gc, px, py + lineHeight, line.ptr, cast(int) line.length);
				cy += lineHeight + 4;
			}
		}

		void drawPixel(int x, int y) {
			XDrawPoint(display, d, gc, x, y);
		}

		// The basic shapes, outlined

		void drawLine(int x1, int y1, int x2, int y2) {
			if(foregroundIsNotTransparent)
				XDrawLine(display, d, gc, x1, y1, x2, y2);
		}

		void drawRectangle(int x, int y, int width, int height) {
			if(backgroundIsNotTransparent) {
				swapColors();
				XFillRectangle(display, d, gc, x, y, width, height);
				swapColors();
			}
			if(foregroundIsNotTransparent)
				XDrawRectangle(display, d, gc, x, y, width, height);
		}

		/// Arguments are the points of the bounding rectangle
		void drawEllipse(int x1, int y1, int x2, int y2) {
			drawArc(x1, y1, x2 - x1, y2 - y1, 0, 360 * 64);
		}

		// NOTE: start and finish are in units of degrees * 64
		void drawArc(int x1, int y1, int width, int height, int start, int finish) {
			if(backgroundIsNotTransparent) {
				swapColors();
				XFillArc(display, d, gc, x1, y1, width, height, start, finish);
				swapColors();
			}
			if(foregroundIsNotTransparent)
				XDrawArc(display, d, gc, x1, y1, width, height, start, finish);
		}

		void drawPolygon(Point[] vertexes) {
			XPoint[] points;
			points.length = vertexes.length;

			foreach(i, p; vertexes) {
				points[i].x = cast(short) p.x;
				points[i].y = cast(short) p.y;
			}

			if(backgroundIsNotTransparent) {
				swapColors();
				XFillPolygon(display, d, gc, points.ptr, cast(int) points.length, PolygonShape.Complex, CoordMode.CoordModeOrigin);
				swapColors();
			}
			if(foregroundIsNotTransparent) {
				XDrawLines(display, d, gc, points.ptr, cast(int) points.length, CoordMode.CoordModeOrigin);
			}
		}
	}


	class XDisplayConnection {
		private static Display* display;

		static Display* get(SimpleWindow window = null) {
			// FIXME: this shouldn't even be necessary
			version(with_eventloop)
				if(window !is null)
					this.window = window;
			if(display is null) {
				display = XOpenDisplay(null);
				if(display is null)
					throw new Exception("Unable to open X display");
				version(with_eventloop) {
					import arsd.eventloop;
					addFileEventListeners(display.fd, &eventListener, null, null);
				}
			}

			return display;
		}

		version(with_eventloop) {
			import arsd.eventloop;
			static void eventListener(OsFileHandle fd) {
				while(XPending(display))
					doXNextEvent(window);
			}

			static SimpleWindow window;
		}

		static void close() {
			if(display is null)
				return;

			version(with_eventloop) {
				import arsd.eventloop;
				removeFileEventListeners(display.fd);
			}

			XCloseDisplay(display);
			display = null;
		}
	}

	mixin template NativeImageImplementation() {
		XImage* handle;
		ubyte* rawData;

		void createImage(int width, int height) {
			auto display = XDisplayConnection.get();
			auto screen = DefaultScreen(display);

			// This actually needs to be malloc to avoid a double free error when XDestroyImage is called
			import core.stdc.stdlib : malloc;
			rawData = cast(ubyte*) malloc(width * height * 4);

			handle = XCreateImage(
				display,
				DefaultVisual(display, screen),
				24, // bpp
				ImageFormat.ZPixmap,
				0, // offset
				rawData,
				width, height,
				8 /* FIXME */, 4 * width); // padding, bytes per line
		}

		void dispose() {
			// note: this calls free(rawData) for us
			if(handle)
			XDestroyImage(handle);
		}

		/*
		Color getPixel(int x, int y) {

		}
		*/

		void setPixel(int x, int y, Color c) {
			auto offset = (y * width + x) * 4;
			rawData[offset + 0] = c.b;
			rawData[offset + 1] = c.g;
			rawData[offset + 2] = c.r;
		}

		void convertToRgbaBytes(ubyte[] where) {
			assert(where.length == this.width * this.height * 4);

			// if rawData had a length....
			//assert(rawData.length == where.length);
			for(int idx = 0; idx < where.length; idx += 4) {
				where[idx + 0] = rawData[idx + 2]; // r
				where[idx + 1] = rawData[idx + 1]; // g
				where[idx + 2] = rawData[idx + 0]; // b
				where[idx + 3] = 255; // a
			}
		}

		void setFromRgbaBytes(in ubyte[] where) {
			assert(where.length == this.width * this.height * 4);

			// if rawData had a length....
			//assert(rawData.length == where.length);
			for(int idx = 0; idx < where.length; idx += 4) {
				rawData[idx + 2] = where[idx + 0]; // r
				rawData[idx + 1] = where[idx + 1]; // g
				rawData[idx + 0] = where[idx + 2]; // b
				//rawData[idx + 3] = 255; // a
			}
		}

	}

	mixin template NativeSimpleWindowImplementation() {
		GC gc;
		Window window;
		Display* display;

		Pixmap buffer;

		version(without_opengl) {} else
		GLXContext glc;

		ScreenPainter getPainter() {
			return ScreenPainter(this, window);
		}

		void setTitle(string title) {
			XTextProperty windowName;
			windowName.value = title.ptr;
			windowName.encoding = XA_STRING;
			windowName.format = 8;
			windowName.nitems = cast(uint) title.length;

			XSetWMName(display, window, &windowName);
		}

		void createWindow(int width, int height, string title, in OpenGlOptions opengl) {
			display = XDisplayConnection.get(this);
			auto screen = DefaultScreen(display);

			version(without_opengl) {}
			else {
				if(opengl == OpenGlOptions.yes) {
					static immutable GLint[] attrs = [ GLX_RGBA, GLX_DEPTH_SIZE, 24, GLX_DOUBLEBUFFER, None ];
					auto vi = glXChooseVisual(display, 0, attrs.ptr);
					if(vi is null) throw new Exception("no open gl visual found");

    					XSetWindowAttributes swa; 
					auto root = RootWindow(display, screen);
					swa.colormap = XCreateColormap(display, root, vi.visual, AllocNone);

					window = XCreateWindow(display, root,
						0, 0, width, height,
						0, vi.depth, 1 /* InputOutput */, vi.visual, CWColormap, &swa);

					glc = glXCreateContext(display, vi, null, GL_TRUE);
					if(glc is null)
						throw new Exception("glc");
				}
			}

			if(opengl == OpenGlOptions.no) {
				window = XCreateSimpleWindow(
					display,
					RootWindow(display, screen),
					0, 0, // x, y
					width, height,
					1, // border width
					BlackPixel(display, screen), // border
					WhitePixel(display, screen)); // background

				buffer = XCreatePixmap(display, cast(Drawable) window, width, height, 24);

				gc = DefaultGC(display, screen);

				// clear out the buffer to get us started...
				XSetForeground(display, gc, WhitePixel(display, screen));
				XFillRectangle(display, cast(Drawable) buffer, gc, 0, 0, width, height);
				XSetForeground(display, gc, BlackPixel(display, screen));
			}

			setTitle(title);
			SimpleWindow.nativeMapping[window] = this;

			// This gives our window a close button
			Atom atom = XInternAtom(display, "WM_DELETE_WINDOW".ptr, true); // FIXME: does this need to be freed?
			XSetWMProtocols(display, window, &atom, 1);

			XSelectInput(display, window,
				EventMask.ExposureMask |
				EventMask.KeyPressMask |
				EventMask.StructureNotifyMask
				| EventMask.PointerMotionMask // FIXME: not efficient
				| EventMask.ButtonPressMask
				| EventMask.ButtonReleaseMask
			);

			XMapWindow(display, window);
			XFlush(display);
		}

		void createOpenGlContext() {

		}

		void closeWindow() {
			if(buffer)
				XFreePixmap(display, buffer);
			XDestroyWindow(display, window);
			XFlush(display);
		}

		void dispose() {
		}

		bool destroyed = false;

		int eventLoop(long pulseTimeout) {
			bool done = false;
			import core.thread;

			while (!done) {
			while(!done &&
				(pulseTimeout == 0 || (XPending(display) > 0)))
			{
				done = doXNextEvent(this.display);
			}
				if(!done && pulseTimeout !=0) {
					if(handlePulse !is null)
						handlePulse();
					Thread.sleep(dur!"msecs"(pulseTimeout));
				}
			}

			return 0;
		}
	}
}

version(X11) {
	bool doXNextEvent(Display* display) {
		bool done;
		XEvent e;
		XNextEvent(display, &e);

		version(with_eventloop)
			import arsd.eventloop;

		if(SimpleWindow.handleNativeEvent !is null) {
			// see windows impl's comments
			auto ret = SimpleWindow.handleNativeEvent(e);
			if(ret == 0)
				return done;
		}

		switch(e.type) {
		  case EventType.ConfigureNotify:
			auto event = e.xconfigure;
		  	if(auto win = event.window in SimpleWindow.nativeMapping) {
				if(event.width != win.width || event.height != win.height) {
					// FIXME: do something here
					// fire resizeEvent at least
					if(win.windowResized !is null)
						win.windowResized(event.width, event.height);
				}
			}
		  break;
		  case EventType.Expose:
		  	if(auto win = e.xexpose.window in SimpleWindow.nativeMapping) {
				if((*win).openglMode == OpenGlOptions.no)
					XCopyArea(display, cast(Drawable) (*win).buffer, cast(Drawable) (*win).window, (*win).gc, 0, 0, (*win).width, (*win).height, 0, 0);
				else {
					// need to redraw the scene somehow.
					win.redrawOpenGlSceneNow();
				}
			}
		  break;
		  case EventType.ClientMessage: // User clicked the close button
			if(auto win = e.xclient.window in SimpleWindow.nativeMapping)
				(*win).close();
		  break;
		  case EventType.DestroyNotify:
			if(auto win = e.xdestroywindow.window in SimpleWindow.nativeMapping) {
				(*win).destroyed = true;
				SimpleWindow.nativeMapping.remove(e.xdestroywindow.window);
				if(SimpleWindow.nativeMapping.keys.length == 0)
					done = true;
			}

			version(with_eventloop) {
				if(done) exit();
			}
		  break;

		  case EventType.MotionNotify:
			MouseEvent mouse;
			auto event = e.xmotion;

			mouse.type = 0;
			mouse.x = event.x;
			mouse.y = event.y;
			mouse.buttonFlags = event.state;

			if(auto win = e.xmotion.window in SimpleWindow.nativeMapping) {
				if((*win).handleMouseEvent)
					(*win).handleMouseEvent(mouse);
				mouse.window = *win;
			}

		  	version(with_eventloop)
				send(mouse);
		  break;
		  case EventType.ButtonPress:
		  case EventType.ButtonRelease:
			MouseEvent mouse;
			auto event = e.xbutton;

			mouse.type = e.type == EventType.ButtonPress ? 1 : 2;
			mouse.x = event.x;
			mouse.y = event.y;

			switch(event.button) {
				case 1: mouse.button = 1; break; // left
				case 2: mouse.button = 4; break; // middle
				case 3: mouse.button = 2; break; // right
				case 4: mouse.button = 8; break; // scroll up
				case 5: mouse.button = 16; break; // scroll down
				default:
			}

			// FIXME: double check this
			mouse.buttonFlags = event.state;

			//mouse.buttonFlags = event.detail;

			if(auto win = e.xbutton.window in SimpleWindow.nativeMapping) {
				if((*win).handleMouseEvent)
					(*win).handleMouseEvent(mouse);
				mouse.window = *win;
			}
			version(with_eventloop)
				send(mouse);
		  break;

		  case EventType.KeyPress:
		  case EventType.KeyRelease:
			KeyEvent ke;
			ke.pressed = e.type == EventType.KeyPress;
			
			auto sym = XKeycodeToKeysym(
				XDisplayConnection.get(),
				e.xkey.keycode,
				0);

			ke.key = cast(Key) sym;//e.xkey.keycode;

			ke.modifierState = e.xkey.state;

			// Xutf8LookupString

			// import std.stdio; writefln("%x", sym);
			if(sym != 0 && ke.pressed) {
				char[16] buffer;
				auto res = XLookupString(&e.xkey, buffer.ptr, buffer.length, null, null);
				if(res && buffer[0] < 128)
					ke.character = cast(dchar) buffer[0];
			}

			else switch(sym) {
				case 0xff09: ke.character = '\t'; break;
				case 0xff8d: // keypad enter
				case 0xff0d: ke.character = '\n'; break;
				default : // ignore
			}

			if(auto win = e.xkey.window in SimpleWindow.nativeMapping) {

				ke.window = *win;

				if((*win).handleKeyEvent)
					(*win).handleKeyEvent(ke);

				// char events are separate since they are on Windows too
				if(ke.pressed && ke.character != dchar.init) {
					// FIXME: I think Windows sends these on releases... we should try to match that, but idk about repeats.
					if((*win).handleCharEvent) {
						(*win).handleCharEvent(ke.character);
					}
				}
			}

			version(with_eventloop)
				send(ke);
		  break;
		  default:
		}

		return done;
	}
}

/* *************************************** */
/*      Done with simpledisplay stuff      */
/* *************************************** */

// Necessary C library bindings follow

version(Windows) {
	import core.sys.windows.windows;

	pragma(lib, "gdi32");

	version(without_opengl){} else {
		extern(Windows) {
			alias HANDLE HGLRC;
			BOOL wglMakeCurrent(HDC, HGLRC);
			HGLRC wglCreateContext(HDC);
			BOOL SwapBuffers(HDC);
			BOOL wglDeleteContext(HGLRC);
			int ChoosePixelFormat(HDC, in PIXELFORMATDESCRIPTOR*);
			BOOL SetPixelFormat(HDC hdc, int iPixelFormat, const PIXELFORMATDESCRIPTOR *ppfd);

			struct PIXELFORMATDESCRIPTOR {
			  WORD  nSize;
			  WORD  nVersion;
			  DWORD dwFlags;
			  BYTE  iPixelType;
			  BYTE  cColorBits;
			  BYTE  cRedBits;
			  BYTE  cRedShift;
			  BYTE  cGreenBits;
			  BYTE  cGreenShift;
			  BYTE  cBlueBits;
			  BYTE  cBlueShift;
			  BYTE  cAlphaBits;
			  BYTE  cAlphaShift;
			  BYTE  cAccumBits;
			  BYTE  cAccumRedBits;
			  BYTE  cAccumGreenBits;
			  BYTE  cAccumBlueBits;
			  BYTE  cAccumAlphaBits;
			  BYTE  cDepthBits;
			  BYTE  cStencilBits;
			  BYTE  cAuxBuffers;
			  BYTE  iLayerType;
			  BYTE  bReserved;
			  DWORD dwLayerMask;
			  DWORD dwVisibleMask;
			  DWORD dwDamageMask;
			}

			enum PFD_TYPE_RGBA = 0;
			enum PFD_TYPE_COLORINDEX = 1;

			enum PFD_MAIN_PLANE = 0;
			enum PFD_OVERLAY_PLANE = 1;
			enum PFD_UNDERLAY_PLANE = -1;

			enum {
				PFD_DOUBLEBUFFER          = 0x00000001,
				PFD_STEREO                = 0x00000002,
				PFD_DRAW_TO_WINDOW        = 0x00000004,
				PFD_DRAW_TO_BITMAP        = 0x00000008,
				PFD_SUPPORT_GDI           = 0x00000010,
				PFD_SUPPORT_OPENGL        = 0x00000020,
				PFD_GENERIC_FORMAT        = 0x00000040,
				PFD_NEED_PALETTE          = 0x00000080,
				PFD_NEED_SYSTEM_PALETTE   = 0x00000100,
				PFD_SWAP_EXCHANGE         = 0x00000200,
				PFD_SWAP_COPY             = 0x00000400,
				PFD_SWAP_LAYER_BUFFERS    = 0x00000800,
				PFD_GENERIC_ACCELERATED   = 0x00001000,
				PFD_SUPPORT_DIRECTDRAW    = 0x00002000,
				/* PIXELFORMATDESCRIPTOR flags for use in ChoosePixelFormat only */
				PFD_DEPTH_DONTCARE        = 0x20000000,
				PFD_DOUBLEBUFFER_DONTCARE = 0x40000000,
				PFD_STEREO_DONTCARE       = 0x80000000
			}



		}
	}

	extern(Windows) {
		// The included D headers are incomplete, finish them here
		// enough that this module works.
		alias GetObjectA GetObject;
		alias GetMessageA GetMessage;
		alias PeekMessageA PeekMessage;
		alias TextOutA TextOut;
		alias DispatchMessageA DispatchMessage;
		alias GetModuleHandleA GetModuleHandle;
		alias LoadCursorA LoadCursor;
		alias LoadIconA LoadIcon;
		alias RegisterClassA RegisterClass;
		alias CreateWindowA CreateWindow;
		alias DefWindowProcA DefWindowProc;
		alias DrawTextA DrawText;

		enum DT_BOTTOM = 8;
		enum DT_CALCRECT = 1024;
		enum DT_CENTER = 1;
		enum DT_EDITCONTROL = 8192;
		enum DT_END_ELLIPSIS = 32768;
		enum DT_PATH_ELLIPSIS = 16384;
		enum DT_WORD_ELLIPSIS = 0x40000;
		enum DT_EXPANDTABS = 64;
		enum DT_EXTERNALLEADING = 512;
		enum DT_LEFT = 0;
		enum DT_MODIFYSTRING = 65536;
		enum DT_NOCLIP = 256;
		enum DT_NOPREFIX = 2048;
		enum DT_RIGHT = 2;
		enum DT_RTLREADING = 131072;
		enum DT_SINGLELINE = 32;
		enum DT_TABSTOP = 128;
		enum DT_TOP = 0;
		enum DT_VCENTER = 4;
		enum DT_WORDBREAK = 16;
		enum DT_INTERNAL = 4096;



		bool GetTextMetricsW(HDC hdc, TEXTMETRIC* lptm);

struct TEXTMETRIC {
  LONG tmHeight; 
  LONG tmAscent; 
  LONG tmDescent; 
  LONG tmInternalLeading; 
  LONG tmExternalLeading; 
  LONG tmAveCharWidth; 
  LONG tmMaxCharWidth; 
  LONG tmWeight; 
  LONG tmOverhang; 
  LONG tmDigitizedAspectX; 
  LONG tmDigitizedAspectY; 
  char tmFirstChar; 
  char tmLastChar; 
  char tmDefaultChar; 
  char tmBreakChar; 
  BYTE tmItalic; 
  BYTE tmUnderlined; 
  BYTE tmStruckOut; 
  BYTE tmPitchAndFamily; 
  BYTE tmCharSet; 
}


		uint SetTextAlign(HDC hdc, uint fMode);

		bool MoveWindow(HWND hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
		HBITMAP CreateDIBSection(HDC, const BITMAPINFO*, uint, void**, HANDLE hSection, DWORD);
		bool BitBlt(HDC hdcDest, int nXDest, int nYDest, int nWidth, int nHeight, HDC hdcSrc, int nXSrc, int nYSrc, DWORD dwRop);

		LRESULT CallWindowProcW(WNDPROC lpPrevWndFunc, HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam) nothrow;
		alias CallWindowProcW CallWindowProc;

		alias SetWindowTextA SetWindowText;

		BOOL SetWindowTextA(HWND hWnd, LPCTSTR lpString);


		alias SetWindowLongW SetWindowLong;
		LONG SetWindowLongW(HWND hWnd,int nIndex,LONG dwNewLong);
		enum GWL_WNDPROC = -4;

		bool DestroyWindow(HWND);
		int DrawTextA(HDC hDC, LPCTSTR lpchText, int nCount, LPRECT lpRect, UINT uFormat);
		bool Rectangle(HDC, int, int, int, int);
		bool Ellipse(HDC, int, int, int, int);
		bool Arc(HDC, int, int, int, int, int, int, int, int);
		bool Polygon(HDC, POINT*, int);
		HBRUSH CreateSolidBrush(COLORREF);

		HBITMAP CreateCompatibleBitmap(HDC, int, int);

		uint SetTimer(HWND, uint, uint, void*);
		bool KillTimer(HWND, uint);


		enum BI_RGB = 0;
		enum DIB_RGB_COLORS = 0;
		enum TRANSPARENT = 1;

	}

}

else version(X11) {

// X11 bindings needed here
/*
	A little of this is from the bindings project on
	D Source and some of it is copy/paste from the C
	header.

	The DSource listing consistently used D's long
	where C used long. That's wrong - C long is 32 bit, so
	it should be int in D. I changed that here.

	Note:
	This isn't complete, just took what I needed for myself.
*/

pragma(lib, "X11");

extern(C):

int XLookupString(XKeyEvent *event_struct, char *buffer_return, int bytes_buffer, KeySym *keysym_return, void *status_in_out);

char *XKeysymToString(KeySym keysym);
KeySym XKeycodeToKeysym(
    Display*		/* display */,
    KeyCode		/* keycode */,
    int			/* index */
);

Display* XOpenDisplay(const char*);
int XCloseDisplay(Display*);

uint XSendEvent(Display* display, Window w, Bool propagate, arch_long event_mask, XEvent* event_send);


enum MappingType:int {
	MappingModifier		=0,
	MappingKeyboard		=1,
	MappingPointer		=2
}

/* ImageFormat -- PutImage, GetImage */
enum ImageFormat:int {
	XYBitmap	=0,	/* depth 1, XYFormat */
	XYPixmap	=1,	/* depth == drawable depth */
	ZPixmap	=2	/* depth == drawable depth */
}

enum ModifierName:int {
	ShiftMapIndex	=0,
	LockMapIndex	=1,
	ControlMapIndex	=2,
	Mod1MapIndex	=3,
	Mod2MapIndex	=4,
	Mod3MapIndex	=5,
	Mod4MapIndex	=6,
	Mod5MapIndex	=7
}

enum ButtonMask:int {
	Button1Mask	=1<<8,
	Button2Mask	=1<<9,
	Button3Mask	=1<<10,
	Button4Mask	=1<<11,
	Button5Mask	=1<<12,
	AnyModifier	=1<<15/* used in GrabButton, GrabKey */
}

enum KeyOrButtonMask:uint {
	ShiftMask	=1<<0,
	LockMask	=1<<1,
	ControlMask	=1<<2,
	Mod1Mask	=1<<3,
	Mod2Mask	=1<<4,
	Mod3Mask	=1<<5,
	Mod4Mask	=1<<6,
	Mod5Mask	=1<<7,
	Button1Mask	=1<<8,
	Button2Mask	=1<<9,
	Button3Mask	=1<<10,
	Button4Mask	=1<<11,
	Button5Mask	=1<<12,
	AnyModifier	=1<<15/* used in GrabButton, GrabKey */
}

enum ButtonName:int {
	Button1	=1,
	Button2	=2,
	Button3	=3,
	Button4	=4,
	Button5	=5
}

/* Notify modes */
enum NotifyModes:int
{
	NotifyNormal		=0,
	NotifyGrab			=1,
	NotifyUngrab		=2,
	NotifyWhileGrabbed	=3
}
const int NotifyHint	=1;	/* for MotionNotify events */

/* Notify detail */
enum NotifyDetail:int
{
	NotifyAncestor			=0,
	NotifyVirtual			=1,
	NotifyInferior			=2,
	NotifyNonlinear			=3,
	NotifyNonlinearVirtual	=4,
	NotifyPointer			=5,
	NotifyPointerRoot		=6,
	NotifyDetailNone		=7
}

/* Visibility notify */

enum VisibilityNotify:int
{
VisibilityUnobscured		=0,
VisibilityPartiallyObscured	=1,
VisibilityFullyObscured		=2
}


enum WindowStackingMethod:int
{
	Above		=0,
	Below		=1,
	TopIf		=2,
	BottomIf	=3,
	Opposite	=4
}

/* Circulation request */
enum CirculationRequest:int
{
	PlaceOnTop		=0,
	PlaceOnBottom	=1
}

enum PropertyNotification:int
{
	PropertyNewValue	=0,
	PropertyDelete		=1
}

enum ColorMapNotification:int
{
	ColormapUninstalled	=0,
	ColormapInstalled		=1
}


	struct _XPrivate {}
	struct _XrmHashBucketRec {}

	alias void* XPointer;
	alias void* XExtData;

	version( X86_64 ) {
		alias ulong XID;
		alias ulong arch_ulong;
		alias long arch_long;
	} else {
		alias uint XID;
		alias uint arch_ulong;
		alias int arch_long;
	}

	alias XID Window;
	alias XID Drawable;
	alias XID Pixmap;

	alias arch_ulong Atom;
	alias bool Bool;
	alias Display XDisplay;

	alias int ByteOrder;
	alias arch_ulong Time;
	alias void ScreenFormat;

	struct XImage {
	    int width, height;			/* size of image */
	    int xoffset;				/* number of pixels offset in X direction */
	    ImageFormat format;		/* XYBitmap, XYPixmap, ZPixmap */
	    void *data;					/* pointer to image data */
	    ByteOrder byte_order;		/* data byte order, LSBFirst, MSBFirst */
	    int bitmap_unit;			/* quant. of scanline 8, 16, 32 */
	    int bitmap_bit_order;		/* LSBFirst, MSBFirst */
	    int bitmap_pad;			/* 8, 16, 32 either XY or ZPixmap */
	    int depth;					/* depth of image */
	    int bytes_per_line;			/* accelarator to next line */
	    int bits_per_pixel;			/* bits per pixel (ZPixmap) */
	    arch_ulong red_mask;	/* bits in z arrangment */
	    arch_ulong green_mask;
	    arch_ulong blue_mask;
	    XPointer obdata;			/* hook for the object routines to hang on */
	    struct F {				/* image manipulation routines */
			XImage* function(
				XDisplay* 			/* display */,
				Visual*				/* visual */,
				uint				/* depth */,
				int					/* format */,
				int					/* offset */,
				byte*				/* data */,
				uint				/* width */,
				uint				/* height */,
				int					/* bitmap_pad */,
				int					/* bytes_per_line */) create_image;
			int  function(XImage *)destroy_image;
			arch_ulong function(XImage *, int, int)get_pixel;
			int  function(XImage *, int, int, uint)put_pixel;
			XImage function(XImage *, int, int, uint, uint)sub_image;
			int function(XImage *, int)add_pixel;
		}

		F f;
	}
	version(X86_64) static assert(XImage.sizeof == 136);

struct XCharStruct {
    short       lbearing;       /* origin to left edge of raster */
    short       rbearing;       /* origin to right edge of raster */
    short       width;          /* advance to next char's origin */
    short       ascent;         /* baseline to top edge of raster */
    short       descent;        /* baseline to bottom edge of raster */
    ushort attributes;  /* per char flags (not predefined) */
}

/*
 * To allow arbitrary information with fonts, there are additional properties
 * returned.
 */
struct XFontProp {
    Atom name;
    arch_ulong card32;
}

alias Atom Font;

struct XFontStruct {
   XExtData *ext_data;           /* Hook for extension to hang data */
   Font fid;                     /* Font ID for this font */
   uint direction;           /* Direction the font is painted */
   uint min_char_or_byte2;   /* First character */
   uint max_char_or_byte2;   /* Last character */
   uint min_byte1;           /* First row that exists (for two-byte
                                  * fonts) */
   uint max_byte1;           /* Last row that exists (for two-byte
                                  * fonts) */
   Bool all_chars_exist;         /* Flag if all characters have nonzero
                                  * size */
   uint default_char;        /* Char to print for undefined character */
   int n_properties;             /* How many properties there are */
   XFontProp *properties;        /* Pointer to array of additional
                                  * properties*/
   XCharStruct min_bounds;       /* Minimum bounds over all existing char*/
   XCharStruct max_bounds;       /* Maximum bounds over all existing char*/
   XCharStruct *per_char;        /* first_char to last_char information */
   int ascent;                   /* Max extent above baseline for spacing */
   int descent;                  /* Max descent below baseline for spacing */
}

	XFontStruct *XLoadQueryFont(Display *display, in char *name);
	int XFreeFont(Display *display, XFontStruct *font_struct);
	int XSetFont(Display* display, GC gc, Font font);
	int XTextWidth(XFontStruct*, in char*, int);

	int XSetLineAttributes(Display *display, GC gc, uint line_width, int line_style, int cap_style, int join_style);
	int XSetDashes(Display *display, GC gc, int dash_offset, in char* dash_list, int n);



/*
 * Definitions of specific events.
 */
struct XKeyEvent
{
	int type;			/* of event */
	arch_ulong serial;		/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window window;	        /* "event" window it is reported relative to */
	Window root;	        /* root window that the event occurred on */
	Window subwindow;	/* child window */
	Time time;		/* milliseconds */
	int x, y;		/* pointer x, y coordinates in event window */
	int x_root, y_root;	/* coordinates relative to root */
	KeyOrButtonMask state;	/* key or button mask */
	uint keycode;	/* detail */
	Bool same_screen;	/* same screen flag */
}
version(X86_64) static assert(XKeyEvent.sizeof == 96);
alias XKeyEvent XKeyPressedEvent;
alias XKeyEvent XKeyReleasedEvent;

struct XButtonEvent
{
	int type;		/* of event */
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window window;	        /* "event" window it is reported relative to */
	Window root;	        /* root window that the event occurred on */
	Window subwindow;	/* child window */
	Time time;		/* milliseconds */
	int x, y;		/* pointer x, y coordinates in event window */
	int x_root, y_root;	/* coordinates relative to root */
	KeyOrButtonMask state;	/* key or button mask */
	uint button;	/* detail */
	Bool same_screen;	/* same screen flag */
}
alias XButtonEvent XButtonPressedEvent;
alias XButtonEvent XButtonReleasedEvent;

struct XMotionEvent{
	int type;		/* of event */
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window window;	        /* "event" window reported relative to */
	Window root;	        /* root window that the event occurred on */
	Window subwindow;	/* child window */
	Time time;		/* milliseconds */
	int x, y;		/* pointer x, y coordinates in event window */
	int x_root, y_root;	/* coordinates relative to root */
	KeyOrButtonMask state;	/* key or button mask */
	byte is_hint;		/* detail */
	Bool same_screen;	/* same screen flag */
}
alias XMotionEvent XPointerMovedEvent;

struct XCrossingEvent{
	int type;		/* of event */
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window window;	        /* "event" window reported relative to */
	Window root;	        /* root window that the event occurred on */
	Window subwindow;	/* child window */
	Time time;		/* milliseconds */
	int x, y;		/* pointer x, y coordinates in event window */
	int x_root, y_root;	/* coordinates relative to root */
	NotifyModes mode;		/* NotifyNormal, NotifyGrab, NotifyUngrab */
	NotifyDetail detail;
	/*
	 * NotifyAncestor, NotifyVirtual, NotifyInferior,
	 * NotifyNonlinear,NotifyNonlinearVirtual
	 */
	Bool same_screen;	/* same screen flag */
	Bool focus;		/* Boolean focus */
	KeyOrButtonMask state;	/* key or button mask */
}
alias XCrossingEvent XEnterWindowEvent;
alias XCrossingEvent XLeaveWindowEvent;

struct XFocusChangeEvent{
	int type;		/* FocusIn or FocusOut */
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window window;		/* window of event */
	NotifyModes mode;		/* NotifyNormal, NotifyWhileGrabbed,
				   NotifyGrab, NotifyUngrab */
	NotifyDetail detail;
	/*
	 * NotifyAncestor, NotifyVirtual, NotifyInferior,
	 * NotifyNonlinear,NotifyNonlinearVirtual, NotifyPointer,
	 * NotifyPointerRoot, NotifyDetailNone
	 */
}
alias XFocusChangeEvent XFocusInEvent;
alias XFocusChangeEvent XFocusOutEvent;
Window XCreateSimpleWindow(
    Display*	/* display */,
    Window		/* parent */,
    int			/* x */,
    int			/* y */,
    uint		/* width */,
    uint		/* height */,
    uint		/* border_width */,
    uint		/* border */,
    uint		/* background */
);
Window XCreateWindow(Display *display, Window parent, int x, int y, uint width, uint height, uint border_width, int depth, uint class_, Visual *visual, arch_ulong valuemask, XSetWindowAttributes *attributes);

       Colormap XCreateColormap(Display *display, Window w, Visual *visual, int alloc);

enum CWBackPixmap              = (1L<<0);
enum CWBackPixel               = (1L<<1);
enum CWBorderPixmap            = (1L<<2);
enum CWBorderPixel             = (1L<<3);
enum CWBitGravity              = (1L<<4);
enum CWWinGravity              = (1L<<5);
enum CWBackingStore            = (1L<<6);
enum CWBackingPlanes           = (1L<<7);
enum CWBackingPixel            = (1L<<8);
enum CWOverrideRedirect        = (1L<<9);
enum CWSaveUnder               = (1L<<10);
enum CWEventMask               = (1L<<11);
enum CWDontPropagate           = (1L<<12);
enum CWColormap                = (1L<<13);
enum CWCursor                  = (1L<<14);


struct XSetWindowAttributes {
	Pixmap background_pixmap;/* background, None, or ParentRelative */
	arch_ulong background_pixel;/* background pixel */
	Pixmap border_pixmap;    /* border of the window or CopyFromParent */
	arch_ulong border_pixel;/* border pixel value */
	int bit_gravity;         /* one of bit gravity values */
	int win_gravity;         /* one of the window gravity values */
	int backing_store;       /* NotUseful, WhenMapped, Always */
	arch_ulong backing_planes;/* planes to be preserved if possible */
	arch_ulong backing_pixel;/* value to use in restoring planes */
	Bool save_under;         /* should bits under be saved? (popups) */
	arch_long event_mask;         /* set of events that should be saved */
	arch_long do_not_propagate_mask;/* set of events that should not propagate */
	Bool override_redirect;  /* boolean value for override_redirect */
	Colormap colormap;       /* color map to be associated with window */
	Cursor cursor;           /* cursor to be displayed (or None) */
}




XImage *XCreateImage(
    Display*		/* display */,
    Visual*		/* visual */,
    uint	/* depth */,
    int			/* format */,
    int			/* offset */,
    ubyte*		/* data */,
    uint	/* width */,
    uint	/* height */,
    int			/* bitmap_pad */,
    int			/* bytes_per_line */
);

Atom XInternAtom(
    Display*		/* display */,
    const char*	/* atom_name */,
    Bool		/* only_if_exists */
);

alias int Status;


enum EventMask:int
{
	NoEventMask				=0,
	KeyPressMask			=1<<0,
	KeyReleaseMask			=1<<1,
	ButtonPressMask			=1<<2,
	ButtonReleaseMask		=1<<3,
	EnterWindowMask			=1<<4,
	LeaveWindowMask			=1<<5,
	PointerMotionMask		=1<<6,
	PointerMotionHintMask	=1<<7,
	Button1MotionMask		=1<<8,
	Button2MotionMask		=1<<9,
	Button3MotionMask		=1<<10,
	Button4MotionMask		=1<<11,
	Button5MotionMask		=1<<12,
	ButtonMotionMask		=1<<13,
	KeymapStateMask		=1<<14,
	ExposureMask			=1<<15,
	VisibilityChangeMask	=1<<16,
	StructureNotifyMask		=1<<17,
	ResizeRedirectMask		=1<<18,
	SubstructureNotifyMask	=1<<19,
	SubstructureRedirectMask=1<<20,
	FocusChangeMask			=1<<21,
	PropertyChangeMask		=1<<22,
	ColormapChangeMask		=1<<23,
	OwnerGrabButtonMask		=1<<24
}

int XPutImage(
    Display*	/* display */,
    Drawable	/* d */,
    GC			/* gc */,
    XImage*	/* image */,
    int			/* src_x */,
    int			/* src_y */,
    int			/* dest_x */,
    int			/* dest_y */,
    uint		/* width */,
    uint		/* height */
);

int XDestroyWindow(
    Display*	/* display */,
    Window		/* w */
);

int XDestroyImage(
	XImage*);

int XSelectInput(
    Display*	/* display */,
    Window		/* w */,
    EventMask	/* event_mask */
);

int XMapWindow(
    Display*	/* display */,
    Window		/* w */
);

int XNextEvent(
    Display*	/* display */,
    XEvent*		/* event_return */
);

Status XSetWMProtocols(
    Display*	/* display */,
    Window		/* w */,
    Atom*		/* protocols */,
    int			/* count */
);

enum EventType:int
{
	KeyPress			=2,
	KeyRelease			=3,
	ButtonPress			=4,
	ButtonRelease		=5,
	MotionNotify		=6,
	EnterNotify			=7,
	LeaveNotify			=8,
	FocusIn				=9,
	FocusOut			=10,
	KeymapNotify		=11,
	Expose				=12,
	GraphicsExpose		=13,
	NoExpose			=14,
	VisibilityNotify	=15,
	CreateNotify		=16,
	DestroyNotify		=17,
	UnmapNotify		=18,
	MapNotify			=19,
	MapRequest			=20,
	ReparentNotify		=21,
	ConfigureNotify		=22,
	ConfigureRequest	=23,
	GravityNotify		=24,
	ResizeRequest		=25,
	CirculateNotify		=26,
	CirculateRequest	=27,
	PropertyNotify		=28,
	SelectionClear		=29,
	SelectionRequest	=30,
	SelectionNotify		=31,
	ColormapNotify		=32,
	ClientMessage		=33,
	MappingNotify		=34,
	LASTEvent			=35	/* must be bigger than any event # */
}
/* generated on EnterWindow and FocusIn  when KeyMapState selected */
struct XKeymapEvent
{
	int type;
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window window;
	byte key_vector[32];
}

struct XExposeEvent
{
	int type;
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window window;
	int x, y;
	int width, height;
	int count;		/* if non-zero, at least this many more */
}

struct XGraphicsExposeEvent{
	int type;
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Drawable drawable;
	int x, y;
	int width, height;
	int count;		/* if non-zero, at least this many more */
	int major_code;		/* core is CopyArea or CopyPlane */
	int minor_code;		/* not defined in the core */
}

struct XNoExposeEvent{
	int type;
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Drawable drawable;
	int major_code;		/* core is CopyArea or CopyPlane */
	int minor_code;		/* not defined in the core */
}

struct XVisibilityEvent{
	int type;
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window window;
	VisibilityNotify state;		/* Visibility state */
}

struct XCreateWindowEvent{
	int type;
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window parent;		/* parent of the window */
	Window window;		/* window id of window created */
	int x, y;		/* window location */
	int width, height;	/* size of window */
	int border_width;	/* border width */
	Bool override_redirect;	/* creation should be overridden */
}

struct XDestroyWindowEvent
{
	int type;
	arch_ulong serial;		/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window event;
	Window window;
}

struct XUnmapEvent
{
	int type;
	arch_ulong serial;		/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window event;
	Window window;
	Bool from_configure;
}

struct XMapEvent
{
	int type;
	arch_ulong serial;		/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window event;
	Window window;
	Bool override_redirect;	/* Boolean, is override set... */
}

struct XMapRequestEvent
{
	int type;
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window parent;
	Window window;
}

struct XReparentEvent
{
	int type;
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window event;
	Window window;
	Window parent;
	int x, y;
	Bool override_redirect;
}

struct XConfigureEvent
{
	int type;
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window event;
	Window window;
	int x, y;
	int width, height;
	int border_width;
	Window above;
	Bool override_redirect;
}

struct XGravityEvent
{
	int type;
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window event;
	Window window;
	int x, y;
}

struct XResizeRequestEvent
{
	int type;
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window window;
	int width, height;
}

struct  XConfigureRequestEvent
{
	int type;
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window parent;
	Window window;
	int x, y;
	int width, height;
	int border_width;
	Window above;
	WindowStackingMethod detail;		/* Above, Below, TopIf, BottomIf, Opposite */
	arch_ulong value_mask;
}

struct XCirculateEvent
{
	int type;
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window event;
	Window window;
	CirculationRequest place;		/* PlaceOnTop, PlaceOnBottom */
}

struct XCirculateRequestEvent
{
	int type;
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window parent;
	Window window;
	CirculationRequest place;		/* PlaceOnTop, PlaceOnBottom */
}

struct XPropertyEvent
{
	int type;
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window window;
	Atom atom;
	Time time;
	PropertyNotification state;		/* NewValue, Deleted */
}

struct XSelectionClearEvent
{
	int type;
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window window;
	Atom selection;
	Time time;
}

struct XSelectionRequestEvent
{
	int type;
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window owner;
	Window requestor;
	Atom selection;
	Atom target;
	Atom property;
	Time time;
}

struct XSelectionEvent
{
	int type;
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window requestor;
	Atom selection;
	Atom target;
	Atom property;		/* ATOM or None */
	Time time;
}
version(X86_64) static assert(XSelectionClearEvent.sizeof == 56);

struct XColormapEvent
{
	int type;
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window window;
	Colormap colormap;	/* COLORMAP or None */
	Bool new_;		/* C++ */
	ColorMapNotification state;		/* ColormapInstalled, ColormapUninstalled */
}
version(X86_64) static assert(XColormapEvent.sizeof == 56);

struct XClientMessageEvent
{
	int type;
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window window;
	Atom message_type;
	int format;
	union Data{
		byte b[20];
		short s[10];
		arch_ulong l[5];
	}
	Data data;
	
}
version(X86_64) static assert(XClientMessageEvent.sizeof == 96);

struct XMappingEvent
{
	int type;
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;	/* Display the event was read from */
	Window window;		/* unused */
	MappingType request;		/* one of MappingModifier, MappingKeyboard,
				   MappingPointer */
	int first_keycode;	/* first keycode */
	int count;		/* defines range of change w. first_keycode*/
}

struct XErrorEvent
{
	int type;
	Display *display;	/* Display the event was read from */
	XID resourceid;		/* resource id */
	arch_ulong serial;	/* serial number of failed request */
	ubyte error_code;	/* error code of failed request */
	ubyte request_code;	/* Major op-code of failed request */
	ubyte minor_code;	/* Minor op-code of failed request */
}

struct XAnyEvent
{
	int type;
	arch_ulong serial;	/* # of last request processed by server */
	Bool send_event;	/* true if this came from a SendEvent request */
	Display *display;/* Display the event was read from */
	Window window;	/* window on which event was requested in event mask */
}

union XEvent{
    int type;		/* must not be changed; first element */
	XAnyEvent xany;
	XKeyEvent xkey;
	XButtonEvent xbutton;
	XMotionEvent xmotion;
	XCrossingEvent xcrossing;
	XFocusChangeEvent xfocus;
	XExposeEvent xexpose;
	XGraphicsExposeEvent xgraphicsexpose;
	XNoExposeEvent xnoexpose;
	XVisibilityEvent xvisibility;
	XCreateWindowEvent xcreatewindow;
	XDestroyWindowEvent xdestroywindow;
	XUnmapEvent xunmap;
	XMapEvent xmap;
	XMapRequestEvent xmaprequest;
	XReparentEvent xreparent;
	XConfigureEvent xconfigure;
	XGravityEvent xgravity;
	XResizeRequestEvent xresizerequest;
	XConfigureRequestEvent xconfigurerequest;
	XCirculateEvent xcirculate;
	XCirculateRequestEvent xcirculaterequest;
	XPropertyEvent xproperty;
	XSelectionClearEvent xselectionclear;
	XSelectionRequestEvent xselectionrequest;
	XSelectionEvent xselection;
	XColormapEvent xcolormap;
	XClientMessageEvent xclient;
	XMappingEvent xmapping;
	XErrorEvent xerror;
	XKeymapEvent xkeymap;
	arch_ulong pad[24];
}


	struct Display {
		XExtData *ext_data;	/* hook for extension to hang data */
		_XPrivate *private1;
		int fd;			/* Network socket. */
		int private2;
		int proto_major_version;/* major version of server's X protocol */
		int proto_minor_version;/* minor version of servers X protocol */
		char *vendor;		/* vendor of the server hardware */
	    	XID private3;
		XID private4;
		XID private5;
		int private6;
		XID function(Display*)resource_alloc;/* allocator function */
		ByteOrder byte_order;		/* screen byte order, LSBFirst, MSBFirst */
		int bitmap_unit;	/* padding and data requirements */
		int bitmap_pad;		/* padding requirements on bitmaps */
		ByteOrder bitmap_bit_order;	/* LeastSignificant or MostSignificant */
		int nformats;		/* number of pixmap formats in list */
		ScreenFormat *pixmap_format;	/* pixmap format list */
		int private8;
		int release;		/* release of the server */
		_XPrivate *private9;
		_XPrivate *private10;
		int qlen;		/* Length of input event queue */
		arch_ulong last_request_read; /* seq number of last event read */
		arch_ulong request;	/* sequence number of last request. */
		XPointer private11;
		XPointer private12;
		XPointer private13;
		XPointer private14;
		uint max_request_size; /* maximum number 32 bit words in request*/
		_XrmHashBucketRec *db;
		int function  (Display*)private15;
		char *display_name;	/* "host:display" string used on this connect*/
		int default_screen;	/* default screen for operations */
		int nscreens;		/* number of screens on this server*/
		Screen *screens;	/* pointer to list of screens */
		arch_ulong motion_buffer;	/* size of motion buffer */
		arch_ulong private16;
		int min_keycode;	/* minimum defined keycode */
		int max_keycode;	/* maximum defined keycode */
		XPointer private17;
		XPointer private18;
		int private19;
		byte *xdefaults;	/* contents of defaults from server */
		/* there is more to this structure, but it is private to Xlib */
	}

	// I got these numbers from a C program as a sanity test
	version(X86_64) {
		static assert(Display.sizeof == 296);
		static assert(XPointer.sizeof == 8);
		static assert(XErrorEvent.sizeof == 40);
		static assert(XAnyEvent.sizeof == 40);
		static assert(XMappingEvent.sizeof == 56);
		static assert(XEvent.sizeof == 192);
	} else {
		static assert(Display.sizeof == 176);
		static assert(XPointer.sizeof == 4);
		static assert(XEvent.sizeof == 96);
	}

struct Depth
{
	int depth;		/* this depth (Z) of the depth */
	int nvisuals;		/* number of Visual types at this depth */
	Visual *visuals;	/* list of visuals possible at this depth */
}

alias void* GC;
alias int VisualID;
alias XID Colormap;
alias XID Cursor;
alias XID KeySym;
alias uint KeyCode;
enum None = 0;

version(without_opengl) {}
else {


enum GLX_USE_GL=            1;       /* support GLX rendering */
enum GLX_BUFFER_SIZE=       2;       /* depth of the color buffer */
enum GLX_LEVEL=             3;       /* level in plane stacking */
enum GLX_RGBA=              4;       /* true if RGBA mode */
enum GLX_DOUBLEBUFFER=      5;       /* double buffering supported */
enum GLX_STEREO=            6;       /* stereo buffering supported */
enum GLX_AUX_BUFFERS=       7;       /* number of aux buffers */
enum GLX_RED_SIZE=          8;       /* number of red component bits */
enum GLX_GREEN_SIZE=        9;       /* number of green component bits */
enum GLX_BLUE_SIZE=         10;      /* number of blue component bits */
enum GLX_ALPHA_SIZE=        11;      /* number of alpha component bits */
enum GLX_DEPTH_SIZE=        12;      /* number of depth bits */
enum GLX_STENCIL_SIZE=      13;      /* number of stencil bits */
enum GLX_ACCUM_RED_SIZE=    14;      /* number of red accum bits */
enum GLX_ACCUM_GREEN_SIZE=  15;      /* number of green accum bits */
enum GLX_ACCUM_BLUE_SIZE=   16;      /* number of blue accum bits */
enum GLX_ACCUM_ALPHA_SIZE=  17;      /* number of alpha accum bits */



XVisualInfo* glXChooseVisual(Display *dpy, int screen, in int *attrib_list);


void gluLookAt(double, double, double, double, double, double, double, double, double);


enum GL_TRUE = 1;
enum GL_FALSE = 0;
alias int GLint;

alias XID GLXContextID;
alias XID GLXPixmap;
alias XID GLXDrawable;
alias XID GLXPbuffer;
alias XID GLXWindow;
alias XID GLXFBConfigID;
alias void* GLXContext;

	 XVisualInfo* glXChooseVisual(Display *dpy, int screen,
			int *attrib_list);

	 void glXCopyContext(Display *dpy, GLXContext src,
			GLXContext dst, arch_ulong mask);

	 GLXContext glXCreateContext(Display *dpy, XVisualInfo *vis,
			GLXContext share_list, Bool direct);

	 GLXPixmap glXCreateGLXPixmap(Display *dpy, XVisualInfo *vis,
			Pixmap pixmap);

	 void glXDestroyContext(Display *dpy, GLXContext ctx);

	 void glXDestroyGLXPixmap(Display *dpy, GLXPixmap pix);

	 int glXGetConfig(Display *dpy, XVisualInfo *vis,
			int attrib, int *value);

	 GLXContext glXGetCurrentContext();

	 GLXDrawable glXGetCurrentDrawable();

	 Bool glXIsDirect(Display *dpy, GLXContext ctx);

	 Bool glXMakeCurrent(Display *dpy, GLXDrawable drawable,
			GLXContext ctx);

	 Bool glXQueryExtension(Display *dpy, int *error_base, int *event_base);

	 Bool glXQueryVersion(Display *dpy, int *major, int *minor);

	 void glXSwapBuffers(Display *dpy, GLXDrawable drawable);

	 void glXUseXFont(Font font, int first, int count, int list_base);

	 void glXWaitGL();

	 void glXWaitX();


	enum AllocNone = 0;
	struct XVisualInfo {
		Visual *visual;
		VisualID visualid;
		int screen;
		int depth;
		int c_class;                                  /* C++ */
		arch_ulong red_mask;
		arch_ulong green_mask;
		arch_ulong blue_mask;
		int colormap_size;
		int bits_per_rgb;
	}
}

struct Screen{
	XExtData *ext_data;		/* hook for extension to hang data */
	Display *display;		/* back pointer to display structure */
	Window root;			/* Root window id. */
	int width, height;		/* width and height of screen */
	int mwidth, mheight;	/* width and height of  in millimeters */
	int ndepths;			/* number of depths possible */
	Depth *depths;			/* list of allowable depths on the screen */
	int root_depth;			/* bits per pixel */
	Visual *root_visual;	/* root visual */
	GC default_gc;			/* GC for the root root visual */
	Colormap cmap;			/* default color map */
	uint white_pixel;
	uint black_pixel;		/* White and Black pixel values */
	int max_maps, min_maps;	/* max and min color maps */
	int backing_store;		/* Never, WhenMapped, Always */
	bool save_unders;
	int root_input_mask;	/* initial root input mask */
}

struct Visual
{
	XExtData *ext_data;	/* hook for extension to hang data */
	VisualID visualid;	/* visual id of this visual */
	int class_;			/* class of screen (monochrome, etc.) */
	uint red_mask, green_mask, blue_mask;	/* mask values */
	int bits_per_rgb;	/* log base 2 of distinct color values */
	int map_entries;	/* color map entries */
}

	alias Display* _XPrivDisplay;

	Screen* ScreenOfDisplay(Display* dpy, int scr) {
		assert(dpy !is null);
		return &dpy.screens[scr];
	}

	Window	RootWindow(Display *dpy,int scr) {
		return ScreenOfDisplay(dpy,scr).root;
	}

	int DefaultScreen(Display *dpy) {
		return dpy.default_screen;
	}

	Visual* DefaultVisual(Display *dpy,int scr) {
		return ScreenOfDisplay(dpy,scr).root_visual;
	}

	GC DefaultGC(Display *dpy,int scr) {
		return ScreenOfDisplay(dpy,scr).default_gc;
	}

	uint BlackPixel(Display *dpy,int scr) {
		return ScreenOfDisplay(dpy,scr).black_pixel;
	}

	uint WhitePixel(Display *dpy,int scr) {
		return ScreenOfDisplay(dpy,scr).white_pixel;
	}

	// check out Xft too: http://www.keithp.com/~keithp/render/Xft.tutorial
	int XDrawString(Display*, Drawable, GC, int, int, in char*, int);
	int XDrawLine(Display*, Drawable, GC, int, int, int, int);
	int XDrawRectangle(Display*, Drawable, GC, int, int, uint, uint);
	int XDrawArc(Display*, Drawable, GC, int, int, uint, uint, int, int);
	int XFillRectangle(Display*, Drawable, GC, int, int, uint, uint);
	int XFillArc(Display*, Drawable, GC, int, int, uint, uint, int, int);
	int XDrawPoint(Display*, Drawable, GC, int, int);
	int XSetForeground(Display*, GC, uint);
	int XSetBackground(Display*, GC, uint);

	GC XCreateGC(Display*, Drawable, uint, void*);
	int XCopyGC(Display*, GC, uint, GC);
	int XFreeGC(Display*, GC);

	bool XCheckWindowEvent(Display*, Window, int, XEvent*);
	bool XCheckMaskEvent(Display*, int, XEvent*);

	int XPending(Display*);

	Pixmap XCreatePixmap(Display*, Drawable, uint, uint, uint);
	int XFreePixmap(Display*, Pixmap);
	int XCopyArea(Display*, Drawable, Drawable, GC, int, int, uint, uint, int, int);
	int XFlush(Display*);
	int XSync(Display*, bool);

	struct XPoint {
		short x;
		short y;
	}

	int XDrawLines(Display*, Drawable, GC, XPoint*, int, CoordMode);
	int XFillPolygon(Display*, Drawable, GC, XPoint*, int, PolygonShape, CoordMode);

	enum CoordMode:int {
		CoordModeOrigin = 0,
		CoordModePrevious = 1
	}

	enum PolygonShape:int {
		Complex = 0,
		Nonconvex = 1,
		Convex = 2
	}

	struct XTextProperty {
		const(char)* value;		/* same as Property routines */
		Atom encoding;			/* prop type */
		int format;				/* prop data format: 8, 16, or 32 */
		arch_ulong nitems;		/* number of data items in value */
	}

	version( X86_64 ) {
		static assert(XTextProperty.sizeof == 32);
	}

	void XSetWMName(Display*, Window, XTextProperty*);

	enum Atom XA_STRING = 31;


 } else version (OSXCocoa) {
private:
    alias void* id;
    alias void* Class;
    alias void* SEL;
    alias void* IMP;
    alias void* Ivar;
    alias byte BOOL;
    alias const(void)* CFStringRef;
    alias const(void)* CFAllocatorRef;
    alias const(void)* CFTypeRef;
    alias const(void)* CGContextRef;
    alias const(void)* CGColorSpaceRef;
    alias const(void)* CGImageRef;
    alias uint CGBitmapInfo;
    
    struct objc_super {
        id self;
        Class superclass;
    }
    
    struct CFRange {
        int location, length;
    }

    struct NSPoint {
        float x, y;
        
        static fromTuple(T)(T tupl) {
            return NSPoint(tupl.tupleof);
        }
    }
    struct NSSize {
        float width, height;
    }
    struct NSRect {
        NSPoint origin;
        NSSize size;
    }
    alias NSPoint CGPoint;
    alias NSSize CGSize;
    alias NSRect CGRect;

    struct CGAffineTransform {
        float a, b, c, d, tx, ty;
    }

    enum NSApplicationActivationPolicyRegular = 0;
    enum NSBackingStoreBuffered = 2;
    enum kCFStringEncodingUTF8 = 0x08000100;

    enum : size_t {
        NSBorderlessWindowMask = 0,
        NSTitledWindowMask = 1 << 0,
        NSClosableWindowMask = 1 << 1,
        NSMiniaturizableWindowMask = 1 << 2,
        NSResizableWindowMask = 1 << 3,
        NSTexturedBackgroundWindowMask = 1 << 8
    }
    
    enum : uint {
        kCGImageAlphaNone,
        kCGImageAlphaPremultipliedLast,
        kCGImageAlphaPremultipliedFirst,
        kCGImageAlphaLast,
        kCGImageAlphaFirst,
        kCGImageAlphaNoneSkipLast,
        kCGImageAlphaNoneSkipFirst
    }
    enum : uint {
        kCGBitmapAlphaInfoMask = 0x1F,
        kCGBitmapFloatComponents = (1 << 8),
        kCGBitmapByteOrderMask = 0x7000,
        kCGBitmapByteOrderDefault = (0 << 12),
        kCGBitmapByteOrder16Little = (1 << 12),
        kCGBitmapByteOrder32Little = (2 << 12),
        kCGBitmapByteOrder16Big = (3 << 12),
        kCGBitmapByteOrder32Big = (4 << 12)
    }
    enum CGPathDrawingMode {
        kCGPathFill,
        kCGPathEOFill,
        kCGPathStroke,
        kCGPathFillStroke,
        kCGPathEOFillStroke
    }
    enum objc_AssociationPolicy : size_t {
        OBJC_ASSOCIATION_ASSIGN = 0,
        OBJC_ASSOCIATION_RETAIN_NONATOMIC = 1,
        OBJC_ASSOCIATION_COPY_NONATOMIC = 3,
        OBJC_ASSOCIATION_RETAIN = 0x301, //01401,
        OBJC_ASSOCIATION_COPY = 0x303 //01403
    };

    extern(C) {
        id objc_msgSend(id receiver, SEL selector, ...);
        id objc_msgSendSuper(objc_super* superStruct, SEL selector, ...);
        id objc_getClass(const(char)* name);
        SEL sel_registerName(const(char)* str);
        Class objc_allocateClassPair(Class superclass, const(char)* name,
                                     size_t extra_bytes);
        void objc_registerClassPair(Class cls);
        BOOL class_addMethod(Class cls, SEL name, IMP imp, const(char)* types);
        id objc_getAssociatedObject(id object, void* key);
        void objc_setAssociatedObject(id object, void* key, id value,
                                      objc_AssociationPolicy policy);
        Ivar class_getInstanceVariable(Class cls, const(char)* name);
        id object_getIvar(id object, Ivar ivar);
        void object_setIvar(id object, Ivar ivar, id value);
        BOOL class_addIvar(Class cls, const(char)* name,
                           size_t size, ubyte alignment, const(char)* types);

        extern __gshared id NSApp;
            
        void CFRelease(CFTypeRef obj);
            
        CFStringRef CFStringCreateWithBytes(CFAllocatorRef allocator,
                                            const(char)* bytes, int numBytes,
                                            int encoding,
                                            BOOL isExternalRepresentation);
        int CFStringGetBytes(CFStringRef theString, CFRange range, int encoding,
                             char lossByte, bool isExternalRepresentation,
                             char* buffer, int maxBufLen, int* usedBufLen);
        int CFStringGetLength(CFStringRef theString);
        
        CGContextRef CGBitmapContextCreate(void* data,
                                           size_t width, size_t height,
                                           size_t bitsPerComponent,
                                           size_t bytesPerRow,
                                           CGColorSpaceRef colorspace,
                                           CGBitmapInfo bitmapInfo);
        void CGContextRelease(CGContextRef c);
        ubyte* CGBitmapContextGetData(CGContextRef c);
        CGImageRef CGBitmapContextCreateImage(CGContextRef c);
        size_t CGBitmapContextGetWidth(CGContextRef c);
        size_t CGBitmapContextGetHeight(CGContextRef c);
                
        CGColorSpaceRef CGColorSpaceCreateDeviceRGB();
        void CGColorSpaceRelease(CGColorSpaceRef cs);
        
        void CGContextSetRGBStrokeColor(CGContextRef c,
                                        float red, float green, float blue,
                                        float alpha);
        void CGContextSetRGBFillColor(CGContextRef c,
                                      float red, float green, float blue,
                                      float alpha);
        void CGContextDrawImage(CGContextRef c, CGRect rect, CGImageRef image);
        void CGContextShowTextAtPoint(CGContextRef c, float x, float y,
                                      const(char)* str, size_t length);
        void CGContextStrokeLineSegments(CGContextRef c,
                                         const(CGPoint)* points, size_t count);
        
        void CGContextBeginPath(CGContextRef c);
        void CGContextDrawPath(CGContextRef c, CGPathDrawingMode mode);
        void CGContextAddEllipseInRect(CGContextRef c, CGRect rect);
        void CGContextAddArc(CGContextRef c, float x, float y, float radius,
                             float startAngle, float endAngle, int clockwise);
        void CGContextAddRect(CGContextRef c, CGRect rect);
        void CGContextAddLines(CGContextRef c,
                               const(CGPoint)* points, size_t count);
        void CGContextSaveGState(CGContextRef c);
        void CGContextRestoreGState(CGContextRef c);
        void CGContextSelectFont(CGContextRef c, const(char)* name, float size,
                                 uint textEncoding);
        CGAffineTransform CGContextGetTextMatrix(CGContextRef c);
        void CGContextSetTextMatrix(CGContextRef c, CGAffineTransform t);
        
        void CGImageRelease(CGImageRef image);
    }
    
private:
    // A convenient method to create a CFString (=NSString) from a D string.
    CFStringRef createCFString(string str) {
        return CFStringCreateWithBytes(null, str.ptr, str.length,
                                             kCFStringEncodingUTF8, false);
    }
    
    // Objective-C calls.
    RetType objc_msgSend_specialized(string selector, RetType, T...)(id self, T args) {
        auto _cmd = sel_registerName(selector.ptr);
        alias extern(C) RetType function(id, SEL, T) ExpectedType;
        return (cast(ExpectedType)&objc_msgSend)(self, _cmd, args);
    }
    RetType objc_msgSend_classMethod(string selector, RetType, T...)(const(char)* className, T args) {
        auto _cmd = sel_registerName(selector.ptr);
        auto cls = objc_getClass(className);
        alias extern(C) RetType function(id, SEL, T) ExpectedType;
        return (cast(ExpectedType)&objc_msgSend)(cls, _cmd, args);
    }
    RetType objc_msgSend_classMethod(string className, string selector, RetType, T...)(T args) {
        return objc_msgSend_classMethod!(selector, RetType, T)(className.ptr, args);
    }
    
    alias objc_msgSend_specialized!("setNeedsDisplay:", void, BOOL) setNeedsDisplay;
    alias objc_msgSend_classMethod!("alloc", id) alloc;
    alias objc_msgSend_specialized!("initWithContentRect:styleMask:backing:defer:",
                                    id, NSRect, size_t, size_t, BOOL) initWithContentRect;
    alias objc_msgSend_specialized!("setTitle:", void, CFStringRef) setTitle;
    alias objc_msgSend_specialized!("center", void) center;
    alias objc_msgSend_specialized!("initWithFrame:", id, NSRect) initWithFrame;
    alias objc_msgSend_specialized!("setContentView:", void, id) setContentView;
    alias objc_msgSend_specialized!("release", void) release;
    alias objc_msgSend_classMethod!("NSColor", "whiteColor", id) whiteNSColor;
    alias objc_msgSend_specialized!("setBackgroundColor:", void, id) setBackgroundColor;
    alias objc_msgSend_specialized!("makeKeyAndOrderFront:", void, id) makeKeyAndOrderFront;
    alias objc_msgSend_specialized!("invalidate", void) invalidate;
    alias objc_msgSend_specialized!("close", void) close;
    alias objc_msgSend_classMethod!("NSTimer", "scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:",
                                    id, double, id, SEL, id, BOOL) scheduledTimer;
    alias objc_msgSend_specialized!("run", void) run;
    alias objc_msgSend_classMethod!("NSGraphicsContext", "currentContext",
                                    id) currentNSGraphicsContext;
    alias objc_msgSend_specialized!("graphicsPort", CGContextRef) graphicsPort;
    alias objc_msgSend_specialized!("characters", CFStringRef) characters;
    alias objc_msgSend_specialized!("superclass", Class) superclass;
    alias objc_msgSend_specialized!("init", id) init;
    alias objc_msgSend_specialized!("addItem:", void, id) addItem;
    alias objc_msgSend_specialized!("setMainMenu:", void, id) setMainMenu;
    alias objc_msgSend_specialized!("initWithTitle:action:keyEquivalent:",
                                    id, CFStringRef, SEL, CFStringRef) initWithTitle;
    alias objc_msgSend_specialized!("setSubmenu:", void, id) setSubmenu;
    alias objc_msgSend_specialized!("setDelegate:", void, id) setDelegate;
    alias objc_msgSend_specialized!("activateIgnoringOtherApps:",
                                    void, BOOL) activateIgnoringOtherApps;
    alias objc_msgSend_classMethod!("NSApplication", "sharedApplication",
                                    id) sharedNSApplication;
    alias objc_msgSend_specialized!("setActivationPolicy:", void, ptrdiff_t) setActivationPolicy;
} else version(html5) {} else static assert(0, "Unsupported operating system");


version(OSXCocoa) {
	// I don't know anything about the Mac, but a couple years ago, KennyTM on the newsgroup wrote this for me
	//
	// http://forum.dlang.org/thread/innr0v$1deh$1@digitalmars.com?page=4#post-int88l:24uaf:241:40digitalmars.com
	// https://github.com/kennytm/simpledisplay.d/blob/osx/simpledisplay.d
	//
	// and it is about time I merged it in here. It is available with -version=OSXCocoa until someone tests it for me!
	// Probably won't even fully compile right now

    import std.math : PI;
    import std.algorithm : map;
    import std.array : array;
    
    alias SimpleWindow NativeWindowHandle;
    alias void delegate(id) NativeEventHandler;

    static Ivar simpleWindowIvar;
    
    enum KEY_ESCAPE = 27;

    mixin template NativeImageImplementation() {
        CGContextRef context;
        ubyte* rawData;

	void convertToRgbaBytes(ubyte[] where) {
		assert(where.length == this.width * this.height * 4);

		// if rawData had a length....
		//assert(rawData.length == where.length);
		for(int idx = 0; idx < where.length; idx += 4) {
			auto alpha = rawData[idx + 3];
			if(alpha == 255) {
				where[idx + 0] = rawData[idx + 0]; // r
				where[idx + 1] = rawData[idx + 1]; // g
				where[idx + 2] = rawData[idx + 2]; // b
				where[idx + 3] = rawData[idx + 3]; // a
			} else {
				where[idx + 0] = cast(ubyte)(rawData[idx + 0] * 255 / alpha); // r
				where[idx + 1] = cast(ubyte)(rawData[idx + 1] * 255 / alpha); // g
				where[idx + 2] = cast(ubyte)(rawData[idx + 2] * 255 / alpha); // b
				where[idx + 3] = rawData[idx + 3]; // a

			}
		}
	}

	void setFromRgbaBytes(in ubyte[] where) {
		// FIXME: this is probably wrong
		assert(where.length == this.width * this.height * 4);

		// if rawData had a length....
		//assert(rawData.length == where.length);
		for(int idx = 0; idx < where.length; idx += 4) {
			auto alpha = rawData[idx + 3];
			if(alpha == 255) {
				rawData[idx + 0] = where[idx + 0]; // r
				rawData[idx + 1] = where[idx + 1]; // g
				rawData[idx + 2] = where[idx + 2]; // b
				rawData[idx + 3] = where[idx + 3]; // a
			} else {
				rawData[idx + 0] = cast(ubyte)(where[idx + 0] * 255 / alpha); // r
				rawData[idx + 1] = cast(ubyte)(where[idx + 1] * 255 / alpha); // g
				rawData[idx + 2] = cast(ubyte)(where[idx + 2] * 255 / alpha); // b
				rawData[idx + 3] = where[idx + 3]; // a

			}
		}
	}

        
        void createImage(int width, int height) {
            auto colorSpace = CGColorSpaceCreateDeviceRGB();
            context = CGBitmapContextCreate(null, width, height, 8, 4*width,
                                            colorSpace,
                                            kCGImageAlphaPremultipliedLast
                                                   |kCGBitmapByteOrder32Big);
            CGColorSpaceRelease(colorSpace);
            rawData = CGBitmapContextGetData(context);
        }
        void dispose() {
            CGContextRelease(context);
        }
        
        void setPixel(int x, int y, Color c) {
            auto offset = (y * width + x) * 4;
            if (c.a == 255) {
                rawData[offset + 0] = c.r;
                rawData[offset + 1] = c.g;
                rawData[offset + 2] = c.b;
                rawData[offset + 3] = c.a;
            } else {
                rawData[offset + 0] = cast(ubyte)(c.r*c.a/255);
                rawData[offset + 1] = cast(ubyte)(c.g*c.a/255);
                rawData[offset + 2] = cast(ubyte)(c.b*c.a/255);
                rawData[offset + 3] = c.a;
            }
        }
    }
    
    mixin template NativeScreenPainterImplementation() {
        CGContextRef context;
        ubyte[4] _outlineComponents;
        
        void create(NativeWindowHandle window) {
            context = window.drawingContext;
        }
        
        void dispose() {
        }
        
        @property void outlineColor(Color color) {
            float alphaComponent = color.a/255.0f;
            CGContextSetRGBStrokeColor(context,
                                       color.r/255.0f, color.g/255.0f, color.b/255.0f, alphaComponent);

            if (color.a != 255) {
                _outlineComponents[0] = cast(ubyte)(color.r*color.a/255);
                _outlineComponents[1] = cast(ubyte)(color.g*color.a/255);
                _outlineComponents[2] = cast(ubyte)(color.b*color.a/255);
                _outlineComponents[3] = color.a;
            } else {
                _outlineComponents[0] = color.r;
                _outlineComponents[1] = color.g;
                _outlineComponents[2] = color.b;
                _outlineComponents[3] = color.a;
            }
        }
        
        @property void fillColor(Color color) {
            CGContextSetRGBFillColor(context,
                                     color.r/255.0f, color.g/255.0f, color.b/255.0f, color.a/255.0f);
        }
        
        void drawImage(int x, int y, Image image) {
            auto cgImage = CGBitmapContextCreateImage(image.context);
            auto size = CGSize(CGBitmapContextGetWidth(image.context),
                               CGBitmapContextGetHeight(image.context));
            CGContextDrawImage(context, CGRect(CGPoint(x, y), size), cgImage);
            CGImageRelease(cgImage);
        }
 
        void drawPixmap(Sprite image, int x, int y) {
		// FIXME: is this efficient?
            auto cgImage = CGBitmapContextCreateImage(image.context);
            auto size = CGSize(CGBitmapContextGetWidth(image.context),
                               CGBitmapContextGetHeight(image.context));
            CGContextDrawImage(context, CGRect(CGPoint(x, y), size), cgImage);
            CGImageRelease(cgImage);
        }

        
        void drawText(int x, int y, int x2, int y2, string text, uint alignment) {
		// FIXME: alignment
            if (_outlineComponents[3] != 0) {
                CGContextSaveGState(context);
                auto invAlpha = 1.0f/_outlineComponents[3];
                CGContextSetRGBFillColor(context, _outlineComponents[0]*invAlpha,
                                                  _outlineComponents[1]*invAlpha,
                                                  _outlineComponents[2]*invAlpha,
                                                  _outlineComponents[3]/255.0f);
                CGContextShowTextAtPoint(context, x, y, text.ptr, text.length);
// auto cfstr = cast(id)createCFString(text);
// objc_msgSend(cfstr, sel_registerName("drawAtPoint:withAttributes:"),
// NSPoint(x, y), null);
// CFRelease(cfstr);
                CGContextRestoreGState(context);
            }
        }

        void drawPixel(int x, int y) {
            auto rawData = CGBitmapContextGetData(context);
            auto width = CGBitmapContextGetWidth(context);
            auto height = CGBitmapContextGetHeight(context);
            auto offset = ((height - y - 1) * width + x) * 4;
            rawData[offset .. offset+4] = _outlineComponents;
        }
        
        void drawLine(int x1, int y1, int x2, int y2) {
            CGPoint[2] linePoints;
            linePoints[0] = CGPoint(x1, y1);
            linePoints[1] = CGPoint(x2, y2);
            CGContextStrokeLineSegments(context, linePoints.ptr, linePoints.length);
        }

        void drawRectangle(int x, int y, int width, int height) {
            CGContextBeginPath(context);
            auto rect = CGRect(CGPoint(x, y), CGSize(width, height));
            CGContextAddRect(context, rect);
            CGContextDrawPath(context, CGPathDrawingMode.kCGPathFillStroke);
        }
        
        void drawEllipse(int x1, int y1, int x2, int y2) {
            CGContextBeginPath(context);
            auto rect = CGRect(CGPoint(x1, y1), CGSize(x2-x1, y2-y1));
            CGContextAddEllipseInRect(context, rect);
            CGContextDrawPath(context, CGPathDrawingMode.kCGPathFillStroke);
        }
        
        void drawArc(int x1, int y1, int width, int height, int start, int finish) {
            // @@@BUG@@@ Does not support elliptic arc (width != height).
            CGContextBeginPath(context);
            CGContextAddArc(context, x1+width*0.5f, y1+height*0.5f, width,
                            start*PI/(180*64), finish*PI/(180*64), 0);
            CGContextDrawPath(context, CGPathDrawingMode.kCGPathFillStroke);
        }
        
        void drawPolygon(Point[] intPoints) {
            CGContextBeginPath(context);
            auto points = array(map!(CGPoint.fromTuple)(intPoints));
            CGContextAddLines(context, points.ptr, points.length);
            CGContextDrawPath(context, CGPathDrawingMode.kCGPathFillStroke);
        }
    }
    
    mixin template NativeSimpleWindowImplementation() {
        void createWindow(int width, int height, string title) {
            synchronized {
                if (NSApp == null) initializeApp();
            }
            
            auto contentRect = NSRect(NSPoint(0, 0), NSSize(width, height));
            
            // create the window.
            window = initWithContentRect(alloc("NSWindow"),
                                         contentRect,
                                         NSTitledWindowMask
                                            |NSClosableWindowMask
                                            |NSMiniaturizableWindowMask
                                            |NSResizableWindowMask,
                                         NSBackingStoreBuffered,
                                         true);

            // set the title & move the window to center.
            auto windowTitle = createCFString(title);
            setTitle(window, windowTitle);
            CFRelease(windowTitle);
            center(window);
            
            // create area to draw on.
            auto colorSpace = CGColorSpaceCreateDeviceRGB();
            drawingContext = CGBitmapContextCreate(null, width, height,
                                                   8, 4*width, colorSpace,
                                                   kCGImageAlphaPremultipliedLast
                                                      |kCGBitmapByteOrder32Big);
            CGColorSpaceRelease(colorSpace);
            CGContextSelectFont(drawingContext, "Lucida Grande", 12.0f, 1);
            auto matrix = CGContextGetTextMatrix(drawingContext);
            matrix.c = -matrix.c;
            matrix.d = -matrix.d;
            CGContextSetTextMatrix(drawingContext, matrix);
            
            // create the subview that things will be drawn on.
            view = initWithFrame(alloc("SDGraphicsView"), contentRect);
            setContentView(window, view);
            object_setIvar(view, simpleWindowIvar, cast(id)this);
            release(view);

            setBackgroundColor(window, whiteNSColor);
            makeKeyAndOrderFront(window, null);
        }
        void dispose() {
            closeWindow();
            release(window);
        }
        void closeWindow() {
            invalidate(timer);
            .close(window);
        }
        
        ScreenPainter getPainter() {
		return ScreenPainter(this, this);
	}
        
        int eventLoop(long pulseTimeout) {
            if (handlePulse !is null && pulseTimeout != 0) {
                timer = scheduledTimer(pulseTimeout*1e-3,
                                       view, sel_registerName("simpledisplay_pulse"),
                                       null, true);
            }
            
            setNeedsDisplay(view, true);
            run(NSApp);
            return 0;
        }
        
        id window;
        id timer;
        id view;
        CGContextRef drawingContext;
    }
    
    extern(C) {
    private:
        BOOL returnTrue3(id self, SEL _cmd, id app) {
            return true;
        }
        BOOL returnTrue2(id self, SEL _cmd) {
            return true;
        }
        
        void pulse(id self, SEL _cmd) {
            auto simpleWindow = cast(SimpleWindow)object_getIvar(self, simpleWindowIvar);
            simpleWindow.handlePulse();
            setNeedsDisplay(self, true);
        }
        void drawRect(id self, SEL _cmd, NSRect rect) {
            auto simpleWindow = cast(SimpleWindow)object_getIvar(self, simpleWindowIvar);
            auto curCtx = graphicsPort(currentNSGraphicsContext);
            auto cgImage = CGBitmapContextCreateImage(simpleWindow.drawingContext);
            auto size = CGSize(CGBitmapContextGetWidth(simpleWindow.drawingContext),
                               CGBitmapContextGetHeight(simpleWindow.drawingContext));
            CGContextDrawImage(curCtx, CGRect(CGPoint(0, 0), size), cgImage);
            CGImageRelease(cgImage);
        }
        void keyDown(id self, SEL _cmd, id event) {
            auto simpleWindow = cast(SimpleWindow)object_getIvar(self, simpleWindowIvar);

            // the event may have multiple characters, and we send them all at
            // once.
            if (simpleWindow.handleCharEvent || simpleWindow.handleKeyEvent) {
                auto chars = characters(event);
                auto range = CFRange(0, CFStringGetLength(chars));
                auto buffer = new char[range.length*3];
                int actualLength;
                CFStringGetBytes(chars, range, kCFStringEncodingUTF8, 0, false,
                                 buffer.ptr, buffer.length, &actualLength);
                foreach (dchar dc; buffer[0..actualLength]) {
                    if (simpleWindow.handleCharEvent)
                        simpleWindow.handleCharEvent(dc);
                    if (simpleWindow.handleKeyEvent)
                        simpleWindow.handleKeyEvent(dc, true); // FIXME: what about keyUp?
                }
            }
            
            // the event's 'keyCode' is hardware-dependent. I don't think people
            // will like it. Let's leave it to the native handler.
            
            // perform the default action.
            auto superData = objc_super(self, superclass(self));
            alias extern(C) void function(objc_super*, SEL, id) T;
            (cast(T)&objc_msgSendSuper)(&superData, _cmd, event);
        }
    }
    
    // initialize the app so that it can be interacted with the user.
    // based on http://cocoawithlove.com/2010/09/minimalist-cocoa-programming.html
    private void initializeApp() {
        // push an autorelease pool to avoid leaking.
        init(alloc("NSAutoreleasePool"));
        
        // create a new NSApp instance
        sharedNSApplication;
        setActivationPolicy(NSApp, NSApplicationActivationPolicyRegular);
        
        // create the "Quit" menu.
        auto menuBar = init(alloc("NSMenu"));
        auto appMenuItem = init(alloc("NSMenuItem"));
        addItem(menuBar, appMenuItem);
        setMainMenu(NSApp, menuBar);
        release(appMenuItem);
        release(menuBar);
        
        auto appMenu = init(alloc("NSMenu"));
        auto quitTitle = createCFString("Quit");
        auto q = createCFString("q");
        auto quitItem = initWithTitle(alloc("NSMenuItem"),
                                      quitTitle, sel_registerName("terminate:"), q);
        addItem(appMenu, quitItem);
        setSubmenu(appMenuItem, appMenu);
        release(quitItem);
        release(appMenu);
        CFRelease(q);
        CFRelease(quitTitle);

        // assign a delegate for the application, allow it to quit when the last
        // window is closed.
        auto delegateClass = objc_allocateClassPair(objc_getClass("NSObject"),
                                                    "SDWindowCloseDelegate", 0);
        class_addMethod(delegateClass,
                        sel_registerName("applicationShouldTerminateAfterLastWindowClosed:"),
                        &returnTrue3, "c@:@");
        objc_registerClassPair(delegateClass);
    
        auto appDelegate = init(alloc("SDWindowCloseDelegate"));
        setDelegate(NSApp, appDelegate);
        activateIgnoringOtherApps(NSApp, true);

        // create a new view that draws the graphics and respond to keyDown
        // events.
        auto viewClass = objc_allocateClassPair(objc_getClass("NSView"),
                                                "SDGraphicsView", (void*).sizeof);
        class_addIvar(viewClass, "simpledisplay_simpleWindow",
                      (void*).sizeof, (void*).alignof, "^v");
        class_addMethod(viewClass, sel_registerName("simpledisplay_pulse"),
                        &pulse, "v@:");
        class_addMethod(viewClass, sel_registerName("drawRect:"),
                        &drawRect, "v@:{NSRect={NSPoint=ff}{NSSize=ff}}");
        class_addMethod(viewClass, sel_registerName("isFlipped"),
                        &returnTrue2, "c@:");
        class_addMethod(viewClass, sel_registerName("acceptsFirstResponder"),
                        &returnTrue2, "c@:");
        class_addMethod(viewClass, sel_registerName("keyDown:"),
                        &keyDown, "v@:@");
        objc_registerClassPair(viewClass);
        simpleWindowIvar = class_getInstanceVariable(viewClass,
                                                     "simpledisplay_simpleWindow");
    }
}

version(html5) {
	import arsd.cgi;

	alias int NativeWindowHandle;
	alias void delegate() NativeEventHandler;

	mixin template NativeImageImplementation() {
		static import arsd.image;
		arsd.image.TrueColorImage handle;

		void createImage(int width, int height) {
			handle = new arsd.image.TrueColorImage(width, height);
		}

		void dispose() {
			handle = null;
		}

		void setPixel(int x, int y, Color c) {
			auto offset = (y * width + x) * 4;
			handle.data[offset + 0] = c.b;
			handle.data[offset + 1] = c.g;
			handle.data[offset + 2] = c.r;
			handle.data[offset + 3] = c.a;
		}

		void convertToRgbaBytes(ubyte[] where) {
			if(where is handle.data)
				return;
			assert(where.length == this.width * this.height * 4);

			where[] = handle.data[];
		}

		void setFromRgbaBytes(in ubyte[] where) {
			if(where is handle.data)
				return;
			assert(where.length == this.width * this.height * 4);

			handle.data[] = where[];
		}

	}

	mixin template NativeScreenPainterImplementation() {
		void create(NativeWindowHandle window) {
		}

		void dispose() {
		}
		@property void outlineColor(Color c) {
		}

		@property void fillColor(Color c) {
		}

		void drawImage(int x, int y, Image i) {
		}

		void drawPixmap(Sprite s, int x, int y) {
		}

		void drawText(int x, int y, int x2, int y2, string text, uint alignment) {
		}

		void drawPixel(int x, int y) {
		}

		void drawLine(int x1, int y1, int x2, int y2) {
		}

		void drawRectangle(int x, int y, int width, int height) {
		}

		/// Arguments are the points of the bounding rectangle
		void drawEllipse(int x1, int y1, int x2, int y2) {
		}

		void drawArc(int x1, int y1, int width, int height, int start, int finish) {
			// FIXME: start X, start Y, end X, end Y
			//Arc(hdc, x1, y1, x1 + width, y1 + height, 0, 0, 0, 0);
		}

		void drawPolygon(Point[] vertexes) {
		}

	}

	/// on html5 mode you MUST set this socket up
	WebSocket socket;

	mixin template NativeSimpleWindowImplementation() {
		ScreenPainter getPainter() {
			return ScreenPainter(this, 0);
		}

		void createWindow(int width, int height, string title) {
			Html5.createCanvas(width, height);
		}

		void closeWindow() { /* no need, can just leave it on the page */ }

		void dispose() { }

		bool destroyed = false;

		int eventLoop(long pulseTimeout) {
			bool done = false;
			import core.thread;

			while (!done) {
			while(!done &&
				(pulseTimeout == 0 || socket.recvAvailable()))
			{
				//done = doXNextEvent(this); // FIXME: what about multiple windows? This wasn't originally going to support them but maybe I should
			}
				if(!done && pulseTimeout !=0) {
					if(handlePulse !is null)
						handlePulse();
					Thread.sleep(dur!"msecs"(pulseTimeout));
				}
			}

			return 0;
		}
	}

	struct JsImpl { string code; }

	struct Html5 {
		@JsImpl(q{

		})
		static void createImage(int handle, Image i) {

		}

		static void freeImage(int handle) {

		}

		static void createCanvas(int width, int height) {

		}
	}
}


version(without_opengl) {} else
extern(System){
	void glGetIntegerv(int, void*);
	void glMatrixMode(int);
	void glPushMatrix();
	void glLoadIdentity();
	void glOrtho(double, double, double, double, double, double);
	void glPopMatrix();
	void glEnable(int);
	void glDisable(int);
	void glClear(int);
	void glBegin(int);
	void glVertex2f(float, float);
	void glVertex3f(float, float, float);
	void glEnd();
	void glColor3b(ubyte, ubyte, ubyte);
	void glColor3i(int, int, int);
	void glColor3f(float, float, float);
	void glColor4f(float, float, float, float);
	void glTranslatef(float, float, float);

	void glRotatef(float, float, float, float);

	uint glGetError();

	void glDeleteTextures(int, uint*);

	char* gluErrorString(uint);

	void glRasterPos2i(int, int);
	void glDrawPixels(int, int, uint, uint, void*);
	void glClearColor(float, float, float, float);



	void glGenTextures(uint, uint*);
	void glBindTexture(int, int);
	void glTexParameteri(uint, uint, int);
	void glTexImage2D(int, int, int, int, int, int, int, int, void*);


	void glTexCoord2f(float, float);
	void glVertex2i(int, int);
	void glBlendFunc (int, int);
	void glViewport(int, int, int, int);

	void glReadBuffer(uint);
	void glReadPixels(int, int, int, int, int, int, void*);


	enum uint GL_FRONT = 0x0404;

	enum uint GL_BLEND = 0x0be2;
	enum uint GL_SRC_ALPHA = 0x0302;
	enum uint GL_ONE_MINUS_SRC_ALPHA = 0x0303;


	enum uint GL_UNSIGNED_BYTE = 0x1401;
	enum uint GL_RGB = 0x1907;
	enum uint GL_BGRA = 0x80e1;
	enum uint GL_RGBA = 0x1908;
	enum uint GL_TEXTURE_2D =   0x0DE1;
	enum uint GL_TEXTURE_MIN_FILTER = 0x2801;
	enum uint GL_NEAREST = 0x2600;
	enum uint GL_LINEAR = 0x2601;
	enum uint GL_TEXTURE_MAG_FILTER = 0x2800;

	enum uint GL_NO_ERROR = 0;



	enum int GL_VIEWPORT = 0x0BA2;
	enum int GL_MODELVIEW = 0x1700;
	enum int GL_TEXTURE = 0x1702;
	enum int GL_PROJECTION = 0x1701;
	enum int GL_DEPTH_TEST = 0x0B71;

	enum int GL_COLOR_BUFFER_BIT = 0x00004000;
	enum int GL_ACCUM_BUFFER_BIT = 0x00000200;
	enum int GL_DEPTH_BUFFER_BIT = 0x00000100;

	enum int GL_POINTS = 0x0000;
	enum int GL_LINES =  0x0001;
	enum int GL_LINE_LOOP = 0x0002;
	enum int GL_LINE_STRIP = 0x0003;
	enum int GL_TRIANGLES = 0x0004;
	enum int GL_TRIANGLE_STRIP = 5;
	enum int GL_TRIANGLE_FAN = 6;
	enum int GL_QUADS = 7;
	enum int GL_QUAD_STRIP = 8;
	enum int GL_POLYGON = 9;

}


