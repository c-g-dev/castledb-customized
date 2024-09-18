package util.query;

import cdb.Database;
import cdb.Parser;
import cdb.Data;

using ludi.commons.extensions.All;

class Querier {

    var database: Database;
    var data: Data;

    public function new(database: Database) {
        this.database = database;
        @:privateAccess this.data = database.data;
    }

    public function select(fields: Dynamic, fromTable: String, whereClause: Dynamic -> Bool):Dynamic {
        return data.sheets
            .filter(sheet -> sheet.name == fromTable)
            .map(sheet -> sheet.lines.filter(whereClause))
            .map(line -> {
                var result = {};
                for (field in Reflect.fields(fields)) {
                    Reflect.setField(result, field, Reflect.field(line, field));
                }
                return result;
            });
    }

    public function delete(fromTable: String, whereClause: Dynamic -> Bool):Void {
        var table = data.sheets.find(sheet -> sheet.name == fromTable);
        if (table != null) {
            table.lines = table.lines.filter(line -> !whereClause(line));
        }
        database.syncbackData();
    }

    public function update(fromTable: String, fields: Dynamic, whereClause: Dynamic -> Bool):Void {
        var table = data.sheets.find(sheet -> sheet.name == fromTable);
        if (table != null) {
            for (line in table.lines) {
                if (whereClause(line)) {
                    for (field in Reflect.fields(fields)) {
                        Reflect.setField(line, field, Reflect.field(fields, field));
                    }
                }
            }
        }
        database.syncbackData();
    }

    public function insert(fromTable: String, row: Dynamic, ?writeback: Bool = true):Void {
        var objArg = parseObjectClause(row);
        switch objArg {
            case None: {}
            case Multiple(arr): {
                for (row in arr) {
                    insert(fromTable, row, false);
                }
            }
            case Single(val): {
                var table = data.sheets.find(sheet -> sheet.name == fromTable);
                if (table != null) {
                    var s = database.getSheet(table.name);
                    var o = s.newLine();
                    for (field in Reflect.fields(o)) {
                        Reflect.setField(o, field, Reflect.field(val, field));
                    }
                }
            }
        }
        if(writeback) {
            database.syncbackData();
        }
    }

    public function count(fromTable: String, whereClause: Dynamic -> Bool):Int {
        var table = data.sheets.find(sheet -> sheet.name == fromTable);
        if (table != null) {
            return table.lines.filter(whereClause).length;
        }
        return 0;
    }

    public function createTable(tableName: String, fields: Dynamic):Void {
        data.sheets.push({
            sheetType: "table",
            name: tableName,
            columns: fields,
            lines: [],
            props: {},
            separators: []
        });
    }

    public function dropTable(tableName: String):Void {
        data.sheets = data.sheets.filter(sheet -> sheet.name != tableName);
    }

    public function addColumn(tableName: String, columnName: String, columnType: ColumnType):Void {
        var table = data.sheets.find(sheet -> sheet.name == tableName);
        if (table != null) {
            table.columns.push({
                name: columnName,
                type: columnType,
                typeStr: Parser.saveType(columnType),
            });
        }
    }

    public function dropColumn(tableName: String, columnName: String):Void {
        var table = data.sheets.find(sheet -> sheet.name == tableName);
        if (table != null) {
            table.columns = table.columns.filter(column -> column.name != columnName);
        }
    }

    public function getColumns(tableName: String):Dynamic {
        var table = data.sheets.find(sheet -> sheet.name == tableName);
        if (table != null) {
            return table.columns;
        }
        return [];
    }

    static function parseObjectClause(arg: Dynamic): ObjectClauseType {
        if (arg == null) {
            return ObjectClauseType.None;
        } else if (arg is Array) {
            if(arg.length == 0) {
                return ObjectClauseType.None;
            }
            return ObjectClauseType.Multiple(arg);
        } else {
            return ObjectClauseType.Single(arg);
        }
    }
}

enum ObjectClauseType {
    None;
    Multiple(arr: Array<Dynamic>);
    Single(val: Dynamic);
}

/*

select("*", "sheets", (row) => {
    return row.id == 1;
});

delete("sheets", (row) => {
    return row.id == 1;
});

update("sheets", (row) => {
        return row.id == 1;
    }, 
    {
        id = 2;
    }
);




select * from sheets where id = 1;

*/