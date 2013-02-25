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

public class ItemHelp : Object {
    private Gtk.Dialog items;
    private Gtk.TreeStore itemstore;
    private Gtk.TreeView itemview;
    private MenuModel menumodel;

    public MultiLoadIndicator indicator { get; construct; }

    public ItemHelp(MultiLoadIndicator indicator) {
        Object(indicator: indicator);
    }

    public void show() {
        if (this.items != null) {
            this.items.present();
            return;
        }

        Gtk.Builder builder;
        this.items = Utils.get_ui("itemhelpdialog", this, {"itemhelpstore"}, out builder) as Gtk.Dialog;
        return_if_fail(this.items != null);

        this.itemstore = builder.get_object("itemhelpstore") as Gtk.TreeStore;
        this.itemview = builder.get_object("itemhelpview") as Gtk.TreeView;

        this.itemstore.clear();

        this.menumodel = new MenuModel(this.indicator.providers);
        string[] expressions = {};
        foreach (var provider in this.indicator.providers.providers) {
            Gtk.TreeIter parent;
            this.itemstore.insert_with_values(out parent, null, -1,
                    0, provider.id,
                    3, -1);
            string[] keys = provider.keys;
            for (uint i = 0, isize = keys.length; i < isize; ++i) {
                var expression = @"$$($(provider.id).$(keys[i]))";
                expressions += expression;
                this.itemstore.insert_with_values(null, parent, -1,
                        0, keys[i],
                        1, expression,
                        3, expressions.length - 1);
            }
        }
        this.menumodel.expressions = expressions;

        this.updateitems();
        this.itemview.expand_all();

        this.items.show_all();
    }

    [CCode (instance_pos = -1)]
    public void on_itemhelpdialog_destroy(Gtk.Widget source) {
        this.items = null;
        this.itemstore = null;
    }

    [CCode (instance_pos = -1)]
    public void on_itemhelpdialog_response(Gtk.Dialog source, int response) {
        switch (response) {
        case 0: // close
            source.destroy();
            return;
        }
    }

    private void updateitems() {
        this.menumodel.update();

        this.itemstore.foreach((model, path, iter) => {
            int index;
            model.get(iter, 3, out index);
            if (index >= 0) {
                (model as Gtk.TreeStore).set(iter,
                        2, this.menumodel.expression(index).label());
            }
            return false;
        });
    }
}

