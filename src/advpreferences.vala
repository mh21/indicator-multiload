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

public class AdvancedPreferences : Object {
    // always allocated
    private SettingsCache settingscache;

    // only when dialog is visible
    private Gtk.Dialog preferences;
    private Gtk.Builder builder;

    // helper
    private unowned Gtk.TreeStore itemstore;
    private unowned Gtk.TreeView itemview;
    private unowned Gtk.Notebook notebook;
    private unowned Object graphminimum;
    private unowned Object graphmaximum;
    private unowned Object graphenabled;
    private unowned Object graphsmooth;
    private unowned Object tracecolor;
    private unowned Object traceenabled;
    private unowned Object traceexpression;

    public ColorMapper colormapper { get; construct; }

    public signal void itemhelp_show();
    public signal void colorscheme_restore();

    public AdvancedPreferences(ColorMapper colormapper) {
        Object(colormapper: colormapper);
    }

    construct {
        this.settingscache = new SettingsCache();
    }

    public void show() {
        if (this.preferences != null) {
            this.preferences.present();
            return;
        }

        this.preferences = Utils.get_ui("advprefdialog", this,
                {"graphtracestore", "advprefsizegroup"},
                out this.builder) as Gtk.Dialog;
        return_if_fail(this.preferences != null);

        this.itemstore = builder.get_object("graphtracestore") as Gtk.TreeStore;
        this.itemview = builder.get_object("graphtraceview") as Gtk.TreeView;
        this.notebook = builder.get_object("graphtracebook") as Gtk.Notebook;
        this.graphminimum = builder.get_object("graphminimum");
        this.graphmaximum = builder.get_object("graphmaximum");
        this.graphenabled = builder.get_object("graphenabled");
        this.graphsmooth = builder.get_object("graphsmooth");
        this.tracecolor = builder.get_object("tracecolor");
        this.traceenabled = builder.get_object("traceenabled");
        this.traceexpression = builder.get_object("traceexpression");

        // TODO react to changes in graphs and *.traces by regenerating everything
        var graphids = this.settingscache.generalsettings().get_strv("graphs");
        foreach (var graphid in graphids) {
            Gtk.TreeIter parent;
            this.itemstore.insert_with_values(out parent, null, -1,
                    0, graphid,
                    1, graphid);
            var graphsettings = this.settingscache.graphsettings(graphid);
            var traceids = graphsettings.get_strv("traces");
            foreach (var traceid in traceids) {
                this.itemstore.insert_with_values(null, parent, -1,
                        0, traceid,
                        1, graphid,
                        2, traceid);
            }
        }

        this.itemview.expand_all();

        this.preferences.show_all();
    }

    private void revert() {
        var graphids = this.settingscache.generalsettings().get_strv("graphs");
        foreach (var graphid in graphids) {
            var graphsettings = this.settingscache.graphsettings(graphid);
            foreach (var key in graphsettings.list_keys())
                graphsettings.reset(key);
            foreach (var traceid in graphsettings.get_strv("traces")) {
                var tracesettings = this.settingscache.tracesettings(graphid, traceid);
                foreach (var key in tracesettings.list_keys()) {
                    if (key != "color")
                        tracesettings.reset(key);
                }
            }
        }
        this.colorscheme_restore();
    }

    [CCode (instance_pos = -1)]
    public void on_advprefdialog_destroy(Gtk.Widget source) {
        this.preferences = null;
        this.builder = null;
    }

    [CCode (instance_pos = -1)]
    public void on_advprefdialog_response(Gtk.Dialog source, int response) {
        switch (response) {
        case 0: // close
            source.destroy();
            return;
        case 1: // revert
            this.revert();
            return;
        case 2: // help
            this.itemhelp_show();
            return;
        }
    }

    [CCode (instance_pos = -1)]
    public void on_graphtraceview_cursor_changed(Gtk.TreeView source) {
        Gtk.TreePath path;
        source.get_cursor(out path, null);
        if (path == null)
            return;
        Gtk.TreeIter iter;
        if (!this.itemstore.get_iter(out iter, path))
            return;
        Value value;
        this.itemstore.get_value(iter, 1, out value);
        var graphid = value as string;
        this.itemstore.get_value(iter, 2, out value);
        var traceid = value as string;
        if (traceid == null) {
            this.notebook.set_current_page(0);
            var graphsettings = this.settingscache.graphsettings(graphid);
            graphsettings.unbind(this.graphminimum, "text");
            graphsettings.bind("minimum", this.graphminimum, "text",
                    SettingsBindFlags.DEFAULT);
            graphsettings.unbind(this.graphmaximum, "text");
            graphsettings.bind("maximum", this.graphmaximum, "text",
                    SettingsBindFlags.DEFAULT);
            graphsettings.unbind(this.graphenabled, "active");
            graphsettings.bind("enabled", this.graphenabled, "active",
                    SettingsBindFlags.DEFAULT);
            graphsettings.unbind(this.graphsmooth, "text");
            graphsettings.bind("smooth", this.graphsmooth, "text",
                    SettingsBindFlags.DEFAULT);
        } else {
            this.notebook.set_current_page(1);
            var tracesettings = this.settingscache.tracesettings(graphid, traceid);
            tracesettings.unbind(this.tracecolor, "rgba");
            PGLib.settings_bind_with_mapping(tracesettings, "color",
                    this.tracecolor, "rgba",
                    SettingsBindFlags.DEFAULT,
                    Utils.get_settings_rgba,
                    (PGLib.SettingsBindSetMapping)Utils.set_settings_rgba,
                    this.colormapper, () => {});
            tracesettings.unbind(this.traceenabled, "active");
            tracesettings.bind("enabled", this.traceenabled, "active",
                    SettingsBindFlags.DEFAULT);
            tracesettings.unbind(this.traceexpression, "text");
            tracesettings.bind("expression", this.traceexpression, "text",
                    SettingsBindFlags.DEFAULT);
        }
    }
}

