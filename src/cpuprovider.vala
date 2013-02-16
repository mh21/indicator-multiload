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

public class CpuProvider : Provider {
    private uint64[] lastdata;

    public CpuProvider() {
	base("cpu", {"user", "sys", "nice", "idle", "io", "inuse"});
    }

    public override void update() {
        GTop.Cpu cpu;
        GTop.get_cpu(out cpu);

        uint64[] newdata = new uint64[6];
        newdata[0] = cpu.user;
        newdata[1] = cpu.sys;
        newdata[2] = cpu.nice;
        newdata[3] = cpu.idle;
        newdata[4] = cpu.iowait + cpu.irq + cpu.softirq;
        newdata[5] = cpu.user + cpu.nice + cpu.sys;

        double total = 0;

        if (this.lastdata.length != 0) {
            for (uint i = 0; i < 5; ++i)
                total += newdata[i] - this.lastdata[i];
            for (uint i = 0, isize = newdata.length; i < isize; ++i)
                this.values[i] = (newdata[i] - this.lastdata[i]) / total;
        }
        this.lastdata = newdata;
    }
}

