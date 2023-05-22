RPHelm README

RPHelm is a simple addon to allow you to have character's helm and/or
cloak be automatically shown or hidden depending on whether you're
in or out of combat.

You may also choose to have RPHelm treat you as "in combat" whenever 
your PVP flag is set.

It can be configured either through the addon control panel, or with
the /rphelm command.  Configuration information is saved per-character,
so you can set up each of your characters differently.

Regardless of whether the automatic switching is active, RPHelm gives
you "/helm" and "/cloak" commands, which will toggle showing your helm
or cloak.  You may also use "/helm hide", "/helm show", "/cloak hide", 
"/cloak show" -- these are for use in macros, so you can reliably show 
or hide helm and cloak without worrying about what state they're already 
in.

You can also manually set "in combat" and "out of combat" status with
the /rphelm command.  "/rphelm combat" or "/rphelm ready" will put
you "in combat" for RPHelm's purposes, while "/rphelm nocombat" or
"/rphelm unready" will put you "out of combat".

All these commands also accept the bracket options of WoW's macro
language, so you can create macros like:

/helm [mod:shift] show; hide
/cloak [mod:alt] show; hide

KNOWN ISSUES

Under some circumstances (e.g., if you die in combat), RPHelm cannot
change your helm/cloak visibility when your combat status changes.  
When this happens, you can either use the /helm or /cloak command to
change the status by hand.  RPHelm will get "back in sync" the next
time you enter or leave combat normally.

THANKS

Thanks go to Invinciblor on Curse, both for adding the "show/hide" 
functionality, and for kicking me about it to actually get off my butt 
and put in his changes.

Thanks also go to Gogibal on Curse, for asking about why the macro 
options didn't work, and suggesting the addition of PVP status as a
trigger.
