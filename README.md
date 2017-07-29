# NotNull

![alt text](https://travis-ci.org/burner/notnull.svg)

A super simple function to make null checks of pointers a breeze for the D
Programming Language

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
