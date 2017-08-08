# NotNull

![alt text](https://travis-ci.org/burner/notnull.svg)

A super simple function to make null checks of pointers a breeze for the D
Programming Language

## $(D nnL) function:
```D
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
```

## $(D Null) type:

$(D Null) could be considered to be the successor to $(D Nullable).
It allows to create a type how is not only nullable but also can carry
$(D Exception)s.
```D

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
```
