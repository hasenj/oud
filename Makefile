static/all.css: styles/*.styl
	stylus --use ~/node_modules/nib styles --out build/css
	cat build/css/*.css > static/all.css

static/client.js: client/*.js client/*.coffee
	coffee --compile --output build/js client/*.coffee
	cat build/js/*.js > static/client.js

static/libs.js: client-libs/*.js
	cat client-libs/*.js > static/libs.js

all: static/all.css static/client.js static/libs.js
