package test;

import haxe.Json;
import util.query.SqlEngine;
import cdb.Database;

class TestSQL {
    
    public static function main() {
        var database = new Database();
        var s = new SqlEngine(database);
        s.run("create table test (a int, b int)");
        s.run("insert into test values (1, 2)");
        trace(Json.stringify(s.run("select * from test")));

        s.run("create table test2 (a int, b int)");
        s.run("insert into test2 (a, b) values (3, 4)");
        s.run("insert into test2 (a, b) values (5, 6)");
        s.run("insert into test2 (a, b) values (3, 4)");
        s.run("insert into test2 (a, b) values (5, 6)");
        trace(Json.stringify(s.run("select * from test2")));

        s.run("insert into test (a, b) select * from test2");
        s.run("insert into test (a, b) select * from test");
        trace(Json.stringify(s.run("select * from test")));
    }
}