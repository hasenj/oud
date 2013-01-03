/*
    Flexible oud-like keyboard allowing to play any kind of "Jins" (tetrachord) without adjusting the current active scale.

    The way to do that is to provide options for "seconds" and "thirds", and even "forths".

        Seconds:
            - Minor second (semitone)
            - Neutral second (three quarter tone)
            - Major second (tone)

        Thirds:
            - Minor third (6:5)
            - Major third (5:4)

        Forths:
            - Diminished forth (major third + semitone)
            - Perfect forth

    The keyboard is made up of rows of octaves,

    Each octave is made up of rows of jins (tetrachords). Jins rows are separated by perfect fifths (3:2)
    With the possibility of adding extra rows to the jins (thus overflowing outside of the octave boundary).

    Each Jins row is made up of "groups" of keys:

        First: 1 key
        Seconds: 3 keys
        Thirds: 2 keys
        Forths: 2 keys

    Totalling 8 keys.

 */

