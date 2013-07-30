test-cov:
	rm -rf lib-js lib-js-cov
	coffee -c -o lib-js lib
	jscoverage lib-js lib-js-cov
	NODE_ENV=test TEST_COV=1 node_modules/mocha/bin/mocha --compilers coffee:coffee-script -R html-cov test/get.coffee test/post.coffee | tee coverage.html
	open coverage.html
test:
	NODE_ENV=test node_modules/mocha/bin/mocha --bail --compilers coffee:coffee-script test/get.coffee test/post.coffee test/nock.coffee

.PHONY: test
