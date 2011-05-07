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

public class IconTraceData : GLib.Object {
    private double[] _values;

    public Gdk.Color color { get; set; }
    public double[] values {
        get {
            return _values;
        }
    }

    public void set_values_length(uint length) {
        if (length > this._values.length) {
            var newvalues = new double[length];
            var offset = length - this._values.length;
            for (uint i = 0, isize = this._values.length; i < isize; ++i)
                newvalues[offset + i] = this._values[i];
            this._values = newvalues;
        } else if (length < this._values.length) {
            this._values = this._values[this._values.length - length:this._values.length];
        }
    }

    public void add_value(double value) {
        for (uint i = 0, isize = this._values.length; i + 1 < isize; ++i)
            this._values[i] = this._values[i + 1];
        this._values[this._values.length - 1] = value;
    }
}
