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

public class LoadProvider : Provider {
    public LoadProvider() {
        base("load", {"avg", "avg5", "avg15", "cpus"}, 'd');
    }

    public override void update() {
        GTop.LoadAvg loadavg;
        GTop.get_loadavg(out loadavg);

        this.values[0] = loadavg.loadavg[0];
        this.values[1] = loadavg.loadavg[1];
        this.values[2] = loadavg.loadavg[2];
        this.values[3] = GTop.global_server->ncpu + 1;
    }
}

