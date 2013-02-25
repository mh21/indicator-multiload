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

public class ItemPreferences : Object {
    private Gtk.Dialog items;
    private Gtk.ListStore itemstore;
    private Gtk.TreeView itemview;
    private Gtk.TreeSelection itemselection;
    private Gtk.Button itemadd;
    private Gtk.Button itemremove;
    private Gtk.Button itemedit;
    private Gtk.Button itemup;
    private Gtk.Button itemdown;
    private Settings itemsettings;
    private bool itemsignoresignals;

    public string settingskey { get; construct; }

    public signal void itemhelp_show();

    public ItemPreferences(string settingskey) {
        Object(settingskey: settingskey);
    }

    public void show() {
        if (this.items != null) {
            this.items.present();
            return;
        }

        Gtk.Builder builder;
        this.items = Utils.get_ui("itemdialog", this, {"itemstore"}, out builder) as Gtk.Dialog;
        return_if_fail(this.items != null);

        this.itemstore = builder.get_object("itemstore") as Gtk.ListStore;
        this.itemview = builder.get_object("itemview") as Gtk.TreeView;
        this.itemsettings = new SettingsCache().generalsettings();
        this.itemsettings.changed["menu-expressions"].connect(on_itemsettings_changed);

        this.itemadd = builder.get_object("itemadd") as Gtk.Button;
        this.itemremove = builder.get_object("itemremove") as Gtk.Button;
        this.itemedit = builder.get_object("itemedit") as Gtk.Button;
        this.itemup = builder.get_object("itemup") as Gtk.Button;
        this.itemdown = builder.get_object("itemdown") as Gtk.Button;

        this.itemselection = (builder.get_object("itemview") as Gtk.TreeView).get_selection();

        this.itemsgsettingstostore();
        // will invoke updatebuttons()
        this.itemselection.select_path(new Gtk.TreePath.from_indices(0));

        this.items.show_all();
        // TODO: F2 does not work
    }

    [CCode (instance_pos = -1)]
    public void on_itemdialog_destroy(Gtk.Widget source) {
        this.items = null;
        this.itemstore = null;
        this.itemview = null;
        this.itemsettings = null;
        this.itemadd = null;
        this.itemremove = null;
        this.itemedit = null;
        this.itemup = null;
        this.itemdown = null;
        this.itemselection = null;
    }

    [CCode (instance_pos = -1)]
    public void on_itemdialog_response(Gtk.Dialog source, int response) {
        switch (response) {
        case 0: // close
            source.destroy();
            return;
        case 1: // revert
            this.itemsettings.reset(this.settingskey);
            this.itemselection.select_path(new Gtk.TreePath.from_indices(0));
            break;
        case 2: // help
            this.itemhelp_show();
            break;
        }
    }

    [CCode (instance_pos = -1)]
    public void on_expressionrenderer_edited(Gtk.CellRendererText renderer,
            string path, string new_text) {
        Gtk.TreeIter iter;
        this.itemstore.get_iter_from_string(out iter, path);
        this.itemstore.set(iter, 0, new_text);
    }

    [CCode (instance_pos = -1)]
    public void on_itemselection_changed(Gtk.TreeSelection selection) {
        this.updatebuttons();
    }

    [CCode (instance_pos = -1)]
    public void on_itemsettings_changed() {
        if (!this.itemsignoresignals)
            this.itemsgsettingstostore();
    }

    [CCode (instance_pos = -1)]
    public void on_itemstore_row_inserted(Gtk.TreeModel model,
            string path, Gtk.TreeIter iter) {
        if (!this.itemsignoresignals)
            this.itemsstoretogsettings();
    }

    [CCode (instance_pos = -1)]
    public void on_itemstore_row_changed(Gtk.TreeModel model,
            string path, Gtk.TreeIter iter) {
        if (!this.itemsignoresignals)
            itemsstoretogsettings();
    }

    [CCode (instance_pos = -1)]
    public void on_itemstore_row_deleted(Gtk.TreeModel model,
            string path) {
        if (!this.itemsignoresignals)
            this.itemsstoretogsettings();
    }

