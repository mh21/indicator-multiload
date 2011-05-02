[CCode (cprefix = "App", lower_case_cprefix = "app_", gir_namespace = "AppIndicator", gir_version = "0.1")]
namespace FixedAppIndicator {
	[CCode (type_check_function = "IS_APP_INDICATOR", cheader_filename = "libappindicator/app-indicator.h")]
	public class Indicator : GLib.Object {
		public AppIndicator.IndicatorPrivate priv;
		[CCode (has_construct_function = false)]
		public Indicator (string id, string icon_name, AppIndicator.IndicatorCategory category);
		public void build_menu_from_desktop (string desktop_file, string desktop_profile);
		public unowned string get_attention_icon ();
		public unowned string get_attention_icon_desc ();
		public AppIndicator.IndicatorCategory get_category ();
		public unowned string get_icon ();
		public unowned string get_icon_desc ();
		public unowned string get_icon_theme_path ();
		public unowned string get_id ();
		public unowned string get_label ();
		public unowned string get_label_guide ();
		public uint32 get_ordering_index ();
		public AppIndicator.IndicatorStatus get_status ();
		public void set_attention_icon (string icon_name);
		public void set_attention_icon_full (string icon_name, string icon_desc);
		public void set_icon (string icon_name);
		public void set_icon_full (string icon_name, string icon_desc);
		public void set_icon_theme_path (string icon_theme_path);
		public void set_label (string label, string guide);
		public void set_menu (Gtk.Menu menu);
		public void set_ordering_index (uint32 ordering_index);
		public void set_status (AppIndicator.IndicatorStatus status);
		[NoWrapper]
		public virtual void unfallback (Gtk.StatusIcon status_icon);
		[CCode (has_construct_function = false)]
		public Indicator.with_path (string id, string icon_name, AppIndicator.IndicatorCategory category, string icon_theme_path);
		public string attention_icon_desc { get; set; }
		[NoAccessorMethod]
		public string attention_icon_name { get; set; }
		public string category { get; construct; }
		[NoAccessorMethod]
		public bool connected { get; }
		public string icon_desc { get; set; }
		[NoAccessorMethod]
		public string icon_name { get; set; }
		public string icon_theme_path { get; set construct; }
		public string id { get; construct; }
		public string label { get; set; }
		public string label_guide { get; set; }
		public uint ordering_index { get; set; }
		public string status { get; set; }
		public virtual signal void connection_changed (bool indicator);
		public virtual signal void new_attention_icon ();
		public virtual signal void new_icon ();
		public virtual signal void new_icon_theme_path (string indicator);
		public virtual signal void new_label (string indicator, string label);
		public virtual signal void new_status (string indicator);
		public virtual signal void scroll_event (int indicator, uint delta);
	}
}
