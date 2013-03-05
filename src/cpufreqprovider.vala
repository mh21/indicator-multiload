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

public class CpuFreqProvider : Provider {

    private static string[] fields() {
        GTop.init();
        string[] templates = {"cur", "min", "max"};
        string[] result = new string[(GTop.global_server->ncpu + 2) * 3];
        for (uint j = 0; j < 3; ++j) {
            var template = templates[j];
            result[j] = template;
            for (uint i = 0, isize = GTop.global_server->ncpu + 1; i < isize; ++i)
                result[(i + 1) * 3 + j] = @"$template$i";
        }
        return result;
    }

    private static double read(uint cpu, string what) {
        string value;
        try {
            FileUtils.get_contents(@"/sys/devices/system/cpu/cpu$cpu/cpufreq/$what", out value);
        } catch (Error e) {
            value = "0";
        }
        return double.parse(value);
    }

    public CpuFreqProvider() {
        base("cpufreq", fields(), 'f');
    }

    construct {
        double minmin = 0, maxmax = 0;
        for (uint i = 0, isize = GTop.global_server->ncpu + 1; i < isize; ++i) {
            var min = 1000.0 * read(i, "cpuinfo_min_freq");
            var max = 1000.0 * read(i, "cpuinfo_max_freq");
            if (i == 0) {
                minmin = min;
                maxmax = max;
            } else {
                minmin = double.min(min, minmin);
                maxmax = double.max(max, maxmax);
            }
            this.values[(i + 1) * 3 + 1] = min;
            this.values[(i + 1) * 3 + 2] = max;
        }
        this.values[1] = minmin;
        this.values[2] = maxmax;
    }

    public override void update() {
        double maxcur = 0;
        for (uint i = 0, isize = GTop.global_server->ncpu + 1; i < isize; ++i) {
            var cur = 1000.0 * read(i, "scaling_cur_freq");
            if (i == 0) {
                maxcur = cur;
            } else {
                maxcur = double.max(cur, maxcur);
            }
            this.values[(i + 1) * 3 + 0] = cur;
        }
        this.values[0] = maxcur;
    }
}

