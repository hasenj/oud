// text in various languages

var language = ko.observable('ar'); // default to arabic

// XXX TODO use cookies to remember language settings

var text = {
    ar: {},
    en: {},
    tr: {}
}

var getText = function(code) {
    var map = text[language()];
    return map.code || text.ar[code] || code;
}

var setText = function(code, lang, value) {
    text[lang][code] = value;
}

var setTextMulti = function(lang, map) {
    text[lang].update(map);
}
