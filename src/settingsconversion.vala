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

public class SettingsConversion : Object {
    public SettingsConversion() {
    }

    public uint oldversion() {
        var settings = Utils.generalsettings();
        return settings.get_value("settings-version").get_uint32();
    }

    public bool is_current() {
        return this.oldversion() == 2;
    }

    public void convert() {
        var settings = Utils.generalsettings();

        while (!this.is_current()) {
            switch (this.oldversion()) {
            case 1:
                this.convert_version1();
                break;
            }
            settings.set_value("settings-version", this.oldversion() + 1);
        }
    }

    private void convert_version1() {
        var oldsettings = new FixedGSettings.Settings.with_path
            ("de.mh21.indicator.multiload.version1", "/apps/indicators/multiload/");
        foreach (var key in oldsettings.list_keys()) {
            var value = oldsettings.get_value(key);
            oldsettings.reset(key);
            var defaultvalue = oldsettings.get_value(key);
            if (!value.equal(defaultvalue)) {
                // TODO: this is not converting between 1 and 2, but between 1 and current
                // no problem yet as we are only at settings version 2
                switch (key) {
                case "cpuload-alpha4":
                    Utils.graphsettings("cpu").set_value("alpha", value);
                    break;
                case "memload-alpha4":
                    Utils.graphsettings("mem").set_value("alpha", value);
                    break;
                case "netload-alpha3":
                    Utils.graphsettings("net").set_value("alpha", value);
                    break;
                case "swapload-alpha1":
                    Utils.graphsettings("swap").set_value("alpha", value);
                    break;
                case "loadavg-alpha1":
                    Utils.graphsettings("load").set_value("alpha", value);
                    break;
                case "diskload-alpha2":
                    Utils.graphsettings("disk").set_value("alpha", value);
                    break;
                case "view-cpuload":
                    Utils.graphsettings("cpu").set_value("enabled", value);
                    break;
                case "view-memload":
                    Utils.graphsettings("mem").set_value("enabled", value);
                    break;
                case "view-netload":
                    Utils.graphsettings("net").set_value("enabled", value);
                    break;
                case "view-swapload":
                    Utils.graphsettings("swap").set_value("enabled", value);
                    break;
                case "view-loadavg":
                    Utils.graphsettings("load").set_value("enabled", value);
                    break;
                case "view-diskload":
                    Utils.graphsettings("disk").set_value("enabled", value);
                    break;
                case "cpuload-color0":
                    Utils.tracesettings("cpu", "cpu1").set_value("color", value);
                    break;
                case "cpuload-color1":
                    Utils.tracesettings("cpu", "cpu2").set_value("color", value);
                    break;
                case "cpuload-color2":
                    Utils.tracesettings("cpu", "cpu3").set_value("color", value);
                    break;
                case "cpuload-color3":
                    Utils.tracesettings("cpu", "cpu4").set_value("color", value);
                    break;
                case "cpuload-color4":
                    Utils.graphsettings("cpu").set_value("background-color", value);
                    break;
                case "memload-color0":
                    Utils.tracesettings("mem", "mem1").set_value("color", value);
                    break;
                case "memload-color1":
                    Utils.tracesettings("mem", "mem2").set_value("color", value);
                    break;
                case "memload-color2":
                    Utils.tracesettings("mem", "mem3").set_value("color", value);
                    break;
                case "memload-color3":
                    Utils.tracesettings("mem", "mem4").set_value("color", value);
                    break;
                case "memload-color4":
                    Utils.graphsettings("mem").set_value("background-color", value);
                    break;
                case "netload-color0":
                    Utils.tracesettings("net", "net1").set_value("color", value);
                    break;
                case "netload-color1":
                    Utils.tracesettings("net", "net2").set_value("color", value);
                    break;
                case "netload-color2":
                    Utils.tracesettings("net", "net3").set_value("color", value);
                    break;
                case "netload-color3":
                    Utils.graphsettings("net").set_value("background-color", value);
                    break;
                case "swapload-color0":
                    Utils.tracesettings("swap", "swap1").set_value("color", value);
                    break;
                case "swapload-color1":
                    Utils.graphsettings("swap").set_value("background-color", value);
                    break;
                case "loadavg-color0":
                    Utils.tracesettings("load", "load1").set_value("color", value);
                    break;
                case "loadavg-color1":
                    Utils.graphsettings("load").set_value("background-color", value);
                    break;
                case "diskload-color0":
                    Utils.tracesettings("disk", "disk1").set_value("color", value);
                    break;
                case "diskload-color1":
                    Utils.tracesettings("disk", "disk2").set_value("color", value);
                    break;
                case "diskload-color2":
                    Utils.graphsettings("disk").set_value("background-color", value);
                    break;
                case "speed":
                    Utils.generalsettings().set_value("speed", value);
                    break;
                case "size":
                    Utils.generalsettings().set_value("size", value);
                    break;
                case "height":
                    Utils.generalsettings().set_value("height", value);
                    break;
                case "system-monitor":
                    Utils.generalsettings().set_value("system-monitor", value);
                    break;
                case "autostart":
                    Utils.generalsettings().set_value("autostart", value);
                    break;
                }
            }
        }
    }
}

