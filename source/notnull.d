module notnull;

class NullPointerException : Exception {
    @safe pure nothrow this(string file = __FILE__, 
			size_t line = __LINE__, Throwable next = null) 
	{
        super("Tried to deference a null pointer", file, line, next );
    }
}

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
