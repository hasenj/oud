_modulo = function(index, length) {
    while(index < 0) {
        index += length;
    }
    return index % length;
}

modIndex = function(list, index) {
    return list[_modulo(index, list.length)];
}

