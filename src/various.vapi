[CCode (cname="g_get_monotonic_time", cheader_filename = "glib.h")]
uint64 get_monotonic_time();
[CCode (cname = "g_strndup", cheader_filename = "glib.h")]
string strndup(char* str, size_t n);

// most of this is in vala git, but not in vala <= 0.16

[CCode (cheader_filename = "unistd.h")]
int execvp(string path, [CCode (array_length = false, null_terminated = true)] string[] arg);

[CCode (cprefix = "Gtk", lower_case_cprefix = "gtk_")]
namespace PGtk {
    public class ColorChooser {
        public void add_palette(Gtk.Orientation orientation, int colors_per_line, [CCode (array_length_pos = 2.9)] Gdk.RGBA[]? colors);
    }
}

[CCode (cprefix = "G", lower_case_cprefix = "g_")]
namespace PGLib {
    [CCode (has_target = false)]
    public delegate bool SettingsBindGetMapping(GLib.Value value, GLib.Variant variant, void *user_data);
    [CCode (has_target = false)]
    public delegate GLib.Variant SettingsBindSetMapping(GLib.Value value, GLib.VariantType expected_type, void *user_data);
    public static void settings_bind_with_mapping(GLib.Settings settings, string key, void* object, string property, GLib.SettingsBindFlags flags, SettingsBindGetMapping get_mapping, SettingsBindSetMapping set_mapping, void *user_data, GLib.DestroyNotify destroy);
}
