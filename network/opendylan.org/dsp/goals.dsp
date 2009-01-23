<%dsp:taglib name="od"/>

<od:standard-header>Our Goals</od:standard-header>

<P>We want to make the GNU development tools even better. Right now,
programmers can choose between many excellent compilers, text editors and
programming languages. We want to supplement these choices with an advanced
tool for building complex applications.</P>

<P>Ideally, it would have the following features. We won't achieve this
vision any time soon, but it will give us inspiration during those
long sessions of coding.</P>

<UL>

<LI><P><STRONG>A command-line compiler.</STRONG> There's no point in throwing
tradition out the window, is there? A command-line compiler allows
Makefiles to work gracefully, and is preferred by many developers.</P>

<LI><P><STRONG>A graphical IDE.</STRONG> Other people like a good, integrated
environment. This should include online help, a database of definitions and
cross references, a debugger and an interface builder. It should be
possible to use an external text editor for the actual coding (perhaps via
CORBA). Fortunately, Dylan was designed with intent of having such tools
(see the <A HREF="browser">screenshots</A> of Apple Dylan), and d2c
is already modularized in most of the right places.</P>

<P>The IDE should also be modular and extensible. We want to allow people
to add a database interface builder or duplicate the features
of <A HREF="http://sourcenav.sourceforge.net/">Source Navigator</A>.</P>

<LI><P><STRONG>Tools for novice and expert developers.</STRONG> A good
environment should be usable by both novice developers (folks who just want
to build a simple database front end) and hardcore hackers (people who want
to build a non-linear video editor in a mixture of C and Dylan, for
example).</P>

<LI><P><STRONG>An open source license.</STRONG> We use a license
similar to that used by X11. It contains no significant restrictions,
but disclaims all warranties.  Some of the components we distribute
were obtained from Functional Objects and are distributed under the LGPL.</P>

<LI><P><STRONG>Support for important free software.</STRONG> Gwydion
Dylan must play nicely with all the standard GNU and Unix tools. Even if it
doesn't support a particular program, it must be a good citizen in a
standard GNU environment.</P>

<LI><P><STRONG>Desktop integration.</STRONG> Gwydion Dylan should also work
well with modern free desktops. This means supporting a popular widget set
(Gtk+), and allowing applications written in Dylan to implement important
Gnome and KDE protocols with as little effort as possible.</P>

<LI><P><STRONG>DUIM.</STRONG> The Dylan User Interface Manager (DUIM)
is a portable GUI toolkit designed by Harlequin/Functional Objects. We
have begun to adapt DUIM using a Gtk+ backend (since the two libraries
have a very similar design), though some work remains to be done.</P>

<LI><P><STRONG>Seamless support for C libraries.</STRONG> Most Unix
libraries are written in C, and it would be impossible (and undesirable) to
duplicate them all in Dylan. It should be just as easy to use a C library
from Dylan as it is from C.</P>

<LI><P><STRONG>Portability to other platforms.</STRONG> Gwydion Dylan
should remain a portable compiler, and standard libraries should not make
assumptions which would prevent a third party from porting them to Rhapsody
or the BeOS.</P>

</UL>

<H3>Related Information</H3>

<P>For more background, you might want to check out the goals of other
Dylan implementors:</P>

<DL>

<DT><STRONG><A HREF="http://www.cs.cmu.edu/afs/cs/project/gwydion/docs/htdocs/gwydion/gwydion-overview.html">The Gwydion Group's original white paper</A></STRONG> 

<DD><P>The Gwydion Group at CMU had a very ambitious vision for Gwydion
Dylan. This paper from 1993 explains what they originally intended to
accomplish.</P>

</DL>

<od:standard-footer/>
