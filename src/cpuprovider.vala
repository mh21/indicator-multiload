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
    private uint64[] newdata;

    private static string[] fields() {
        GTop.init();
        string[] templates = {"user", "sys", "nice", "idle", "io", "inuse"};
        string[] result = new string[(GTop.global_server->ncpu + 2) * 6];
        for (uint j = 0; j < 6; ++j) {
            var template = templates[j];
            result[j] = template;
            for (uint i = 0, isize = GTop.global_server->ncpu + 1; i < isize; ++i)
                result[(i + 1) * 6 + j] = @"$template$i";
        }
        return result;
    }

    public CpuProvider() {
        base("cpu", fields(), 'p');
    }

    private void updatecpu(uint index, uint64 user, uint64 sys, uint64 nice,
            uint64 idle, uint64 io) {
        this.newdata[index + 0] = user;
        this.newdata[index + 1] = sys;
        this.newdata[index + 2] = nice;
        this.newdata[index + 3] = idle;
        this.newdata[index + 4] = io;
        this.newdata[index + 5] = user + nice + sys;

        double total = 0;

        if (this.lastdata.length != 0) {
            for (uint i = index; i < index + 5; ++i)
                total += this.newdata[i] - this.lastdata[i];
            for (uint i = index; i < index + 6; ++i)
                this.values[i] = (this.newdata[i] - this.lastdata[i]) / total;
        }
    }

    public override void update() {
        GTop.Cpu cpu;
        GTop.get_cpu(out cpu);

        this.newdata = new uint64[(GTop.global_server->ncpu + 2) * 6];
        updatecpu(0, cpu.user, cpu.sys, cpu.nice, cpu.idle, cpu.iowait + cpu.irq + cpu.softirq);
        for (uint i = 0, isize = GTop.global_server->ncpu + 1; i < isize; ++i) {
            updatecpu((i + 1) * 6, cpu.xcpu_user[i], cpu.xcpu_sys[i], cpu.xcpu_nice[i],
                    cpu.xcpu_idle[i], cpu.xcpu_iowait[i] + cpu.xcpu_irq[i] + cpu.xcpu_softirq[i]);
        }

        this.lastdata = this.newdata;
        this.newdata = null;
    }
}

