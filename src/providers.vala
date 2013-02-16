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

public class Providers : Object {
    public Provider[] providers { get; private set; }
    public Function[] functions { get; private set; }

    construct {
        this.providers = {
            new CpuProvider(), new MemProvider(), new NetProvider(),
            new SwapProvider(), new LoadProvider(), new DiskProvider()
        };
        this.update();
        this.functions = {
            new DecimalsFunction(), new SizeFunction(),
            new SpeedFunction(), new PercentFunction()
        };
    }

    // TODO: use exceptions
    public double value(string name, out bool found)
    {
        var varparts = name.split(".");
        return_val_if_fail(varparts.length == 2, 0);

        found = true;
        foreach (var provider in this.providers) {
            if (provider.id != varparts[0])
                continue;
            for (uint j = 0, jsize = provider.keys.length; j < jsize; ++j) {
                if (provider.keys[j] != varparts[1])
                    continue;
                return provider.values[j];
            }
        }

        found = false;
        return 0;
    }

    public string call(string name, string[] parameters, bool widest, out bool found) throws Error
    {
        found = true;
        foreach (var function in this.functions) {
            if (function.id != name)
                continue;
            return function.call(parameters, widest);
        }

        found = false;
        return "";
    }

    public void update() {
        foreach (var provider in this.providers)
            provider.update();
    }
}
