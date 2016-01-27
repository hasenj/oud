SHELL := /bin/bash

all: web

web: out/index.html out/all.css out/client.js out/libs.js web-res

web-res: static/**
	mkdir -p out
	cp -r static/* out/

out/index.html: templates/*.html
	mkdir -p out
	venv/bin/python render.py templates/index.html > out/index.html

out/all.css: styles/*.styl
	mkdir -p build/css
	mkdir -p out
	./node_modules/stylus/bin/stylus --compress --use ./node_modules/nib styles styles --out build/css
	cat build/css/{global,keyboard,maqam}.css > out/all.css

out/client.js: client/*.js client/*.coffee
	mkdir -p build/js
	mkdir -p out
	./node_modules/coffee-script/bin/coffee --compile --output build/js client/*.coffee
	cp client/*.js build/js/
	cat build/js/{utils,text,ratios,synth,maqam,controls,keyboard}.js | jsmin > out/client.js

out/libs.js: client-libs/*.js
	mkdir -p out
	cat client-libs/{jquery,sugar,jquery.hotkeys,jquery.cookie,ko}.js > out/libs.js

clean-css:
	rm -rf build/css
	rm -f out/all.css

clean-js:
	rm -rf build/js
	rm -f out/client.js

clean-libs:
	rm -f out/libs.js

clean-web: clean-css clean-js clean-libs
	rm -r build
	rm -r out

clean: clean-web

