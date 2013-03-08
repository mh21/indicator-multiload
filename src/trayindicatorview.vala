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

public class TrayIndicatorView : IndicatorView, Object {
    private Gtk.StatusIcon indicator;
    private string icondirectory;


    public string label { set {} }
    public string guide { set {} }

    public string icon {
        set {
            var path = Path.build_filename(this.icondirectory, value + ".png");
            stdout.printf("%s\n", path);
            this.indicator.set_from_file(path);
        }
    }

    public string description {
        set {
            this.indicator.set_tooltip_text(value);
        }
    }

    public TrayIndicatorView(string icondirectory, Gtk.Menu menu) {
        this.indicator = new Gtk.StatusIcon();
        // Unity no-whitelist workaround
        this.indicator.set_name("Wine");
        this.indicator.set_visible(true);

        this.icondirectory = icondirectory;

        this.indicator.activate.connect(() => {
            menu.popup(null, null, this.indicator.position_menu, 1,
                Gtk.get_current_event_time());
        });

        this.indicator.popup_menu.connect((button, activate_time) => {
            menu.popup(null, null, this.indicator.position_menu, button,
                activate_time);
        });

        this.indicator.scroll_event.connect((event) => {
            this.scroll_event(1, event.direction);
            return true;
        });

        this.indicator.button_release_event.connect((event) => {
            if (event.button == 2 &&
                event.type == Gdk.EventType.BUTTON_RELEASE) {
                menu.get_children().data.activate();
                return true;
            }
            return false;
        });
    }
}
