module.exports = function(grunt) {
	// Project configuration.
	// Assumes that make has already run to produce the dist/*.js
	grunt.initConfig({
		lint: {
			all: ['dist/mithgrid.js']
		},
		jshint: {
			options: {
				browser: true,
				noarg: true,
				strict: true,
				
			},
			globals: {
				jQuery: true,
			}
		},
		qunit: {
			files: ['test/*.html']
		},
		min: {
			dist: {
				src: ['dist/mithgrid.js'],
				dest: ['dist/mithgrid.min.js']
			}
		}
	});
};
