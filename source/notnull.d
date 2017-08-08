module notnull;

/** Thrown if $(D nnL) gets passed a pointer that is null.
*/
class NullPointerException : Exception {
    @safe pure nothrow this(string file = __FILE__, 
			size_t line = __LINE__, Throwable next = null) 
	{
        super("Tried to deference a null pointer", file, line, next );
    }

    @safe pure nothrow this(NullPointerException old) {
		super(old.msg, old.file, old.line, old.next);
	}
}

/** Returns a reference to the object the passed pointer points to.
If $(D ptr) is null a $(D NullPointerException) is thrown.
*/
ref T nnL(T)(return scope T* ptr, string file = __FILE__,
	   	size_t line = __LINE__) 
{
	if(ptr is null) {
		throw new NullPointerException(file, line);
	}

	return *ptr;
}

unittest {
	int a;
	nnL(&a);

	(&a).nnL();
}

unittest {
	import std.exception : assertThrown;
	int* a = null;
	assertThrown!NullPointerException(nnL(a));
}

unittest {
	import std.exception : assertThrown, assertNotThrown;
	struct A {
	}

	struct B {
		A* a;
	}

	B* b;
	assertThrown!NullPointerException(nnL(b));
	
	b = new B;
	assertNotThrown(nnL(b));

	assertThrown!NullPointerException(nnL(b).a.nnL());
	assertThrown!NullPointerException(b.nnL().a.nnL());

	b.a = new A;
	assertNotThrown(nnL(b).a.nnL());
}

private string buildErrorStringRecur(E...)() if(E.length > 0) {
	return E[0].stringof ~ "," ~ buildErrorStringRecur!(E[1 .. $]);
}

private string buildErrorStringRecur(E...)() if(E.length == 0) {
	return "}";
}

private string buildErrorString(Exp...)() {
	return "enum ErrorType { hasData, hasNoData, " ~ 
		buildErrorStringRecur!Exp();
}

private string buildThrowSwitch(Exp...)() {
	return `switch(this.error) {
		case ErrorType.hasData:
			goto default;
		default:
			break;
		case ErrorType.hasNoData:
			assert(false, "No Data nor an Exception Present");
	`~ buildThrowSwitchRecu!(Exp)();
}

private string buildThrowSwitchRecu(E...)() if(E.length > 0) {
	static if(is(E[0] == Exception)) {
		return "case ErrorType.Exception:" ~
			"throw new Exception(" ~
				"(cast(Exception)(this.payload.ptr)).msg," ~
				"(cast(Exception)(this.payload.ptr)).file," ~
				"(cast(Exception)(this.payload.ptr)).line," ~
				"(cast(Exception)(this.payload.ptr)).next);"
			~ buildThrowSwitchRecu!(E[1 .. $]);
	} else static if(is(E[0] == Error)) {
		return "case ErrorType.Error:" ~
			"throw new Error(" ~
				"(cast(Error)(this.payload.ptr)).msg," ~
				"(cast(Error)(this.payload.ptr)).file," ~
				"(cast(Error)(this.payload.ptr)).line," ~
				"(cast(Error)(this.payload.ptr)).next);"
			~ buildThrowSwitchRecu!(E[1 .. $]);
	} else static if(is(E[0] == Throwable)) {
		return "case ErrorType.Throwable:" ~
			"throw new Throwable(" ~
				"(cast(Throwable)(this.payload.ptr)).msg," ~
				"(cast(Throwable)(this.payload.ptr)).file," ~
				"(cast(Throwable)(this.payload.ptr)).line," ~
				"(cast(Throwable)(this.payload.ptr)).next);"
			~ buildThrowSwitchRecu!(E[1 .. $]);
	} else {
		return "case ErrorType." ~ E[0].stringof ~ `:
			throw new ` ~ E[0].stringof ~ "((cast(" ~ E[0].stringof 
			~ ")(this.payload.ptr)));"
			~ buildThrowSwitchRecu!(E[1 .. $]);
	}
}

private string buildThrowSwitchRecu(E...)() if(E.length == 0) {
	return "}";
}

