var JSLINT = require("./lib/jslint").check, //.JSLINT,
	print = require("sys").print,
	src = require("fs").readFileSync("dist/mithgrid.js", "utf8");

JSLINT(src, { 
	forin: true, 
	maxerr: 100, 
	vars: false, 
	white: true, 
	sloppy: true, 
	browser: true, 
	plusplus: false,
	"continue": true,
	confusion: true
});

// All of the following are known issues that we think are 'ok'
// (in contradiction with JSLint) more information here:
// http://docs.jquery.com/JQuery_Core_Style_Guidelines
var ok = {
//	"Don't make functions within a loop.": true,
};

var e = JSLINT.errors, found = 0, w;

for ( var i = 0; i < e.length; i++ ) {
	w = e[i];
	if(w === null) { continue; }

	if ( !ok[ w.reason ] ) {
		found++;
		print( "\n" + w.evidence + "\n" );
		print( "    Problem at line " + w.line + " character " + w.character + ": " + w.reason );
	}
}

if ( found > 0 ) {
	print( "\n" + found + " Error(s) found.\n" );

} else {
	print( "JSLint check passed.\n" );
}