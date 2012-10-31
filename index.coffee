if process.env.TEST_COV
  module.exports = require "#{__dirname}/lib-js-cov/quest"
else
  module.exports = require "#{__dirname}/lib/quest"
