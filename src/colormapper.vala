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

public class ColorMapper : Object {
    static string[] colornames = {
        "cpu1",  "cpu2",  "cpu3",  "cpu4",
        "mem1",  "mem2",  "mem3",  "mem4",
        "net1",  "net2",  "net3",  "swap1",
        "load1", "disk1", "disk2", "background"
    };
    static string[] traditionalcolors = {
        "#0072b3", "#0092e6", "#00a3ff", "#002f3d",
        "#00b35b", "#00e675", "#00ff82", "#aaf5d0",
        "#fce94f", "#edd400", "#c4a000", "#8b00c3",
        "#d50000", "#c65000", "#ff6700", "rgba(0,0,0,.25)"
    };
    static Gdk.RGBA traditionalrgbas[16];
    static string[] pangocolors = {
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
    static Gdk.RGBA pangorgbas[27];
    static string[] graycolors = {
        "#000000", "#2e3436", "#555753", "#888a85", "#babdb6",
        "#d3d7cf", "#eeeeec", "#f3f3f3", "#ffffff"
    };
    static Gdk.RGBA grayrgbas[9];

    static construct {
        for (uint j = 0; j < 16; ++j)
            traditionalrgbas[j].parse(traditionalcolors[j]);
        for (uint j = 0; j < 27; ++j)
            pangorgbas[j].parse(pangocolors[j]);
        for (uint j = 0; j < 9; ++j)
            grayrgbas[j].parse(graycolors[j]);
    }

    public bool parse_colorname(string value, ref Gdk.RGBA rgba) {
        var parts = value.split(":");
        if (parts.length == 2 && parts[0] == "traditional") {
            for (uint j = 0, jsize = colornames.length; j < jsize; ++j) {
                if (colornames[j] == parts[1]) {
                    rgba = traditionalrgbas[j];
                    return true;
                }
            }
        }
        return rgba.parse(value);
    }

    public void add_palette(P.ColorChooser chooser) {
        chooser.clear_palette();
        chooser.add_palette(Gtk.Orientation.VERTICAL, 3, pangorgbas);
        chooser.add_palette(Gtk.Orientation.HORIZONTAL, 9, grayrgbas);
        chooser.add_palette(Gtk.Orientation.HORIZONTAL, 8, traditionalrgbas);
    }
}

