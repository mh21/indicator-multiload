/******************************************************************************
 * Copyright (C) 2011  Michael Hofmann <mh21@piware.de>                       *
 *                                                                            *
 * This program is free software; you can redistribute it and/or modify       *
 * it under the terms of the GNU General Public License as published by       *
 * the Free Software Foundation; either version 3 of the License, or          *
 * (at your option) any later version.                                        *
 *                                                                            *
 * This program is distributed in the hope that it will be useful,            *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of             *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *
 * GNU General Public License for more details.                               *
 *                                                                            *
 * You should have received a copy of the GNU General Public License along    *
 * with this program; if not, write to the Free Software Foundation, Inc.,    *
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.                *
 ******************************************************************************/

public bool get_settings_color(Value value, Variant variant, void *user_data)
{
    Gdk.Color color;
    if (Gdk.Color.parse(variant.get_string(), out color)) {
        value.set_boxed(&color);
        return true;
    }
    return false;
}

public Variant set_settings_color(Value value, VariantType expected_type, void *user_data)
{
    Gdk.Color color = *(Gdk.Color*)value.get_boxed();
    return new Variant.string(color.to_string());
}

public class Main : Application {
    private MultiLoadIndicator multi;
    private Gtk.Dialog about;
    private Gtk.Dialog preferences;
    private Gtk.CheckButton[] checkbuttons;
    private static string datadirectory;
    private string gsettings;
    private string autostartkey;
    private string desktopfilename;
    private string autostartfile;
    private string applicationfile;
    private string uifile;

    public bool autostart {
        get {
            KeyFile file = new KeyFile();
            try {
                file.load_from_file(this.autostartfile, KeyFileFlags.NONE);
            } catch (Error e) {
                return false;
            }
            try {
                return file.get_boolean(KeyFileDesktop.GROUP, autostartkey);
            } catch (Error e) {
                return true;
            }
        }

        set {
            KeyFile file = new KeyFile();
            try {
                file.load_from_file(this.autostartfile, KeyFileFlags.KEEP_COMMENTS |
                        KeyFileFlags.KEEP_TRANSLATIONS);
            } catch (Error e) {
                try {
                    file.load_from_data_dirs(this.applicationfile, null, KeyFileFlags.KEEP_COMMENTS |
                            KeyFileFlags.KEEP_TRANSLATIONS);
                } catch (Error e) {
                    // TODO: nicer defaults: icon, name, description
                    file.set_string(KeyFileDesktop.GROUP, KeyFileDesktop.KEY_TYPE, "Application");
                    file.set_string(KeyFileDesktop.GROUP, KeyFileDesktop.KEY_NAME, "indicator-multiload");
                    file.set_string(KeyFileDesktop.GROUP, KeyFileDesktop.KEY_EXEC, "indicator-multiload");
                }
            }
            file.set_boolean(KeyFileDesktop.GROUP, autostartkey, value);
            try {
                FileUtils.set_contents(this.autostartfile, file.to_data());
            } catch (Error e) {
                stderr.printf("Could not create autostart desktop file: %s\n", e.message);
            }
        }
    }

    [CCode (instance_pos = -1)]
    public void on_sysmon_activate(Gtk.MenuItem source) {
        var settings = new FixedGSettings.Settings("de.mh21.indicator.multiload");
        var sysmon = settings.get_string("system-monitor");
        if (sysmon.length == 0)
            sysmon = "gnome-system-monitor.desktop";
        var info = new DesktopAppInfo(sysmon);
        if (info != null) {
            try {
                info.launch(null, null);
            } catch (Error e) {
                stderr.printf("Could not launch system monitor: %s\n", e.message);
            }
        } else {
            try {
                Process.spawn_command_line_async("gnome-system-monitor");
            } catch (Error e) {
                stderr.printf("Could not launch system monitor: %s\n", e.message);
            }
        }
    }

