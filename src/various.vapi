[CCode (cname="g_get_monotonic_time", cheader_filename = "glib.h")]
uint64 get_monotonic_time();
[CCode (cname = "g_strndup", cheader_filename = "glib.h")]
string strndup(char* str, size_t n);

// this is in vala git, but not in vala <= 0.16
[CCode (cheader_filename = "unistd.h")]
int execvp(string path, [CCode (array_length = false, null_terminated = true)] string[] arg);

// this is mostly in vala git, but not in vala <= 0.16
[CCode (cprefix = "Gtk", lower_case_cprefix = "gtk_")]
namespace P {
    public class ColorChooser {
	[CCode (cname = "gtk_color_chooser_add_palette")]
	private void _add_palette(Gtk.Orientation orientation, int colors_per_line, int n, Gdk.RGBA* colors);
	[CCode (cname = "gtk_color_chooser_add_palette_vala")]
	public void add_palette(Gtk.Orientation orientation, int colors_per_line, Gdk.RGBA[] colors) {
	    _add_palette(orientation, colors_per_line, colors.length, colors);
	}
	public void clear_palette() {
	    _add_palette(Gtk.Orientation.HORIZONTAL, 0, 0, null);
	}
    }
}
