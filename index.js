var path = __dirname + '/' + (process.env.TEST_COV ? 'lib-js-cov' : 'lib-js') + '/quest';
module.exports = require(path);
