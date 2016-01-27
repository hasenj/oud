# install npm dependencies
mkdir -p node_modules # deploy server doesn't like it without this
npm install coffee-script
npm install stylus
npm install nib

# build client files ..
make
