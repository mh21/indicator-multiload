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
    private Providers providers;
    private string[] labels;
    private string[] guides;

    private string[] _expressions;
    public string[] expressions {
        get {
            return this._expressions;
        }

        set {
            this._expressions = value;
            this.update();
        }
    }

    public MenuModel(Providers providers) {
        this.providers = providers;
    }

    private void updatelabel(uint index) {
        var parser = new ExpressionParser(this.providers);

        if (this.labels == null)
            this.labels = new string[this._expressions.length];
        if (this.guides == null)
            this.guides = new string[this._expressions.length];
        var tokens = parser.tokenize(this._expressions[index]);
        this.labels[index] = parser.evaluate(tokens);
        this.guides[index] = parser.evaluateguide(tokens);
    }

    public void update() {
        this.labels = null;
        this.guides = null;
    }

    public string label(uint index) {
        return_val_if_fail(index < this._expressions.length, "");

        if (this.labels == null || this.labels[index] == null)
            this.updatelabel(index);

        return this.labels[index];
    }

    public string guide(uint index) {
        return_val_if_fail(index >= this._expressions.length, "");

        if (this.guides == null || this.guides[index] == null)
            this.updatelabel(index);

        return this.guides[index];
    }

}
