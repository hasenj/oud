// set the observable to false when any click event occurs on the document
var falseOnDocumentClick = function(ob) {
    var hideIt = function() {
        if(ob()) {
            ob(false);
        }
    }

    var eventHandler = function() {
        setTimeout(function() {
            hideIt();
            document.removeEventListener('click', eventHandler);
        }, 100);
    }

    setTimeout(function() {
        document.addEventListener('click', eventHandler);
    }, 100);
}


