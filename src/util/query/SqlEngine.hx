package util.query;

import haxe.Json;
import cdb.Parser;
import cdb.Data.Column;
import hxsqlparser.SqlCommandParse.SqlType;
import cdb.Data.ColumnType;
import hxsqlparser.SqlCommandParse.SqlValue;
import hxsqlparser.SqlCommandParse.SqlCommand;
import hxsqlparser.SqlCommandParse.Condition;
import hxsqlparser.SqlCommandParse.FromClause;
import cdb.Database;
import hxsqlparser.SqlCommandParse.InsertValue;
import hxsqlparser.SqlCommandParse.Field;
import hxsqlparser.SqlParser;

class SqlEngine {
    var querier: Querier;

    public function new(database: Database) {
        this.querier = new Querier(database);
    }

    public function run(q: String): Array<Dynamic> {
        var result: Array<Dynamic> = [];
        var sqlParser = new SqlParser();
        
        for (command in sqlParser.parse(q)) {
            result.push(evaluateQuery(command));
        }

        return result;
    }

    function extractTableName(fromClause: FromClause): String {
        switch (fromClause) {
            case Table(table): return table;
            case _: return ""; // Add more logic if needed to handle other FromClause types
        }
    }

    function createWhereFunction(whereClause: Array<Condition>): Dynamic -> Bool {
        return function(line: Dynamic): Bool {
            for (condition in whereClause) {
                if (!evaluateCondition(line, condition)) {
                    return false;
                }
            }
            return true;
        };
    }

    function evaluateQuery(command: SqlCommand): Dynamic {
        trace("evaluateQuery: " + command);
        switch (command) {
            case Select(fields, fromClause, whereClause): {
                var fromTable: String = extractTableName(fromClause);
                var whereFunction = createWhereFunction(whereClause);
                return querier.select(fields, fromTable, whereFunction);
            }
            case Update(table, setFields, whereClause): {
                var updateFields = {};
                for (setField in setFields) {
                    Reflect.setField(updateFields, setField.field, setField.value);
                }
                var whereFunction = createWhereFunction(whereClause);
                querier.update(table, updateFields, whereFunction);
            }
            case Insert(table, fieldNames, insertValue): {
                if(fieldNames == null || fieldNames.length == 0) {
                    fieldNames = [];
                    var columns = querier.getColumns(table);
                    for (column in columns) {
                        fieldNames.push({
                            field: column.name
                        });
                    }
                }
                var insertRow = mapInsertValue(fieldNames, insertValue);
                querier.insert(table, insertRow);
            }
            case Delete(table, whereClause): {
                var whereFunction = createWhereFunction(whereClause);
                querier.delete(table, whereFunction);
            }
            case CreateTable(table, fields): {
                var fieldMap: Array<Column> = [];
                for (field in fields) {
                    var columnType = convertType(field.type);
                    fieldMap.push({
                        name: field.name,
                        type: columnType,
                        typeStr: Parser.saveType(columnType),
                    });
                }
                querier.createTable(table, fieldMap);
            }
            case AlterTable(table, alters): {
                for (alter in alters) {
                    switch (alter) {
                        case RenameTo(name): {
                            // Handle table rename if your storage supports it.
                        }
                        case AddColumn(name, type): {
                            querier.addColumn(table, name, convertType(type));
                        }
                        case DropColumn(name): {
                            querier.dropColumn(table, name);
                        }
                        case ModifyColumn(name, type): {
                            // Handle column modification if your storage supports it.
                        }
                        case RenameColumn(oldName, newName): {
                            // Handle column rename if your storage supports it.
                        }
                    }
                }
            }
            case DropTable(table): {
                querier.dropTable(table);
            }
        }

        return null;
    }

    function convertType(value: SqlType<Dynamic>): ColumnType {
        switch value {
            case INT: return ColumnType.TInt;
            case STRING: return ColumnType.TString;
            case DATE: return ColumnType.TString;
            case BOOLEAN: return ColumnType.TBool;
            case FLOAT: return ColumnType.TFloat;
            case OTHER(name): return ColumnType.TDynamic;
            case UNKNOWN: return ColumnType.TDynamic;
        }
    }

    function evaluateCondition(line: Dynamic, condition: Condition): Bool {
        switch (condition) {
            case Relational(field, binop, v):
                var lineValue = Reflect.field(line, field);
                var value = switch v {
                    case Value(kind, v2): v2;
                    case Query(command):  evaluateQuery(command);
                }
                switch (binop) {
                    case Eq: return lineValue == value;
                    case Neq: return lineValue != value;
                    case Gt: return (cast lineValue: Float) > (cast value: Float);
                    case GtEq: return (cast lineValue: Float) >= (cast value: Float);
                    case Lt: return (cast lineValue: Float) < (cast value: Float);
                    case LtEq: return (cast lineValue: Float) <= (cast value: Float);
                    case Like: return StringTools.startsWith(cast lineValue, cast value);
                    case NotLike: return !StringTools.startsWith(cast lineValue, cast value);
                    case In: return (cast value : Array<Dynamic>).indexOf(lineValue) != -1;
                    case NotIn: return (cast value : Array<Dynamic>).indexOf(lineValue) == -1;
                }
            case IsNull(field):
                return Reflect.field(line, field) == null;
            case IsNotNull(field):
                return Reflect.field(line, field) != null;
            case And(left, right):
                return evaluateCondition(line, left) && evaluateCondition(line, right);
            case Or(left, right):
                return evaluateCondition(line, left) || evaluateCondition(line, right);
        }
        return false;
    }

    function getValue(value: SqlValue): Dynamic {
        switch value {
            case Value(kind, value): return value;
            case Query(command): return evaluateQuery(command);
        }
    }

    function mapInsertValue(fieldNames: Array<Field>, insertValue: InsertValue): Dynamic {
        switch (insertValue) {
            case Row(fields):
                var row: Dynamic = {};
                for (i in 0...fields.length) {
                    var fieldName = fieldNames[i].field;
                    Reflect.setField(row, fieldName, getValue(fields[i]));
                }
                return row;
            case Multiple(rows):
                return rows.map(row -> mapInsertValue(fieldNames, row));
            case Query(command): {
                var result: Array<Dynamic> = cast evaluateQuery(command);
                if (result != null) {
                    trace("internal query result: " + Json.stringify(result));
                    var arrayedResults: Array<InsertValue> = [];
                    for (eachEntry in result) {
                        var fields: Array<SqlValue> = [];
                        for (eachField in Reflect.fields(eachEntry)) {
                            fields.push(Value(UNKNOWN, Reflect.field(eachEntry, eachField)));
                        }
                        arrayedResults.push(Row(fields));
                    }
                    return mapInsertValue(fieldNames, Multiple(arrayedResults));
                }
            }
        }
        return {};
    }
}