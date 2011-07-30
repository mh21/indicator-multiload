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

public class Preferences : Object {
    private Gtk.Dialog preferences;
    private Gtk.CheckButton[] checkbuttons;

    private MenuPreferences menupreferences;

    public Preferences()
    {
        this.menupreferences = new MenuPreferences();
    }

    public void show() {
        if (this.preferences != null) {
            this.preferences.present();
            return;
        }

        Gtk.Builder builder;
        this.preferences = Utils.get_ui("preferencesdialog", this, 
                {"sizeadjustment", "speedadjustment"}, 
                out builder) as Gtk.Dialog;
        return_if_fail(this.preferences != null);

        var datasettings = Utils.globalsettings();
        var graphids = datasettings.get_strv("graphs");

        foreach (var graphid in graphids) {
            var checkbutton = builder.get_object(@"$(graphid)_enabled") as Gtk.CheckButton;
            if (checkbutton != null)
                this.checkbuttons += checkbutton;
        }

        foreach (var graphid in graphids) {
            var graphsettings = Utils.graphsettings(graphid);
            var traceids = graphsettings.get_strv("traces");
            for (uint j = 0, jsize = traceids.length; j < jsize; ++j) {
                var traceid = traceids[j];
                var tracesettings = Utils.tracesettings(graphid, traceid);
                tracesettings.bind_with_mapping("color",
                        builder.get_object(@"$(traceid)_color"), "color",
                        SettingsBindFlags.DEFAULT, Utils.get_settings_color,
                        Utils.set_settings_color, null, () => {});
            }

            graphsettings.bind("enabled",
                    builder.get_object(@"$(graphid)_enabled"), "active",
                    SettingsBindFlags.DEFAULT);
            graphsettings.bind_with_mapping("background-color",
                    builder.get_object(@"$(graphid)_background_color"), "color",
                    SettingsBindFlags.DEFAULT, Utils.get_settings_color,
                    Utils.set_settings_color, null, () => {});
            graphsettings.bind("alpha",
                    builder.get_object(@"$(graphid)_background_color"), "alpha",
                    SettingsBindFlags.DEFAULT);
        }

        var prefsettings = Utils.globalsettings();
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
    public void on_preferencesdialog_response(Gtk.Dialog source, int response) {
        if (response != 1) {
            source.destroy();
            return;
        }

        this.menupreferences.show();
    }

    [CCode (instance_pos = -1)]
    public void on_preferencesdialog_destroy(Gtk.Widget source) {
        this.preferences = null;
        this.checkbuttons = null;
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
}

