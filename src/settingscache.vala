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

public class SettingsCache : Object {
    public static const string[] presetgraphids = {"cpu", "mem", "net", "load", "swap", "disk"};
    private HashTable<string, FixedGSettings.Settings> cached =
        new HashTable<string, FixedGSettings.Settings>.full
            (str_hash, str_equal, g_free, g_object_unref);

    private FixedGSettings.Settings settings(string key, string? path) {
        var result = this.cached.lookup(key);
        if (result == null) {
            result = path == null ?
                new FixedGSettings.Settings(key) :
                new FixedGSettings.Settings.with_path(key, path);
            this.cached.insert(path == null ? key : @"$key:$path", result);
        }
        return result;
    }

    public List<unowned FixedGSettings.Settings> cachedsettings() {
        return this.cached.get_values();
    }

    public FixedGSettings.Settings generalsettings() {
        return this.settings("de.mh21.indicator.multiload.general", null);
    }

    public FixedGSettings.Settings graphsettings(string graphid) {
        if (graphid in presetgraphids)
            return this.settings
                (@"de.mh21.indicator.multiload.graphs.$graphid", null);
        return this.settings
            ("de.mh21.indicator.multiload.graph",
             @"/apps/indicators/multiload/graphs/$graphid/");
    }

    public FixedGSettings.Settings tracesettings(string graphid,
            string traceid) {
        if (graphid in presetgraphids)
            return this.settings
                (@"de.mh21.indicator.multiload.traces.$traceid", null);
        return this.settings
            ("de.mh21.indicator.multiload.trace",
             @"/apps/indicators/multiload/graphs/$graphid/$traceid/");
    }
}
