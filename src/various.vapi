[CCode (cname="g_get_monotonic_time", cheader_filename = "glib.h")]
uint64 get_monotonic_time();
[CCode (cname = "g_strndup", cheader_filename = "glib.h")]
static string strndup(char* str, size_t n);
[CCode (cheader_filename = "unistd.h")]
long sysconf(int name);
[CCode (cname = "_SC_PAGESIZE", cheader_filename = "unistd.h")]
public static int PAGESIZE;
[CCode (cheader_filename = "unistd.h")]
int execvp(char* filename, [CCode (array_length = false, array_null_terminated = true)] string[] argv);
