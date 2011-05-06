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

public class MemIconData : IconData {
    public MemIconData() {
        base("memload", 4, 1, 1);
    }

    // for SI units as g_format_size_for_display uses base 2
    private string format_size(double val) {
        const string[] units = {
            // TRANSLATORS: Please leave {} as it is, it is replaced by the size
            N_("{} kB"),
            // TRANSLATORS: Please leave {} as it is, it is replaced by the size
            N_("{} MB"),
            // TRANSLATORS: Please leave {} as it is, it is replaced by the size
            N_("{} GB")
        };
        int index = -1;
        while (index + 1 < units.length && val >= 1000) {
            val /= 1000;
            ++index;
        }
        if (index < 0)
            return ngettext("%u byte", "%u bytes", (ulong)val).printf((uint)val);
        // 4 significant digits
        var pattern = _(units[index]).replace("{}",
            val < 9.9995 ? "%.3f" :
            val < 99.995 ? "%.2f" :
            val < 999.95 ? "%.1f" : "%.0f");
        return pattern.printf(val);
    }

    public override void update() {
        GTop.Mem mem;
        GTop.get_mem(out mem);

        double total = mem.total;

        this.traces[0].add_value(mem.user / total);
        this.traces[1].add_value(mem.shared / total);
        this.traces[2].add_value(mem.buffer / total);
        this.traces[3].add_value(mem.cached / total);

        this.menuitems = {
            _("Mem: %s, cache %s").printf
                (this.format_size(mem.user),
                 this.format_size(mem.shared + mem.buffer + mem.cached))
        };

        this.update_scale();
    }
}

