package cdb;

import cdb.SqlLexer.Token;


enum SqlCommand {
    Select( fields: Array<Field>, fromClause: FromClause, whereClause: Array<Condition> );
    Update( table: String, setFields: Array<SetField>, whereClause: Array<Condition> );
    Insert( table: String, insertValue: InsertValue );
    Delete( table: String, whereClause: Array<Condition> );
    CreateTable( table: String, fields: Array<FieldDesc>);
    AlterTable( table: String, alters: Array<AlterCommand> );
    DropTable( table: String );
}

enum FromClause {
    Table(table: String);
    Query(command: SqlCommand);
    InnerJoin(left: FromClause, right: FromClause, on: Array<Condition>);
    OuterJoin(left: FromClause, right: FromClause, on: Array<Condition>);
}

enum SqlValue {
    Value<T>(kind: SqlType<T>, value: T);
    Query(command: SqlCommand);
}

typedef Field = {
    table: String,
    field: String,
    all: Bool,
}

typedef SetField = {
    field: String,
    value: String
}

typedef FieldAssignment = {
    field: Field,
    value: SqlValue
}

enum InsertValue {
    Row(fields: Array<FieldAssignment>);
    Multiple(rows: Array<InsertValue>);
    Query(command: SqlCommand);
}

typedef FieldDesc = {
    name: String,
    type: SqlType<Dynamic>
}

typedef WhereClause = Array<Condition>;

enum Condition {
    Relational(field: String, binop: String, value: SqlValue);
    IsNull(field: String);
    IsNotNull(field: String);
    And(left: Condition, right: Condition);
    Or(left: Condition, right: Condition);
}

enum Binop {
    Eq;
    Neq;
    Gt;
    GtEq;
    Lt;
    LtEq;
    Like;
    NotLike;
    In;
    NotIn;
}

enum SqlType<T> {
    INT: SqlType<Int>;
    STRING: SqlType<String>;
    DATE: SqlType<Date>;
    BOOLEAN: SqlType<Bool>;
    FLOAT: SqlType<Float>;
    OTHER( name: String ): SqlType<Dynamic>;
    UNKNOWN: SqlType<Dynamic>;
}

enum AlterCommand {
    RenameTo( name: String );
    AddColumn( name: String, type: SqlType<Dynamic> );
    DropColumn( name: String );
    ModifyColumn( name: String, type: SqlType<Dynamic> );
    RenameColumn( oldName: String, newName: String );
}


class SqlParser {

    private var tokens: Array<Token>;
    private var pos: Int;

    public function parse(args: Array<Token>): Array<SqlCommand> {
        tokens = args;
        pos = 0;
        var commands = new Array<SqlCommand>();
        while (pos < tokens.length) {
            commands.push(parseCommand());
        }
        return commands;
    }

    private function parseCommand(): SqlCommand {
        var token = nextToken();
        switch(token) {
            case Token.Kwd("SELECT"): {
                return parseSelect();
            }
            case Token.Kwd("UPDATE"): {
                return parseUpdate();
            }
            case Token.Kwd("INSERT"): {
                return parseInsert();
            }
            case Token.Kwd("DELETE"): {
                return parseDelete();
            }
            case Token.Kwd("CREATE"): {
                return parseCreate();
            }
            case Token.Kwd("ALTER"): {
                return parseAlter();
            }
            case Token.Kwd("DROP"): {
                return parseDrop();
            }
            case Token.Eof: {
                throw "Unexpected end of input";
            }
            default: {
                throw "Unexpected token: " + Std.string(token);
            }
        }
    }

    private function parseSelect(): SqlCommand {
        // Parse fields
        var fields = new Array<Field>();
        var token = nextToken();
        if (token == Token.Star) {
            fields.push({table: "", field: "", all: true});
            token = nextToken();
        } else {
            while (token != Token.Kwd("FROM")) {
                switch token {
                    case Ident(s): {
                        var field = { table: "", field: s, all: false };
                        fields.push(field);
                        token = nextToken();
                        if (token == Token.Comma) {
                            token = nextToken();
                        }
                    }
                    default: throw "Unexpected token in SELECT fields: " + Std.string(token);
                }
            }
        }

        // Parse from clause
        if (token != Token.Kwd("FROM")) {
            throw "Expected FROM, found: " + Std.string(token);
        }
        var fromClause = parseFromClause();

        // Parse where clause if present
        var whereClause = new Array<Condition>();
        token = peekToken();
        if (token == Token.Kwd("WHERE")) {
            whereClause = parseWhereClause();
        }
        
        return SqlCommand.Select(fields, fromClause, whereClause);
    }

