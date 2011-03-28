dev: has-coffee
	@coffee -wc --bare -o lib src/

test: has-coffee
	@find test -name '*.coffee' | xargs -n 1 -t coffee
	
test-nzb: has-coffee
	@coffee test/nzb.coffee
	
test-parser: has-coffee
	@coffee test/parser.coffee

has-coffee:
	@test `which coffee` || 'You need to install CoffeeScript.'
