/******************************************************************************
 * Copyright (C) 2013  Michael Hofmann <mh21@piware.de>                       *
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

public class Reaper : Object {
    public string[] args { get; construct; }
    public TimeoutSource timeout { get; construct; }

    public Reaper(string[] args) {
        Object(args: args, timeout: new TimeoutSource(60 * 1000));
    }

    construct {
        this.timeout.attach(null);
        this.timeout.set_callback(() => {
            try {
                string status;
                FileUtils.get_contents("/proc/self/statm", out status);
                var pages = long.parse(status.split(" ")[1]);
                var pagesize = Posix.sysconf(Posix._SC_PAGESIZE);
                // restart on RSS > 50 MB to contain memory leaks
                if (pagesize * pages > 50 * 1000 * 1000) {
                    execvp(args[0], args);
                }
            } catch (Error e) {
                stderr.printf("Could not determine memory use: %s\n",
                        e.message);
            }
            return true;
        });
    }
}