    private function parseUpdate(): SqlCommand {
        // Parse table name
        var table = nextToken();
        if (!(table.match(Token.Ident(_)))) {
            throw "Expected table name";
        }

        // Parse SET keyword
        var token = nextToken();
        if (token != Token.Kwd("SET")) {
            throw "Expected SET, found: " + Std.string(token);
        }

        // Parse set fields
        var setFields = new Array<SetField>();
        while (true) {
            var field = nextToken();
            if (!(field.match(Token.Ident(_)))) {
                throw "Expected field name in SET clause";
            }

            token = nextToken();
            if (!token.match(Token.Op(Eq))) {
                throw "Expected = in SET clause";
            }

            var value = nextToken();
            if (!(value.match(Token.Ident(_))) && !(value.match(Token.CInt(_))) && !(value.match(Token.CFloat(_)))) {
                throw "Expected value in SET clause";
            }

            switch field {
                case Ident(s): {
                    setFields.push({field: s, value: Std.string(value)});
                }
                default:
            }
            

            token = peekToken();
            if (token != Token.Comma) {
                break;
            }
            nextToken(); // consume the comma
        }

        // Parse where clause if present
        var whereClause = new Array<Condition>();
        token = peekToken();
        if (token == Token.Kwd("WHERE")) {
            whereClause = parseWhereClause();
        }

        switch table {
            case Ident(s): {
                return SqlCommand.Update(s, setFields, whereClause);
            }
            default: throw "Expected table name";
        }
       
    }

    private function parseInsert(): SqlCommand {
        // Parse INTO keyword
        var token = nextToken();
        if (token != Token.Kwd("INTO")) {
            throw "Expected INTO, found: " + Std.string(token);
        }

        // Parse table name
        var table = nextToken();
        if (!(table.match(Token.Ident(_)))) {
            throw "Expected table name";
        }

        // Parse values
        token = nextToken();
        if (token != Token.Kwd("VALUES")) {
            throw "Expected VALUES, found: " + Std.string(token);
        }

        var insertValue = parseInsertValue();

        return SqlCommand.Insert(extractValue(table), insertValue);
    }

    private function parseDelete(): SqlCommand {
        // Parse FROM keyword
        var token = nextToken();
        if (token != Token.Kwd("FROM")) {
            throw "Expected FROM, found: " + Std.string(token);
        }

        // Parse table name
        var table = nextToken();
        if (!(table.match(Token.Ident(_)))) {
            throw "Expected table name";
        }

        // Parse where clause if present
        var whereClause = new Array<Condition>();
        token = peekToken();
        if (token == Token.Kwd("WHERE")) {
            whereClause = parseWhereClause();
        }

        return SqlCommand.Delete(extractValue(table), whereClause);
    }

    private function parseCreate(): SqlCommand {
        // Parse TABLE keyword
        var token = nextToken();
        if (token != Token.Kwd("TABLE")) {
            throw "Expected TABLE, found: " + Std.string(token);
        }

        // Parse table name
        var table = nextToken();
        if (!(table.match(Token.Ident(_)))) {
            throw "Expected table name";
        }

        // Parse fields
        var fields = new Array<FieldDesc>();
        if (nextToken() != Token.POpen) {
            throw "Expected ( after table name";
        }
        while (true) {
            var fieldName = nextToken();
            if (!(fieldName.match(Token.Ident(_)))) {
                throw "Expected field name";
            }

            var fieldType = nextToken();
            if (!(fieldType.match(Token.Ident(_)))) {
                throw "Expected field type";
            }

            fields.push(
                {
                    name: extractValue(fieldName),
                    type: parseSqlType(extractValue(fieldType))
                }
            );

            token = nextToken();
            if (token == Token.PClose) {
                break;
            }
            if (token != Token.Comma) {
                throw "Expected , or ) in field list";
            }
        }

        return SqlCommand.CreateTable(extractValue(table), fields);
    }

