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

public class NetIconData : IconData {
    private uint64[] lastdata;
    private uint64 lasttime;

    public NetIconData() {
        // minimum of 5kb/s
        base("netload", 3, 10, 5000);
    }

    public override void update() {
        uint64[] newdata = new uint64[3];
        uint64 newtime = get_monotonic_time();

        string[] devices;
        GTop.NetList netlist;
        devices = GTop.get_netlist(out netlist);
        for (uint i = 0; i < netlist.number; ++i) {
            GTop.NetLoad netload;
            GTop.get_netload(out netload, devices[i]);
            if ((netload.if_flags & (1L << GTop.IFFlags.UP)) == 0) {
                // ignore (counters jumps to zero when shut down)
            } else if (FileUtils.test("/sys/class/net/%s/device".printf(devices[i]), FileTest.EXISTS)) {
                newdata[0] += netload.bytes_in;
                newdata[1] += netload.bytes_out;
            } else if ((netload.if_flags & (1L << GTop.IFFlags.LOOPBACK)) > 0) {
                newdata[2] += netload.bytes_in;
            }
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

        this.update_scale();
    }
}
