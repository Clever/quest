test-cov:
	rm -rf lib-js lib-js-cov
	coffee -c -o lib-js lib
	jscoverage lib-js lib-js-cov
	NODE_ENV=test TEST_COV=1 node_modules/mocha/bin/mocha --compilers coffee:coffee-script/register -R html-cov test/get.coffee test/post.coffee test/nock.coffee test/promise.coffee | tee coverage.html
	open coverage.html
test:
	NODE_ENV=test node_modules/mocha/bin/mocha --bail --compilers coffee:coffee-script/register test/get.coffee test/post.coffee test/nock.coffee test/promise.coffee

LIBS=$(shell find . -regex "^./lib\/.*\.coffee\$$" | sed s/\.coffee$$/\.js/ | sed s/lib/lib-js/)

lib-js/%.js : lib/%.coffee
	node_modules/coffee-script/bin/coffee --bare -c -o $(@D) $(patsubst lib-js/%,lib/%,$(patsubst %.js,%.coffee,$@))

build: $(LIBS)

.PHONY: test

clean:
	rm -rf lib-js