    private function parseAlter(): SqlCommand {
        // Parse TABLE keyword
        var token = nextToken();
        if (token != Token.Kwd("TABLE")) {
            throw "Expected TABLE, found: " + Std.string(token);
        }

        // Parse table name
        var table = nextToken();
        if (!(table.match(Token.Ident(_)))) {
            throw "Expected table name";
        }

        // Parse alter commands
        var alters = new Array<AlterCommand>();
        while (pos < tokens.length) {
            token = nextToken();
            switch (token) {
                case Token.Kwd("RENAME"): {
                    var to = nextToken();
                    if (to != Token.Kwd("TO")) {
                        throw "Expected TO after RENAME";
                    }
                    var newName = nextToken();
                    if (!(newName.match(Token.Ident(_)))) {
                        throw "Expected new table name";
                    }
                    alters.push(AlterCommand.RenameTo(extractValue(newName)));
                }
                case Token.Kwd("ADD"): {
                    var column = nextToken();
                    if (column != Token.Kwd("COLUMN")) {
                        throw "Expected COLUMN after ADD";
                    }
                    var columnName = nextToken();
                    if (!(columnName.match(Token.Ident(_)))) {
                        throw "Expected column name";
                    }
                    var columnType = nextToken();
                    if (!(columnType.match(Token.Ident(_)))) {
                        throw "Expected column type";
                    }
                    alters.push(AlterCommand.AddColumn(extractValue(columnName), parseSqlType(extractValue(columnType))));
                }
                case Token.Kwd("DROP"): {
                    var column = nextToken();
                    if (column != Token.Kwd("COLUMN")) {
                        throw "Expected COLUMN after DROP";
                    }
                    var columnName = nextToken();
                    if (!(columnName.match(Token.Ident(_)))) {
                        throw "Expected column name";
                    }
                    alters.push(AlterCommand.DropColumn(extractValue(columnName)));
                }
                case Token.Kwd("MODIFY"): {
                    var column = nextToken();
                    if (column != Token.Kwd("COLUMN")) {
                        throw "Expected COLUMN after MODIFY";
                    }
                    var columnName = nextToken();
                    if (!(columnName.match(Token.Ident(_)))) {
                        throw "Expected column name";
                    }
                    var columnType = nextToken();
                    if (!(columnType.match(Token.Ident(_)))) {
                        throw "Expected column type";
                    }
                    alters.push(AlterCommand.ModifyColumn(extractValue(columnName), parseSqlType(extractValue(columnType))));
                }
                /*case Token.Kwd("RENAME"): {
                    var column = nextToken();
                    if (column != Token.Kwd("COLUMN")) {
                        throw "Expected COLUMN after RENAME";
                    }
                    var oldName = nextToken();
                    if (!(oldName is Token.Ident)) {
                        throw "Expected old column name";
                    }
                    var to = nextToken();
                    if (to != Token.Kwd("TO")) {
                        throw "Expected TO after old column name";
                    }
                    var newName = nextToken();
                    if (!(newName is Token.Ident)) {
                        throw "Expected new column name";
                    }
                    alters.push(AlterCommand.RenameColumn((oldName: Token.Ident).s, (newName: Token.Ident).s));
                }*/
                default: {
                    throw "Unexpected token in ALTER TABLE command: " + Std.string(token);
                }
            }

            // Check for end of commands
            token = peekToken();
            if (token == Token.Eof || !(token.match(Token.Kwd(_)))) {
                break;
            }
        }

        return SqlCommand.AlterTable(extractValue(table), alters);
    }

    private function parseDrop(): SqlCommand {
        // Parse TABLE keyword
        var token = nextToken();
        if (token != Token.Kwd("TABLE")) {
            throw "Expected TABLE, found: " + Std.string(token);
        }

        // Parse table name
        var table = nextToken();
        if (!(table.match(Token.Ident(_)))) {
            throw "Expected table name";
        }

        return SqlCommand.DropTable(extractValue(table));
    }

    private function parseFromClause(): FromClause {
        var next = nextToken();
        if (!(next.match(Token.Ident(_)))) {
            throw "Expected table name in FROM clause";
        }
        return FromClause.Table(extractValue(next));
    }

    private function parseWhereClause(): Array<Condition> {
        // Assuming "WHERE" keyword is already consumed
        var conditions = new Array<Condition>();
        while (true) {
            var field = nextToken();
            if (!(field.match(Token.Ident(_)))) {
                throw "Expected field name in WHERE clause";
            }
            var binop = nextToken();
            if (!(binop.match(Token.Op(_)))) {
                throw "Expected binary operator in WHERE clause";
            }
            var value = nextToken();
            if (!(value.match(Token.Ident(_))) && !(value.match(Token.CInt(_))) && !(value.match(Token.CFloat(_)))) {
                throw "Expected value in WHERE clause";
            }
            conditions.push(Condition.Relational(extractValue(field), Std.string(binop), SqlValue.Value(SqlType.STRING, Std.string(value))));
            if (peekToken() != Token.Kwd("AND")) {
                break;
            }
            nextToken(); // consume the AND
        }
        return conditions;
    }

    private function parseInsertValue(): InsertValue {
        if (nextToken() != Token.POpen) {
            throw "Expected ( to start INSERT values";
        }
        var fields = new Array<FieldAssignment>();
        while (true) {
            var field = nextToken();
            if (!(field.match(Token.Ident(_)))) {
                throw "Expected field name";
            }
            if (nextToken() != Token.Op(Eq)) {
                throw "Expected = after field name";
            }
            var value = nextToken();
            fields.push({field: {table: "", field: extractValue(field), all: false}, value: SqlValue.Value(SqlType.STRING, Std.string(value))});
            if (peekToken() == Token.PClose) {
                nextToken(); // consume the )
                break;
            }
        }
        return InsertValue.Row(fields);
    }

    private function extractValue(t: Token): Dynamic {
        switch t {
            case CInt(v): {
                return v;
            }
            case CFloat(v): {
                return v;
            }
            case Kwd(s): {
                return s;
            }
            case Ident(s): {
                return s;
            }
            case Op(op): {
                return op;
            }
            default: return t;
        }
    }

    private function peekToken(): Token {
        return tokens[pos];
    }

    private function nextToken(): Token {
        return tokens[pos++];
    }

    private function parseSqlType(type: String): SqlType<Dynamic> {
        switch(type) {
            case "INT": return SqlType.INT;
            case "STRING": return SqlType.STRING;
            case "DATE": return SqlType.DATE;
            case "BOOLEAN": return SqlType.BOOLEAN;
            case "FLOAT": return SqlType.FLOAT;
            default: return SqlType.OTHER(type);
        }
    }

}