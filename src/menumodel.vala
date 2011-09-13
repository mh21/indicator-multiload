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

public class MenuModel : Object {
    private Providers providers;
    private ExpressionCache[] caches;

    public string[] expressions { get; set; }

    construct {
        this.notify["expressions"].connect(() => {
                this.caches = new ExpressionCache[this._expressions.length];
                for (uint i = 0, isize = this.caches.length; i < isize; ++i)
                    this.caches[i] = new ExpressionCache(this.providers, this._expressions[i]);
            });
    }

    public MenuModel(Providers providers) {
        this.providers = providers;
    }

    public void update() {
        foreach (var cache in this.caches)
            cache.update();
    }

    public ExpressionCache expression(uint index)
        requires(index < this.caches.length)
    {
        return this.caches[index];
    }
}
