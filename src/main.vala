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

public class Main : Application {
    private MultiLoadIndicator multi;
    private Gtk.Dialog about;
    private Preferences preferences;
    private FixedGSettings.Settings[] creationnotifiers;
    private static string datadirectory;
    private string gsettings;
    private string autostartkey;
    private string desktopfilename;
    private string autostartfile;
    private string applicationfile;

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
                file.load_from_file(this.autostartfile,
                        KeyFileFlags.KEEP_COMMENTS |
                        KeyFileFlags.KEEP_TRANSLATIONS);
            } catch (Error e) {
                try {
                    file.load_from_data_dirs(this.applicationfile, null,
                            KeyFileFlags.KEEP_COMMENTS |
                            KeyFileFlags.KEEP_TRANSLATIONS);
                } catch (Error e) {
                    file.set_string(KeyFileDesktop.GROUP,
                            KeyFileDesktop.KEY_TYPE, "Application");
                    file.set_string(KeyFileDesktop.GROUP,
                            KeyFileDesktop.KEY_NAME, "indicator-multiload");
                    file.set_string(KeyFileDesktop.GROUP,
                            KeyFileDesktop.KEY_EXEC, "indicator-multiload");
                }
            }
            file.set_boolean(KeyFileDesktop.GROUP, autostartkey, value);
            try {
                DirUtils.create(Path.build_filename
                        (Environment.get_user_config_dir(), "autostart"),
                        0777);
                FileUtils.set_contents(this.autostartfile, file.to_data());
            } catch (Error e) {
                stderr.printf("Could not create autostart desktop file: %s\n",
                        e.message);
            }
        }
    }

    [CCode (instance_pos = -1)]
    public void on_sysmon_activate(Gtk.MenuItem source) {
        var settings = Utils.globalsettings();
        var sysmon = settings.get_string("system-monitor");
        if (sysmon.length == 0)
            sysmon = "gnome-system-monitor.desktop";
        var info = new DesktopAppInfo(sysmon);
        if (info != null) {
            try {
                info.launch(null, null);
            } catch (Error e) {
                stderr.printf("Could not launch system monitor: %s\n",
                        e.message);
            }
        } else {
            try {
                Process.spawn_command_line_async("gnome-system-monitor");
            } catch (Error e) {
                stderr.printf("Could not launch system monitor: %s\n",
                        e.message);
            }
        }
    }

    [CCode (instance_pos = -1)]
    public void on_preferences_activate(Gtk.MenuItem source) {
        this.preferences.show();
    }

    [CCode (instance_pos = -1)]
    public void on_about_activate(Gtk.MenuItem source) {
        if (this.about != null) {
            this.about.present();
            return;
        }

        this.about = Utils.get_ui("aboutdialog", this) as Gtk.Dialog;
        return_if_fail(this.about != null);

        this.about.show_all();
    }

    [CCode (instance_pos = -1)]
    public void on_quit_activate(Gtk.MenuItem source) {
        this.release();
    }

    [CCode (instance_pos = -1)]
    public void on_aboutdialog_destroy(Gtk.Widget source) {
        this.about = null;
    }

    public Main(string app_id, ApplicationFlags flags) {
        Object(application_id: app_id, flags: flags);

        this.gsettings = "de.mh21.indicator.multiload";
        this.autostartkey = "X-GNOME-Autostart-enabled";
        this.desktopfilename = "indicator-multiload.desktop";
        this.autostartfile = Path.build_filename
            (Environment.get_user_config_dir(),
             "autostart", desktopfilename);
        this.applicationfile = Path.build_filename("applications",
                desktopfilename);

        string[] datadirs = { Config.PACKAGE_DATA_DIR };
        foreach (var datadir in Environment.get_system_data_dirs())
            datadirs += Path.build_filename(datadir, Config.PACKAGE_NAME);
        foreach (var datadir in datadirs) {
            var uifile = Path.build_filename(datadir, "preferences.ui");
            if (!FileUtils.test(uifile, FileTest.IS_REGULAR))
                continue;
            Utils.uifile = uifile;
            break;
        }
    }

    private void creategraphs() {
        var datasettings = Utils.globalsettings();

        GraphData[] graphdatas = null;
        foreach (var graphid in datasettings.get_strv("graphs"))
            graphdatas += new GraphData(graphid);
        this.multi.graphdatas = graphdatas;

        // dconf binds: will overwrite the old binds
        foreach (var graphdata in this.multi.graphdatas)
            this.addgraphbinds(graphdata);

        // dconf notifications for graph/trace creation
        foreach (var creationnotifier in this.creationnotifiers)
            SignalHandler.disconnect_by_func(creationnotifier, 
                    (void*) Main.creategraphs, this);
        this.creationnotifiers = { datasettings };
        datasettings.changed["graphs"].connect(this.creategraphs);
        foreach (var graphdata in this.multi.graphdatas) {
            var graphsettings = Utils.graphsettings(graphdata.id);
            this.creationnotifiers += graphsettings;
            graphsettings.changed["traces"].connect(this.creategraphs);
        }
    }

    private void addgraphbinds(GraphData graphdata) {
        var graphid = graphdata.id;
        var graphsettings = Utils.graphsettings(graphid);
        graphsettings.bind_with_mapping("background-color",
                graphdata, "background_color",
                SettingsBindFlags.DEFAULT, 
                Utils.get_settings_color, 
                Utils.set_settings_color, 
                null, () => {});
        string[] graphproperties = {
            "enabled", 
            "minimum", 
            "maximum", 
            "smooth", 
            "alpha", 
            "traces" };
        foreach (var property in graphproperties)
            graphsettings.bind(property, graphdata, property,
                    SettingsBindFlags.DEFAULT);

        var traceids = graphdata.traces;
        var tracedatas = graphdata.tracedatas;
        for (uint i = 0, isize = traceids.length; i < isize; ++i)
            this.addtracebinds(tracedatas[i], graphid, traceids[i]);
    }

    private void addtracebinds(TraceData tracedata, 
            string graphid, string traceid) {
        var tracesettings = Utils.tracesettings(graphid, traceid);
        tracesettings.bind_with_mapping("color",
                tracedata, "color",
                SettingsBindFlags.DEFAULT, 
                Utils.get_settings_color, 
                Utils.set_settings_color, 
                null, () => {});
        string[] traceproperties = {"enabled", "expression"};
        foreach (var property in traceproperties)
            tracesettings.bind(property, tracedata, property,
                    SettingsBindFlags.DEFAULT);
    }

    public override void activate() {
        // all the work is done in startup
    }

    public override void startup() {
        this.multi = new MultiLoadIndicator(datadirectory, {
                new CpuData(), new MemData(), new NetData(),
                new SwapData(), new LoadData(), new DiskData()
        });
        var datasettings = Utils.globalsettings();

        datasettings.bind("size",
                this.multi, "size",
                SettingsBindFlags.DEFAULT);
        datasettings.bind("menu-expressions",
                this.multi.menudata, "expressions",
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

        this.creategraphs();

        var menu = Utils.get_ui("menu", this) as Gtk.Menu;
        return_if_fail(menu != null);
        this.multi.menu = menu;

        this.preferences = new Preferences();

        this.hold();

        Gdk.notify_startup_complete();
    }

    ~Main() {
        if (multi != null)
            this.multi.destroy();
    }

    public static int main(string[] args) {
        // Data[] datas = { new CpuData(), new MemData(), new NetData(),
        //         new SwapData(), new LoadData(), new DiskData() };
        // foreach (var data in datas)
        //     data.update();
        // var parser = new ExpressionParser(datas);
        // var tokens = parser.tokenize(args[1]);
        // stdout.printf("Original: %s\n", args[1]);
        // stdout.printf("Tokens:");
        // foreach (var token in tokens)
        //     stdout.printf(" '%s'", token);
        // stdout.printf("\n");
        // stdout.printf("Result: %s\n", parser.evaluate(tokens));
        // return 1;

        Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.PACKAGE_LOCALE_DIR);
        Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain(Config.GETTEXT_PACKAGE);

        // needs to happen before get_system_data_dirs is called the first time
        var template = "/var/lock/multiload-icons-XXXXXX".dup();
        Main.datadirectory = DirUtils.mkdtemp(template);
        var xdgdatadirs = Environment.get_variable("XDG_DATA_DIRS");
        if (xdgdatadirs.length > 0)
            xdgdatadirs += ":";
        Environment.set_variable("XDG_DATA_DIRS",
                xdgdatadirs + Main.datadirectory, true);

        Gtk.init(ref args);
        Gtk.Window.set_default_icon_name("utilities-system-monitor");

        var result = new Main("de.mh21.indicator.multiload",
                ApplicationFlags.FLAGS_NONE).run(args);

        DirUtils.remove(Main.datadirectory);

        return result;
    }
}
