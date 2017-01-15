/**
 * Copyright: Copyright 2016 Mojo
 * Authors: Mojo
 * License: $(LINK2 https://github.com/coop-mojo/moecoop/blob/master/LICENSE, MIT License)
 */
module coop.migemo.derelict.migemo;

private {
    import derelict.util.loader;
    import derelict.util.system;

    static if (Derelict_OS_Windows)
        enum libNames = "migemo.dll";
    else static if (Derelict_OS_Mac)
        enum libNames = "libmigemo.1.dylib,libmigemo.dylib";
    else static if (Derelict_OS_Posix)
        enum libNames = "libmigemo.so";
    else
        static assert(false, "Need to implement Migemo libNames for this operating system.");
}

/// for migemo_load()
enum MIGEMO_DICTID: int
{
    INVALID   = 0,
    MIGEMO    = 1,
    ROMA2HIRA = 2,
    HIRA2KATA = 3,
    HAN2ZEN   = 4,
    ZEN2HAN   = 5,
}

/// for migemo_set_operator()/migemo_get_operator()
enum MIGEMO_OPINDEX: int
{
    OR         = 0,
    NEST_IN    = 1,
    NEST_OUT   = 2,
    SELECT_IN  = 3,
    SELECT_OUT = 4,
    NEWLINE    = 5,
}

extern(C) pure nothrow @nogc{
    alias MIGEMO_PROC_CHAR2INT = int function(const(char)*, uint*);
    alias MIGEMO_PROC_INT2CHAR = int function(uint, char*);
}

struct migemo;

extern(C) pure nothrow @nogc
{
    alias da_migemo_open = migemo* function(const(char)*);
    alias da_migemo_close = void function(migemo*);
    alias da_migemo_query = char* function(migemo*, const(char)*);
    alias da_migemo_release = void function(migemo*, char*);

    alias da_migemo_set_operator = int function(migemo*, MIGEMO_OPINDEX, const(char)*);
    alias da_migemo_get_operator = const(char)* function(migemo*, MIGEMO_OPINDEX);
    alias da_migemo_setproc_char2int = void function(migemo*, MIGEMO_PROC_CHAR2INT);
    alias da_migemo_setproc_int2char = void function(migemo*, MIGEMO_PROC_INT2CHAR);

    alias da_migemo_load = MIGEMO_DICTID function(migemo*, MIGEMO_DICTID, const(char)*);
    alias da_migemo_is_enable = int function(migemo*);
}

__gshared {
    da_migemo_open migemo_open;
    da_migemo_close migemo_close;
    da_migemo_query migemo_query;
    da_migemo_release migemo_release;

    da_migemo_set_operator migemo_set_operator;
    da_migemo_get_operator migemo_get_operator;
    da_migemo_setproc_char2int migemo_setproc_char2int;
    da_migemo_setproc_int2char migemo_setproc_int2char;

    da_migemo_load migemo_load;
    da_migemo_is_enable migemo_is_enable;
}

class DerelictMigemoLoader: SharedLibLoader {
    this() {
        super(libNames);
    }

    protected override void loadSymbols() {
        bindFunc(cast(void**)&migemo_open, "migemo_open");
        bindFunc(cast(void**)&migemo_close, "migemo_close");
        bindFunc(cast(void**)&migemo_query, "migemo_query");
        bindFunc(cast(void**)&migemo_release, "migemo_release");

        bindFunc(cast(void**)&migemo_set_operator, "migemo_set_operator");
        bindFunc(cast(void**)&migemo_get_operator, "migemo_get_operator");
        bindFunc(cast(void**)&migemo_setproc_char2int, "migemo_setproc_char2int");
        bindFunc(cast(void**)&migemo_setproc_int2char, "migemo_setproc_int2char");

        bindFunc(cast(void**)&migemo_load, "migemo_load");
        bindFunc(cast(void**)&migemo_is_enable, "migemo_is_enable");
    }
}

__gshared DerelictMigemoLoader DerelictMigemo;

shared static this() {
    DerelictMigemo = new DerelictMigemoLoader();
}
