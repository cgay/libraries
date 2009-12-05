<%dsp:taglib name="od"/>

<od:standard-header>A GUI for Gwydion</od:standard-header>

<P>Work is underway on adding <A HREF="http://www.gtk.org/">GTK+</A> and
<A HREF="http://www.gnome.org/">GNOME</A> support to Gwydion Dylan.
If you would like to help, please join the mailing list.</P>

<P>We'd eventually like to support DUIM (the Dylan User
Interface Manager) as a wrapper around GTK+ and GNOME.
This probably involves a huge amount of work.</P>

<P><STRONG>[<A HREF="images/dylan-gtk-hello.png">Screenshot of a trivial GTK+ application in Gwydion Dylan</A>]</STRONG></P>

<?php
begin_progress_table();
progress("Improve <A HREF=\"melange\">Melange</A>", 8);
progress("Wrap GLib", 8);
progress("Wrap GDK", 1);
progress("Wrap GTK+", 4);
progress("Wrap GNOME", 0);
progress("Dylan-like interfaces", 0);
progress("Implement DUIM", 0);
end_progress_table();
?>

<P>Note that OpenDylan already has a GTK+ backend for DUIM.
While this code has been suffering from bit rot for the last
few years&mdash;the main problem being that it doesn't
support GTK+ 2.0&mdash;renovation work has been started.</P>

<od:standard-footer/>
