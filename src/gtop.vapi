[CCode (cprefix = "glibtop_", lower_case_cprefix = "glibtop_", gir_namespace = "GTop", gir_version = "2.0")]
namespace GTop {
    [CCode (cheader_filename = "glibtop/cpu.h")]
    public static void get_cpu(out Cpu buf);

    [CCode (cheader_filename = "glibtop/mem.h")]
    public static void get_mem(out Mem buf);

    [CCode (cheader_filename = "glibtop/netlist.h", array_length = false, array_null_terminated = true)]
    public static string[] get_netlist(out NetList buf);

    [CCode (cheader_filename = "glibtop/netload.h")]
    public static void get_netload(out NetLoad buf, string @interface);

    [CCode (cheader_filename = "glibtop/swap.h")]
    public static void get_swap(out Swap buf);

    [CCode (cheader_filename = "glibtop/loadavg.h")]
    public static void get_loadavg(out LoadAvg buf);

    [CCode (cheader_filename = "glibtop/mountlist.h", array_length = false, array_null_terminated = true)]
    public static MountEntry[] get_mountlist(out MountList buf, bool allfs);

    [CCode (cheader_filename = "glibtop/fsusage.h")]
    public static void get_fsusage(out FSUsage buf, string mount_dir);

    [CCode (cheader_filename = "glibtop.h")]
    public static GTop *global_server;

    [CCode (cheader_filename = "glibtop.h")]
    public static GTop *init();

    [CCode (cname = "glibtop", type_id = "GTOP_TYPE_GLIBTOP", cheader_filename = "glibtop.h")]
    public struct GTop {
        public uint flags;
        public uint method;
        public uint error_method;
        [CCode (array_length = false)]
        public weak int[] input;
        [CCode (array_length = false)]
        public weak int[] output;
        public int socket;
        public int ncpu;
        public int real_ncpu;
        public uint os_version_code;
        public weak string name;
        public weak string server_command;
        public weak string server_host;
        public weak string server_user;
        public weak string server_rsh;
        public uint features;
        public uint server_port;
        public SysDeps sysdeps;
        public SysDeps required;
        public int pid;
    }

    [CCode (cname = "glibtop_sysdeps", type_id = "GTOP_TYPE_GLIBTOP_SYSDEPS", cheader_filename = "glibtop.h")]
    public struct SysDeps {
        public uint64 flags;
        public uint64 features;
        public uint64 cpu;
        public uint64 mem;
        public uint64 swap;
        public uint64 uptime;
        public uint64 loadavg;
        public uint64 shm_limits;
        public uint64 msg_limits;
        public uint64 sem_limits;
        public uint64 proclist;
        public uint64 proc_state;
        public uint64 proc_uid;
        public uint64 proc_mem;
        public uint64 proc_time;
        public uint64 proc_signal;
        public uint64 proc_kernel;
        public uint64 proc_segment;
        public uint64 proc_args;
        public uint64 proc_map;
        public uint64 proc_open_files;
        public uint64 mountlist;
        public uint64 fsusage;
        public uint64 netlist;
        public uint64 netload;
        public uint64 ppp;
        public uint64 proc_wd;
        public uint64 proc_affinity;
    }

    [CCode (cname = "glibtop_cpu", type_id = "GTOP_TYPE_GLIBTOP_CPU", cheader_filename = "glibtop/cpu.h")]
    public struct Cpu {
        public uint64 flags;
        public uint64 total;
        public uint64 user;
        public uint64 nice;
        public uint64 sys;
        public uint64 idle;
        public uint64 iowait;
        public uint64 irq;
        public uint64 softirq;
        public uint64 frequency;
        [CCode (array_length = false)]
        public weak uint64[] xcpu_total;
        [CCode (array_length = false)]
        public weak uint64[] xcpu_user;
        [CCode (array_length = false)]
        public weak uint64[] xcpu_nice;
        [CCode (array_length = false)]
        public weak uint64[] xcpu_sys;
        [CCode (array_length = false)]
        public weak uint64[] xcpu_idle;
        [CCode (array_length = false)]
        public weak uint64[] xcpu_iowait;
        [CCode (array_length = false)]
        public weak uint64[] xcpu_irq;
        [CCode (array_length = false)]
        public weak uint64[] xcpu_softirq;
        public uint64 xcpu_flags;
    }

    [CCode (cname = "glibtop_mem", type_id = "GTOP_TYPE_GLIBTOP_MEM", cheader_filename = "glibtop/mem.h")]
    public struct Mem {
        public uint64 flags;
        public uint64 total;
        public uint64 used;
        public uint64 free;
        public uint64 shared;
        public uint64 buffer;
        public uint64 cached;
        public uint64 user;
        public uint64 locked;
    }

    [CCode (cname = "glibtop_netlist", type_id = "GTOP_TYPE_GLIBTOP_NETLIST", cheader_filename = "glibtop/netlist.h")]
    public struct NetList {
        public uint64 flags;
        public uint32 number;
    }

