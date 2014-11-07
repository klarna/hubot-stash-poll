var gulp = require('gulp'),
    mocha = require('gulp-mocha'),
    coffeescript = require('coffee-script'),
    coffeelint = require('gulp-coffeelint'),
    runSequence = require('run-sequence'),
    exit = require('gulp-exit');


// -- task definitions ------------------------------------------------------
gulp.task('lint', function () {
    return gulp.src(['test/**/*.coffee', 'src/**/*.coffee'])
        .pipe(coffeelint())
        .pipe(coffeelint.reporter('failOnWarning'));
});


gulp.task('mocha', function() {
    return gulp.src(['test/**/*.spec.coffee'], { read: false })
        .pipe(mocha({ reporter: 'list' }))
        .pipe(exit());
});


gulp.task('mocha-min', function() {
    return gulp.src(['test/**/*.spec.coffee'], { read: false })
        .pipe(mocha({
            reporter: 'min',
            growl: true
        }));
});


gulp.task('watch', function() {
    return gulp.watch(['test/**/*.coffee', 'src/**/*.coffee'], ['lint', 'mocha-min']);
});


// -- test ------------------------------------------------------------------
gulp.task('test', function(callback) {
    runSequence('lint', 'mocha', callback);
});


// -- default ---------------------------------------------------------------
gulp.task('default', ['test']);