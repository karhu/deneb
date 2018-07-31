module deneb.proxy;

mixin template Proxy(alias a)
{
    private alias ValueType = typeof({ return a; }());

    /* Determine if 'T.a' can referenced via a const(T).
     * Use T* as the parameter because 'scope' inference needs a fully
     * analyzed T, which doesn't work when accessibleFrom() is used in a
     * 'static if' in the definition of Proxy or T.
     */
    private enum bool accessibleFrom(T) =
        is(typeof((T* self){ cast(void) mixin("(*self)."~__traits(identifier, a)); }));

    static if (is(typeof(this) == class))
    {
        override bool opEquals(Object o)
        {
            if (auto b = cast(typeof(this))o)
            {
                return a == mixin("b."~__traits(identifier, a));
            }
            return false;
        }

        bool opEquals(T)(T b)
            if (is(ValueType : T) || is(typeof(a.opEquals(b))) || is(typeof(b.opEquals(a))))
        {
            static if (is(typeof(a.opEquals(b))))
                return a.opEquals(b);
            else static if (is(typeof(b.opEquals(a))))
                return b.opEquals(a);
            else
                return a == b;
        }

        override int opCmp(Object o)
        {
            if (auto b = cast(typeof(this))o)
            {
                return a < mixin("b."~__traits(identifier, a)) ? -1
                     : a > mixin("b."~__traits(identifier, a)) ? +1 : 0;
            }
            static if (is(ValueType == class))
                return a.opCmp(o);
            else
                throw new Exception("Attempt to compare a "~typeid(this).toString~" and a "~typeid(o).toString);
        }

        int opCmp(T)(auto ref const T b)
            if (is(ValueType : T) || is(typeof(a.opCmp(b))) || is(typeof(b.opCmp(a))))
        {
            static if (is(typeof(a.opCmp(b))))
                return a.opCmp(b);
            else static if (is(typeof(b.opCmp(a))))
                return -b.opCmp(b);
            else
                return a < b ? -1 : a > b ? +1 : 0;
        }

        static if (accessibleFrom!(const typeof(this)))
        {
            override hash_t toHash() const nothrow @trusted
            {
                static if (is(typeof(&a) == ValueType*))
                    alias v = a;
                else
                    auto v = a;     // if a is (property) function
                return typeid(ValueType).getHash(cast(const void*)&v);
            }
        }
    }
    else
    {
        auto ref opEquals(this X, B)(auto ref B b)
        {
            static if (is(immutable B == immutable typeof(this)))
            {
                return a == mixin("b."~__traits(identifier, a));
            }
            else
                return a == b;
        }

        auto ref opCmp(this X, B)(auto ref B b)
          if (!is(typeof(a.opCmp(b))) || !is(typeof(b.opCmp(a))))
        {
            static if (is(typeof(a.opCmp(b))))
                return a.opCmp(b);
            else static if (is(typeof(b.opCmp(a))))
                return -b.opCmp(a);
            else static if (isFloatingPoint!ValueType || isFloatingPoint!B)
                return a < b ? -1 : a > b ? +1 : a == b ? 0 : float.nan;
            else
                return a < b ? -1 : (a > b);
        }
    }

    auto ref opCall(this X, Args...)(auto ref Args args) { return a(args); }

    auto ref opCast(T, this X)() { return cast(T) a; }

    auto ref opIndex(this X, D...)(auto ref D i)               { return a[i]; }
    auto ref opSlice(this X      )()                           { return a[]; }
    auto ref opSlice(this X, B, E)(auto ref B b, auto ref E e) { return a[b .. e]; }

    auto ref opUnary     (string op, this X      )()                           { return mixin(op~"a"); }
    auto ref opIndexUnary(string op, this X, D...)(auto ref D i)               { return mixin(op~"a[i]"); }
    auto ref opSliceUnary(string op, this X      )()                           { return mixin(op~"a[]"); }
    auto ref opSliceUnary(string op, this X, B, E)(auto ref B b, auto ref E e) { return mixin(op~"a[b .. e]"); }

    auto ref opBinary(string op, this X, B)(auto ref B b)
    if (op == "in" && is(typeof(a in b)) || op != "in")
    {
        return mixin("a "~op~" b");
    }
    auto ref opBinaryRight(string op, this X, B)(auto ref B b) { return mixin("b "~op~" a"); }

    static if (!is(typeof(this) == class))
    {
        import std.traits;
        static if (isAssignable!ValueType)
        {
            auto ref opAssign(this X)(auto ref typeof(this) v)
            {
                a = mixin("v."~__traits(identifier, a));
                return this;
            }
        }
        else
        {
            @disable void opAssign(this X)(auto ref typeof(this) v);
        }
    }

    auto ref opAssign     (this X, V      )(auto ref V v) if (!is(V == typeof(this))) { return a       = v; }
    auto ref opIndexAssign(this X, V, D...)(auto ref V v, auto ref D i)               { return a[i]    = v; }
    auto ref opSliceAssign(this X, V      )(auto ref V v)                             { return a[]     = v; }
    auto ref opSliceAssign(this X, V, B, E)(auto ref V v, auto ref B b, auto ref E e) { return a[b .. e] = v; }

    auto ref opOpAssign     (string op, this X, V      )(auto ref V v)
    {
        return mixin("a "      ~op~"= v");
    }
    auto ref opIndexOpAssign(string op, this X, V, D...)(auto ref V v, auto ref D i)
    {
        return mixin("a[i] "   ~op~"= v");
    }
    auto ref opSliceOpAssign(string op, this X, V      )(auto ref V v)
    {
        return mixin("a[] "    ~op~"= v");
    }
    auto ref opSliceOpAssign(string op, this X, V, B, E)(auto ref V v, auto ref B b, auto ref E e)
    {
        return mixin("a[b .. e] "~op~"= v");
    }

    template opDispatch(string name)
    {
        static if (is(typeof(__traits(getMember, a, name)) == function))
        {
            // non template function
            auto ref opDispatch(this X, Args...)(auto ref Args args) { return mixin("a."~name~"(args)"); }
        }
        else static if (is(typeof({ enum x = mixin("a."~name); })))
        {
            // built-in type field, manifest constant, and static non-mutable field
            enum opDispatch = mixin("a."~name);
        }
        else static if (is(typeof(mixin("a."~name))) || __traits(getOverloads, a, name).length != 0)
        {
            // field or property function
            @property auto ref opDispatch(this X)()                { return mixin("a."~name);        }
            @property auto ref opDispatch(this X, V)(auto ref V v) { return mixin("a."~name~" = v"); }
        }
        else
        {
            // member template
            template opDispatch(T...)
            {
                enum targs = T.length ? "!T" : "";
                auto ref opDispatch(this X, Args...)(auto ref Args args){ return mixin("a."~name~targs~"(args)"); }
            }
        }
    }

    import std.traits : isArray;

    static if (isArray!ValueType)
    {
        auto opDollar() const { return a.length; }
    }
    else static if (is(typeof(a.opDollar!0)))
    {
        auto ref opDollar(size_t pos)() { return a.opDollar!pos(); }
    }
    else static if (is(typeof(a.opDollar) == function))
    {
        auto ref opDollar() { return a.opDollar(); }
    }
    else static if (is(typeof(a.opDollar)))
    {
        alias opDollar = a.opDollar;
    }
}