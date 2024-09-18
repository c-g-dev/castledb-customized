package cdb;

enum Token {
	CInt( v : Int );
	CFloat( v : Float );
	Kwd( s : String );
	Ident( s : String );
	Star;
	Eof;
	POpen;
	PClose;
	Comma;
	Op( op : TokenBinop );
}

enum TokenBinop {
	Eq;
    Lt;
    Gt;
    LtEq;
    GtEq;
    Neq;
}

class SqlLexer {

    static var KWDS = [
		"ALTER", "SELECT", "UPDATE", "INSERT", "INTO", "WHERE", "CREATE", "FROM", "TABLE", "NOT", "NULL",
		"ADD", "ON", "DELETE", "SET",
	];

	var query : String;
	var pos : Int;
	var keywords : Map<String,Bool>;
	var idChar : Array<Bool>;
	var cache : Array<Token>;

	public function new() {
		idChar = [];
		for( i in 'A'.code...'Z'.code + 1 )
			idChar[i] = true;
		for( i in 'a'.code...'z'.code + 1 )
			idChar[i] = true;
		for( i in '0'.code...'9'.code + 1 )
			idChar[i] = true;
		idChar['_'.code] = true;
		keywords = [for( k in KWDS ) k => true];
    }

    public function lex( q : String ): Array<Token> {
		this.query = q;
		this.pos = 0;
		cache = [];
		
        var result = [];
        while( true ) {
            var t = token();
            if( t == null ) break;
            result.push(t);
        }    
        return result;
	}

    function token() {
		var t = cache.pop();
		if( t != null ) return t;
		while( true ) {
			var c = nextChar();
			switch( c ) {
			case ' '.code, '\r'.code, '\n'.code, '\t'.code:
				continue;
			case '*'.code:
				return Star;
			case '('.code:
				return POpen;
			case ')'.code:
				return PClose;
			case ','.code:
				return Comma;
			case '='.code:
				return Op(Eq);
			case '`'.code:
				var start = pos;
				do {
					c = nextChar();
				} while( isIdentChar(c) );
				if( c != '`'.code )
					throw "Unclosed `";
				return Ident(query.substr(start, (pos - 1) - start));
			case '0'.code, '1'.code, '2'.code, '3'.code, '4'.code, '5'.code, '6'.code, '7'.code, '8'.code, '9'.code:
				var n = (c - '0'.code) * 1.0;
				var exp = 0.;
				while( true ) {
					c = nextChar();
					exp *= 10;
					switch( c ) {
					case 48,49,50,51,52,53,54,55,56,57:
						n = n * 10 + (c - 48);
					case '.'.code:
						if( exp > 0 )
							invalidChar(c);
						exp = 1.;
					default:
						pos--;
						var i = Std.int(n);
						return (exp > 0) ? CFloat(n * 10 / exp) : ((i == n) ? CInt(i) : CFloat(n));
					}
				}
			default:
				if( (c >= 'A'.code && c <= 'Z'.code) || (c >= 'a'.code && c <= 'z'.code) ) {
					var start = pos - 1;
					do {
						c = nextChar();
					} while( isIdentChar(c) );
					pos--;
					var i = query.substr(start, pos - start);
					var iup = i.toUpperCase();
					if( keywords.exists(iup) )
						return Kwd(iup);
					return Ident(i);
				}
				if( StringTools.isEof(c) )
					return Eof;
				invalidChar(c);
			}
		}
	}

    inline function nextChar() {
		return StringTools.fastCodeAt(query, pos++);
	}

    inline function isIdentChar( c : Int ) {
		return idChar[c];
	}

	function invalidChar(c) {
		throw "Unexpected char '" + String.fromCharCode(c)+"'";
	}

}