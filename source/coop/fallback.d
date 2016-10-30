/**
 * Copyright: Copyright (c) 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.fallback;

version(LDC)
{
    // from std.exception
    mixin template basicExceptionCtors()
    {
        /++
         Params:
         msg  = The message for the exception.
         file = The file where the exception occurred.
         line = The line number where the exception occurred.
         next = The previous exception in the chain of exceptions, if any.
         +/
        this(string msg, string file = __FILE__, size_t line = __LINE__,
             Throwable next = null) @nogc @safe pure nothrow
        {
            super(msg, file, line, next);
        }

        /++
         Params:
         msg  = The message for the exception.
         next = The previous exception in the chain of exceptions.
         file = The file where the exception occurred.
         line = The line number where the exception occurred.
         +/
        this(string msg, Throwable next, string file = __FILE__,
             size_t line = __LINE__) @nogc @safe pure nothrow
        {
            super(msg, file, line, next);
        }
    }

    // from std.algorithm.iteration
    template fold(fun...) if (fun.length >= 1)
    {
        auto fold(R, S...)(R r, S seed)
        {
            static if (S.length < 2)
            {
                return reduce!fun(seed, r);
            }
            else
            {
                import std.typecons : tuple;
                return reduce!fun(tuple(seed), r);
            }
        }
    }
}
