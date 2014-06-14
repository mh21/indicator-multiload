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

internal class ExpressionTokenizer {
    private char *last;
    private char *current;
    private string[] result;

    public string[] tokenize(string expression) {
        this.result = null;
        this.last = null;
        int level = 0;
        bool inexpression = false;
        bool instringsingle = false;
        bool instringdouble = false;
        for (this.current = (char*)expression; *this.current != '\0';
                this.current = this.current + 1) {
            if (!inexpression) {
                if (*this.current == '$') {
                    this.save();
                    this.addcurrent();
                    inexpression = true;
                } else {
                    this.expand();
                }
                continue;
            }
            // inexpression
            if (level == 0) {
                if (this.isvariable()) {
                    this.expand();
                } else if (this.last == null && *this.current == '(') {
                    this.addcurrent();
                    ++level;
                } else {
                    this.add('(');
                    this.save();
                    this.add(')');
                    this.expand();
                    inexpression = false;
                }
                continue;
            }
            // level > 0
            if (instringsingle) {
                this.expand();
                if (*this.current == '\'') {
                    this.savewithcurrent();
                    instringsingle = false;
                }
                continue;
            }
            if (instringdouble) {
                this.expand();
                if (*this.current == '"') {
                    this.savewithcurrent();
                    instringdouble = false;
                }
                continue;
            }
            // !instring
            if (*this.current == '\'') {
                this.save();
                this.expand();
                instringsingle = true;
            } else if (*this.current == '"') {
                this.save();
                this.expand();
                instringdouble = true;
            } else if (*this.current == '(') {
                this.save();
                this.addcurrent();
                ++level;
            } else if (*this.current == ')') {
                this.save();
                this.addcurrent();
                --level;
                if (level == 0)
                    inexpression = false;
            } else if (this.isspace()) {
                this.save();
            } else if (!this.isvariable()) {
                this.save();
                this.addcurrent();
            } else {
                this.expand();
            }
        }
        // fixup open strings, parentheses
        if (instringdouble)
            this.savewith('"');
        else if (instringsingle)
            this.savewith('\'');
        else
            this.save();
        while (level > 0) {
            this.add(')');
            --level;
        }
        return this.result;
    }

    private void expand() {
        if (this.last == null)
            this.last = this.current;
        // stderr.printf("Expanding token to '%s'\n", strndup(last, current - last + 1));
    }

    // add the current character as a new token
    private void addcurrent() {
        this.add(*this.current);
    }

    // add a character as a new token
    private void add(char what) {
        var token = what.to_string();
        // stderr.printf("Adding token '%s'\n", token);
        this.result += token;
    }

    // if the current token is not empty, push it to the token list and set the
    // current token to empty; this will not include the current character
    private void save() {
        if (this.last != null) {
            var token = strndup(this.last, this.current - this.last);
            // stderr.printf("Saving token '%s'\n", token);
            this.result += token;
            this.last = null;
        } else {
            // stderr.printf("Not saving empty token\n");
        }
    }

    private void savewithcurrent() {
        this.savewith(*this.current);
    }

    // add a character to the current token, push it to the token list
    // and set the current token to empty
    private void savewith(char what) {
        string token = (this.last != null ?
                strndup(this.last, this.current - this.last) : "") + what.to_string();
        // stderr.printf("Saving token '%s'\n", token);
        this.result += token;
        this.last = null;
    }

    private bool isspace() {
        return *this.current == ' ';
    }

    private bool isvariable() {
        return
            *this.current >= 'a' && *this.current <= 'z' ||
            *this.current >= '0' && *this.current <= '9' ||
            *this.current == '.';
    }
}

internal class ExpressionEvaluator {
    private Providers providers;

    private uint index;
    private string[] tokens;
    bool guide;

    public ExpressionEvaluator(Providers providers) {
        this.providers = providers;
    }

    private static Error error(uint index, string message) {
        return new Error(Quark.from_string("expression-error-quark"),
                (int)index, "%s", message);
    }

    private string parens_or_identifier() throws Error {
        if (this.index >= this.tokens.length)
            throw error(this.index, "empty expression");
        if (this.tokens[this.index] == "(")
            return parens();
        return identifier();
    }

    private string times() throws Error {
        string result = null;
        bool div = false;
        for (;;) {
            if (this.index >= this.tokens.length)
                throw error(this.index, "expression expected");
            var value = parens_or_identifier();
            if (result == null)
                result = value;
            else if (!div)
                result = (double.parse(result) * double.parse(value)).to_string();
            else
                result = (double.parse(result) / double.parse(value)).to_string();
            if (this.index >= this.tokens.length)
                return result;
            switch (this.tokens[this.index]) {
            case "*":
                div = false;
                ++this.index;
                continue;
            case "/":
                div = true;
                ++this.index;
                continue;
            default:
                return result;
            }
        }
    }

