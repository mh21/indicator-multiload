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

public class MenuModel : GLib.Object {
    public string[] labels { get; private set; default = {}; }
    public string[] guides { get; private set; default = {}; }
    public string[] expressions { get; set; }
    public string[] guide_expressions { get; set; }

    public void update(Providers providers) {
        var parser = new ExpressionParser(providers);

        this.labels = new string[this._expressions.length];
        for (uint i = 0, isize = this._expressions.length; i < isize; ++i)
            this.labels[i] = parser.parse(this._expressions[i]);

        this.guides = new string[this._guide_expressions.length];
        for (uint i = 0, isize = this._guide_expressions.length; i < isize; ++i)
            this.guides[i] = parser.parse(this._guide_expressions[i]);
    }
}
