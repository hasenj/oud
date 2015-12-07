SHELL := /bin/bash

all: web mobile

web: out/index.html out/all.css out/client.js out/libs.js web-res

web-res: static/images/* static/fonts/*
	mkdir -p out
	cp -r static/images out/images
	cp -r static/fonts out/fonts

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

mobile: mobile/client.js mobile/styles.css mobile/libs.js

mobile/client.js: client/*.js client/*.coffee
	mkdir -p mobile
	echo "" > mobile/client.js
	# mkdir -p build-mobile/js
	# coffee --compile --output build-mobile/js client/*.coffee
	# cp client/*.js build-mobile/js/
	# cat build-mobile/js/{utils,text,ratios,synth,maqam,controls,mobile}.js | jsmin > mobile/client.js

mobile/styles.css: styles/mobile.less
	mkdir -p mobile
	echo "" > mobile/styles.css
	# mkdir -p build-mobile/css
	# lessc styles/mobile.less > mobile/styles.css

mobile/libs.js: client-libs/*.js
	mkdir -p mobile
	echo "" > mobile/libs.js
	# cat client-libs/{jquery,sugar,jquery.hotkeys,jquery.cookie,ko}.js > mobile/libs.js

