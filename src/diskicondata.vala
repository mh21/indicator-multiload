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

public class DiskIconData : IconData {
    private uint64[] lastdata;
    private uint64 lasttime;

    public DiskIconData() {
        // minimum of 1 kb/s
        base("diskload", 2, 10, 1000);
    }

    public override void update_traces() {
        uint64[] newdata = new uint64[3];
        uint64 newtime = get_monotonic_time();

        // TODO: This does not work for LVM or virtual fs
        // may give weird results anyway if there are two partitions on the same drive?
        // on Linux, maybe copy the code from iotop?
        GTop.MountEntry[] mountentries;
        GTop.MountList mountlist;
        mountentries = GTop.get_mountlist (out mountlist, false);

        for (uint i = 0; i < mountlist.number; ++i) {
            GTop.FSUsage fsusage;
            GTop.get_fsusage(out fsusage, mountentries[i].mountdir);
            newdata[0] += fsusage.read;
            newdata[1] += fsusage.write;
        }

        if (this.lastdata.length == 0) {
            foreach (unowned IconTraceData trace in this.traces)
                trace.add_value(0);
        } else {
            double delta = (newtime - this.lasttime) / 1e6;
            for (uint i = 0, isize = this.traces.length; i < isize; ++i)
                this.traces[i].add_value((newdata[i] - this.lastdata[i]) / delta);
        }
        this.lastdata = newdata;
        this.lasttime = newtime;

        base.update_traces();
    }
}
