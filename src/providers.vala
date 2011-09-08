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

public class Providers : Object {
    public Provider[] providers { get; private set; }

    construct {
        this.providers = {
            new CpuProvider(), new MemProvider(), new NetProvider(),
            new SwapProvider(), new LoadProvider(), new DiskProvider()
        };
        this.update();
    }

    public double value(string variable, out bool found)
    {
        var varparts = variable.split(".");
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

    public void update() {
        foreach (var provider in this.providers)
            provider.update();
    }
}
