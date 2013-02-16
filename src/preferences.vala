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

public class Preferences : Object {
    private Gtk.Dialog preferences;
    private ItemPreferences menupreferences;
    private ItemPreferences indicatorpreferences;
    private ColorMapper colormapper;

    public Preferences(ColorMapper colormapper)
    {
        this.colormapper = colormapper;
    }

    construct {
        this.menupreferences = new ItemPreferences("menu-expressions");
        this.indicatorpreferences = new ItemPreferences("indicator-expressions");
    }

    public void show() {
        if (this.preferences != null) {
            this.preferences.present();
            return;
        }

        Gtk.Builder builder;
        this.preferences = Utils.get_ui("preferencesdialog", this,
                {"widthadjustment", "speedadjustment", "schemestore"},
                out builder) as Gtk.Dialog;
        return_if_fail(this.preferences != null);

        var settingscache = new SettingsCache();
        var prefsettings = settingscache.generalsettings();
        var graphids = prefsettings.get_strv("graphs");

        foreach (var graphid in graphids) {
            if (!(graphid in SettingsCache.presetgraphids))
                continue;

            var graphsettings = settingscache.graphsettings(graphid);
            var traceids = graphsettings.get_strv("traces");
            for (uint j = 0, jsize = traceids.length; j < jsize; ++j) {
                var traceid = traceids[j];
                var tracesettings = settingscache.tracesettings(graphid, traceid);
                tracesettings.bind_with_mapping("color",
                        builder.get_object(@"$(traceid)_color"), "rgba",
                        SettingsBindFlags.DEFAULT,
                        Utils.get_settings_rgba,
                        Utils.set_settings_rgba,
                        this.colormapper, () => {});
            }

            graphsettings.bind("enabled",
                    builder.get_object(@"$(graphid)_enabled"), "active",
                    SettingsBindFlags.DEFAULT);
        }

        // TODO: rgba, alpha need settings conversion
        prefsettings.bind("width",
                builder.get_object("width"), "value",
                SettingsBindFlags.DEFAULT);
        prefsettings.bind_with_mapping("background-color",
                builder.get_object("background_color"), "rgba",
                SettingsBindFlags.DEFAULT,
                Utils.get_settings_rgba,
                Utils.set_settings_rgba,
                this.colormapper, () => {});
        prefsettings.bind("speed",
                builder.get_object("speed"), "value",
                SettingsBindFlags.DEFAULT);
        prefsettings.bind("autostart",
                builder.get_object("autostart"), "active",
                SettingsBindFlags.DEFAULT);

        this.preferences.show_all();
    }

    [CCode (instance_pos = -1)]
    public void on_colorbutton_clicked(Gtk.Button button) {
        this.colormapper.add_palette((P.ColorChooser)button);
    }

    [CCode (instance_pos = -1)]
    public void on_preferencesdialog_response(Gtk.Dialog source, int response) {
        switch (response) {
        case 1:
            this.menupreferences.show();
            return;
        case 2:
            this.indicatorpreferences.show();
            return;
        default:
            source.destroy();
            return;
        }
    }

    [CCode (instance_pos = -1)]
    public void on_preferencesdialog_destroy(Gtk.Widget source) {
        this.preferences = null;
    }
}

