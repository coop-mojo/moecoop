/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.fallback;

version(LDC)
{
    // from std.algorithm.iteration
    template fold(fun...) if (fun.length >= 1)
    {
        auto fold(R, S...)(R r, S seed)
        {
            import std.algorithm: reduce;

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
