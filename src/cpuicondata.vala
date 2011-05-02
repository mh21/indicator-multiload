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

public class CpuIconData : IconData {
    private uint64[] lastdata;

    public CpuIconData() {
        base("cpuload", 4, 1, 1);
    }

    public override void update_traces() {
        GTop.Cpu cpu;
        GTop.get_cpu(out cpu);

        uint64[] newdata = new uint64[5];
        newdata[0] = cpu.user;
        newdata[1] = cpu.nice;
        newdata[2] = cpu.sys;
        newdata[3] = cpu.iowait + cpu.irq + cpu.softirq;
        newdata[4] = cpu.idle;

        if (this.lastdata.length == 0) {
            foreach (unowned IconTraceData trace in this.traces)
                trace.add_value(0);
        } else {
            double total = 0;
            for (uint i = 0, isize = newdata.length; i < isize; ++i)
            	total += newdata[i] - this.lastdata[i];
            for (uint i = 0, isize = this.traces.length; i < isize; ++i)
                this.traces[i].add_value((newdata[i] - this.lastdata[i]) / total);
        }
        this.lastdata = newdata;
    }
}

