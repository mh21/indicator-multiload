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

public class IconData : GLib.Object {
    private uint _trace_length;
    private uint scalerdelay;
    private double[] scalerhistory;

    string[] expressions;
    string[] menuexpressions;
    string minimumexpression;

    public Gdk.Color color { get; set; }
    public uint alpha { get; set; default = 0xffff; }
    public bool enabled { get; set; default = true; }
    public string id { get; private set; }
    public double scale { get; private set; default = 1; }
    public string[] menuitems { get; protected set; default = {}; }
    public IconTraceData[] traces {get; private set; }
    public uint trace_length {
        get {
            return this._trace_length;
        }
        set {
            this._trace_length = value;
            foreach (var trace in this.traces)
                trace.set_values_length(value);
        }
    }

    // set scalerdelay to 1 and scalerminimum to 1 for percentage values without scaling
    public IconData(string id, string limits, string[] expressions, 
            string[] menuexpressions) {
        var slimits = limits.split(":");
        if (slimits.length < 1)
            slimits += "1";
        if (slimits.length < 2)
            slimits += "0"; // TODO: maximum
        if (slimits.length < 3)
            slimits += "1";

        this.expressions = expressions;
        this.menuexpressions = menuexpressions;
        this.minimumexpression = slimits[0];

        this.traces = new IconTraceData[expressions.length];
        for (uint i = 0, isize = this.traces.length; i < isize; ++i)
            this.traces[i] = new IconTraceData();
        this.id = id;
        this.trace_length = 16;
        this.scalerdelay = (uint)uint64.parse(slimits[2]);
        this.scalerhistory = null;
    }

    public void update(Data[] datas) {
        var parser = new ExpressionParser(datas);

        for (uint i = 0, isize = this.traces.length; i < isize; ++i) {
            var tokens = parser.tokenize(this.expressions[i]);
            this.traces[i].add_value(double.parse(parser.evaluate(tokens)));
        }

        {
            var tokens = parser.tokenize(this.minimumexpression);
            this.update_scale(double.parse(parser.evaluate(tokens)));
        }

        this.menuitems = new string[this.menuexpressions.length];
        for (uint i = 0, isize = this.menuexpressions.length; i < isize; ++i) {
            var tokens = parser.tokenize(this.menuexpressions[i]);
            this.menuitems[i] = parser.evaluate(tokens);
        }
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
    protected virtual void update_scale(double scalerminimum) {
        double currentpeak = scalerminimum;
        for (uint i = 0, isize = this.trace_length; i < isize; ++i) {
            double currentvalue = 0;
            foreach (var trace in this.traces)
                currentvalue += trace.values[i];
            currentpeak = double.max(currentpeak, currentvalue);
        }
        if (this.scalerhistory.length == 0) {
	    this.scalerhistory = new double[this.scalerdelay];
	    for (uint i = 0; i < this.scalerdelay; ++i)
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
        ctx.set_source_rgba(this.color.red / 65535.0,
                this.color.green / 65565.0,
                this.color.blue / 65565.0,
                this.alpha / 65565.0);
    }
}
