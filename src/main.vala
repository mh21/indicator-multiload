/******************************************************************************
 * Copyright (C) 2011-2013  Michael Hofmann <mh21@mh21.de>                    *
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
    private static string datadirectory;
    [CCode (array_length=false, array_null_terminated = true)]
    private static string[] expressionoptions;
    private static bool versionoption;
    private static Reaper reaper;

    private Indicator multi;
    private Gtk.Dialog about;
    private Preferences preferences;
    private AdvancedPreferences advancedpreferences;
    private ItemPreferences menupreferences;
    private ItemPreferences indicatorpreferences;
    private ItemHelp itemhelp;
    private SettingsCache settingscache;
    private ColorMapper colormapper;
    private string autostartkey;
    private string desktopfilename;
    private string autostartfile;
    private string applicationfile;
    private string graphsetups;

    const OptionEntry[] options = {
        { "version", 0, 0, OptionArg.NONE,
            ref versionoption, N_("Output version information and exit"), null },
        { "evaluate-expression", 'e', 0, OptionArg.STRING_ARRAY,
            ref expressionoptions, N_("Evaluate an expression"), null },
        { null }
    };

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
        var settings = this.settingscache.generalsettings();
        var sysmon = settings.get_string("system-monitor");
        if (sysmon.length == 0) {
            if (Environment.get_variable("XDG_CURRENT_DESKTOP") == "KDE" ||
                Environment.get_variable("DESKTOP_SESSION") == "kde-plasma") {
                sysmon = "kde4-ksysguard.desktop";
            } else {
                sysmon = "gnome-system-monitor.desktop";
            }
        }
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

    private void creategraphs(Settings? settings, string key) {
        // For some reason, directly after converting settings v1->v2, this is
        // called a lot. Recreating the graphs is expensive, so check whether
        // it is really necessary.
        string newgraphsetups = "";
        foreach (var graphid in this.settingscache.generalsettings().get_strv("graphs"))
            newgraphsetups += "%s=%s\n".printf(graphid, string.joinv(",",
                        this.settingscache.graphsettings(graphid).get_strv("traces")));
        if (this.graphsetups == newgraphsetups)
            return;
        this.graphsetups = newgraphsetups;

        var datasettings = this.settingscache.generalsettings();

        this.multi.graphmodels = new GraphModels(datasettings.get_strv("graphs"), this.multi.providers);

        // dconf binds: will overwrite the old binds
        foreach (var graphmodel in this.multi.graphmodels.graphmodels)
            this.addgraphbinds(graphmodel);

        // dconf notifications for graph/trace creation
        foreach (var cachedsetting in this.settingscache.cachedsettings())
            SignalHandler.disconnect_by_func(cachedsetting,
                    (void*) Main.creategraphs, this);
        datasettings.changed["graphs"].connect(this.creategraphs);
        foreach (var graphmodel in this.multi.graphmodels.graphmodels) {
            var graphsettings = this.settingscache.graphsettings(graphmodel.id);
            graphsettings.changed["traces"].connect(this.creategraphs);
        }
    }

    private void addgraphbinds(GraphModel graphmodel) {
        var graphid = graphmodel.id;
        var graphsettings = this.settingscache.graphsettings(graphid);
        graphsettings.bind("minimum", graphmodel.minimum, "expression",
                SettingsBindFlags.DEFAULT);
        graphsettings.bind("maximum", graphmodel.maximum, "expression",
                SettingsBindFlags.DEFAULT);
        string[] graphproperties = {
            "enabled",
            "smooth",
            "traces" };
        foreach (var property in graphproperties)
            graphsettings.bind(property, graphmodel, property,
                    SettingsBindFlags.DEFAULT);

        var traceids = graphmodel.traces;
        var tracemodels = graphmodel.tracemodels;
        for (uint i = 0, isize = traceids.length; i < isize; ++i)
            this.addtracebinds(tracemodels[i], graphid, traceids[i]);
    }

    private void addtracebinds(TraceModel tracemodel,
            string graphid, string traceid) {
        var tracesettings = this.settingscache.tracesettings(graphid, traceid);
        PGLib.settings_bind_with_mapping(tracesettings, "color",
                tracemodel, "rgba",
                SettingsBindFlags.DEFAULT,
                Utils.get_settings_rgba,
                (PGLib.SettingsBindSetMapping)Utils.set_settings_rgba,
                null, () => {});
        tracesettings.bind("enabled", tracemodel, "enabled",
                SettingsBindFlags.DEFAULT);
        tracesettings.bind("expression", tracemodel.expression, "expression",
                SettingsBindFlags.DEFAULT);
    }

    public override void activate() {
        // all the work is done in startup
    }

    public override void startup() {
        var icondirectory = Path.build_filename(datadirectory, "icons");
        var menu = Utils.get_ui("menu", this) as Gtk.Menu;
        this.multi = new Indicator(icondirectory, new Providers(), menu);

        this.colormapper = new ColorMapper();
        this.settingscache = new SettingsCache();

        new SettingsConversion().convert();

        // initialize indicator, won't update before speed is set; order is
        // important here
        this.creategraphs(null, "");

        var datasettings = this.settingscache.generalsettings();
        datasettings.bind("menu-expressions",
                this.multi.menumodel, "expressions",
                SettingsBindFlags.DEFAULT);
        datasettings.bind("indicator-expressions",
                this.multi.labelmodel, "expressions",
                SettingsBindFlags.DEFAULT);
        datasettings.bind("description-expressions",
                this.multi.descriptionmodel, "expressions",
                SettingsBindFlags.DEFAULT);
        datasettings.bind("indicator-expression-index",
                this.multi, "indicator-index",
                SettingsBindFlags.DEFAULT);
        datasettings.bind("width",
                this.multi, "width",
                SettingsBindFlags.DEFAULT);
        datasettings.bind("height",
                this.multi, "height",
                SettingsBindFlags.DEFAULT);
        PGLib.settings_bind_with_mapping(datasettings, "background-color",
                this.multi, "background-rgba",
                SettingsBindFlags.DEFAULT,
                Utils.get_settings_rgba,
                (PGLib.SettingsBindSetMapping)Utils.set_settings_rgba,
                null, () => {});
        datasettings.bind("autostart",
                this, "autostart",
                SettingsBindFlags.DEFAULT);
        datasettings.bind("color-scheme",
                this.colormapper, "color-scheme",
                SettingsBindFlags.DEFAULT);
        // should be the last one as it initializes the timer
        datasettings.bind("speed",
                this.multi, "speed",
                SettingsBindFlags.DEFAULT);

        this.multi.updateall();

        this.itemhelp = new ItemHelp(this.multi);

        this.advancedpreferences = new AdvancedPreferences(this.colormapper);
        this.advancedpreferences.itemhelp_show.connect(this.itemhelp.show);

        this.menupreferences = new ItemPreferences("menu-expressions");
        this.menupreferences.itemhelp_show.connect(this.itemhelp.show);

        this.indicatorpreferences = new ItemPreferences("indicator-expressions");
        this.indicatorpreferences.itemhelp_show.connect(this.itemhelp.show);

        this.preferences = new Preferences(this.colormapper);
        this.preferences.advancedpreferences_show.connect(this.advancedpreferences.show);
        this.preferences.menupreferences_show.connect(this.menupreferences.show);
        this.preferences.indicatorpreferences_show.connect(this.indicatorpreferences.show);

        this.advancedpreferences.colorscheme_restore.connect(this.preferences.restore_colorscheme);

        this.multi.providers_updated.connect(this.itemhelp.update);

        this.hold();

        Gdk.notify_startup_complete();

        base.startup();
    }

    public override int command_line(GLib.ApplicationCommandLine command_line) {
        // no command line processing in primary instance
        return 0;
    }

    public override bool local_command_line
        ([CCode (array_null_terminated = true, array_length = false)]
         ref unowned string[] arguments,
         out int exit_status) {
        try {
            OptionGroup group = new OptionGroup("", "", "", this);
            group.add_entries(options);
            var context = new OptionContext (_("- System load application indicator"));
            context.set_help_enabled(true);
            context.set_main_group((owned) group);
            context.add_group(Gtk.get_option_group(true));
            unowned string[] local_args = arguments;
            context.parse(ref local_args);
        } catch (OptionError e) {
            stdout.printf("%s\n", e.message);
            stdout.printf(_("Run '%s --help' to see a full list of available command line options.\n"), arguments[0]);
            exit_status = 1;
            return true;
        }

        exit_status = 0;
        bool result = false;

        if (versionoption) {
            var about = Utils.get_ui("aboutdialog", this) as Gtk.AboutDialog;
            try {
            stdout.printf("%s %s\n%s\n%s\n\n%s\n",
                    about.get_program_name(),
                    about.get_version(),
                    about.get_copyright(),
                    new Regex("</?a[^>]*>").replace(about.get_license(), -1, 0, ""),
                    about.get_website());
            } catch (RegexError e) {
                // ignored
            }
            result = true;
        }

        foreach (var expressionoption in expressionoptions) {
            var cache = new ExpressionCache(new Providers(), expressionoption);
            stdout.printf("Original: %s\n", expressionoption);
            stdout.printf("Tokens: '%s'\n", string.joinv("' '", cache.tokens()));
            stdout.printf("Result: %s\n", cache.label());
            stdout.printf("Guide: %s\n", cache.guide());
            result = true;
        }

        return result;
    }

    ~Main() {
        if (multi != null)
            this.multi.destroy();
    }

    public static int main(string[] args) {
        Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.PACKAGE_LOCALE_DIR);
        Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain(Config.GETTEXT_PACKAGE);

        var directory = Environment.get_variable("XDG_RUNTIME_DIR");
        if (directory == null || directory.length == 0) {
            directory = "/var/lock";
        }
        Main.datadirectory = DirUtils.mkdtemp(directory + "/multiload-icons-XXXXXX");

        Gtk.init(ref args);
        Gtk.Window.set_default_icon_name("utilities-system-monitor");

        Main.reaper = new Reaper(args);

        var result = new Main("de.mh21.indicator-multiload",
                ApplicationFlags.FLAGS_NONE).run(args);

        DirUtils.remove(Main.datadirectory);

        return result;
    }
}
