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

public class GraphModel : Object {
    private uint smoothvalue;
    private double[] scalerhistory;

    public string id { get; construct; }
    public Providers providers {get; construct; }
    public ExpressionCache minimum { get; construct; }
    public ExpressionCache maximum { get; construct; }
    public string smooth { get; set; }
    public Gdk.Color background_color { get; set; }
    public uint alpha { get; set; }
    public bool enabled { get; set; }
    public string[] traces { get; set; }
    public double scale { get; private set; default = 1; }

    // not a real property because of unsupported datatype, no notify
    public TraceModel[] tracemodels { get; private set; }

    construct {
        this.notify["smooth"].connect(() => {
                this.smoothvalue = (uint)uint64.parse(this.smooth);
                this.scalerhistory = null;
            });
        this.notify["traces"].connect(() => {
                while (this._tracemodels.length < this._traces.length)
                    this._tracemodels += new TraceModel(this.providers);
                this._tracemodels = this._tracemodels[0:this._traces.length];
            });
    }

    public GraphModel(string id, Providers providers) {
        Object(id: id, providers: providers,
                minimum: new ExpressionCache(providers, ""),
                maximum: new ExpressionCache(providers, ""));
    }

    public void update(uint trace_length) {
        foreach (var tracemodel in this.tracemodels) {
            tracemodel.set_values_length(trace_length);
            tracemodel.expression.update();
            tracemodel.add_value(double.parse(tracemodel.expression.label()));
        }

        var scalerminimum = double.parse(this.minimum.label());
        var scalermaximum = double.parse(this.maximum.label());
        this.update_scale(scalerminimum, scalermaximum, trace_length);
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
    private void update_scale(double scalerminimum, double scalermaximum, uint trace_length) {
        double currentpeak = scalerminimum;
        for (uint i = 0, isize = trace_length; i < isize; ++i) {
            double currentvalue = 0;
            foreach (var tracemodel in this.tracemodels)
                if (tracemodel.enabled)
                    currentvalue += tracemodel.values[i];
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
