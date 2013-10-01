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

ko.bindingHandlers.hover = {
    init: function(element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) {
        // This will be called when the binding is first applied to an element
        // Set up any initial state, event handlers, etc. here

        $(element).on('mouseover', function() {
            valueAccessor()(true);
        });
        $(element).on('mouseout', function() {
            valueAccessor()(false);
        });
    }
};

// from the wiki https://github.com/knockout/knockout/wiki/Bindings---class
ko.bindingHandlers['class'] = {
    'update': function(element, valueAccessor) {
        if (element['__ko__previousClassValue__']) {
            ko.utils.toggleDomNodeCssClass(element, element['__ko__previousClassValue__'], false);
        }
        var value = ko.utils.unwrapObservable(valueAccessor());
        ko.utils.toggleDomNodeCssClass(element, value, true);
        element['__ko__previousClassValue__'] = value;
    }
};
