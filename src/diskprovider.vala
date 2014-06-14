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

public class DiskProvider : Provider {
    private uint64[] lastdata;
    private uint64 lasttime;
    private static const string[] networkfs = { "smbfs", "nfs", "cifs", "fuse.sshfs" };

    public DiskProvider() {
        base("disk", {"read", "write"}, "s");
    }

    private string[] split(string val) {
        string[] result = null;
        char *last = null;
        char *current = (char*)val;
        for (; *current != '\0'; current = current + 1) {
            if (*current == ' ' || *current == '\n') {
                if (last != null) {
                    result += strndup(last, current - last);
                    last = null;
                }
            } else {
                if (last == null)
                    last = current;
            }
        }
        if (last != null)
            result += strndup(last, current - last);
        return result;
    }

    public override void update() {
        uint64[] newdata = new uint64[3];
        uint64 newtime = get_monotonic_time();

        try {
            // Accounts for io for everything that has an associated device
            // TODO: will jump on unmount
            Dir directory = Dir.open("/sys/block");
            string entry;
            while ((entry = directory.read_name()) != null) {
                if (!FileUtils.test(@"/sys/block/$entry/device", FileTest.EXISTS))
                    continue;
                string stat;
                try {
                    FileUtils.get_contents(@"/sys/block/$entry/stat", out stat);
                } catch (Error e) {
                    continue;
                }
                string[] stats = this.split(stat);
                if (stats.length < 8)
                    continue;
                newdata[0] += 512 * uint64.parse(stats[2]);
                newdata[1] += 512 * uint64.parse(stats[6]);
            }
        } catch (Error e) {
            // Fall back to libgtop if we have no /sys
            GTop.MountEntry[] mountentries;
            GTop.MountList mountlist;
            mountentries = GTop.get_mountlist (out mountlist, false);
            for (uint i = 0; i < mountlist.number; ++i) {
                // Skip network mounts to prevent hangs if not available and to
                // allow suspend (gnome bug #579888)
                if (mountentries[i].type in networkfs)
                    continue;
                GTop.FSUsage fsusage;
                GTop.get_fsusage(out fsusage, mountentries[i].mountdir);
                newdata[0] += fsusage.block_size * fsusage.read;
                newdata[1] += fsusage.block_size * fsusage.write;
            }
        }

        if (this.lastdata.length != 0) {
            double delta = (newtime - this.lasttime) / 1e6;
            this.values[0] = (newdata[0] - this.lastdata[0]) / delta;
            this.values[1] = (newdata[1] - this.lastdata[1]) / delta;
        }
        this.lastdata = newdata;
        this.lasttime = newtime;
    }
}
