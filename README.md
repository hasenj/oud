This project is a web audio experiment.

Quick Info
---------------

The code for generating/synthesizing the stringed instrument is in `assets/synth.coffee`. The instrument we're attempting to simulate is the Oud.

This project was originally aimed at Firefox 4, but as time passed, Chrome's web audio got more mature, so now Chrome is the preferred browser.

Aim
-------------

This project is designed for playing music on the Arabic (or more generally: Middle Eastern) musical scales, which utilize quarter tones. 

The interface has 2 parts: the music keyboard (`assets/keyboard.coffee`), and the maqam chooser & editor (`assets/maqam.coffee`).

Maqam
--------------

A "Maqam" is a concept roughly corresponding to a musical scale. However, since I'm not well versed in either Western or Middle Eastern music theories, you should take anything I say here with a grain of salt.

Sometimes, the same musical scale with a different starting point produces a different "Maqam". Other times, a Maqam could have a "variation", where one element on the scale is changed, but the Maqam itself doesn't change! Don't ask me. It probably has to do with the mood that the Maqam conveys.

For more info, head to [Maqam World](http://www.maqamworld.com/)

Tones
---------------

I invented my own notation for numbering the tones. 0 is C on the first octave. 1 is D on the first octave, and so on. `n` is the tone that's n steps away from C1.

So, the C major scale starts on tone 0, and has the scale: [1, 1, 0.5, 1, 1, 1, 0.5]

Incidentally, this the same as Maqam Ajam.

