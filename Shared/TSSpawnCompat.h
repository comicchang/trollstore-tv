#ifndef TSSPAWNCOMPAT_H
#define TSSPAWNCOMPAT_H

// tvOS SDK 将 posix_spawn 系列标记为 unavailable，但 libSystem 运行时仍导出。
// 该头文件在 tvOS 下用 dlsym 包装这些调用；其它平台直接使用系统声明。

#include <spawn.h>
#include <dispatch/dispatch.h>

#if TARGET_OS_TV

#include <dlfcn.h>

typedef int (*ts_spawn_fn)(pid_t*, const char*, posix_spawn_file_actions_t*, posix_spawnattr_t*, char* const[], char* const[]);
typedef int (*ts_spawnattr_fn)(posix_spawnattr_t*);
typedef int (*ts_spawnattr_set_persona_np_fn)(posix_spawnattr_t*, uint32_t, uint32_t);
typedef int (*ts_spawnattr_set_persona_uid_np_fn)(posix_spawnattr_t*, uid_t);
typedef int (*ts_spawnattr_set_persona_gid_np_fn)(posix_spawnattr_t*, gid_t);
typedef int (*ts_fa_init_fn)(posix_spawn_file_actions_t*);
typedef int (*ts_fa_destroy_fn)(posix_spawn_file_actions_t*);
typedef int (*ts_fa_adddup2_fn)(posix_spawn_file_actions_t*, int, int);
typedef int (*ts_fa_addclose_fn)(posix_spawn_file_actions_t*, int);

typedef struct {
	ts_spawn_fn spawn;
	ts_spawnattr_fn attr_init;
	ts_spawnattr_fn attr_destroy;
	ts_spawnattr_set_persona_np_fn persona;
	ts_spawnattr_set_persona_uid_np_fn persona_uid;
	ts_spawnattr_set_persona_gid_np_fn persona_gid;
	ts_fa_init_fn fa_init;
	ts_fa_destroy_fn fa_destroy;
	ts_fa_adddup2_fn fa_adddup2;
	ts_fa_addclose_fn fa_addclose;
} ts_spawn_syms_t;

static inline ts_spawn_syms_t* ts_spawn_syms(void)
{
	static ts_spawn_syms_t syms;
	static dispatch_once_t once;
	dispatch_once(&once, ^
	{
		void* h = dlopen("/usr/lib/libSystem.B.dylib", RTLD_LAZY | RTLD_GLOBAL);
		if (!h) h = dlopen(NULL, RTLD_LAZY);
		syms.spawn = (ts_spawn_fn)dlsym(h, "posix_spawn");
		syms.attr_init = (ts_spawnattr_fn)dlsym(h, "posix_spawnattr_init");
		syms.attr_destroy = (ts_spawnattr_fn)dlsym(h, "posix_spawnattr_destroy");
		syms.persona = (ts_spawnattr_set_persona_np_fn)dlsym(h, "posix_spawnattr_set_persona_np");
		syms.persona_uid = (ts_spawnattr_set_persona_uid_np_fn)dlsym(h, "posix_spawnattr_set_persona_uid_np");
		syms.persona_gid = (ts_spawnattr_set_persona_gid_np_fn)dlsym(h, "posix_spawnattr_set_persona_gid_np");
		syms.fa_init = (ts_fa_init_fn)dlsym(h, "posix_spawn_file_actions_init");
		syms.fa_destroy = (ts_fa_destroy_fn)dlsym(h, "posix_spawn_file_actions_destroy");
		syms.fa_adddup2 = (ts_fa_adddup2_fn)dlsym(h, "posix_spawn_file_actions_adddup2");
		syms.fa_addclose = (ts_fa_addclose_fn)dlsym(h, "posix_spawn_file_actions_addclose");
	});
	return &syms;
}

static inline int tsr_posix_spawn(pid_t* pid, const char* path, posix_spawn_file_actions_t* fa, posix_spawnattr_t* attr, char* const argv[], char* const envp[])
{
	ts_spawn_syms_t* s = ts_spawn_syms();
	return s->spawn ? s->spawn(pid, path, fa, attr, argv, envp) : -1;
}

static inline int tsr_posix_spawnattr_init(posix_spawnattr_t* attr)
{
	ts_spawn_syms_t* s = ts_spawn_syms();
	return s->attr_init ? s->attr_init(attr) : -1;
}

static inline int tsr_posix_spawnattr_destroy(posix_spawnattr_t* attr)
{
	ts_spawn_syms_t* s = ts_spawn_syms();
	return s->attr_destroy ? s->attr_destroy(attr) : -1;
}

static inline int tsr_posix_spawnattr_set_persona_np(posix_spawnattr_t* attr, uint32_t persona, uint32_t flags)
{
	ts_spawn_syms_t* s = ts_spawn_syms();
	return s->persona ? s->persona(attr, persona, flags) : -1;
}

static inline int tsr_posix_spawnattr_set_persona_uid_np(posix_spawnattr_t* attr, uid_t uid)
{
	ts_spawn_syms_t* s = ts_spawn_syms();
	return s->persona_uid ? s->persona_uid(attr, uid) : -1;
}

static inline int tsr_posix_spawnattr_set_persona_gid_np(posix_spawnattr_t* attr, gid_t gid)
{
	ts_spawn_syms_t* s = ts_spawn_syms();
	return s->persona_gid ? s->persona_gid(attr, gid) : -1;
}

static inline int tsr_posix_spawn_file_actions_init(posix_spawn_file_actions_t* fa)
{
	ts_spawn_syms_t* s = ts_spawn_syms();
	return s->fa_init ? s->fa_init(fa) : -1;
}

static inline int tsr_posix_spawn_file_actions_destroy(posix_spawn_file_actions_t* fa)
{
	ts_spawn_syms_t* s = ts_spawn_syms();
	return s->fa_destroy ? s->fa_destroy(fa) : -1;
}

static inline int tsr_posix_spawn_file_actions_adddup2(posix_spawn_file_actions_t* fa, int fd, int newfd)
{
	ts_spawn_syms_t* s = ts_spawn_syms();
	return s->fa_adddup2 ? s->fa_adddup2(fa, fd, newfd) : -1;
}

static inline int tsr_posix_spawn_file_actions_addclose(posix_spawn_file_actions_t* fa, int fd)
{
	ts_spawn_syms_t* s = ts_spawn_syms();
	return s->fa_addclose ? s->fa_addclose(fa, fd) : -1;
}

#define posix_spawn tsr_posix_spawn
#define posix_spawnattr_init tsr_posix_spawnattr_init
#define posix_spawnattr_destroy tsr_posix_spawnattr_destroy
#define posix_spawnattr_set_persona_np tsr_posix_spawnattr_set_persona_np
#define posix_spawnattr_set_persona_uid_np tsr_posix_spawnattr_set_persona_uid_np
#define posix_spawnattr_set_persona_gid_np tsr_posix_spawnattr_set_persona_gid_np
#define posix_spawn_file_actions_init tsr_posix_spawn_file_actions_init
#define posix_spawn_file_actions_destroy tsr_posix_spawn_file_actions_destroy
#define posix_spawn_file_actions_adddup2 tsr_posix_spawn_file_actions_adddup2
#define posix_spawn_file_actions_addclose tsr_posix_spawn_file_actions_addclose

#endif // TARGET_OS_TV

#endif // TSSPAWNCOMPAT_H