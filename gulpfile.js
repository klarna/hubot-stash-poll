var gulp = require('gulp'),
    mocha = require('gulp-spawn-mocha'),
    coffeescript = require('coffee-script'),
    coffeelint = require('gulp-coffeelint'),
    runSequence = require('run-sequence'),
    exit = require('gulp-exit');


// -- task definitions ------------------------------------------------------
gulp.task('lint', function () {
    return gulp.src(['test/**/*.coffee', 'src/**/*.coffee'])
        .pipe(coffeelint())
        .pipe(coffeelint.reporter())
        .pipe(coffeelint.reporter('fail'));
});


gulp.task('mocha', function() {
    return gulp.src(['test/**/*.spec.coffee'], { read: false })
        .pipe(mocha({
            reporter: 'tap',
            compilers: 'coffee:coffee-script',
            env: { 'NODE_ENV': 'test' }
        }))
        .pipe(exit());
});


gulp.task('mocha-watch', function() {
    return gulp.src(['test/**/*.spec.coffee'], { read: false })
        .pipe(mocha({
            reporter: 'min',
            compilers: 'coffee:coffee-script',
            env: { 'NODE_ENV': 'test' }
        }));
});


gulp.task('watch', function() {
    return gulp.watch(['test/**/*.coffee', 'src/**/*.coffee'], ['lint', 'mocha-watch']);
});


// -- test ------------------------------------------------------------------
gulp.task('test', function(callback) {
    runSequence('lint', 'mocha', callback);
});


// -- default ---------------------------------------------------------------
gulp.task('default', ['test']);
