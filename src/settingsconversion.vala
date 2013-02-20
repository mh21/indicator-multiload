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

public class SettingsConversion : Object {
    SettingsCache settingscache = new SettingsCache();

    public void convert() {
        var settings = this.settingscache.generalsettings();
        if (settings.get_value("settings-version").get_uint32() == 3) {
            return;
        }
        if (new Settings.with_path("de.mh21.indicator-multiload.version2.general",
                    "/apps/indicators/multiload/general/")
                .get_value("settings-version").get_uint32() == 2) {
            this.convert_version2();
        } else {
            this.convert_version1();
        }
        //settings.set_value("settings-version", 3u);
    }

    private void convert_version1() {
        var oldsettings = new Settings.with_path
            ("de.mh21.indicator-multiload.version1", "/apps/indicators/multiload/");
        foreach (var key in oldsettings.list_keys()) {
            var value = oldsettings.get_value(key);
            oldsettings.reset(key);
            var defaultvalue = oldsettings.get_value(key);
            if (!value.equal(defaultvalue)) {
                switch (key) {
                // alpha and background values are not converted
                case "view-cpuload":
                    this.settingscache.graphsettings("cpu").set_value("enabled", value);
                    break;
                case "view-memload":
                    this.settingscache.graphsettings("mem").set_value("enabled", value);
                    break;
                case "view-netload":
                    this.settingscache.graphsettings("net").set_value("enabled", value);
                    break;
                case "view-swapload":
                    this.settingscache.graphsettings("swap").set_value("enabled", value);
                    break;
                case "view-loadavg":
                    this.settingscache.graphsettings("load").set_value("enabled", value);
                    break;
                case "view-diskload":
                    this.settingscache.graphsettings("disk").set_value("enabled", value);
                    break;
                case "cpuload-color0":
                    this.settingscache.tracesettings("cpu", "cpu1").set_value("color", value);
                    break;
                case "cpuload-color1":
                    this.settingscache.tracesettings("cpu", "cpu2").set_value("color", value);
                    break;
                case "cpuload-color2":
                    this.settingscache.tracesettings("cpu", "cpu3").set_value("color", value);
                    break;
                case "cpuload-color3":
                    this.settingscache.tracesettings("cpu", "cpu4").set_value("color", value);
                    break;
                case "memload-color0":
                    this.settingscache.tracesettings("mem", "mem1").set_value("color", value);
                    break;
                case "memload-color1":
                    this.settingscache.tracesettings("mem", "mem2").set_value("color", value);
                    break;
                case "memload-color2":
                    this.settingscache.tracesettings("mem", "mem3").set_value("color", value);
                    break;
                case "memload-color3":
                    this.settingscache.tracesettings("mem", "mem4").set_value("color", value);
                    break;
                case "netload-color0":
                    this.settingscache.tracesettings("net", "net1").set_value("color", value);
                    break;
                case "netload-color1":
                    this.settingscache.tracesettings("net", "net2").set_value("color", value);
                    break;
                case "netload-color2":
                    this.settingscache.tracesettings("net", "net3").set_value("color", value);
                    break;
                case "swapload-color0":
                    this.settingscache.tracesettings("swap", "swap1").set_value("color", value);
                    break;
                case "loadavg-color0":
                    this.settingscache.tracesettings("load", "load1").set_value("color", value);
                    break;
                case "diskload-color0":
                    this.settingscache.tracesettings("disk", "disk1").set_value("color", value);
                    break;
                case "diskload-color1":
                    this.settingscache.tracesettings("disk", "disk2").set_value("color", value);
                    break;
                case "speed":
                    this.settingscache.generalsettings().set_value("speed", value);
                    break;
                case "size":
                    this.settingscache.generalsettings().set_value("width", value);
                    break;
                case "height":
                    this.settingscache.generalsettings().set_value("height", value);
                    break;
                case "system-monitor":
                    this.settingscache.generalsettings().set_value("system-monitor", value);
                    break;
                case "autostart":
                    this.settingscache.generalsettings().set_value("autostart", value);
                    break;
                }
            }
        }
    }

    private static const string[] version2graphs = {
        "cpu", "mem", "net", "swap", "load", "disk"
    };

    private static const uint[] version2traces = {
        4, 4, 3, 1, 1, 2
    };

    private void copysettings(Settings oldsettings, Settings newsettings, string[] ignore) {
        foreach (var key in oldsettings.list_keys()) {
            if (key in ignore)
                continue;
            var value = oldsettings.get_value(key);
            oldsettings.reset(key);
            var defaultvalue = oldsettings.get_value(key);
            if (!value.equal(defaultvalue))
                newsettings.set_value(key, value);
        }
    }

    private void convert_version2() {
        copysettings(new Settings.with_path
                (@"de.mh21.indicator-multiload.version2.general",
                    @"/apps/indicators/multiload/general/"),
                this.settingscache.generalsettings(),
                {"settings-version"});
        for (uint j = 0, jsize = version2graphs.length; j < jsize; ++j) {
            var graph = version2graphs[j];
            copysettings(new Settings.with_path
                    (@"de.mh21.indicator-multiload.version2.graphs.$graph",
                     @"/apps/indicators/multiload/graphs/$graph/"),
                    this.settingscache.graphsettings(graph),
                    {"alpha", "background-color"});
            for (uint i = 1, isize = version2traces[j]; i <= isize; ++i) {
                copysettings(new Settings.with_path
                        (@"de.mh21.indicator-multiload.version2.traces.$graph$i",
                         @"/apps/indicators/multiload/graphs/$graph/$graph$i/"),
                        this.settingscache.tracesettings(graph, @"$graph$i"),
                        {});
            }
        }
    }
}

