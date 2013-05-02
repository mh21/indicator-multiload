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

public class NetProvider : Provider {
    private uint64[] lastdata;
    private uint64 lasttime;
    private string[] devicefields;

    private static string[] fields(out string[] devices) {
        GTop.init();

        GTop.NetList netlist;
        devices = GTop.get_netlist(out netlist);

        string[] result = new string[3 + 2 * netlist.number];
        result[0] = "down";
        result[1] = "up";
        result[2] = "local";
        for (uint j = 0; j < netlist.number; ++j) {
            var device = devices[j];
            result[3 + 2 * j] = @"$device.down";
            result[3 + 2 * j + 1] = @"$device.up";
        }
        return result;
    }

    public NetProvider() {
        string[] devices;
        base("net", fields(out devices), 's');
        this.devicefields = devices;
    }

    public override void update() {
        uint64[] newdata = new uint64[keys.length];
        uint64 newtime = get_monotonic_time();

        GTop.NetList netlist;
        string[] devices = GTop.get_netlist(out netlist);
        debug("Netlist: %u entries", netlist.number);
        for (uint i = 0; i < netlist.number; ++i) {
            var device = devices[i];
            GTop.NetLoad netload;
            GTop.get_netload(out netload, device);
            debug("Netload: " + device);
            debug("  flags: %x", (uint32)netload.flags);
            debug("  if flags: %x", (uint32)netload.if_flags);
            debug("  mtu: " + netload.mtu.to_string());
            debug("  subnet: " + netload.subnet.to_string());
            debug("  address: " + netload.address.to_string());
            debug("  packets in: " + netload.packets_in.to_string());
            debug("  packets out: " + netload.packets_out.to_string());
            debug("  packets total: " + netload.packets_total.to_string());
            debug("  bytes in: " + netload.bytes_in.to_string());
            debug("  bytes out: " + netload.bytes_out.to_string());
            debug("  bytes total: " + netload.bytes_total.to_string());
            debug("  errors in: " + netload.errors_in.to_string());
            debug("  errors out: " + netload.errors_out.to_string());
            debug("  errors total: " + netload.errors_total.to_string());
            debug("  collisions: " + netload.collisions.to_string());
            if (((netload.if_flags & (1L << GTop.IFFlags.UP)) == 0) |
                ((netload.if_flags & (1L << GTop.IFFlags.RUNNING)) == 0)) {
                // TODO: transient high differences when shut down
                debug("  down or not running");
            } else if (FileUtils.test("/sys/class/net/%s/device".printf(device), FileTest.EXISTS)) {
                newdata[0] += netload.bytes_in;
                newdata[1] += netload.bytes_out;
                debug("  existing device link");
            } else if ((netload.if_flags & (1L << GTop.IFFlags.POINTOPOINT)) > 0) {
                newdata[0] += netload.bytes_in;
                newdata[1] += netload.bytes_out;
                debug("  pointtopoint");
            } else if ((netload.if_flags & (1L << GTop.IFFlags.LOOPBACK)) > 0) {
                newdata[2] += netload.bytes_in;
                debug("  loopback");
            } else {
                debug("  unknown");
            }
            for (uint j = 0, isize = devicefields.length; j < isize; ++j) {
                if (devicefields[j] == device) {
                    newdata[3 + j * 2] = netload.bytes_in;
                    newdata[3 + j * 2 + 1] = netload.bytes_out;
                    break;
                }
            }
        }

        if (this.lastdata.length != 0) {
            double delta = (newtime - this.lasttime) / 1e6;
            for (uint i = 0, isize = this.values.length; i < isize; ++i)
                this.values[i] = (newdata[i] - this.lastdata[i]) / delta;
        }
        this.lastdata = newdata;
        this.lasttime = newtime;
    }
}