    private string plus() throws Error {
        string result = null;
        bool minus = false;
        for (;;) {
            if (this.index >= this.tokens.length)
                throw error(this.index, "expression expected");
            var value = times();
            if (result == null)
                result = value;
            else if (!minus)
                result = (double.parse(result) + double.parse(value)).to_string();
            else
                result = (double.parse(result) - double.parse(value)).to_string();
            if (this.index >= this.tokens.length)
                return result;
            switch (this.tokens[this.index]) {
            case "+":
                minus = false;
                ++this.index;
                continue;
            case "-":
                minus = true;
                ++this.index;
                continue;
            default:
                return result;
            }
        }
    }

    private string parens() throws Error {
        if (this.index >= this.tokens.length ||
                this.tokens[this.index] != "(")
            throw error(this.index, "'(' expected");
        ++this.index;
        var result = plus();
        if (this.index >= this.tokens.length ||
                this.tokens[this.index] != ")")
            throw error(this.index, "')' expected");
        ++this.index;
        return result;
    }

    private string[] params() throws Error {
        string[] result = null;
        if (this.index >= this.tokens.length ||
                this.tokens[this.index] != "(")
            throw error(this.index, "'(' expected");
        ++this.index;
        if (this.index >= this.tokens.length)
            throw error(this.index, "parameters expected");
        if (this.tokens[this.index] != ")") {
            for (;;) {
                result += plus();
                if (this.index >= this.tokens.length)
                    throw error(this.index, "')' expected");
                if (this.tokens[this.index] != ",")
                    break;
                ++this.index;
            }
        }
        if (this.index >= this.tokens.length ||
                this.tokens[this.index] != ")")
            throw error(this.index, "')' expected");
        ++this.index;
        return result;
    }

    private string identifier() throws Error {
        if (this.index >= this.tokens.length)
            throw error(this.index, "identifier expected");
        double sign = 1;
        if (this.tokens[this.index] == "+") {
            ++this.index;
            if (this.index >= this.tokens.length)
                throw error(this.index, "identifier expected");
        } else if (this.tokens[this.index] == "-") {
            sign = -1.0;
            ++this.index;
            if (this.index >= this.tokens.length)
                throw error(this.index, "identifier expected");
        }
        var token = this.tokens[this.index];
        if (token.length > 0 && (token[0] == '\'' || token[0] == '"')) {
            ++this.index;
            return (sign == -1 ? "-" : "") + token[1:token.length - 1];
        }
        if (token.length > 0 && (token[0] >= '0' && token[0] <= '9' || token[0] == '.')) {
            ++this.index;
            if (sign == -1)
                return "-" + token;
            return token;
        }
        var varparts = token.split(".", 2);
        var nameindex = this.index;
        ++this.index;
        switch (varparts.length) {
        case 1:
            bool found = false;
            try {
                var result = this.providers.call(token, this.params(),
                        this.guide, out found);
                if (!found)
                    throw error(nameindex, "unknown function");
                return (sign == -1 ? "-" : "") + result;
            } catch (Error e) {
                // TODO: this is not the right error position, maybe it is one
                // of the parameters so how to we transport this, maybe add
                // nameindex + e.errorcode?
                throw error(nameindex, e.message);
            }
        case 2:
            bool found = false;
            var result = (sign * this.providers.value(token, out found)).to_string();
            if (!found)
                throw error(nameindex, "unknown variable");
            return result;
        default:
            // not reached
            throw error(nameindex, "too many identifier parts");
        }
    }

    private string text() throws Error {
        string[] result = {};
        while (this.index < this.tokens.length) {
            string current = this.tokens[this.index];
            if (current == "$") {
                ++this.index;
                result += parens_or_identifier();
            } else {
                result += current;
                ++this.index;
            }
        }

        return string.joinv("", result);
    }

    public string evaluate(string[] tokens, bool guide) {
        this.index = 0;
        this.tokens = tokens;
        this.guide = guide;
        try {
            return text();
        } catch (Error e) {
            stderr.printf("Expression error: %s\n", e.message);
            string errormessage = "";
            int errorpos = -1;
            for (uint i = 0, isize = this.tokens.length; i < isize; ++i) {
                if (e.code == i)
                    errorpos = errormessage.length;
                errormessage += " " + this.tokens[i];
            }
            if (errorpos < 0)
                errorpos = errormessage.length;
            stderr.printf("%s\n%s^\n", errormessage, string.nfill(errorpos, '-'));
            return "";
        }
    }
}

public class ExpressionCache : Object {
    public Providers providers { get; construct; }

    private string[] _tokens;
    private string _label;
    private string _guide;

    private string _expression;
    public string expression {
        get {
            return this._expression;
        }
        construct set {
            this._expression = value;
            this._tokens = null;
            this._label = null;
            this._guide = null;
        }
    }

    public ExpressionCache(Providers providers, string expression) {
        Object(providers: providers, expression: expression);
    }

    public void update() {
        this._label = null;
        this._guide = null;
    }

    public string[] tokens() {
        if (this._tokens == null)
            this._tokens = new ExpressionTokenizer().tokenize(this._expression);
        return this._tokens;
    }

    public string label() {
        if (this._label == null)
            this._label = new ExpressionEvaluator(this.providers).evaluate(this.tokens(), false);
        return this._label;
    }

    public string guide() {
        if (this._guide == null)
            this._guide = new ExpressionEvaluator(this.providers).evaluate(this.tokens(), true);
        return this._guide;
    }

}

