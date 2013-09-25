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
    return map[code] || text.ar[code] || code;
}

var setText = function(code, lang, value) {
    text[lang][code] = value;
}

var setTextMulti = function(lang, map) {
    text[lang].update(map);
}

//////

setText('on', 'en', 'on');
setText('on', 'ar', 'على');
setText('on', 'tr', '-');

setText('maqam-presets', 'en', 'Maqam Presets');
setText('maqam-presets', 'ar', 'مقامات جاهزة');
setText('maqam-presets', 'tr', 'Makamlar');

setText('base-note', 'en', 'Base Note');
setText('base-note', 'ar', 'نغمة البداية');
setText('base-note', 'tr', 'nota');

setText('first-jins', 'en', 'First Jins');
setText('first-jins', 'ar', 'الجنس الأول');
setText('first-jins', 'tr', 'ilk dörtlü');

setText('second-jins', 'en', 'Second Jins');
setText('second-jins', 'ar', 'الجنس الثاني');
setText('second-jins', 'tr', 'ikinci dörtlü');
