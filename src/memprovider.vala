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

public class MemProvider : Provider {
    public MemProvider() {
        base("mem", {"user", "shared", "buffer", "cached", "total", "cache"});
    }

    public override void update() {
        GTop.Mem mem;
        GTop.get_mem(out mem);

        this.values[0] = mem.user;
        this.values[1] = mem.user;
        this.values[2] = mem.shared;
        this.values[3] = mem.buffer;
        this.values[4] = mem.cached;
        this.values[5] = mem.total;
        this.values[6] = mem.shared + mem.buffer + mem.cached;
    }
}

