/******************************************************************************
 * Copyright (C) 2013  Michael Hofmann <mh21@mh21.de>                         *
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

class ColorScheme {
    public string label;
    public string[] colors;
    public Gdk.RGBA rgbas[16];

    public ColorScheme(string label, string[] colors) {
        this.label = label;
        this.colors = colors;
        for (uint j = 0, jsize = colors.length; j < jsize; ++j)
            this.rgbas[j].parse(colors[j]);
    }

}

public class ColorMapper : Object {
    public static const string[] colorschemes = {
        "traditional", "ambiance", "radiance", "xosview"
    };

    static HashTable<string, ColorScheme> schemes = new HashTable<string, ColorScheme>
        .full(str_hash, str_equal, g_free, g_object_unref);

    static const string[] colornames = {
        "cpu1",  "cpu2",  "cpu3",  "cpu4",
        "mem1",  "mem2",  "mem3",  "mem4",
        "net1",  "net2",  "net3",  "swap1",
        "load1", "disk1", "disk2", "background"
    };

    static const string[] tangocolors = {
        "#ef2929", "#cc0000", "#a40000",
        "#fcaf3e", "#f57900", "#ce5c00",
        "#fce94f", "#edd400", "#c4a000",
        "#8ae234", "#73d216", "#4e9a06",
        "#729fcf", "#3465a4", "#204a87",
        "#ad7fa8", "#75507b", "#5c3566",
        "#e9b96e", "#c17d11", "#8f5902",
        "#888a85", "#555753", "#2e3436",
        "#eeeeec", "#d3d7cf", "#babdb6"
    };
    static Gdk.RGBA tangorgbas[27];

    static const string[] graycolors = {
        "#000000", "#2e3436", "#555753", "#888a85", "#babdb6",
        "#d3d7cf", "#eeeeec", "#f3f3f3", "#ffffff"
    };
    static Gdk.RGBA grayrgbas[9];

    public string color_scheme { get; set; }

    static construct {
        for (uint j = 0; j < 27; ++j)
            tangorgbas[j].parse(tangocolors[j]);
        for (uint j = 0; j < 9; ++j)
            grayrgbas[j].parse(graycolors[j]);

        schemes.insert("traditional", new ColorScheme
            // TRANSLATORS: Color theme name
            (_("Traditional"), {
            "#0072b3", "#0092e6", "#00a3ff", "#002f3d",
            "#00b35b", "#00e675", "#00ff82", "#aaf5d0",
            "#fce94f", "#edd400", "#c4a000", "#8b00c3",
            "#d50000", "#c65000", "#ff6700", "rgba(0,0,0,.25)"
        }));
        schemes.insert("ambiance", new ColorScheme
            // TRANSLATORS: Color theme name for the Ubuntu Ambiance (light on dark) theme
            (_("Ambiance"), {
            "#dfdbd2", "#dfdbd2", "#dfdbd2", "#a39f96",
            "#dfdbd2", "#dfdbd2", "#a39f96", "#a39f96",
            "#dfdbd2", "#a39f96", "#a39f96", "#dfdbd2",
            "#dfdbd2", "#dfdbd2", "#a39f96", "rgba(0,0,0,0)"
        }));
        schemes.insert("radiance", new ColorScheme
            // TRANSLATORS: Color theme name for the Ubuntu Radiance (dark on light) theme
            (_("Radiance"), {
            "#3c3c3c", "#3c3c3c", "#3c3c3c", "#a39f96",
            "#3c3c3c", "#3c3c3c", "#a39f96", "#a39f96",
            "#3c3c3c", "#a39f96", "#a39f96", "#3c3c3c",
            "#3c3c3c", "#3c3c3c", "#a39f96", "rgba(0,0,0,0)"
        }));
        // additional mem colors: slab 0000ff, map 836fff
        schemes.insert("xosview", new ColorScheme
            // TRANSLATORS: Color theme name for the XOSView theme
            (_("XOSView"), {
            "#2e8b57", "#ffa500", "#ffff00", "#add8e6",
            "#2e8b57", "#0000ff", "#ffa500", "#ff0000",
            "#87ceeb", "#836fff", "#0000ff", "#2e8b57",
            "#2e8b57", "#87ceeb", "#836fff", "rgba(127,255,212,0)"
        }));
    }

    static Gdk.RGBA[] schemergbas(string name) {
        var scheme = schemes.lookup(name);
        if (scheme == null)
            scheme = schemes.lookup("traditional");
        return scheme.rgbas;
    }

    public static string schemelabel(string name) {
        var scheme = schemes.lookup(name);
        if (scheme == null)
            scheme = schemes.lookup("traditional");
        return scheme.label;
    }

    public static bool parse_colorname(string value, ref Gdk.RGBA rgba) {
        var parts = value.split(":");
        if (parts.length == 2) {
            var rgbas = schemergbas(parts[0]);
            for (uint j = 0, jsize = colornames.length; j < jsize; ++j) {
                if (colornames[j] == parts[1]) {
                    rgba = rgbas[j];
                    return true;
                }
            }
        }
        return rgba.parse(value);
    }

    public void add_palette(PGtk.ColorChooser chooser) {
        // https://bugzilla.gnome.org/show_bug.cgi?id=693995
        if (Gtk.check_version(3, 8, 0) == null) {
            chooser.add_palette(Gtk.Orientation.VERTICAL, 0, null);
            chooser.add_palette(Gtk.Orientation.VERTICAL, 3, tangorgbas);
            chooser.add_palette(Gtk.Orientation.HORIZONTAL, 9, grayrgbas);
            chooser.add_palette(Gtk.Orientation.HORIZONTAL, 8, schemergbas(this.color_scheme));
        }
    }
}

