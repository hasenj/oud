all: static/all.css static/client.js static/libs.js

static/all.css: styles/*.styl
	stylus --use ~/node_modules/nib styles --out build/css
	cat build/css/{global,keyboard,maqam}.css > static/all.css

static/client.js: client/*.js client/*.coffee
	coffee --compile --output build/js client/*.coffee
	cp client/*.js build/js/
	cat build/js/{utils,ratios,synth,maqam,controls,keyboard}.js > static/client.js

static/libs.js: client-libs/*.js
	cat client-libs/{jquery,sugar,jquery.hotkeys,jquery.cookie,sink,ko}.js > static/libs.js

clean-css:
	rm -f build/css/*
	rm -f static/all.css

clean-js:
	rm -f build/js/*
	rm -f static/client.js

clean-libs:
	rm -f static/libs.js

clean: clean-css clean-js clean-libs
