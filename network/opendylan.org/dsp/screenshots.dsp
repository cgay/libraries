<%dsp:taglib name="od"/>

<od:standard-header>Screenshots</od:standard-header>

<DL>

<DT><STRONG><A HREF="images/vrml-viewer.png">VRML Viewer</A></STRONG>

<DD><P>This is a screenshot from our VRML viewer. This uses the OpenGL bindings for Dylan.</P>

<DT><STRONG><A HREF="images/duim-gui-tests-gd236pr1.png">DUIM Test Suite</A></STRONG>

<DD><P>We are currently porting the DUIM (Dylan User Interface
Manager) and gtk-duim libraries (provided by Functional Objects) to
Gwydion Dylan.  (<A HREF="images/duim-gui-tests-hd12.png">This</A>,
compiled with Functional Developer (now called Open Dylan) and running on Win32, is what it
<EMPH>should</EMPH> look like.)</P>

<DT><STRONG><A HREF="images/dylan-gtk-hello.png">Old Gtk+ demo from CVS</A></STRONG>

<DD><P>Gwydion can also be used to write simple Gtk+ programs.</P>

<P>The following screenshots demonstrate various ideas for a Gwydion IDE.
Please feel free to make your own suggestions.</P>

<DT><STRONG><A HREF="images/browser-mockup.png">Gwydion Hypercode Browser mockup</A></STRONG> (Fake)

<DD><P>We want our IDE to seemlessly browse code and documentation. You
should be able to right-click on a name and jump to the relevant
documentation.</P>

<P>These hypercode features could be implemented using a code database. Of
course, such a scheme should still be compatible with CVS, traditional text
editors and command-line compilers.</P>

<P>An essential part of the Gwydion Hypercode environment (as conceived)
was the
<A HREF="http://www-2.cs.cmu.edu/afs/cs.cmu.edu/project/gwydion/hackers/rgs/demo2.gif">
versioning of objects</A> and
<A HREF="http://www-2.cs.cmu.edu/afs/cs.cmu.edu/project/gwydion/hackers/rgs/demo1.gif">
cross-referenced browsing</A>.</P>

<P>It wouldn't be impossible to make Gwydion browse C code, too--we
already have a working C parser written in Dylan.</P>

<DT><STRONG><A HREF="images/browsers1.png">Apple Dylan editor</A></STRONG> (Real)
<DT><STRONG><A HREF="images/browsers2.png">Apple Dylan class browser</A></STRONG> (Real)

<DD><P>Apple Dylan provided a similar environment based on linked
panes. Gwydion would probably represent each pane as a browser window.</P>

</DL>

<od:standard-footer/>
