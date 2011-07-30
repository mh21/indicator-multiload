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

public class GraphData : GLib.Object {
    private string[] _traces;
    private uint _trace_length;
    private string _smooth;

    private uint smoothvalue;
    private double[] scalerhistory;

    public string minimum { get; set; }
    public string maximum { get; set; } // TODO not used
    public string smooth { 
        get {
            return this._smooth;
        } 
        set {
            this._smooth = value;
            this.smoothvalue = (uint)uint64.parse(value);
            this.scalerhistory = null;
        } 
    }

    public Gdk.Color background_color { get; set; }
    public uint alpha { get; set; }
    public bool enabled { get; set; }
    public uint trace_length {
        get {
            return this._trace_length;
        }
        set {
            this._trace_length = value;
            foreach (var tracedata in this.tracedatas)
                tracedata.set_values_length(value);
        }
    }
    public string[] traces {
        get {
            return this._traces;
        }
        set {
            this._traces = value;
            while (this._tracedatas.length < this._traces.length) {
                var tracedata = new TraceData();
                tracedata.set_values_length(this._trace_length);
                this._tracedatas += tracedata;
            }
            this._tracedatas = this._tracedatas[0:this._traces.length];
        }
    }

    public string id { get; private set; }
    public double scale { get; private set; default = 1; }
    public TraceData[] tracedatas { get; private set; }

    public GraphData(string id) {
        this.id = id;
    }

    public void update(Data[] datas) {
        var parser = new ExpressionParser(datas);

        foreach (var tracedata in this.tracedatas) {
            var tokens = parser.tokenize(tracedata.expression);
            tracedata.add_value(double.parse(parser.evaluate(tokens)));
        }

        var minimumtokens = parser.tokenize(this.minimum);
        var scalerminimum = double.parse(parser.evaluate(minimumtokens));
        var maximumtokens = parser.tokenize(this.maximum);
        var scalermaximum = double.parse(parser.evaluate(maximumtokens));
        this.update_scale(scalerminimum, scalermaximum);
    }

    // Fast attack, slow decay
    // - each cycle, the peak value in the plot is determined
    // - if the peak value is greater than anything in the history buffer, the
    //   history buffer is filled with the peak value
    // - otherwise, the peak value is added to the history buffer at the end
    // - the scaling factor is the average of the history buffer:
    //   - it is never smaller than the peak value in the plot
    //   - after the current peak leaves the plot, the scaling factor gets
    //     reduced slowly
    private void update_scale(double scalerminimum, double scalermaximum) {
        double currentpeak = scalerminimum;
        for (uint i = 0, isize = this.trace_length; i < isize; ++i) {
            double currentvalue = 0;
            foreach (var tracedata in this.tracedatas)
                if (tracedata.enabled)
                    currentvalue += tracedata.values[i];
            currentpeak = double.max(currentpeak, currentvalue);
        }
        if (scalermaximum != 0)
            currentpeak = double.min(currentpeak, scalermaximum);
        if (this.scalerhistory.length == 0) {
            this.scalerhistory = new double[this.smoothvalue];
            for (uint i = 0; i < this.smoothvalue; ++i)
                this.scalerhistory[i] = scalerminimum;
        }
        double historymaximum = Utils.max(this.scalerhistory);
        if (currentpeak < historymaximum) {
            for (uint i = 0, isize = this.scalerhistory.length; i + 1 < isize; ++i)
                this.scalerhistory[i] = this.scalerhistory[i + 1];
        } else {
            for (uint i = 0, isize = this.scalerhistory.length; i + 1 < isize; ++i)
                this.scalerhistory[i] = currentpeak;
        }
        this.scalerhistory[this.scalerhistory.length - 1] = currentpeak;
        this.scale = Utils.mean(this.scalerhistory);
    }

    public void set_source_color(Cairo.Context ctx)
    {
        ctx.set_source_rgba(this.background_color.red / 65535.0,
                this.background_color.green / 65565.0,
                this.background_color.blue / 65565.0,
                this.alpha / 65565.0);
    }
}
