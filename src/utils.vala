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

namespace Utils {
    public string uifile;

    public double max(double[] data) {
        if (data.length == 0)
            return 0;
        double result = data[0];
        foreach (var v in data)
            if (result < v)
                result = v;
        return result;
    }

    public double mean(double[] data) {
        if (data.length == 0)
            return 0;
        double result = 0;
        foreach (var v in data)
            result += v;
        return result / data.length;
    }

    // for SI units as g_format_size_for_display uses base 2
    public string format_size(double val) {
        const string[] units = {
            // TRANSLATORS: Please leave {} as it is, it is replaced by the size
            N_("{} kB"),
            // TRANSLATORS: Please leave {} as it is, it is replaced by the size
            N_("{} MB"),
            // TRANSLATORS: Please leave {} as it is, it is replaced by the size
            N_("{} GB")
        };
        int index = -1;
        while (index + 1 < units.length && (val >= 1000 || index < 0)) {
            val /= 1000;
            ++index;
        }
        if (index < 0)
            // TRANSLATORS: Please leave %u as it is, it is replaced by the size
            return ngettext("%u B", "%u B",
                    (ulong)val).printf((uint)val);
        // 4 significant digits
        var pattern = _(units[index]).replace("{}",
            val <   9.95 ? "%.1f" :
            val <  99.5  ? "%.0f" :
            val < 999.5  ? "%.0f" : "%.0f");
        return pattern.printf(val);
    }

    public string format_speed(double val) {
        const string[] units = {
            // TRANSLATORS: Please leave {} as it is, it is replaced by the speed
            N_("{} kB/s"),
            // TRANSLATORS: Please leave {} as it is, it is replaced by the speed
            N_("{} MB/s"),
            // TRANSLATORS: Please leave {} as it is, it is replaced by the speed
            N_("{} GB/s"),
            // TRANSLATORS: Please leave {} as it is, it is replaced by the speed
            N_("{} TB/s")
        };
        int index = -1;
        while (index + 1 < units.length && (val >= 1000 || index < 0)) {
            val /= 1000;
            ++index;
        }
        if (index < 0)
            // TRANSLATORS: Please leave %u as it is, it is replaced by the speed
            return ngettext("%u B/s", "%u B/s",
                    (ulong)val).printf((uint)val);
        // 4 significant digits
        var pattern = _(units[index]).replace("{}",
            val <   9.95 ? "%.1f" :
            val <  99.5  ? "%.0f" :
            val < 999.5  ? "%.0f" : "%.0f");
        return pattern.printf(val);
    }

    public string format_bitrate(double val) {
        const string[] units = {
            // TRANSLATORS: Please leave {} as it is, it is replaced by the bitrate
            N_("{} kbit/s"),
            // TRANSLATORS: Please leave {} as it is, it is replaced by the bitrate
            N_("{} Mbit/s"),
            // TRANSLATORS: Please leave {} as it is, it is replaced by the bitrate
            N_("{} Gbit/s"),
            // TRANSLATORS: Please leave {} as it is, it is replaced by the bitrate
            N_("{} Tbit/s")
        };
        int index = -1;
        while (index + 1 < units.length && (val >= 1000 || index < 0)) {
            val /= 1000;
            ++index;
        }
        if (index < 0)
            // TRANSLATORS: Please leave %u as it is, it is replaced by the bit rate
            return ngettext("%u bit/s", "%u bit/s",
                    (ulong)val).printf((uint)val);
        // 4 significant digits
        var pattern = _(units[index]).replace("{}",
            val <   9.95 ? "%.1f" :
            val <  99.5  ? "%.0f" :
            val < 999.5  ? "%.0f" : "%.0f");
        return pattern.printf(val);
    }

    public string format_frequency(double val) {
        const string[] units = {
            // TRANSLATORS: Please leave {} as it is, it is replaced by the frequency
            N_("{} kHz"),
            // TRANSLATORS: Please leave {} as it is, it is replaced by the frequency
            N_("{} MHz"),
            // TRANSLATORS: Please leave {} as it is, it is replaced by the frequency
            N_("{} GHz")
        };
        int index = -1;
        while (index + 1 < units.length && (val >= 1000 || index < 0)) {
            val /= 1000;
            ++index;
        }
        if (index < 0)
            // TRANSLATORS: Please leave %u as it is, it is replaced by the frequency
            return ngettext("%u Hz", "%u Hz",
                    (ulong)val).printf((uint)val);
        // 4 significant digits
        var pattern = _(units[index]).replace("{}",
            val <   9.95 ? "%.1f" :
            val <  99.5  ? "%.0f" :
            val < 999.5  ? "%.0f" : "%.0f");
        return pattern.printf(val);
    }

    public Object get_ui(string objectid, Object signalhandlers,
            string[] additional = {}, out Gtk.Builder builder = null) {
        builder = new Gtk.Builder();
        string[] ids = additional;
        ids += objectid;
        try {
            builder.add_objects_from_file(Utils.uifile, ids);
        } catch (Error e) {
            stderr.printf("Could not load indicator ui %s from %s: %s\n",
                    objectid, Utils.uifile, e.message);
        }
        builder.connect_signals(signalhandlers);
        return builder.get_object(objectid);
    }

    public bool get_settings_rgba(Value value, Variant variant,
            void *user_data)
    {
        Gdk.RGBA rgba = Gdk.RGBA();
        if (ColorMapper.parse_colorname(variant.get_string(), ref rgba)) {
            value.set_boxed(&rgba);
            return true;
        }
        return false;
    }

    public Variant set_settings_rgba(Value value, VariantType expected_type,
            void *user_data)
    {
        Gdk.RGBA rgba = *(Gdk.RGBA*)value.get_boxed();
        return new Variant.string(rgba.to_string());
    }
}