private template classSize(C) if(is(C : Exception)) {
	enum size_t classSize = __traits(classInstanceSize, C);
}

struct Null(T,Exp...) {
	import std.algorithm.comparison : max;
	import std.meta : staticMap;
	import std.traits : isImplicitlyConvertible;

	alias Type = T;

	static if(Exp.length > 0) {
		align(8)
		void[max(staticMap!(classSize, Exp), T.sizeof)] payload;
	} else {
		align(8)
		void[T.sizeof] payload;
	}
	mixin(buildErrorString!Exp());
	ErrorType error = ErrorType.hasNoData;

	@property bool isNull() pure nothrow @nogc const {
		return this.error >= ErrorType.hasNoData;
	}

	@property bool isNotNull() pure nothrow @nogc const {
		return this.error == ErrorType.hasData;
	}
	
	void opAssign(S)(auto ref S s) if(isImplicitlyConvertible!(S,T)) {
		*(cast(T*)(this.payload.ptr)) = s;
		this.error = ErrorType.hasData;
	}

	void set(E, string file = __FILE__, size_t line = __LINE__, Args...)(auto ref Args args) {
		import std.conv : emplace;
		emplace!E(this.payload[0 .. $], args, file, line);
		mixin("this.error = ErrorType." ~ E.stringof ~ ";");
	}

	ErrorType getError() const pure @safe nothrow @nogc {
		return this.error;
	}

	ref T get() @trusted {
		if(this.error == ErrorType.hasData) {
			return *(cast(T*)(this.payload.ptr));
		}
		mixin(buildThrowSwitch!(Exp)());
		assert(false);
	}

	void rethrow() {
		mixin(buildThrowSwitch!(Exp)());
	}
}

T makeNull(T,S)(auto ref S s) {
	T ret;
	ret = s;
	return ret;
}

T makeNull(T,E, string file = __FILE__, size_t line = __LINE__, Args...)
		(auto ref Args args) 
{
	T ret;
	ret.set!(E,file,line)(args);
	return ret;
}

pure unittest {
	alias NullInt = Null!(int, NullPointerException, Exception);
	NullInt ni;
	pragma(msg, NullInt.sizeof);
	assert(ni.isNull);
	assert(!ni.isNotNull);

	ni = 10;
	assert(ni.get() == 10);
}

pure unittest {
	alias NullInt = Null!(int, NullPointerException, Exception);
	NullInt ni;

	string f = __FILE__;
	int l = __LINE__ + 1;
	ni.set!NullPointerException();
	assert(ni.getError() == NullInt.ErrorType.NullPointerException);

	NullPointerException npe;
	try {
		ni.rethrow();
	} catch(NullPointerException e) {
		npe = e;
	}
	assert(npe !is null);
	assert(npe.file == f, npe.file);
	assert(npe.line == l);
}

pure unittest {
	alias NullInt = Null!(int, NullPointerException, Exception);
	auto ni = makeNull!NullInt(10);
	assert(ni.isNotNull);
	assert(ni.get() == 10);
}

pure @safe unittest {
	alias NullT = Null!(float);
	NullT nf;
}

pure unittest {
	alias NullInt = Null!(int, NullPointerException, Exception);
	auto ni = makeNull!(NullInt,NullPointerException)();
	assert(ni.isNull);
}

pure unittest {
	alias NullInt = Null!(int, NullPointerException, Exception);
	string msg = "some message";
	auto ni = makeNull!(NullInt,Exception)(msg);
	assert(ni.isNull);

	try {
		ni.rethrow();
	} catch(Exception e) {
		assert(msg == e.msg);
		return;
	}
	assert(false, "Wrong Exception rethrown");
}

pure unittest {
	alias NullInt = Null!(int, NullPointerException, Exception);
	NullInt ni;
	assert(ni.isNull);
	assert(!ni.isNotNull);

	ni = 10;
	assert(!ni.isNull);
	assert(ni.isNotNull);
	assert(ni.get() == 10);

	ni.set!NullPointerException();
	assert(ni.isNull);
}
