Dynamic Music Keyboard
-------------------------

- Built with HTML5 technologies
    - Audio generated in javascript on the fly (code is actually written in coffee-script)
- Focus on Middle Eastern scales (maqam/makam)
- Oud/Qanun like sounds (ud/kanun)

Note: Awtar is Arabic for "Strings"

Scale Theory
------------------------

Forget about semitones and whole tones. We're going back to the basics.

The scale is built by combining two (or sometimes three) Tetrachords, separated by a perfect fifth ratio (3:2).

A tetrachord is a series of 3 intervals (spanning four notes). Each interval is defined by its distance to the first/base note (not the previous note).

We have 8 basic tetrachords that scales can be built out of.

Acquiring these tetrachords is based on what choices are available for the forth, third, and second intervals, and understanding which choices go with which. Arguable one can derive many more tetrachords, but they would mostly be useless repititions. In fact, we already have repitition in these 8 tetrachords, but that's sort of okay because they happen to be pretty standard, and choosing to eliminate any of them for being repititive may confuse the user.

Deriving the tetrachords is demonstrated in the following diagram:

    +- perfect forth
        +- major third
            +- major second [ajem]
            +- minor second [hijaz]
        +- neutral third
            +- major second [rast]
        +- minor third
            +- major second [nahawend]
            +- neutral second [beyat]
            +- minor second [kurd]
    +- diminished forth
        +- minor third
            +- neutral second [saba]
            +- minor second [zemzem]

If the second tetrachord in the scale is a diminished tetrachord (saba/zemzem), a third tetrachord is added (a clone of the second tetrachord).

A musical scale also requires a starting tone. We chose to stick to the standard and use the A-minor/C-major scale as a base for naming notes and providing options for starting notes.

Modulation
---------------------------
Modulation or scale switching is done by changing one (or two) of the tetrachords during play. This can be achieved either by choosing a tetrachord from the dropdown menu (with the mouse) or using keyboard shortcuts.

Hitting a number from 1-8 changes the active tetrachord and moves the "current tetrachord pointer", unless the point is locked. Locking/unlocking the pointer is done by hitting key 9 on the keyboard (or toggling the lock icon by clicking it with the mouse)

Changing the starting note, while not technically considered "modulation", is also possible via either the gui or keyboard short cuts (via the + and - keys).
