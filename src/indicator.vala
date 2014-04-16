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

public class Indicator : Object {
    private uint currenticonindex;
    private uint lasticonwidth;
    private TimeoutSource timeout;
    private Gtk.MenuItem[] menuitems;
    private IndicatorView indicatorview;

    // TODO some of these don't need to be properties
    public string icondirectory { get; construct; }
    public Providers providers { get; construct; }
    public Gtk.Menu menu { get; construct; }
    public MenuModel menumodel { get; construct; }
    public MenuModel labelmodel { get; construct; }
    public MenuModel descriptionmodel { get; construct; }
    public int indicator_index { get; set; }
    public uint height { get; set; }
    public uint width { get; set; }
    public uint speed { get; set; }
    public Gdk.RGBA background_rgba { get; set; }
    public GraphModels graphmodels { get; set; }

    public signal void providers_updated();

    public Indicator(string icondirectory, Providers providers, Gtk.Menu menu,
            bool trayicon) {
        Object(icondirectory: icondirectory,
                providers: providers,
                menu: menu,
                menumodel: new MenuModel(providers),
                labelmodel: new MenuModel(providers),
                descriptionmodel: new MenuModel(providers));

        DirUtils.create(this.icondirectory, 0777);

        this.iconwritedummy();

        this.notify["indicator-index"].connect(() => {
            this.updateviews();
        });
        this.notify["speed"].connect(() => {
                if (this.timeout != null)
                    this.timeout.destroy();
                if (this.speed == 0) {
                    this.timeout = null;
                    return;
                }
                if (this.speed % 1000 == 0)
                    this.timeout = new TimeoutSource.seconds(this.speed / 1000);
                else
                    this.timeout = new TimeoutSource(this.speed);
                this.timeout.attach(null);
                this.timeout.set_callback(() => {
                        this.updateall();
                        return true;
                    });
            });

        if (trayicon)
            this.indicatorview = new TrayIndicatorView(this.icondirectory, this.menu);
        else
            this.indicatorview = new AppIndicatorView(this.icondirectory, this.menu);

        this.indicatorview.scroll_event.connect(this.scrollhandler);
    }

    ~MultiLoadIndicator() {
        FileUtils.remove(this.iconpath(0));
        FileUtils.remove(this.iconpath(1));
        DirUtils.remove(this.icondirectory);
    }

    // Needs to be called before destruction to break the reference cycle from the timeout source
    public void destroy() {
        if (this.timeout == null)
            return;
        this.timeout.destroy();
        this.timeout = null;
    }

    public void updateall() {
        this.providers.update();
        this.providers_updated();
        this.updatemodels();
        this.updateviews();
    }

    private void scrollhandler(int delta, uint direction) {
        var index = this.indicator_index;
        if (direction == Gdk.ScrollDirection.DOWN)
            index += delta;
        else if (direction == Gdk.ScrollDirection.UP)
            index -= delta;
        if (index >= this.labelmodel.expressions.length)
            index = this.labelmodel.expressions.length - 1;
        if (index < 0)
            index = 0;
        this.indicator_index = index;
    }

    private void updatemodels() {
        this.menumodel.update();
        this.graphmodels.update(this.width);
        this.descriptionmodel.update();
        this.labelmodel.update();
    }

    private void updateviews() {
        this.updatemenuview();
        this.updategraphsview();
        // needs to after updategraphsview
        this.updatelabelview();
    }

    private void updatemenuview() {
        // start after system monitor and separator
        uint menu_position = 2;
        var length = this.menumodel.expressions.length;
        for (uint j = 0; j < length; ++j) {
            Gtk.MenuItem item;
            if (j < this.menuitems.length) {
                item = this.menuitems[j];
            } else {
                item = new Gtk.MenuItem.with_label("");
                item.visible = true;
                this.menu.insert(item, (int)menu_position);
                this.menuitems += item;
            }
            item.label = this.menumodel.expression(j).label();
            ++menu_position;
        }
        if (length != this.menuitems.length) {
            for (uint j = length, jsize = this.menuitems.length; j < jsize; ++j)
                menuitems[j].destroy();
            this.menuitems = this.menuitems[0:length];
        }
    }

