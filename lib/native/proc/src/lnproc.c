#include "lnproc.h"
#include "lauxlib.h"
#include "lua.h"
#include "luaconf.h"
#include <errno.h>
#include <stdio.h>
#include <string.h>

/*
** {==================================================================
** from losliv.c #102 - #136
** Configuration for 'tmpnam':
** By default, Lua uses tmpnam except when POSIX is available, where
** it uses mkstemp.
** ===================================================================
*/
#if !defined(eli_tmpnam)   /* { */
#if defined(LUA_USE_POSIX) /* { */

#include <unistd.h>
#define ELI_TMPNAMBUFSIZE 32
#if !defined(ELI_TMPNAMTEMPLATE)
#define ELI_TMPNAMBUFSIZE "/tmp/eli_XXXXXX"
#endif

#define eli_tmpnam(b, e)                                                       \
  {                                                                            \
    strcpy(b, LUA_TMPNAMTEMPLATE);                                             \
    e = mkstemp(b);                                                            \
    if (e != -1)                                                               \
      close(e);                                                                \
    e = (e == -1);                                                             \
  }

#else /* }{ */
/* ISO C definitions */
#define ELI_TMPNAMBUFSIZE L_tmpnam
#define eli_tmpnam(b, e)                                                       \
  { e = (tmpnam(b) == NULL); }
#endif /* } */
#endif /* } */
/* }================================================================== */

#if !defined(l_inspectstat) /* { */

#if defined(LUA_USE_POSIX)

#include <sys/wait.h>

/*
** use appropriate macros to interpret 'pclose' return status
*/
#define l_inspectstat(stat, what)                                              \
  if (WIFEXITED(stat)) {                                                       \
    stat = WEXITSTATUS(stat);                                                  \
  } else if (WIFSIGNALED(stat)) {                                              \
    stat = WTERMSIG(stat);                                                     \
    what = "signal";                                                           \
  }

#else

#define l_inspectstat(stat, what) /* no op */

#endif

#endif /* } */

static NATIVE_PROC_STDSTREAM_KIND get_stdstream_kind(lua_State *L, int idx) {
  int stdstreamType = lua_type(L, idx);
  switch (stdstreamType) {
  case LUA_TBOOLEAN:
    int wants = lua_toboolean(L, idx);
    return wants ? NATIVE_PROC_STDSTREAM_TMP_KIND
                 : NATIVE_PROC_STDSTREAM_IGNORE_KIND;
  case LUA_TSTRING:
    return NATIVE_PROC_STDSTREAM_FILE_KIND;
  default:
    return luaL_typeerror(L, idx, "boolean/string");
  }
}

static int eli_exec(lua_State *L) {
  size_t cmdl;
  const char *cmd = luaL_optlstring(L, 1, NULL, &cmdl);
  const char *stdoutFile = NULL;
  const char *stderrFile = NULL;
  if (cmd != NULL) {
    int optionsType = lua_type(L, 2);
    NATIVE_PROC_STDSTREAM_KIND collect_stdout =
        NATIVE_PROC_STDSTREAM_IGNORE_KIND;
    NATIVE_PROC_STDSTREAM_KIND collect_stderr =
        NATIVE_PROC_STDSTREAM_IGNORE_KIND;
    switch (optionsType) {
    case LUA_TTABLE:
      lua_getfield(L, 2, "stdio");
      int stdioType = lua_type(L, 3);
      switch (stdioType) {
      case LUA_TTABLE:
        lua_getfield(L, 3, "stdout");
        collect_stdout = get_stdstream_kind(L, 4);
        if (collect_stdout == NATIVE_PROC_STDSTREAM_FILE_KIND) {
          // get_stdstream_kind makes sure we get string here
          stdoutFile = luaL_checkstring(L, 4);
        }
        lua_pop(L, 1);

        lua_getfield(L, 3, "stderr");
        collect_stderr = get_stdstream_kind(L, 4);
        if (collect_stdout == NATIVE_PROC_STDSTREAM_FILE_KIND) {
          // get_stdstream_kind makes sure we get string here
          stdoutFile = luaL_checkstring(L, 4);
        }
        lua_pop(L, 1);
        break;
      case LUA_TBOOLEAN:;
        int collect = lua_toboolean(L, 3);
        collect_stdout = collect ? NATIVE_PROC_STDSTREAM_TMP_KIND
                                 : NATIVE_PROC_STDSTREAM_IGNORE_KIND;
        collect_stderr = collect ? NATIVE_PROC_STDSTREAM_TMP_KIND
                                 : NATIVE_PROC_STDSTREAM_IGNORE_KIND;
        break;
      }
      lua_pop(L, 1);
      break;
    case LUA_TNIL:
      break;
    default:
      return luaL_typeerror(L, 2, "table");
    }

    if (collect_stdout != NATIVE_PROC_STDSTREAM_IGNORE_KIND) {
      if (stdoutFile == NULL) {
        const char buff[ELI_TMPNAMBUFSIZE];
        int err;
        eli_tmpnam(buff, err);
        stdoutFile = buff;
      }
    }
    if (collect_stderr != NATIVE_PROC_STDSTREAM_IGNORE_KIND) {
      if (stderrFile == NULL) {
        const char buff[ELI_TMPNAMBUFSIZE];
        int err;
        eli_tmpnam(buff, err);
        stderrFile = buff;
      }
    }

    int stdoutFilel = stdoutFile == NULL ? 0 : strlen(stdoutFile) + 5;
    int stderrFilel = stderrFile == NULL ? 0 : strlen(stderrFile) + 6;
    const char *newCmd = malloc(cmdl + stdoutFilel + stderrFilel);
    const char *p = newCmd;
    strcpy(p, cmd);
    p += cmdl;
    strcpy(p, " >\"");
    p += 3;
    strcpy(p, stdoutFile);
    p += strlen(stdoutFile);
    strcpy(p++, '"');

    strcpy(p, " 2>\"");
    p += 4;
    strcpy(p, stderrFile);
    p += strlen(stderrFile);
    strcpy(p, '"');
    cmd = newCmd;
  }

  int stat;
  errno = 0;
  stat = system(cmd);
  if (cmd != NULL) {
    if (stat == -1) /* error? */
      return luaL_fileresult(L, 0, NULL);
    else {
      lua_pushinteger(L, stat);
      lua_pushstring(L, stdoutFile);
      lua_pushstring(L, stderrFile);
      return 3; /* return true/nil,what,code */
    }
    return luaL_execresult(L, stat);
  } else {
    lua_pushboolean(L, stat); /* true if there is a shell */
    return 1;
  }
}

static const struct luaL_Reg eliProcNative[] = {
    {"exec", eli_exec},
    {NULL, NULL},
};

int luaopen_eli_proc_native(lua_State *L)
{
    process_create_meta(L);

    lua_newtable(L);
    luaL_setfuncs(L, eliProcNative, 0);
    return 1;
}