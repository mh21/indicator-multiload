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

public class MultiLoadIndicator : Indicator {
    private AppIndicator.Indicator indicator;

    public MultiLoadIndicator(string icondirectory, Providers providers,
            Gtk.Menu menu) {
        base(icondirectory, providers, menu);
    }

    construct {
        this.indicator = new AppIndicator.Indicator.with_path("multiload", "",
                AppIndicator.IndicatorCategory.SYSTEM_SERVICES, this.icondirectory);
        this.indicator.set_status(AppIndicator.IndicatorStatus.ACTIVE);
        this.indicator.set_menu(this.menu);
        this.indicator.scroll_event.connect(this.scrollhandler);
        this.indicator.set_secondary_activate_target(this.menu.get_children().data);
    }

    protected override void setindicatorlabel(string label, string guide) {
        this.indicator.set_label(label, guide);
    }

    protected override void setindicatoricon(string icon, string description) {
        this.indicator.set_icon_full(icon, description);
    }
}
