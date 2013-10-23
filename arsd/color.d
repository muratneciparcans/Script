module arsd.color;

// importing phobos explodes the size of this code 10x, so not doing it.

private {
	real toInternal(T)(string s) {
		real accumulator = 0.0;
		size_t i = s.length;
		foreach(idx, c; s) {
			if(c >= '0' && c <= '9') {
				accumulator *= 10;
				accumulator += c - '0';
			} else if(c == '.') {
				i = idx + 1;
				break;
			} else
				throw new Exception("bad char to make real from " ~ s);
		}

		real accumulator2 = 0.0;
		real count = 1;
		foreach(c; s[i .. $]) {
			if(c >= '0' && c <= '9') {
				accumulator2 *= 10;
				accumulator2 += c - '0';
				count *= 10;
			} else
				throw new Exception("bad char to make real from " ~ s);
		}

		return accumulator + accumulator2 / count;
	}

	string toInternal(T)(int a) {
		if(a == 0)
			return "0";
		char[] ret;
		while(a) {
			ret ~= (a % 10) + '0';
			a /= 10;
		}
		for(int i = 0; i < ret.length / 2; i++) {
			char c = ret[i];
			ret[i] = ret[$ - i - 1];
			ret[$ - i - 1] = c;
		}
		return cast(string) ret;
	}
	string toInternal(T)(real a) {
		// a simplifying assumption here is the fact that we only use this in one place: toInternal!string(cast(real) a / 255)
		// thus we know this will always be between 0.0 and 1.0, inclusive.
		if(a <= 0.0)
			return "0.0";
		if(a >= 1.0)
			return "1.0";
		string ret = "0.";
		// I wonder if I can handle round off error any better. Phobos does, but that isn't worth 100 KB of code.
		int amt = cast(int)(a * 1000);
		return ret ~ toInternal!string(amt);
	}

	real absInternal(real a) { return a < 0 ? -a : a; }
	real minInternal(real a, real b, real c) {
		auto m = a;
		if(b < m) m = b;
		if(c < m) m = c;
		return m;
	}
	real maxInternal(real a, real b, real c) {
		auto m = a;
		if(b > m) m = b;
		if(c > m) m = c;
		return m;
	}
	bool startsWithInternal(string a, string b) {
		return (a.length >= b.length && a[0 .. b.length] == b);
	}
	string[] splitInternal(string a, char c) {
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
	string stripInternal(string s) {
		foreach(i, char c; s)
			if(c != ' ' && c != '\t' && c != '\n') {
				s = s[i .. $];
				break;
			}
		for(int a = cast(int)(s.length - 1); a > 0; a--) {
			char c = s[a];
			if(c != ' ' && c != '\t' && c != '\n') {
				s = s[0 .. a + 1];
				break;
			}
		}

		return s;
	}
}

// done with mini-phobos

struct Color {
	ubyte r;
	ubyte g;
	ubyte b;
	ubyte a;

	this(int red, int green, int blue, int alpha = 255) {
		this.r = cast(ubyte) red;
		this.g = cast(ubyte) green;
		this.b = cast(ubyte) blue;
		this.a = cast(ubyte) alpha;
	}

	static Color transparent() { return Color(0, 0, 0, 0); }
	static Color white() { return Color(255, 255, 255); }
	static Color black() { return Color(0, 0, 0); }
	static Color red() { return Color(255, 0, 0); }
	static Color green() { return Color(0, 255, 0); }
	static Color blue() { return Color(0, 0, 255); }
	static Color yellow() { return Color(255, 255, 0); }
	static Color teal() { return Color(0, 255, 255); }
	static Color purple() { return Color(255, 0, 255); }

	/*
	ubyte[4] toRgbaArray() {
		return [r,g,b,a];
	}
	*/

	string toCssString() {
		if(a == 255)
			return "#" ~ toHexInternal(r) ~ toHexInternal(g) ~ toHexInternal(b);
		else {
			return "rgba("~toInternal!string(r)~", "~toInternal!string(g)~", "~toInternal!string(b)~", "~toInternal!string(cast(real)a / 255.0)~")";
		}
	}

	string toString() {
		if(a == 255)
			return toCssString()[1 .. $];
		else
			return toHexInternal(r) ~ toHexInternal(g) ~ toHexInternal(b) ~ toHexInternal(a);
	}

	static Color fromNameString(string s) {
		Color c;
		foreach(member; __traits(allMembers, Color)) {
			static if(__traits(compiles, c = __traits(getMember, Color, member))) {
				if(s == member)
					return __traits(getMember, Color, member);
			}
		}
		throw new Exception("Unknown color " ~ s);
	}

	static Color fromString(string s) {
		s = s.stripInternal();

		Color c;
		c.a = 255;

		// trying named colors via the static no-arg methods here
		foreach(member; __traits(allMembers, Color)) {
			static if(__traits(compiles, c = __traits(getMember, Color, member))) {
				if(s == member)
					return __traits(getMember, Color, member);
			}
		}

		// try various notations borrowed from CSS (though a little extended)

		// hsl(h,s,l,a) where h is degrees and s,l,a are 0 >= x <= 1.0
		if(s.startsWithInternal("hsl(") || s.startsWithInternal("hsla(")) {
			assert(s[$-1] == ')');
			s = s[s.startsWithInternal("hsl(") ? 4 : 5  .. $ - 1]; // the closing paren

			real[3] hsl;
			ubyte a = 255;

			auto parts = s.splitInternal(',');
			foreach(i, part; parts) {
				if(i < 3)
					hsl[i] = toInternal!real(part.stripInternal);
				else
					a = cast(ubyte) (toInternal!real(part.stripInternal) * 255);
			}

			c = .fromHsl(hsl);
			c.a = a;

			return c;
		}

		// rgb(r,g,b,a) where r,g,b are 0-255 and a is 0-1.0
		if(s.startsWithInternal("rgb(") || s.startsWithInternal("rgba(")) {
			assert(s[$-1] == ')');
			s = s[s.startsWithInternal("rgb(") ? 4 : 5  .. $ - 1]; // the closing paren

			auto parts = s.splitInternal(',');
			foreach(i, part; parts) {
				// lol the loop-switch pattern
				auto v = toInternal!real(part.stripInternal);
				switch(i) {
					case 0: // red
						c.r = cast(ubyte) v;
					break;
					case 1:
						c.g = cast(ubyte) v;
					break;
					case 2:
						c.b = cast(ubyte) v;
					break;
					case 3:
						c.a = cast(ubyte) (v * 255);
					break;
					default: // ignore
				}
			}

			return c;
		}




		// otherwise let's try it as a hex string, really loosely

		if(s.length && s[0] == '#')
			s = s[1 .. $];

		// not a built in... do it as a hex string
		if(s.length >= 2) {
			c.r = fromHexInternal(s[0 .. 2]);
			s = s[2 .. $];
		}
		if(s.length >= 2) {
			c.g = fromHexInternal(s[0 .. 2]);
			s = s[2 .. $];
		}
		if(s.length >= 2) {
			c.b = fromHexInternal(s[0 .. 2]);
			s = s[2 .. $];
		}
		if(s.length >= 2) {
			c.a = fromHexInternal(s[0 .. 2]);
			s = s[2 .. $];
		}

		return c;
	}

	static Color fromHsl(real h, real s, real l) {
		return .fromHsl(h, s, l);
	}
}

private string toHexInternal(ubyte b) {
	string s;
	if(b < 16)
		s ~= '0';
	else {
		ubyte t = (b & 0xf0) >> 4;
		if(t >= 10)
			s ~= 'A' + t - 10;
		else
			s ~= '0' + t;
		b &= 0x0f;
	}
	if(b >= 10)
		s ~= 'A' + b - 10;
	else
		s ~= '0' + b;

	return s;
}

private ubyte fromHexInternal(string s) {
	int result = 0;

	int exp = 1;
	//foreach(c; retro(s)) { // FIXME: retro doesn't work right in dtojs
	foreach_reverse(c; s) {
		if(c >= 'A' && c <= 'F')
			result += exp * (c - 'A' + 10);
		else if(c >= 'a' && c <= 'f')
			result += exp * (c - 'a' + 10);
		else if(c >= '0' && c <= '9')
			result += exp * (c - '0');
		else
			// throw new Exception("invalid hex character: " ~ cast(char) c);
			return 0;

		exp *= 16;
	}

	return cast(ubyte) result;
}


Color fromHsl(real[3] hsl) {
	return fromHsl(hsl[0], hsl[1], hsl[2]);
}

Color fromHsl(real h, real s, real l, real a = 255) {
	h = h % 360;

	real C = (1 - absInternal(2 * l - 1)) * s;

	real hPrime = h / 60;

	real X = C * (1 - absInternal(hPrime % 2 - 1));

	real r, g, b;

	if(h is real.nan)
		r = g = b = 0;
	else if (hPrime >= 0 && hPrime < 1) {
		r = C;
		g = X;
		b = 0;
	} else if (hPrime >= 1 && hPrime < 2) {
		r = X;
		g = C;
		b = 0;
	} else if (hPrime >= 2 && hPrime < 3) {
		r = 0;
		g = C;
		b = X;
	} else if (hPrime >= 3 && hPrime < 4) {
		r = 0;
		g = X;
		b = C;
	} else if (hPrime >= 4 && hPrime < 5) {
		r = X;
		g = 0;
		b = C;
	} else if (hPrime >= 5 && hPrime < 6) {
		r = C;
		g = 0;
		b = X;
	}

	real m = l - C / 2;

	r += m;
	g += m;
	b += m;

	return Color(
		cast(ubyte)(r * 255),
		cast(ubyte)(g * 255),
		cast(ubyte)(b * 255),
		cast(ubyte)(a));
}

real[3] toHsl(Color c, bool useWeightedLightness = false) {
	real r1 = cast(real) c.r / 255;
	real g1 = cast(real) c.g / 255;
	real b1 = cast(real) c.b / 255;

	real maxColor = maxInternal(r1, g1, b1);
	real minColor = minInternal(r1, g1, b1);

	real L = (maxColor + minColor) / 2 ;
	if(useWeightedLightness) {
		// the colors don't affect the eye equally
		// this is a little more accurate than plain HSL numbers
		L = 0.2126*r1 + 0.7152*g1 + 0.0722*b1;
	}
	real S = 0;
	real H = 0;
	if(maxColor != minColor) {
		if(L < 0.5) {
			S = (maxColor - minColor) / (maxColor + minColor);
		} else {
			S = (maxColor - minColor) / (2.0 - maxColor - minColor);
		}
		if(r1 == maxColor) {
			H = (g1-b1) / (maxColor - minColor);
		} else if(g1 == maxColor) {
			H = 2.0 + (b1 - r1) / (maxColor - minColor);
		} else {
			H = 4.0 + (r1 - g1) / (maxColor - minColor);
		}
	}

	H = H * 60;
	if(H < 0){
		H += 360;
	}

	return [H, S, L]; 
}


Color lighten(Color c, real percentage) {
	auto hsl = toHsl(c);
	hsl[2] *= (1 + percentage);
	if(hsl[2] > 1)
		hsl[2] = 1;
	return fromHsl(hsl);
}

Color darken(Color c, real percentage) {
	auto hsl = toHsl(c);
	hsl[2] *= (1 - percentage);
	return fromHsl(hsl);
}

/// for light colors, call darken. for dark colors, call lighten.
/// The goal: get toward center grey.
Color moderate(Color c, real percentage) {
	auto hsl = toHsl(c);
	if(hsl[2] > 0.5)
		hsl[2] *= (1 - percentage);
	else {
		if(hsl[2] <= 0.01) // if we are given black, moderating it means getting *something* out
			hsl[2] = percentage;
		else
			hsl[2] *= (1 + percentage);
	}
	if(hsl[2] > 1)
		hsl[2] = 1;
	return fromHsl(hsl);
}

/// the opposite of moderate. Make darks darker and lights lighter
Color extremify(Color c, real percentage) {
	auto hsl = toHsl(c, true);
	if(hsl[2] < 0.5)
		hsl[2] *= (1 - percentage);
	else
		hsl[2] *= (1 + percentage);
	if(hsl[2] > 1)
		hsl[2] = 1;
	return fromHsl(hsl);
}

/// Move around the lightness wheel, trying not to break on moderate things
Color oppositeLightness(Color c) {
	auto hsl = toHsl(c);

	auto original = hsl[2];

	if(original > 0.4 && original < 0.6)
		hsl[2] = 0.8 - original; // so it isn't quite the same
	else
		hsl[2] = 1 - original;

	return fromHsl(hsl);
}

/// Try to determine a text color - either white or black - based on the input
Color makeTextColor(Color c) {
	auto hsl = toHsl(c, true); // give green a bonus for contrast
	if(hsl[2] > 0.71)
		return Color(0, 0, 0);
	else
		return Color(255, 255, 255);
}

Color setLightness(Color c, real lightness) {
	auto hsl = toHsl(c);
	hsl[2] = lightness;
	return fromHsl(hsl);
}



Color rotateHue(Color c, real degrees) {
	auto hsl = toHsl(c);
	hsl[0] += degrees;
	return fromHsl(hsl);
}

Color setHue(Color c, real hue) {
	auto hsl = toHsl(c);
	hsl[0] = hue;
	return fromHsl(hsl);
}

Color desaturate(Color c, real percentage) {
	auto hsl = toHsl(c);
	hsl[1] *= (1 - percentage);
	return fromHsl(hsl);
}

Color saturate(Color c, real percentage) {
	auto hsl = toHsl(c);
	hsl[1] *= (1 + percentage);
	if(hsl[1] > 1)
		hsl[1] = 1;
	return fromHsl(hsl);
}

Color setSaturation(Color c, real saturation) {
	auto hsl = toHsl(c);
	hsl[1] = saturation;
	return fromHsl(hsl);
}


/*
void main(string[] args) {
	auto color1 = toHsl(Color(255, 0, 0));
	auto color = fromHsl(color1[0] + 60, color1[1], color1[2]);

	writefln("#%02x%02x%02x", color.r, color.g, color.b);
}
*/

/* Color algebra functions */

/* Alpha putpixel looks like this:

void putPixel(Image i, Color c) {
	Color b;
	b.r = i.data[(y * i.width + x) * bpp + 0];
	b.g = i.data[(y * i.width + x) * bpp + 1];
	b.b = i.data[(y * i.width + x) * bpp + 2];
	b.a = i.data[(y * i.width + x) * bpp + 3];

	float ca = cast(float) c.a / 255;

	i.data[(y * i.width + x) * bpp + 0] = alpha(c.r, ca, b.r);
	i.data[(y * i.width + x) * bpp + 1] = alpha(c.g, ca, b.g);
	i.data[(y * i.width + x) * bpp + 2] = alpha(c.b, ca, b.b);
	i.data[(y * i.width + x) * bpp + 3] = alpha(c.a, ca, b.a);
}

ubyte alpha(ubyte c1, float alpha, ubyte onto) {
	auto got = (1 - alpha) * onto + alpha * c1;

	if(got > 255)
		return 255;
	return cast(ubyte) got;
}

So, given the background color and the resultant color, what was
composited on to it?
*/

ubyte unalpha(ubyte colorYouHave, float alpha, ubyte backgroundColor) {
	// resultingColor = (1-alpha) * backgroundColor + alpha * answer
	auto resultingColorf = cast(float) colorYouHave;
	auto backgroundColorf = cast(float) backgroundColor;

	auto answer = (resultingColorf - backgroundColorf + alpha * backgroundColorf) / alpha;
	if(answer > 255)
		return 255;
	if(answer < 0)
		return 0;
	return cast(ubyte) answer;
}

ubyte makeAlpha(ubyte colorYouHave, ubyte backgroundColor/*, ubyte foreground = 0x00*/) {
	//auto foregroundf = cast(float) foreground;
	auto foregroundf = 0.00f;
	auto colorYouHavef = cast(float) colorYouHave;
	auto backgroundColorf = cast(float) backgroundColor;

	// colorYouHave = backgroundColorf - alpha * backgroundColorf + alpha * foregroundf
	auto alphaf = 1 - colorYouHave / backgroundColorf;
	alphaf *= 255;

	if(alphaf < 0)
		return 0;
	if(alphaf > 255)
		return 255;
	return cast(ubyte) alphaf;
}


int fromHex(string s) {
	int result = 0;

	int exp = 1;
	// foreach(c; retro(s)) {
	foreach_reverse(c; s) {
		if(c >= 'A' && c <= 'F')
			result += exp * (c - 'A' + 10);
		else if(c >= 'a' && c <= 'f')
			result += exp * (c - 'a' + 10);
		else if(c >= '0' && c <= '9')
			result += exp * (c - '0');
		else
			throw new Exception("invalid hex character: " ~ cast(char) c);

		exp *= 16;
	}

	return result;
}

Color colorFromString(string s) {
	if(s.length == 0)
		return Color(0,0,0,255);
	if(s[0] == '#')
		s = s[1..$];
	assert(s.length == 6 || s.length == 8);

	Color c;

	c.r = cast(ubyte) fromHex(s[0..2]);
	c.g = cast(ubyte) fromHex(s[2..4]);
	c.b = cast(ubyte) fromHex(s[4..6]);
	if(s.length == 8)
		c.a = cast(ubyte) fromHex(s[6..8]);
	else
		c.a = 255;

	return c;
}

/*
import browser.window;
import std.conv;
void main() {
	import browser.document;
	foreach(ele; document.querySelectorAll("input")) {
		ele.addEventListener("change", {
			auto h = toInternal!real(document.querySelector("input[name=h]").value);
			auto s = toInternal!real(document.querySelector("input[name=s]").value);
			auto l = toInternal!real(document.querySelector("input[name=l]").value);

			Color c = Color.fromHsl(h, s, l);

			auto e = document.getElementById("example");
			e.style.backgroundColor = c.toCssString();

			// JSElement __js_this;
			// __js_this.style.backgroundColor = c.toCssString();
		}, false);
	}
}
*/



/**
	This provides two image classes and a bunch of functions that work on them.

	Why are they separate classes? I think the operations on the two of them
	are necessarily different. There's a whole bunch of operations that only
	really work on truecolor (blurs, gradients), and a few that only work
	on indexed images (palette swaps).

	Even putpixel is pretty different. On indexed, it is a palette entry's
	index number. On truecolor, it is the actual color.

	A greyscale image is the weird thing in the middle. It is truecolor, but
	fits in the same size as indexed. Still, I'd say it is a specialization
	of truecolor.

	There is a subset that works on both

*/


interface MemoryImage {
	//IndexedImage convertToIndexedImage() const;
	//TrueColorImage convertToTrueColor() const;
	TrueColorImage getAsTrueColorImage();
}

class IndexedImage : MemoryImage {
	bool hasAlpha;
	Color[] palette;
	ubyte[] data;

	int width;
	int height;

	this(int w, int h) {
		width = w;
		height = h;
		data = new ubyte[w*h];
	}

	/*
	void resize(int w, int h, bool scale) {

	}
	*/

	override TrueColorImage getAsTrueColorImage() {
		return convertToTrueColor();
	}

	TrueColorImage convertToTrueColor() const {
		auto tci = new TrueColorImage(width, height);
		foreach(i, b; data) {
			tci.imageData.colors[i] = palette[b];
		}
		return tci;
	}

	ubyte getOrAddColor(Color c) {
		foreach(i, co; palette) {
			if(c == co)
				return cast(ubyte) i;
		}

		return addColor(c);
	}

	int numColors() const {
		return palette.length;
	}

	ubyte addColor(Color c) {
		assert(palette.length < 256);
		if(c.a != 255)
			hasAlpha = true;
		palette ~= c;

		return cast(ubyte) (palette.length - 1);
	}
}

class TrueColorImage : MemoryImage {
//	bool hasAlpha;
//	bool isGreyscale;
	//ubyte[] data; // stored as rgba quads, upper left to right to bottom
	union Data {
		ubyte[] bytes;
		Color[] colors;

		static assert(Color.sizeof == 4);
	}

	Data imageData;
	alias imageData.bytes data;

	int width;
	int height;

	this(int w, int h) {
		width = w;
		height = h;
		imageData.bytes = new ubyte[w*h*4];
	}

	override TrueColorImage getAsTrueColorImage() {
		return this;
	}

/+
	IndexedImage convertToIndexedImage(int maxColors = 256) {

	}
+/
}
