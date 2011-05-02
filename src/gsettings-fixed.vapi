[CCode (cprefix = "G", lower_case_cprefix = "g_", gir_namespace = "Gio", gir_version = "2.0")]
namespace FixedGSettings {
        [CCode (cheader_filename = "gio/gio.h")]
        public class Settings : GLib.Object {
                [CCode (has_construct_function = false)]
                public Settings (string schema);
                public void apply ();
                public void bind (string key, void* object, string property, GLib.SettingsBindFlags flags);
                public void bind_with_mapping (string key, void* object, string property, GLib.SettingsBindFlags flags,  FixedGSettings.SettingsBindGetMapping get_mapping,  FixedGSettings.SettingsBindSetMapping set_mapping, void *user_data, GLib.DestroyNotify destroy);
                public void bind_writable (string key, void* object, string property, bool inverted);
                public void delay ();
                [CCode (sentinel = "")]
                public void @get (string key, string format, ...);
                public bool get_boolean (string key);
                public unowned GLib.Settings get_child (string name);
                public double get_double (string key);
                public int get_enum (string key);
                public uint get_flags (string key);
                public bool get_has_unapplied ();
                public int get_int (string key);
                public void* get_mapped (string key, GLib.SettingsGetMapping mapping);
                public unowned GLib.Variant get_range (string key);
                public string get_string (string key);
                [CCode (array_length = false, array_null_terminated = true)]
                public string[] get_strv (string key);
                public GLib.Variant get_value (string key);
                public bool is_writable (string name);
                [CCode (array_length = false, array_null_terminated = true)]
                public string[] list_children ();
                [CCode (array_length = false, array_null_terminated = true)]
                public string[] list_keys ();
                public static unowned string list_relocatable_schemas ();
                [CCode (array_length = false, array_null_terminated = true)]
                public static unowned string[] list_schemas ();
                public bool range_check (string key, GLib.Variant value);
                public void reset (string key);
                public void revert ();
                [CCode (sentinel = "")]
                public bool @set (string key, string format, ...);
                public bool set_boolean (string key, bool value);
                public bool set_double (string key, double value);
                public bool set_enum (string key, int value);
                public bool set_flags (string key, uint value);
                public bool set_int (string key, int value);
                public bool set_string (string key, string value);
                public bool set_strv (string key, [CCode (array_length = false)] string[] value);
                public bool set_value (string key, GLib.Variant value);
                public static void sync ();
                public static void unbind (void* object, string property);
                [CCode (has_construct_function = false)]
                public Settings.with_backend (string schema, GLib.SettingsBackend backend);
                [CCode (has_construct_function = false)]
                public Settings.with_backend_and_path (string schema, GLib.SettingsBackend backend, string path);
                [CCode (has_construct_function = false)]
                public Settings.with_path (string schema, string path);
                [NoAccessorMethod]
                public GLib.SettingsBackend backend { owned get; construct; }
                [NoAccessorMethod]
                public bool delay_apply { get; }
                public bool has_unapplied { get; }
                [NoAccessorMethod]
                public string path { owned get; construct; }
                [NoAccessorMethod]
                public string schema { owned get; construct; }
                public virtual signal bool change_event (void* keys, int n_keys);
                public virtual signal void changed (string key);
                public virtual signal bool writable_change_event (uint key);
                public virtual signal void writable_changed (string key);
        }
        [CCode (cheader_filename = "gio/gio.h", has_target = false)]
        public delegate bool SettingsBindGetMapping (GLib.Value value, GLib.Variant variant, void *user_data);
        [CCode (cheader_filename = "gio/gio.h", has_target = false)]
        public delegate GLib.Variant SettingsBindSetMapping (GLib.Value value, GLib.VariantType expected_type, void *user_data);

}
