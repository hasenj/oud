root = window

jdiv = -> $("<div/>")
jcls = (cls) -> jdiv().addClass(cls)

issue_error = (msg) -> $("#error_box").append(jcls('error').html(msg))
issue_warning = (msg) -> $("#error_box").append(jcls('warning').html(msg))

last = (array) -> 
    array[array.length-1]

_(root).extend({jdiv, jcls, last, issue_error, issue_warning})
