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
    private Gtk.TreeView menuitemview;
    private Gtk.TreeSelection menuitemselection;
    private Gtk.Button menuitemadd;
    private Gtk.Button menuitemremove;
    private Gtk.Button menuitemedit;
    private Gtk.Button menuitemup;
    private Gtk.Button menuitemdown;
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
        this.menuitemview = builder.get_object("menuitemview") as Gtk.TreeView;
        this.menuitemsettings = Utils.generalsettings();
        this.menuitemsettings.changed["menu-expressions"].connect(on_menuitemsettings_changed);

        this.menuitemadd = builder.get_object("menuitemadd") as Gtk.Button;
        this.menuitemremove = builder.get_object("menuitemremove") as Gtk.Button;
        this.menuitemedit = builder.get_object("menuitemedit") as Gtk.Button;
        this.menuitemup = builder.get_object("menuitemup") as Gtk.Button;
        this.menuitemdown = builder.get_object("menuitemdown") as Gtk.Button;

        this.menuitemselection = (builder.get_object("menuitemview") as Gtk.TreeView).get_selection();
        this.menuitemselection.changed.connect(on_menuitemselection_changed);

        this.menuitemsgsettingstostore();
        // will invoke updatebuttons()
        this.menuitemselection.select_path(new Gtk.TreePath.from_indices(0));

        this.menuitems.show_all();
        // TODO: F2 does not work
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

        this.menuitemsettings.reset("menu-expressions");
        this.menuitemselection.select_path(new Gtk.TreePath.from_indices(0));
    }

    [CCode (instance_pos = -1)]
    public void on_expressionrenderer_edited(Gtk.CellRendererText renderer,
            string path, string new_text) {
        Gtk.TreeIter iter;
        this.menuitemstore.get_iter_from_string(out iter, path);
        this.menuitemstore.set(iter, 0, new_text);
    }

    [CCode (instance_pos = -1)]
    public void on_menuitemselection_changed() {
        this.updatebuttons();
    }

    [CCode (instance_pos = -1)]
    public void on_menuitemsettings_changed() {
        if (!this.menuitemsignoresignals)
            this.menuitemsgsettingstostore();
    }

    [CCode (instance_pos = -1)]
    public void on_menuitemstore_row_inserted(Gtk.TreeModel model,
            string path, Gtk.TreeIter iter) {
        if (!this.menuitemsignoresignals)
            this.menuitemsstoretogsettings();
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
            this.menuitemsstoretogsettings();
    }

    [CCode (instance_pos = -1)]
    public void on_menuitemadd_clicked(Gtk.Button button) {
        uint pos = 0;
        Gtk.TreeIter iter;
        if (this.menuitemselection.get_selected(null, out iter)) {
            var path = this.menuitemstore.get_path(iter);
            var indices = path.get_indices();
            pos = indices[0] + 1;
        }
        this.menuitemstore.insert(out iter, (int) pos);
        this.menuitemview.grab_focus();
        this.menuitemview.set_cursor(this.menuitemstore.get_path(iter), 
                this.menuitemview.get_column(0), true);
    }

    [CCode (instance_pos = -1)]
    public void on_menuitemremove_clicked(Gtk.Button button) {
        Gtk.TreeIter iter;
        if (!this.menuitemselection.get_selected(null, out iter))
            return;

        var path = this.menuitemstore.get_path(iter);
        this.menuitemstore.remove(iter);
        if (!this.menuitemstore.get_iter(out iter, path))
            path.prev();
        this.menuitemselection.select_path(path);
    }

    [CCode (instance_pos = -1)]
    public void on_menuitemedit_clicked(Gtk.Button button) {
        Gtk.TreeIter iter;
        if (!this.menuitemselection.get_selected(null, out iter))
            return;

        this.menuitemview.grab_focus();
        this.menuitemview.set_cursor(this.menuitemstore.get_path(iter), 
                this.menuitemview.get_column(0), true);
    }

    [CCode (instance_pos = -1)]
    public void on_menuitemup_clicked(Gtk.Button button) {
        Gtk.TreeIter iter;
        if (!this.menuitemselection.get_selected(null, out iter))
            return;

        Gtk.TreeIter previter;
        var prevpath = this.menuitemstore.get_path(iter);
        if (!prevpath.prev())
            return;
        if (!this.menuitemstore.get_iter(out previter, prevpath))
            return;

        GLib.Value value, prevvalue;
        this.menuitemstore.get_value(iter, 0, out value);
        this.menuitemstore.get_value(previter, 0, out prevvalue);
        this.menuitemstore.set_value(iter, 0, prevvalue);
        this.menuitemstore.set_value(previter, 0, value);

        this.menuitemselection.select_path(prevpath);
    }

    [CCode (instance_pos = -1)]
    public void on_menuitemdown_clicked(Gtk.Button button) {
        Gtk.TreeIter iter;
        if (!this.menuitemselection.get_selected(null, out iter))
            return;

        Gtk.TreeIter nextiter;
        var nextpath = this.menuitemstore.get_path(iter);
        nextpath.next();
        if (!this.menuitemstore.get_iter(out nextiter, nextpath))
            return;

        GLib.Value value, nextvalue;
        this.menuitemstore.get_value(iter, 0, out value);
        this.menuitemstore.get_value(nextiter, 0, out nextvalue);
        this.menuitemstore.set_value(iter, 0, nextvalue);
        this.menuitemstore.set_value(nextiter, 0, value);

        this.menuitemselection.select_path(nextpath);
    }

    private void updatebuttons() {
        Gtk.TreeIter iter;
        bool add = true, remove = false, edit = false, up = false, down = false;
        if (this.menuitemselection.get_selected(null, out iter)) {
            edit = true;
            remove = true;

            var path = this.menuitemstore.get_path(iter);
            var indices = path.get_indices();
            up = indices[0] > 0;
            down = indices[0] + 1 < this.menuitemstore.iter_n_children(null);
        }
        this.menuitemadd.sensitive = add;
        this.menuitemremove.sensitive = remove;
        this.menuitemedit.sensitive = edit;
        this.menuitemup.sensitive = up;
        this.menuitemdown.sensitive = down;
    }

    private void menuitemsgsettingstostore() {
        var expressions = this.menuitemsettings.get_strv("menu-expressions");

        this.menuitemsignoresignals = true;
        this.menuitemstore.clear();
        for (uint i = 0, isize = expressions.length; i < isize; ++i)
            this.menuitemstore.insert_with_values(null, (int) i, 0, expressions[i]);
        this.menuitemsignoresignals = false;
    }

    private void menuitemsstoretogsettings() {
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

