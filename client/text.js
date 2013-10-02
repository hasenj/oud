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

var languageClass = ko.computed(function() {
    if(language() == "ar") {
        return "lang_rtl";
    } else {
        return "lang_ltr";
    }
});

var goEn = function() {
    language('en');
}

var goAr = function() {
    language('ar');
}

var goTr = function() {
    language('tr');
}

////// app-specific code

bindCookies(language, 'language');

languagePopup = ko.observable(false);
showLanguagePopup = function() {
    languagePopup(true);
    falseOnDocumentClick(languagePopup);
}

// show a language popup if the user hasn't chosen one before
if(!$.cookie('language')) {
    showLanguagePopup();
}


// values for texts

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
