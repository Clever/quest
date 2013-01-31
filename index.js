require('coffee-script');
var path = __dirname + '/' + (process.env.TEST_COV ? 'lib-js-cov' : 'lib') + '/quest';
module.exports = require(path);