    [CCode (instance_pos = -1)]
    public void on_preferences_activate(Gtk.MenuItem source) {
        if (this.preferences != null) {
            this.preferences.present();
            return;
        }

        Gtk.Builder builder;
        this.preferences = get_ui("preferencesdialog", {"sizeadjustment",
                "speedadjustment"}, out builder) as Gtk.Dialog;
        return_if_fail(this.preferences != null);

        foreach (var icon_data in this.multi.icon_datas)
            this.checkbuttons += builder.get_object(@"view_$(icon_data.id)") as Gtk.CheckButton;

        var prefsettings = new FixedGSettings.Settings("de.mh21.indicator.multiload");
        foreach (var icon_data in this.multi.icon_datas) {
            var id = icon_data.id;
            var length = icon_data.traces.length;
            for (uint j = 0, jsize = length; j < jsize; ++j)
                prefsettings.bind_with_mapping(@"$id-color$j",
                        builder.get_object(@"$(id)_color$j"), "color",
                        SettingsBindFlags.DEFAULT, get_settings_color, set_settings_color, null, () => {});
            prefsettings.bind_with_mapping(@"$id-color$length",
                    builder.get_object(@"$(id)_color$length"), "color",
                    SettingsBindFlags.DEFAULT, get_settings_color, set_settings_color, null, () => {});
            prefsettings.bind(@"view-$id",
                    builder.get_object(@"view_$id"), "active",
                    SettingsBindFlags.DEFAULT);
            prefsettings.bind(@"$id-alpha$length",
                    builder.get_object(@"$(id)_color$length"), "alpha",
                    SettingsBindFlags.DEFAULT);
        }

        prefsettings.bind("size",
                builder.get_object("size"), "value",
                SettingsBindFlags.DEFAULT);
        prefsettings.bind("speed",
                builder.get_object("speed"), "value",
                SettingsBindFlags.DEFAULT);
        prefsettings.bind("autostart",
                builder.get_object("autostart"), "active",
                SettingsBindFlags.DEFAULT);

        this.preferences.show_all();
    }

    [CCode (instance_pos = -1)]
    public void on_about_activate(Gtk.MenuItem source) {
        if (this.about != null) {
            this.about.present();
            return;
        }

        this.about = get_ui("aboutdialog") as Gtk.Dialog;
        return_if_fail(this.about != null);

        this.about.show_all();
    }

    [CCode (instance_pos = -1)]
    public void on_quit_activate(Gtk.MenuItem source) {
        this.release();
    }

    [CCode (instance_pos = -1)]
    public void on_checkbutton_toggled(Gtk.CheckButton source) {
        uint count = 0;
        foreach (var checkbutton in this.checkbuttons)
            count += (uint)checkbutton.active;
        if (count == 1)
            foreach (var checkbutton in this.checkbuttons)
                checkbutton.sensitive = !checkbutton.active;
        else
            foreach (var checkbutton in this.checkbuttons)
                checkbutton.sensitive = true;
    }

    [CCode (instance_pos = -1)]
    public void on_aboutdialog_destroy(Gtk.Widget source) {
        this.about = null;
    }

    [CCode (instance_pos = -1)]
    public void on_preferencesdialog_destroy(Gtk.Widget source) {
        this.preferences = null;
        this.checkbuttons = null;
    }

    public Main(string app_id, ApplicationFlags flags) {
        Object(application_id: app_id, flags: flags);

        this.gsettings = "de.mh21.indicator.multiload";
        this.autostartkey = "X-GNOME-Autostart-enabled";
        this.desktopfilename = "indicator-multiload.desktop";
        this.autostartfile = Path.build_filename(Environment.get_user_config_dir(),
                "autostart", desktopfilename);
        this.applicationfile = Path.build_filename("applications",
                desktopfilename);

        string[] datadirs = { Config.PACKAGE_DATA_DIR };
        foreach (var datadir in Environment.get_system_data_dirs())
            datadirs += Path.build_filename(datadir, Config.PACKAGE_NAME);
        foreach (var datadir in datadirs) {
            var uifile = Path.build_filename(datadir, "preferences.ui");
            stderr.printf("%s\n", uifile);
            if (!FileUtils.test(uifile, FileTest.IS_REGULAR))
                continue;
            this.uifile = uifile;
            break;
        }
    }