    private void updategraphsview() {
        this.iconwrite();
        var found = false;
        // fix icon size if using a GtkStatusIcon
        foreach (var toplevel in Gtk.Window.list_toplevels()) {
            if (toplevel.get_type().name() != "GtkTrayIcon" || !(toplevel is Gtk.Container))
                continue;
            ((Gtk.Container) toplevel).foreach((w) => {
                if (!(w is Gtk.Image))
                    return;
                ((Gtk.Image) w).set_from_file(this.iconpath(this.currenticonindex));
                ((Gtk.Image) w).pixel_size = (int) uint.max(this.lasticonwidth, this.height);
                found = true;
            });
        }
        if (!found) {
            this.indicatorview.icon = this.lasticonwidth > 0 ?
                    this.iconname(this.currenticonindex) : "";
        }
        this.indicatorview.description = this.descriptionmodel.expression(0).label();
    }

    private void updatelabelview() {
        var indicatorcount = this.labelmodel.expressions.length;
        var label = 0 <= this.indicator_index &&
            this.indicator_index < indicatorcount ?
            this.labelmodel.expression(this.indicator_index).label() : "";
        var guide = 0 <= this.indicator_index &&
            this.indicator_index < indicatorcount ?
            this.labelmodel.expression(this.indicator_index).guide() : "";
        this.indicatorview.label = this.lasticonwidth == 0 && label == "" ?
            "im" : label;
        this.indicatorview.guide = this.lasticonwidth == 0 && guide == "" ?
            "im" : guide;
    }

    private string iconname(uint index) {
        return @"indicator-multiload-graphs-$index";
    }

    private string iconpath(uint index) {
        return Path.build_filename(this.icondirectory, this.iconname(index) + ".png");
    }

    // Create dummy icons because the availability of icons is cached per theme
    private void iconwritedummy() {
        var surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, 1, 1);
        surface.write_to_png(this.iconpath(0));
        surface.write_to_png(this.iconpath(1));
    }

    private void iconwrite() {
        this.lasticonwidth = 0;
        if (this.graphmodels == null)
            return;
        uint count = 0;
        foreach (var graphmodel in this.graphmodels.graphmodels)
            if (graphmodel.enabled)
                ++count;
        if (count == 0)
            return;

        this.lasticonwidth = (int) (count * (this._width + 2)) - 2;
        var surface = new Cairo.ImageSurface(Cairo.Format.ARGB32,
                (int) this.lasticonwidth, (int) this.height);
        var ctx = new Cairo.Context(surface);
        ctx.set_antialias(Cairo.Antialias.NONE);
        ctx.set_line_width(1);
        uint offset = 0;
        foreach (var graphmodel in this.graphmodels.graphmodels) {
            if (!graphmodel.enabled)
                continue;
            Gdk.cairo_set_source_rgba(ctx, this.background_rgba);
            ctx.rectangle(offset, 0, this._width, this.height);
            ctx.fill();
            var tracemodels = graphmodel.tracemodels;
            var values = new double[tracemodels.length, this._width];
            var scale = graphmodel.scale;
            for (uint j = 0, jsize = values.length[0]; j < jsize; ++j) {
                var enabled = tracemodels[j].enabled;
                unowned double[] tracedata = tracemodels[j].values;
                for (uint i = 0, isize = values.length[1]; i < isize; ++i)
                    values[j, i] = (j > 0 ? values[j - 1, i] : 0) + (enabled ? tracedata[i] : 0) / scale;
            }

            for (int j = values.length[0] - 1; j >= 0; --j) {
                Gdk.cairo_set_source_rgba(ctx, graphmodel.tracemodels[j].rgba);
                for (uint i = 0, isize = values.length[1]; i < isize; ++i) {
                    // the baseline is outside the canvas
                    ctx.move_to(0.5 + offset + i, this.height + 0.5);
                    ctx.line_to(0.5 + offset + i,
                            this.height + 0.5 - this.height * values[j, i]);
                }
                ctx.stroke();
            }
            offset += this._width + 2;
        }
        this.currenticonindex = 1 - this.currenticonindex;
        surface.write_to_png(this.iconpath(this.currenticonindex));
    }
}

