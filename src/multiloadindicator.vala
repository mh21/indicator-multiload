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

public class MultiLoadIndicator : Object {
    private uint index;
    private uint count;
    private uint height;
    private string directory;
    private TimeoutSource timeout;
    private FixedAppIndicator.Indicator indicator;

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
            foreach (unowned IconData icon_data in this._icon_datas)
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
                    foreach (unowned IconData icon_data in this._icon_datas)
                        icon_data.update_traces();
                    if (indicator != null)
                        indicator.set_icon(this.write());
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
                this.indicator = new FixedAppIndicator.Indicator.with_path("multiload", this.write(),
                        AppIndicator.IndicatorCategory.SYSTEM_SERVICES, this.directory);
                this.indicator.set_status(AppIndicator.IndicatorStatus.ACTIVE);
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
        for (uint i = 0, icount = this.count; i < icount; ++i)
            FileUtils.remove(this.filename(i));
        DirUtils.remove(this.directory);
    }

    public MultiLoadIndicator() {
        var template = "/var/lock/multiload-icons-XXXXXX".dup();
        this.directory = DirUtils.mkdtemp(template);
        this.index = 0;
        this.count = 2;
        this.height = 22;

        this.size = 40;
        this.speed = 1000;
    }

    public void add_icon_data(IconData data) {
        data.trace_length = this._size;
        this._icon_datas += data;
    }

    private string filename(uint index) {
        return @"$(this.directory)/$index.png";
    }

    private string write() {
        uint count = 0;
        foreach (unowned IconData icon_data in this._icon_datas)
            if (icon_data.enabled)
                ++count;
        var surface = new Cairo.ImageSurface(Cairo.Format.ARGB32,
                (int)(count * (this._size + 2)) - 2, (int)this.height);
        var ctx = new Cairo.Context(surface);
        ctx.set_antialias(Cairo.Antialias.NONE);
        ctx.set_line_width(1);
        uint offset = 0;
        foreach (unowned IconData icon_data in this._icon_datas) {
            if (!icon_data.enabled)
                continue;
            icon_data.set_source_color(ctx);
            ctx.rectangle(offset, 0, this._size, this.height);
            ctx.fill();
            var values = new double[icon_data.traces.length, this._size];
            var scale = icon_data.factor;
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
        string name = this.filename(this.index);
        surface.write_to_png(name);
        this.index = (this.index + 1) % this.count;
        return name;
    }
}
