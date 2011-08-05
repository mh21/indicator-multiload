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

Quark expression_error_quark() {
  return Quark.from_string("expression-error-quark");
}

public class ExpressionParser {
    Data[] datas;

    public ExpressionParser(Data[] datas) {
        this.datas = datas;
    }

    private static void expandtoken(char *current,
            ref char *last) {
        if (last == null)
            last = current;
        // stderr.printf("Expanding token to '%s'\n", strndup(last, current - last + 1));
    }

    private static string[] savetoken(char *current,
            ref char *last, string[] result) {
        string[] r = result;
        if (last != null) {
            var token = strndup(last, current - last);
            // stderr.printf("Saving token '%s'\n", token);
            r += token;
            last = null;
        } else {
            // stderr.printf("Not saving empty token\n");
        }
        return r;
    }

    private static string[] addtoken(char current,
            string[] result) {
        string[] r = result;
        var token = current.to_string();
        // stderr.printf("Adding token '%s'\n", token);
        r += token;
        return r;
    }

    private static bool isspace(char current) {
        return current == ' ';
    }

    private static bool isvariable(char current) {
        return current >= 'a' && current <= 'z' || current == '.';
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
                    if (isvariable(*current)) {
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
                    } else if (isspace(*current)) {
                        result = savetoken(current, ref last, result);
                    } else if (!isvariable(*current)) {
                        result = savetoken(current, ref last, result);
                        result = addtoken(*current, result);
                    } else {
                        expandtoken(current, ref last);
                    }
                }
            }
        }
        result = savetoken(current, ref last, result);

        return result;
    }

    private Error error(uint index, string message) {
        return new Error(expression_error_quark(), (int)index, "%s", message);
    }

    private string evaluate_expression(string[] tokens, ref uint index) throws Error {
        if (index >= tokens.length)
            throw error(index, "empty expression");
        if (tokens[index] == "(")
            return evaluate_expression_parens(tokens, ref index);
        return evaluate_expression_name(tokens, ref index);
    }

    private string evaluate_expression_times(string[] tokens, ref uint index) throws Error {
        string result = null;
        bool div = false;
        for (;;) {
            if (index >= tokens.length)
                throw error(index, "times: expected expression");
            var value = evaluate_expression(tokens, ref index);
            if (result == null)
                result = value;
            else if (!div)
                result = (double.parse(result) * double.parse(value)).to_string();
            else
                result = (double.parse(result) / double.parse(value)).to_string();
            if (index >= tokens.length)
                return result;
            switch (tokens[index]) {
            case "*":
                div = false;
                index = index + 1;
                continue;
            case "/":
                div = true;
                index = index + 1;
                continue;
            default:
                return result;
            }
        }
    }

    private string evaluate_expression_plus(string[] tokens, ref uint index) throws Error {
        string result = null;
        bool minus = false;
        for (;;) {
            if (index >= tokens.length)
                throw error(index, "plus: expected expression");
            var value = evaluate_expression_times(tokens, ref index);
            if (result == null)
                result = value;
            else if (!minus)
                result = (double.parse(result) + double.parse(value)).to_string();
            else
                result = (double.parse(result) - double.parse(value)).to_string();
            if (index >= tokens.length)
                return result;
            switch (tokens[index]) {
            case "+":
                minus = false;
                index = index + 1;
                continue;
            case "-":
                minus = true;
                index = index + 1;
                continue;
            default:
                return result;
            }
        }
    }

    private string evaluate_expression_parens(string[] tokens, ref uint index) throws Error {
        if (index >= tokens.length || tokens[index] != "(")
            throw error(index, "parens: expected '('");
        index = index + 1;
        var result = evaluate_expression_plus(tokens, ref index);
        if (index >= tokens.length || tokens[index] != ")")
            throw error(index, "parens: expected ')'");
        index = index + 1;
        return result;
    }

    // TODO: constants with +, -, .
    private string evaluate_expression_name(string[] tokens, ref uint index) throws Error {
        if (index >= tokens.length)
            throw error(index, "name: expected identifier");
        var varparts = tokens[index].split(".");
        var nameindex = index;
        index = index + 1;
        switch (varparts.length) {
        case 1:
            var function = varparts[0];
            var parameter = evaluate_expression_parens(tokens, ref index);
            switch (function) {
            case "decimals":
                return "%.2f".printf(double.parse(parameter));
            case "size":
                return Utils.format_size(double.parse(parameter));
            case "speed":
                return Utils.format_speed(double.parse(parameter));
            case "percent":
                return _("%u%%").printf
                    ((uint)Math.round(100 * double.parse(parameter)));
            default:
                throw error(nameindex, "name: unknown function");
            }
        case 2:
            foreach (var data in this.datas) {
                if (data.id != varparts[0])
                    continue;
                for (uint j = 0, jsize = data.keys.length; j < jsize; ++j) {
                    if (data.keys[j] != varparts[1])
                        continue;
                    var value = data.values[j].to_string();
                    return value;
                }
            }
            throw error(nameindex, "name: unknown variable");
        default:
            throw error(nameindex, "name: too many identifier parts");
        }
    }

    private string evaluate_text(string[] tokens, ref uint index) throws Error {
        string[] result = null;
        while (index < tokens.length) {
            string current = tokens[index];
            if (current == "$") {
                index = index + 1;
                result += evaluate_expression(tokens, ref index);
            } else {
                result += current;
                index = index + 1;
            }
        }

        return string.joinv("", result);
    }

    public string evaluate(string[] tokens) {
        uint index = 0;
        try {
            return evaluate_text(tokens, ref index);
        } catch (Error e) {
            stderr.printf("Expression error at token %i: %s\n", e.code, e.message);
            foreach (var token in tokens)
                stderr.printf(" '%s'", token);
            stderr.printf("\n");
            return "";
        }
    }
}