    private Object get_ui(string object_id, string[] additional = {},
            out Gtk.Builder builder = null) {
        builder = new Gtk.Builder();
        string[] ids = additional;
        ids += object_id;
        try {
            builder.add_objects_from_file(this.uifile, ids);
        } catch (Error e) {
            stderr.printf("Could not load indicator ui %s from %s: %s\n",
                    object_id, this.uifile, e.message);
        }
        builder.connect_signals(this);
        return builder.get_object(object_id);
    }

    public override void activate() {
        // all the work is done in startup
    }

    public override void startup() {
        this.multi = new MultiLoadIndicator(datadirectory);
        this.multi.add_icon_data(new CpuIconData());
        this.multi.add_icon_data(new MemIconData());
        this.multi.add_icon_data(new NetIconData());
        this.multi.add_icon_data(new SwapIconData());
        this.multi.add_icon_data(new LoadIconData());
        this.multi.add_icon_data(new DiskIconData());

        var datasettings = new FixedGSettings.Settings("de.mh21.indicator.multiload");
        foreach (var icon_data in this.multi.icon_datas) {
            var id = icon_data.id;
            var length = icon_data.traces.length;
            for (uint j = 0, jsize = length; j < jsize; ++j)
                datasettings.bind_with_mapping(@"$id-color$j",
                        icon_data.traces[j], "color",
                        SettingsBindFlags.DEFAULT, get_settings_color, set_settings_color, null, () => {});
            datasettings.bind_with_mapping(@"$id-color$length",
                    icon_data, "color",
                    SettingsBindFlags.DEFAULT, get_settings_color, set_settings_color, null, () => {});
            datasettings.bind(@"view-$id",
                    icon_data, "enabled",
                    SettingsBindFlags.DEFAULT);
            datasettings.bind(@"$id-alpha$length",
                    icon_data, "alpha",
                    SettingsBindFlags.DEFAULT);
        }
        datasettings.bind("size",
                this.multi, "size",
                SettingsBindFlags.DEFAULT);
        datasettings.bind("height",
                this.multi, "height",
                SettingsBindFlags.DEFAULT);
        datasettings.bind("speed",
                this.multi, "speed",
                SettingsBindFlags.DEFAULT);
        datasettings.bind("autostart",
                this, "autostart",
                SettingsBindFlags.DEFAULT);

        var menu = get_ui("menu") as Gtk.Menu;
        return_if_fail(menu != null);
        this.multi.menu = menu;

        this.hold();

        Gdk.notify_startup_complete();
    }

    ~Main() {
        if (multi != null)
            this.multi.destroy();
    }

    public static int main(string[] args) {
        Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.PACKAGE_LOCALE_DIR);
        Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain(Config.GETTEXT_PACKAGE);

        // This needs to happen before get_system_data_dirs is called the first time
        var template = "/var/lock/multiload-icons-XXXXXX".dup();
        Main.datadirectory = DirUtils.mkdtemp(template);
        var xdgdatadirs = Environment.get_variable("XDG_DATA_DIRS");
        if (xdgdatadirs.length > 0)
            xdgdatadirs += ":";
        Environment.set_variable("XDG_DATA_DIRS",
                xdgdatadirs + Main.datadirectory, true);

        Gtk.init(ref args);
        Gtk.Window.set_default_icon_name("utilities-system-monitor");

        var result = new Main("de.mh21.indicator.multiload", ApplicationFlags.FLAGS_NONE).run(args);

        DirUtils.remove(Main.datadirectory);

        return result;
    }
}
