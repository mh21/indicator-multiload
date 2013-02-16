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

public abstract class Function : GLib.Object {
    public string id { get; construct; }
    public string[] parameterdescs { get; construct; }

    public Function(string id, string[] parameterdescs) {
        Object(id: id, parameterdescs: parameterdescs);
    }

    protected static Error error(string message) {
        return new Error(Quark.from_string("function-error-quark"), 0, "%s", message);
    }

    public abstract string call(string[] parameters, bool widest) throws Error;
}

public class DecimalsFunction : Function {
    public DecimalsFunction() {
        base("decimals", {"value", "decimals"});
    }

    public override string call(string[] parameters, bool widest) throws Error {
        if (parameters.length != 2)
            throw error("two parameters expected");
        if (widest)
            parameters[0] = "8";
        return "%.*f".printf(int.parse(parameters[1]), double.parse(parameters[0]));
    }
}

public class SizeFunction : Function {
    public SizeFunction() {
        base("size", {"value"});
    }

    public override string call(string[] parameters, bool widest) throws Error {
        if (parameters.length != 1)
            throw error("one parameter expected");
        if (widest)
            parameters[0] = "999000000"; // MB
        // TODO inline
        return Utils.format_size(double.parse(parameters[0]));
    }
}

public class SpeedFunction : Function {
    public SpeedFunction() {
        base("speed", {"value"});
    }

    public override string call(string[] parameters, bool widest) throws Error {
        if (parameters.length != 1)
            throw error("one parameter expected");
        if (widest)
            parameters[0] = "999000000"; // MB
        // TODO inline
        return Utils.format_speed(double.parse(parameters[0]));
    }
}

public class PercentFunction : Function {
    public PercentFunction() {
        base("percent", {"value"});
    }

    public override string call(string[] parameters, bool widest) throws Error {
        if (parameters.length != 1)
            throw error("one parameter expected");
        if (widest)
            parameters[0] = "1";
        return _("%u%%").printf
            ((uint) Math.round(100 * double.parse(parameters[0])));
    }
}
