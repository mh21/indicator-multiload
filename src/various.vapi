[CCode (cname="g_get_monotonic_time", cheader_filename = "glib.h")]
uint64 get_monotonic_time();
[CCode (cname = "g_strndup", cheader_filename = "glib.h")]
static string strndup(char* str, size_t n);
// this is in vala git, but not in vala <= 0.16
[CCode (cheader_filename = "unistd.h")]
int execvp (string path, [CCode (array_length = false, null_terminated = true)] string[] arg);
