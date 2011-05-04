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
    private Gtk.Builder builder;
    private MultiLoadIndicator multi;
    private FixedGSettings.Settings datasettings;
    private FixedGSettings.Settings prefsettings;
    private unowned Gtk.Window preferences;
    private unowned Gtk.AboutDialog about;
    private unowned Gtk.Menu menu;
    private Gtk.CheckButton*[] checkbuttons; // unowned
    private static const string autostartkey = "X-GNOME-Autostart-enabled";
    private static const string desktopfilename = "indicator-multiload.desktop";
    private string autostartfile = Path.build_filename(Environment.get_user_config_dir(),
            "autostart", desktopfilename);
    private string applicationfile = Path.build_filename("applications",
            desktopfilename);

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
        var screen = this.menu.get_screen(); // TODO: maybe this needs to be the default?
        if (info != null) {
            var context = new Gdk.AppLaunchContext();
            context.set_timestamp(Gtk.get_current_event_time());
            context.set_screen(screen);
            try {
                info.launch(null, context); // TODO: launches in background
            } catch (Error e) {
                stderr.printf("Could not launch system monitor: %s\n", e.message);
            }
        } else {
            try {
                Gdk.spawn_command_line_on_screen(screen, "gnome-system-monitor");
            } catch (Error e) {
                stderr.printf("Could not launch system monitor: %s\n", e.message);
            }
        }
    }

    [CCode (instance_pos = -1)]
    public void on_preferences_activate(Gtk.MenuItem source) {
        this.preferences.show_all();
    }

    [CCode (instance_pos = -1)]
    public void on_about_activate(Gtk.MenuItem source) {
        this.about.show_all();
    }

    [CCode (instance_pos = -1)]
    public void on_quit_activate(Gtk.MenuItem source) {
        this.release();
    }

    [CCode (instance_pos = -1)]
    public void on_checkbutton_toggled(Gtk.CheckButton source) {
        uint count = 0;
        foreach (unowned Gtk.CheckButton checkbutton in this.checkbuttons)
            count += (uint)checkbutton.active;
        if (count == 1)
            foreach (unowned Gtk.CheckButton checkbutton in this.checkbuttons)
                checkbutton.sensitive = !checkbutton.active;
        else
            foreach (unowned Gtk.CheckButton checkbutton in this.checkbuttons)
                checkbutton.sensitive = true;
    }

    public Main(string app_id, ApplicationFlags flags) {
        Object(application_id: app_id, flags: flags);
    }

    public override void activate() {
        // all the work is done in startup
    }

    public override void startup() {
        this.builder = new Gtk.Builder();

        string[] datadirs = { Config.PACKAGE_DATA_DIR };
        foreach (var datadir in Environment.get_system_data_dirs())
            datadirs += Path.build_filename(datadir, Config.PACKAGE_NAME);
        bool found = false;
        foreach (var datadir in datadirs) {
            try {
                this.builder.add_from_file(Path.build_filename(datadir, "preferences.ui"));
                found = true;
                break;
            } catch (Error e) {
                stderr.printf("Could not initialize indicator gui from %s: %s\n", datadir, e.message);
            }
        }
        if (!found)
            return;

        this.builder.connect_signals(this);

        this.preferences = this.builder.get_object("preferencesdialog") as Gtk.Window;
        this.about = this.builder.get_object("aboutdialog") as Gtk.AboutDialog;

        this.multi = new MultiLoadIndicator();
        this.multi.add_icon_data(new CpuIconData());
        this.multi.add_icon_data(new MemIconData());
        this.multi.add_icon_data(new NetIconData());
        this.multi.add_icon_data(new SwapIconData());
        this.multi.add_icon_data(new LoadIconData());
        this.multi.add_icon_data(new DiskIconData());

        this.datasettings = new FixedGSettings.Settings("de.mh21.indicator.multiload");
        foreach (unowned IconData icon_data in this.multi.icon_datas) {
            var id = icon_data.id;
            var length = icon_data.traces.length;
            for (uint j = 0, jsize = length; j < jsize; ++j)
                this.datasettings.bind_with_mapping(@"$id-color$j",
                        icon_data.traces[j], "color",
                        SettingsBindFlags.DEFAULT, get_settings_color, set_settings_color, null, () => {});
            this.datasettings.bind_with_mapping(@"$id-color$length",
                    icon_data, "color",
                    SettingsBindFlags.DEFAULT, get_settings_color, set_settings_color, null, () => {});
            this.datasettings.bind(@"view-$id",
                    icon_data, "enabled",
                    SettingsBindFlags.DEFAULT);
            this.datasettings.bind(@"$id-alpha$length",
                    icon_data, "alpha",
                    SettingsBindFlags.DEFAULT);
        }
        this.datasettings.bind("size",
                this.multi, "size",
                SettingsBindFlags.DEFAULT);
        this.datasettings.bind("speed",
                this.multi, "speed",
                SettingsBindFlags.DEFAULT);
        this.datasettings.bind("autostart",
                this, "autostart",
                SettingsBindFlags.DEFAULT);

        this.prefsettings = new FixedGSettings.Settings("de.mh21.indicator.multiload");
        foreach (unowned IconData icon_data in this.multi.icon_datas) {
            var id = icon_data.id;
            var length = icon_data.traces.length;
            for (uint j = 0, jsize = length; j < jsize; ++j)
                this.prefsettings.bind_with_mapping(@"$id-color$j",
                        this.builder.get_object(@"$(id)_color$j"), "color",
                        SettingsBindFlags.DEFAULT, get_settings_color, set_settings_color, null, () => {});
            this.prefsettings.bind_with_mapping(@"$id-color$length",
                    this.builder.get_object(@"$(id)_color$length"), "color",
                    SettingsBindFlags.DEFAULT, get_settings_color, set_settings_color, null, () => {});
            this.prefsettings.bind(@"view-$id",
                    this.builder.get_object(@"view_$id"), "active",
                    SettingsBindFlags.DEFAULT);
            this.prefsettings.bind(@"$id-alpha$length",
                    this.builder.get_object(@"$(id)_color$length"), "alpha",
                    SettingsBindFlags.DEFAULT);
        }

        this.prefsettings.bind("size",
                this.builder.get_object("size"), "value",
                SettingsBindFlags.DEFAULT);
        this.prefsettings.bind("speed",
                this.builder.get_object("speed"), "value",
                SettingsBindFlags.DEFAULT);
        this.prefsettings.bind("autostart",
                this.builder.get_object("autostart"), "active",
                SettingsBindFlags.DEFAULT);

        foreach (unowned IconData icon_data in this.multi.icon_datas)
            this.checkbuttons += this.builder.get_object(@"view_$(icon_data.id)") as Gtk.CheckButton;

        this.menu = this.builder.get_object("menu") as Gtk.Menu;
        this.multi.menu = this.menu;

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

        Gtk.init(ref args);
        Gtk.Window.set_default_icon_name("utilities-system-monitor");

        return new Main("de.mh21.indicator.multiload", ApplicationFlags.FLAGS_NONE).run(args);
    }
}
