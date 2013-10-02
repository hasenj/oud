SHELL := /bin/bash
all: static/all.css static/client.js static/libs.js

static/all.css: styles/*.styl
	mkdir -p build/css
	stylus --compress --use ~/node_modules/nib styles --out build/css
	cat build/css/{global,keyboard,maqam}.css > static/all.css

static/client.js: client/*.js client/*.coffee
	mkdir -p build/js
	coffee --compile --output build/js client/*.coffee
	cp client/*.js build/js/
	cat build/js/{text,utils,ratios,synth,maqam,controls,keyboard}.js | jsmin > static/client.js

static/libs.js: client-libs/*.js
	cat client-libs/{jquery,sugar,jquery.hotkeys,jquery.cookie,ko}.js > static/libs.js

clean-css:
	rm -rf build/css
	rm -f static/all.css

clean-js:
	rm -rf build/js
	rm -f static/client.js

clean-libs:
	rm -f static/libs.js

clean: clean-css clean-js clean-libs
	rm -r build
