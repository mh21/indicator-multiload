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

internal class IconMenu {
    public Gtk.MenuItem[] items;
    public Gtk.MenuItem separator;
}

public class MultiLoadIndicator : Object {
    private bool currenticonisattention;
    private uint height;
    private string directory;
    private TimeoutSource timeout;
    private FixedAppIndicator.Indicator indicator;
    private IconMenu[] icon_menus;

    private uint _size;
    private uint _speed;
    private IconData[] _icon_datas;
    private Gtk.Menu _menu;

    public uint size {
        get {
            return this._size;
        }
        set {
            this._size = value;
            foreach (var icon_data in this._icon_datas)
                icon_data.trace_length = value;
        }
    }

    public uint speed {
        get {
            return this._speed;
        }
        set {
            this._speed = value;
            if (this.timeout != null)
                this.timeout.destroy();
            if (this.speed % 1000 == 0)
                this.timeout = new TimeoutSource.seconds(this.speed / 1000);
            else
                this.timeout = new TimeoutSource(this.speed);
            this.timeout.attach(null);
            this.timeout.set_callback(() => {
                    uint menu_position = 0;
                    // TODO: hide these for the invisible icons
                    for (uint i = 0, isize = this._icon_datas.length; i < isize; ++i) {
                        IconMenu icon_menu = this.icon_menus[i];
                        IconData icon_data = this._icon_datas[i];
                        icon_data.update();
                        var enabled = icon_data.enabled;
                        var menuitems = icon_data.menuitems;
                        var length = menuitems.length;
                        for (uint j = 0, jsize = length; j < jsize; ++j) {
                            Gtk.MenuItem item;
                            if (j < icon_menu.items.length) {
                                item = icon_menu.items[j];
                            } else {
                                item = new Gtk.MenuItem();
                                this.menu.insert(item, (int)menu_position);
                                icon_menu.items += item;
                            }
                            item.label = menuitems[j];
                            item.visible = enabled;
                            ++menu_position;
                        }
                        if (length != icon_menu.items.length) {
                            for (uint j = length, jsize = icon_menu.items.length; j < jsize; ++j)
                                icon_menu.items[j].destroy();
                            icon_menu.items = icon_menu.items[0:length];
                        }
                        if (icon_menu.separator == null) {
                            icon_menu.separator = new Gtk.SeparatorMenuItem();
                            this.menu.insert(icon_menu.separator, (int)menu_position);
                        }
                        ++menu_position;
                        icon_menu.separator.visible = length > 0 && enabled;
                    }
                    if (indicator != null)
                        indicator.set_status(this.write());
                    return true;
                });
        }
    }

    public IconData[] icon_datas {
        get {
            return this._icon_datas;
        }
    }

    public Gtk.Menu menu {
        get {
            return this._menu;
        }
        set {
            this._menu = value;
            if (value == null)
                this.indicator = null;
            if (value != null && this.indicator == null) {
                // create icon
                this.write();
                this.indicator = new FixedAppIndicator.Indicator.with_path("multiload", this.filename(0),
                        AppIndicator.IndicatorCategory.SYSTEM_SERVICES, this.directory);
                this.indicator.set_attention_icon(this.filename(1));
                this.indicator.set_status(AppIndicator.IndicatorStatus.ACTIVE);
                // TODO: get the initial menu correct
            }
            if (value != null)
                this.indicator.set_menu(value);
        }
    }

    // Needs to be called before destruction to break the reference cycle from the timeout source
    public void destroy() {
        if (this.timeout == null)
            return;
        this.timeout.destroy();
        this.timeout = null;
    }

    ~MultiLoadIndicator() {
        for (uint i = 0; i < 2; ++i)
            FileUtils.remove(this.filename(i));
        DirUtils.remove(this.directory);
    }

    public MultiLoadIndicator() {
        var template = "/var/lock/multiload-icons-XXXXXX".dup();
        this.directory = DirUtils.mkdtemp(template);
        this.currenticonisattention = false;
        this.height = 22;

        this.size = 40;
        this.speed = 1000;
    }

    public void add_icon_data(IconData data) {
        data.trace_length = this._size;
        this._icon_datas += data;
        this.icon_menus += new IconMenu();
    }

    private string filename(uint index) {
        return @"$(this.directory)/$index.png";
    }

    // uses the attention icon as secondary icon
    // if the active icon was changed directly another dbus roundtrip would happen
    private AppIndicator.IndicatorStatus write() {
        uint count = 0;
        foreach (var icon_data in this._icon_datas)
            if (icon_data.enabled)
                ++count;
        var surface = new Cairo.ImageSurface(Cairo.Format.ARGB32,
                (int)(count * (this._size + 2)) - 2, (int)this.height);
        var ctx = new Cairo.Context(surface);
        ctx.set_antialias(Cairo.Antialias.NONE);
        ctx.set_line_width(1);
        uint offset = 0;
        foreach (var icon_data in this._icon_datas) {
            if (!icon_data.enabled)
                continue;
            icon_data.set_source_color(ctx);
            ctx.rectangle(offset, 0, this._size, this.height);
            ctx.fill();
            var values = new double[icon_data.traces.length, this._size];
            var scale = icon_data.scale;
            for (uint j = 0, jsize = values.length[0]; j < jsize; ++j) {
                unowned double[] trace_data = icon_data.traces[j].values;
                for (uint i = 0, isize = values.length[1]; i < isize; ++i)
                    values[j, i] = (j > 0 ? values[j - 1, i] : 0) + trace_data[i] / scale;
            }

            for (int j = values.length[0] - 1; j >= 0; --j) {
                Gdk.cairo_set_source_color(ctx, icon_data.traces[j].color);
                for (uint i = 0, isize = values.length[1]; i < isize; ++i) {
                    // the baseline is outside the canvas
                    ctx.move_to(0.5 + offset + i, this.height + 0.5);
                    ctx.line_to(0.5 + offset + i,
                            this.height + 0.5 - this.height * values[j, i]);
                }
                ctx.stroke();
            }
            offset += this._size + 2;
        }
        surface.write_to_png(this.filename((uint)this.currenticonisattention));
        this.currenticonisattention = !this.currenticonisattention;
        return this.currenticonisattention ?
            AppIndicator.IndicatorStatus.ACTIVE : AppIndicator.IndicatorStatus.ATTENTION;
    }
}
