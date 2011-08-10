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

public class MenuPreferences : Object {
    private Gtk.Dialog menuitems;
    private Gtk.ListStore menuitemstore;
    private FixedGSettings.Settings menuitemsettings;
    private bool menuitemsignoresignals;

    public void show() {
        if (this.menuitems != null) {
            this.menuitems.present();
            return;
        }

        Gtk.Builder builder;
        this.menuitems = Utils.get_ui("menuitemdialog", this,
                {"menuitemstore", "menuitemadj1", "menuitemadj2"},
                out builder) as Gtk.Dialog;
        return_if_fail(this.menuitems != null);

        this.menuitemstore = builder.get_object("menuitemstore") as Gtk.ListStore;
        this.menuitemsettings = Utils.generalsettings();
        this.menuitemsettings.changed["menu-expressions"] += on_menuitemsettings_changed;
        this.menuitemsgsettingstostore();

        this.menuitems.show_all();
        // TODO: treeview not scrollable
        // TODO: no way to delete, add new, F2 does not work
    }

    [CCode (instance_pos = -1)]
    public void on_menuitemdialog_destroy(Gtk.Widget source) {
        this.menuitems = null;
        this.menuitemstore = null;
        this.menuitemsettings = null;
    }

    [CCode (instance_pos = -1)]
    public void on_menuitemdialog_response(Gtk.Dialog source, int response) {
        if (response != 1) {
            source.destroy();
            return;
        }

        var settings = new FixedGSettings.Settings("de.mh21.indicator.multiload");
        settings.reset("menu-expressions");
    }

    [CCode (instance_pos = -1)]
    public void on_expressionrenderer_edited(Gtk.CellRendererText renderer,
            string path, string new_text) {
        Gtk.TreeIter iter;
        this.menuitemstore.get_iter_from_string(out iter, path);
        this.menuitemstore.set(iter, 0, new_text);
    }

    [CCode (instance_pos = -1)]
    public void on_menuitemsettings_changed() {
        if (!this.menuitemsignoresignals)
            menuitemsgsettingstostore();
    }

    [CCode (instance_pos = -1)]
    public void on_menuitemstore_row_inserted(Gtk.TreeModel model,
            string path, Gtk.TreeIter iter) {
        if (!this.menuitemsignoresignals)
            menuitemsstoretogsettings();
    }

    [CCode (instance_pos = -1)]
    public void on_menuitemstore_row_changed(Gtk.TreeModel model,
            string path, Gtk.TreeIter iter) {
        if (!this.menuitemsignoresignals)
            menuitemsstoretogsettings();
    }

    [CCode (instance_pos = -1)]
    public void on_menuitemstore_row_deleted(Gtk.TreeModel model,
            string path) {
        if (!this.menuitemsignoresignals)
            menuitemsstoretogsettings();
    }

    public void menuitemsgsettingstostore() {
        var expressions = this.menuitemsettings.get_strv("menu-expressions");

        this.menuitemsignoresignals = true;
        this.menuitemstore.clear();
        foreach (var expression in expressions) {
            Gtk.TreeIter iter;
            this.menuitemstore.append(out iter);
            this.menuitemstore.set(iter, 0, expression);
        }
        this.menuitemsignoresignals = false;
    }

    public void menuitemsstoretogsettings() {
        var result = new string[this.menuitemstore.iter_n_children(null)];
        Gtk.TreeIter iter;
        for (uint i = 0, isize = result.length; i < isize; ++i) {
            this.menuitemstore.iter_nth_child(out iter, null, (int)i);
            GLib.Value value;
            this.menuitemstore.get_value(iter, 0, out value);
            result[i] = value as string;
        }

        this.menuitemsignoresignals = true;
        this.menuitemsettings.set_strv("menu-expressions", result);
        this.menuitemsignoresignals = false;
    }
}

