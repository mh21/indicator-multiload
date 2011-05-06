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
                (Utils.format_size(mem.user),
                 Utils.format_size(mem.shared + mem.buffer + mem.cached))
        };

        this.update_scale();
    }
}

