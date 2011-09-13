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

public class GraphModels : Object {
    public Providers providers {get; construct; }
    public GraphModel[] graphmodels { get; private set; }

    public GraphModels(string[] graphids, Providers providers) {
        Object(providers: providers);
        foreach (var graphid in graphids)
            this._graphmodels += new GraphModel(graphid, this.providers);
    }

    public void update(uint trace_length) {
        foreach (var graphmodel in this.graphmodels)
            graphmodel.update(trace_length);
    }
}