    [CCode (instance_pos = -1)]
    public void on_itemadd_clicked(Gtk.Button button) {
        uint pos = 0;
        Gtk.TreeIter iter;
        if (this.itemselection.get_selected(null, out iter)) {
            var path = this.itemstore.get_path(iter);
            var indices = path.get_indices();
            pos = indices[0] + 1;
        }
        this.itemstore.insert(out iter, (int) pos);
        this.itemview.grab_focus();
        this.itemview.set_cursor(this.itemstore.get_path(iter),
                this.itemview.get_column(0), true);
    }

    [CCode (instance_pos = -1)]
    public void on_itemremove_clicked(Gtk.Button button) {
        Gtk.TreeIter iter;
        if (!this.itemselection.get_selected(null, out iter))
            return;

        var path = this.itemstore.get_path(iter);
        this.itemstore.remove(iter);
        if (!this.itemstore.get_iter(out iter, path))
            path.prev();
        this.itemselection.select_path(path);
    }

    [CCode (instance_pos = -1)]
    public void on_itemedit_clicked(Gtk.Button button) {
        Gtk.TreeIter iter;
        if (!this.itemselection.get_selected(null, out iter))
            return;

        this.itemview.grab_focus();
        this.itemview.set_cursor(this.itemstore.get_path(iter),
                this.itemview.get_column(0), true);
    }

    [CCode (instance_pos = -1)]
    public void on_itemup_clicked(Gtk.Button button) {
        Gtk.TreeIter iter;
        if (!this.itemselection.get_selected(null, out iter))
            return;

        Gtk.TreeIter previter;
        var prevpath = this.itemstore.get_path(iter);
        if (!prevpath.prev())
            return;
        if (!this.itemstore.get_iter(out previter, prevpath))
            return;

        GLib.Value value, prevvalue;
        this.itemstore.get_value(iter, 0, out value);
        this.itemstore.get_value(previter, 0, out prevvalue);
        this.itemstore.set_value(iter, 0, prevvalue);
        this.itemstore.set_value(previter, 0, value);

        this.itemselection.select_path(prevpath);
    }

    [CCode (instance_pos = -1)]
    public void on_itemdown_clicked(Gtk.Button button) {
        Gtk.TreeIter iter;
        if (!this.itemselection.get_selected(null, out iter))
            return;

        Gtk.TreeIter nextiter;
        var nextpath = this.itemstore.get_path(iter);
        nextpath.next();
        if (!this.itemstore.get_iter(out nextiter, nextpath))
            return;

        GLib.Value value, nextvalue;
        this.itemstore.get_value(iter, 0, out value);
        this.itemstore.get_value(nextiter, 0, out nextvalue);
        this.itemstore.set_value(iter, 0, nextvalue);
        this.itemstore.set_value(nextiter, 0, value);

        this.itemselection.select_path(nextpath);
    }

    private void updatebuttons() {
        Gtk.TreeIter iter;
        bool add = true, remove = false, edit = false, up = false, down = false;
        if (this.itemselection.get_selected(null, out iter)) {
            edit = true;
            remove = true;

            var path = this.itemstore.get_path(iter);
            var indices = path.get_indices();
            up = indices[0] > 0;
            down = indices[0] + 1 < this.itemstore.iter_n_children(null);
        }
        this.itemadd.sensitive = add;
        this.itemremove.sensitive = remove;
        this.itemedit.sensitive = edit;
        this.itemup.sensitive = up;
        this.itemdown.sensitive = down;
    }

    private void itemsgsettingstostore() {
        var expressions = this.itemsettings.get_strv(this.settingskey);

        this.itemsignoresignals = true;
        this.itemstore.clear();
        for (uint i = 0, isize = expressions.length; i < isize; ++i)
            this.itemstore.insert_with_values(null, (int) i, 0, expressions[i]);
        this.itemsignoresignals = false;
    }

    private void itemsstoretogsettings() {
        var result = new string[this.itemstore.iter_n_children(null)];
        Gtk.TreeIter iter;
        for (uint i = 0, isize = result.length; i < isize; ++i) {
            this.itemstore.iter_nth_child(out iter, null, (int)i);
            GLib.Value value;
            this.itemstore.get_value(iter, 0, out value);
            result[i] = value as string;
        }

        this.itemsignoresignals = true;
        this.itemsettings.set_strv(this.settingskey, result);
        this.itemsignoresignals = false;
    }
}

