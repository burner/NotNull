module notnull;

class NullPointerException : Exception {
    @safe pure nothrow this(string file = __FILE__, 
			size_t line = __LINE__, Throwable next = null) 
	{
        super("Tried to deference a null pointer", file, line, next );
    }
}

ref T nnl(T)(return scope T* ptr, string file = __FILE__,
	   	size_t line = __LINE__) 
{
	if(ptr is null) {
		throw new NullPointerException(file, line);
	}

	return *ptr;
}

unittest {
	int a;
	nnl(&a);

	(&a).nnl();
}

unittest {
	import std.exception : assertThrown;
	int* a = null;
	assertThrown!NullPointerException(nnl(a));
}

unittest {
	import std.exception : assertThrown, assertNotThrown;
	struct A {
	}

	struct B {
		A* a;
	}

	B* b;
	assertThrown!NullPointerException(nnl(b));
	
	b = new B;
	assertNotThrown(nnl(b));

	assertThrown!NullPointerException(nnl(b).a.nnl());
	assertThrown!NullPointerException(b.nnl().a.nnl());

	b.a = new A;
	assertNotThrown(nnl(b).a.nnl());
}
