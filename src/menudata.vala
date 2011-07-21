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

public class MenuData : GLib.Object {
    string[] menuexpressions;

    public string[] menuitems { get; private set; default = {}; }

    public MenuData(string[] menuexpressions) {
        this.menuexpressions = menuexpressions;
    }

    public void update(Data[] datas) {
        var parser = new ExpressionParser(datas);

        this.menuitems = new string[this.menuexpressions.length];
        for (uint i = 0, isize = this.menuexpressions.length; i < isize; ++i) {
            var tokens = parser.tokenize(this.menuexpressions[i]);
            this.menuitems[i] = parser.evaluate(tokens);
        }
    }
}