    [CCode (cname = "glibtop_netload", type_id = "GTOP_TYPE_GLIBTOP_NETLOAD", cheader_filename = "glibtop/netload.h")]
    public struct NetLoad {
        public uint64 flags;
        public uint64 if_flags;
        public uint32 mtu;
        public uint32 subnet;
        public uint32 address;
        public uint64 packets_in;
        public uint64 packets_out;
        public uint64 packets_total;
        public uint64 bytes_in;
        public uint64 bytes_out;
        public uint64 bytes_total;
        public uint64 errors_in;
        public uint64 errors_out;
        public uint64 errors_total;
        public uint64 collisions;
        [CCode (array_length = false)]
        public weak uint8[] address6;
        [CCode (array_length = false)]
        public weak uint8[] prefix6;
        public uint8 scope6;
        [CCode (array_length = false)]
        public weak uint8[] hwaddress;
    }

    [CCode (cname = "glibtop_swap", type_id = "GTOP_TYPE_GLIBTOP_SWAP", cheader_filename = "glibtop/swap.h")]
    public struct Swap {
        public uint64 flags;
        public uint64 total;
        public uint64 used;
        public uint64 free;
        public uint64 pagein;
        public uint64 pageout;
    }

    [CCode (cname = "glibtop_loadavg", type_id = "GTOP_TYPE_GLIBTOP_LOADAVG", cheader_filename = "glibtop/loadavg.h")]
    public struct LoadAvg {
        public uint64 flags;
        [CCode (array_length = false)]
        public weak double[] loadavg;
        public uint64 nr_running;
        public uint64 nr_tasks;
        public uint64 last_pid;
    }

    [CCode (cname = "glibtop_mountlist", type_id = "GTOP_TYPE_GLIBTOP_MOUNTLIST", cheader_filename = "glibtop/mountlist.h")]
    public struct MountList {
        public uint64 flags;
        public uint64 number;
        public uint64 total;
        public uint64 size;
    }

    [CCode (cname = "glibtop_mountentry", type_id = "GTOP_TYPE_GLIBTOP_MOUNTENTRY", cheader_filename = "glibtop/mountlist.h")]
    public struct MountEntry {
        public uint64 dev;
        public weak string devname;
        public weak string mountdir;
        public weak string type;
    }

    [CCode (cname = "glibtop_fsusage", type_id = "GTOP_TYPE_GLIBTOP_FSUSAGE", cheader_filename = "glibtop/fsusage.h")]
    public struct FSUsage {
        public uint64 flags;
        public uint64 blocks;
        public uint64 bfree;
        public uint64 bavail;
        public uint64 files;
        public uint64 ffree;
        public uint32 block_size;
        public uint64 read;
        public uint64 write;
    }

    namespace IFFlags {
        [CCode (cname = "GLIBTOP_IF_FLAGS_UP", cheader_filename = "glibtop/netload.h")]
        public static int UP;
        [CCode (cname = "GLIBTOP_IF_FLAGS_BROADCAST", cheader_filename = "glibtop/netload.h")]
        public static int BROADCAST;
        [CCode (cname = "GLIBTOP_IF_FLAGS_DEBUG", cheader_filename = "glibtop/netload.h")]
        public static int DEBUG;
        [CCode (cname = "GLIBTOP_IF_FLAGS_LOOPBACK", cheader_filename = "glibtop/netload.h")]
        public static int LOOPBACK;
        [CCode (cname = "GLIBTOP_IF_FLAGS_POINTOPOINT", cheader_filename = "glibtop/netload.h")]
        public static int POINTOPOINT;
        [CCode (cname = "GLIBTOP_IF_FLAGS_RUNNING", cheader_filename = "glibtop/netload.h")]
        public static int RUNNING;
        [CCode (cname = "GLIBTOP_IF_FLAGS_NOARP", cheader_filename = "glibtop/netload.h")]
        public static int NOARP;
        [CCode (cname = "GLIBTOP_IF_FLAGS_PROMISC", cheader_filename = "glibtop/netload.h")]
        public static int PROMISC;
        [CCode (cname = "GLIBTOP_IF_FLAGS_ALLMULTI", cheader_filename = "glibtop/netload.h")]
        public static int ALLMULTI;
        [CCode (cname = "GLIBTOP_IF_FLAGS_OACTIVE", cheader_filename = "glibtop/netload.h")]
        public static int OACTIVE;
        [CCode (cname = "GLIBTOP_IF_FLAGS_SIMPLEX", cheader_filename = "glibtop/netload.h")]
        public static int SIMPLEX;
        [CCode (cname = "GLIBTOP_IF_FLAGS_LINK0", cheader_filename = "glibtop/netload.h")]
        public static int LINK0;
        [CCode (cname = "GLIBTOP_IF_FLAGS_LINK1", cheader_filename = "glibtop/netload.h")]
        public static int LINK1;
        [CCode (cname = "GLIBTOP_IF_FLAGS_LINK2", cheader_filename = "glibtop/netload.h")]
        public static int LINK2;
        [CCode (cname = "GLIBTOP_IF_FLAGS_ALTPHYS", cheader_filename = "glibtop/netload.h")]
        public static int ALTPHYS;
        [CCode (cname = "GLIBTOP_IF_FLAGS_MULTICAST", cheader_filename = "glibtop/netload.h")]
        public static int MULTICAST;
        [CCode (cname = "GLIBTOP_IF_FLAGS_WIRELESS", cheader_filename = "glibtop/netload.h")]
        public static int WIRELESS;
    }
}
