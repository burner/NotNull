module notnull;

/** Thrown if $(D nnL) gets passed a pointer that is null.
*/
class NullPointerException : Exception {
    @safe pure nothrow this(string file = __FILE__, 
			size_t line = __LINE__, Throwable next = null) 
	{
        super("Tried to deference a null pointer", file, line, next );
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
