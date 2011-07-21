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

public class ExpressionParser {
    Data[] datas;

    public ExpressionParser(Data[] datas) {
        this.datas = datas;
    }

    public static void expandtoken(char *current, 
            ref char *last) {
        if (last == null)
            last = current;
    }

    public static string[] savetoken(char *current, 
            ref char *last, string[] result) {
        string[] r = result;
        if (last != null) {
            r += strndup(last, current - last);
            last = null;
        }
        return r;
    }

    public static string[] addtoken(char current, 
            string[] result) {
        string[] r = result;
        r += current.to_string();
        return r;
    }

    public string[] tokenize(string expression) {
        string[] result = null;
        char *last = null;
        char *current = expression;
        int level = 0;
        bool inexpression = false;
        for (; *current != '\0'; current = current + 1) {
            if (!inexpression) {
                if (*current == '$') {
                    result = savetoken(current, ref last, result);
                    result = addtoken(*current, result);
                    inexpression = true;
                } else {
                    expandtoken(current, ref last);
                }
            } else {
                if (level == 0) {
                    if (*current >= 'a' && *current <= 'z' || 
                        *current == '.') {
                        expandtoken(current, ref last);
                    } else if (last == null && *current == '(') {
                        result = addtoken(*current, result);
                        ++level;
                    } else {
                        result = addtoken('(', result);
                        result = savetoken(current, ref last, result);
                        result = addtoken(')', result);
                        expandtoken(current, ref last);
                        inexpression = false;
                    }
                } else {
                    if (*current == '(') {
                        result = savetoken(current, ref last, result);
                        result = addtoken(*current, result);
                        ++level;
                    } else if (*current == ')') {
                        result = savetoken(current, ref last, result);
                        result = addtoken(*current, result);
                        --level;
                        if (level == 0)
                            inexpression = false;
                    } else {
                        expandtoken(current, ref last);
                    }
                }
            }
        }
        result = savetoken(current, ref last, result);

        return result;
    }

    public string evaluate(string[] tokens) {
        string[] result = null;
        string function = "";
        int level = 0;
        bool inexpression = false;
        for (uint i = 0, isize = tokens.length; i < isize; ++i) {
            string current = tokens[i];
            if (!inexpression) {
                if (current == "$") {
                    inexpression = true;
                    function = "";
                } else {
                    result += current;
                }
            } else {
                // TODO: this needs to be a proper recursive parser
                if (current == "(") {
                    ++level;
                } else if (current == ")") {
                    --level;
                    if (level == 0)
                        inexpression = false;
                } else {
                    var varparts = current.split(".");
                    if (varparts.length == 1) {
                        function = varparts[0];
                    } else if (varparts.length == 2) {
                        foreach (var data in this.datas) {
                            if (data.id != varparts[0])
                                continue;
                            for (uint j = 0, jsize = data.keys.length; j < jsize; ++j) {
                                if (data.keys[j] != varparts[1])
                                    continue;
                                var value = data.values[j];
                                if (function == "") {
                                    result += "%.2f".printf(value);
                                } else if (function == "size") {
                                    result += Utils.format_size(value);
                                } else if (function == "speed") {
                                    result += Utils.format_speed(value);
                                } else if (function == "percent") {
                                    result += _("%u%%").printf
                                        ((uint)Math.round(100 * value));
                                }
                                break;
                            }
                            break;
                        }
                    }
                }
            }
        }

        return string.joinv("", result);
    }
}

