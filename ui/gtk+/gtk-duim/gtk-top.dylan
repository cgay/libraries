Module:       gtk-duim
Synopsis:     GTK top level window handling
Author:       Andy Armstrong, Scott McKay
Copyright:    Original Code is Copyright (c) 1999-2000 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Useful constants 

//---*** This should really be computed
define constant $top-level-border     = 0;
define constant $top-level-y-spacing  = 3;		// in pixels
define constant $default-window-title = "DUIM Window";


/// Top level mirrors

define sealed class <top-level-mirror> (<widget-mirror>)
  sealed slot %dialog-mirrors :: <stretchy-object-vector>
    = make(<stretchy-vector>);
end class <top-level-mirror>;

define sealed method top-level-mirror
    (sheet :: <sheet>, #key error? = #f)
 => (mirror :: false-or(<top-level-mirror>))
  let sheet  = top-level-sheet(sheet);
  let mirror = sheet & sheet-direct-mirror(sheet);
  mirror
    | (error? & error("Failed to find top-level mirror for %=", sheet))
end method top-level-mirror;

define sealed method top-level-mirror
    (frame :: <frame>, #key error? = #f)
 => (mirror :: false-or(<top-level-mirror>))
  let sheet  = top-level-sheet(frame);
  let mirror = sheet & sheet-direct-mirror(sheet);
  mirror
    | (error? & error("Failed to find top-level mirror for %=", sheet))
end method top-level-mirror;

define method set-mirror-parent
    (child :: <widget-mirror>, parent :: <top-level-mirror>)
 => ()
  let (x, y) = sheet-native-edges(mirror-sheet(child));
  gtk-container-add(GTK-CONTAINER(mirror-widget(parent)),
		    mirror-widget(child))
end method set-mirror-parent;
    
define method move-mirror
    (parent :: <top-level-mirror>, child :: <widget-mirror>,
     x :: <integer>, y :: <integer>)
 => ()
  unless (x == 0 & y == 0)
    ignoring("move-mirror for <top-level-mirror>")
  end
end method move-mirror;

define method size-mirror
    (parent :: <top-level-mirror>, child :: <widget-mirror>,
     width :: <integer>, height :: <integer>)
 => ()
  ignore(parent);
  set-mirror-size(child, width, height)
end method size-mirror;


/// Accelerator handling

define function make-keyboard-gesture
    (keysym :: <symbol>, #rest modifiers)
 => (gesture :: <keyboard-gesture>)
  make(<keyboard-gesture>, keysym: keysym, modifiers: modifiers)
end function make-keyboard-gesture;

define function gesture-modifiers
    (gesture :: <keyboard-gesture>)
 => (shift? :: <boolean>, control? :: <boolean>, alt? :: <boolean>)
  let modifier-state = gesture-modifier-state(gesture);
  values(~zero?(logand(modifier-state, $shift-key)),
	 ~zero?(logand(modifier-state, $control-key)),
	 ~zero?(logand(modifier-state, $alt-key)))
end function gesture-modifiers;

//---*** WHAT ABOUT ALL THIS ACCELERATOR STUFF?
define table $accelerator-table :: <object-table>
  = { // This is the set defined by WIG, Appendix B, Table B.2, page 438
      #"Copy"        => make-keyboard-gesture(#"c", #"control"),
      #"Cut"         => make-keyboard-gesture(#"x", #"control"),
      #"Help"        => make-keyboard-gesture(#"f1"),
      #"Open"        => make-keyboard-gesture(#"o", #"control"),
      #"Open..."     => make-keyboard-gesture(#"o", #"control"),
      #"Paste"       => make-keyboard-gesture(#"v", #"control"),
      #"Print"       => make-keyboard-gesture(#"p", #"control"),
      #"Print..."    => make-keyboard-gesture(#"p", #"control"),
      #"Save"        => make-keyboard-gesture(#"s", #"control"),
      #"Undo"        => make-keyboard-gesture(#"z", #"control"),

      // The same set with the mnemonics already in (a bit of a hack!)
      #"&Copy"       => make-keyboard-gesture(#"c", #"control"),
      #"Cu&t"        => make-keyboard-gesture(#"x", #"control"),
      #"&Help"       => make-keyboard-gesture(#"f1"),
      #"&Open"       => make-keyboard-gesture(#"o", #"control"),
      #"&Open..."    => make-keyboard-gesture(#"o", #"control"),
      #"&Paste"      => make-keyboard-gesture(#"v", #"control"),
      #"&Print"      => make-keyboard-gesture(#"p", #"control"),
      #"&Print..."   => make-keyboard-gesture(#"p", #"control"),
      #"&Save"       => make-keyboard-gesture(#"s", #"control"),
      #"&Undo"       => make-keyboard-gesture(#"z", #"control"),

      // Some extras that seemed to be missing
      #"Delete"      => make-keyboard-gesture(#"delete"),
      #"Find"        => make-keyboard-gesture(#"f", #"control"),
      #"Find..."     => make-keyboard-gesture(#"f", #"control"),
      #"New"         => make-keyboard-gesture(#"n", #"control"),
      #"New..."      => make-keyboard-gesture(#"n", #"control"),
      #"Redo"        => make-keyboard-gesture(#"y", #"control"),
      #"Select All"  => make-keyboard-gesture(#"a", #"control"),

      // The same set with the mnemonics already in (a bit of a hack!)
      #"&Delete"     => make-keyboard-gesture(#"delete"),
      #"&Find"       => make-keyboard-gesture(#"f", #"control"),
      #"&Find..."    => make-keyboard-gesture(#"f", #"control"),
      #"&New"        => make-keyboard-gesture(#"n", #"control"),
      #"&New..."     => make-keyboard-gesture(#"n", #"control"),
      #"&Redo"       => make-keyboard-gesture(#"y", #"control"),
      #"&Select All" => make-keyboard-gesture(#"a", #"control")
      };

define sealed method defaulted-gadget-accelerator
    (framem :: <gtk-frame-manager>, gadget :: <accelerator-mixin>)
 => (accelerator :: false-or(<accelerator>))
  let accelerator = gadget-accelerator(gadget);
  if (unsupplied?(accelerator))
    let label = gadget-label(gadget);
    let key   = instance?(label, <string>) & as(<symbol>, label);
    element($accelerator-table, key, default: #f)
  else
    accelerator
  end
end method defaulted-gadget-accelerator;


define sealed method add-gadget-label-postfix
    (gadget :: <gtk-gadget-mixin>, label :: <string>) => (label :: <string>)
  label
end method add-gadget-label-postfix;

define sealed method add-gadget-label-postfix
    (gadget :: <accelerator-mixin>, label :: <string>) => (label :: <string>)
  let framem  = frame-manager(gadget);
  let gesture = defaulted-gadget-accelerator(framem, gadget);
  if (gesture)
    let keysym = gesture-keysym(gesture);
    let (shift?, control?, alt?) = gesture-modifiers(gesture);
    concatenate-as(<string>, 
		   label,
		   "\t",
		   if (shift?)   "Shift+" else "" end,
		   if (control?) "Ctrl+"  else "" end,
		   if (alt?)     "Alt+"   else "" end,
		   keysym->key-name(keysym))
  else
    label
  end
end method add-gadget-label-postfix;

// Map keysyms to their labels on a typical keyboard
define table $keysym->key-name :: <object-table>
  = { #"return"     => "Enter",
      #"newline"    => "Shift+Enter",
      #"linefeed"   => "Line Feed",
      #"up"	    => "Up Arrow",
      #"down"	    => "Down Arrow",
      #"left"	    => "Left Arrow",
      #"right"	    => "Right Arrow",
      #"prior"	    => "Page Up",
      #"next"	    => "Page Down",
      #"lwin"	    => "Left Windows",
      #"rwin"	    => "Right Windows",
      #"numpad0"    => "Num 0",
      #"numpad1"    => "Num 1",
      #"numpad2"    => "Num 2",
      #"numpad3"    => "Num 3",
      #"numpad4"    => "Num 4",
      #"numpad5"    => "Num 5",
      #"numpad6"    => "Num 6",
      #"numpad7"    => "Num 7",
      #"numpad8"    => "Num 8",
      #"numpad9"    => "Num 9",
      #"num-lock"   => "Num Lock",
      #"caps-lock"  => "Caps Lock" };

define function keysym->key-name
    (keysym) => (name :: <string>)
  element($keysym->key-name, keysym, default: #f)
  | string-capitalize(as(<string>, keysym))
end function keysym->key-name;

/*---*** What should we do here?
define sealed method accelerator-table
    (sheet :: <top-level-sheet>) => (accelerators :: false-or(<HACCEL>))
  let mirror = sheet-direct-mirror(sheet);
  // Ensure that we don't build the accelerator table too early (i.e.,
  // before all of the resource ids have been created).  This isn't as bad
  // as it seems, since users won't have been able to use an accelerator
  // before the top-level sheet is mapped anyway...
  when (sheet-mapped?(sheet))
    mirror.%accelerator-table
    | (mirror.%accelerator-table := make-accelerator-table(sheet))
  end
end method accelerator-table;

define sealed method accelerator-table
    (sheet :: <sheet>) => (accelerators :: false-or(<HACCEL>))
  let top-sheet = top-level-sheet(sheet);
  top-sheet & accelerator-table(top-sheet)
end method accelerator-table;

define method make-accelerator-table
    (sheet :: <top-level-sheet>) => (accelerators :: <HACCEL>)
  local method fill-accelerator-entry
	    (gadget :: <accelerator-mixin>, accelerator :: <accelerator>,
	     entry :: <LPACCEL>) => ()
	  let keysym    = gesture-keysym(accelerator);
	  let modifiers = gesture-modifier-state(accelerator);
	  let char      = gesture-character(accelerator);
	  let (vkey :: <integer>, fVirt :: <integer>)
	    = case
		char
		& zero?(logand(modifiers, logior($control-key, $meta-key)))
		& character->virtual-key(char) =>
		  values(character->virtual-key(char), 0);
		keysym->virtual-key(keysym) =>
		  values(keysym->virtual-key(keysym),
			 logior($ACCEL-FVIRTKEY,
				if (zero?(logand(modifiers, $shift-key)))   0 else $ACCEL-FSHIFT end,
				if (zero?(logand(modifiers, $control-key))) 0 else $ACCEL-FCONTROL end,
				if (zero?(logand(modifiers, $alt-key)))     0 else $ACCEL-FALT end));
		otherwise =>
		  error("Can't decode the gesture with keysym %=, modifiers #o%o",
			keysym, modifiers);
	      end;
	  let cmd :: <integer>
	    = sheet-resource-id(gadget) | gadget->id(gadget);
	  entry.fVirt-value := fVirt;
	  entry.key-value   := vkey;
	  entry.cmd-value   := cmd;
	end method;
  let accelerators   = frame-accelerators(sheet-frame(sheet));
  let n :: <integer> = size(accelerators);
  if (n > 0)
    with-stack-structure (entries :: <LPACCEL>, element-count: n)
      for (i :: <integer> from 0 below n)
	let entry  = accelerators[i];
	let gadget = entry[0];
	let accel  = entry[1];
	let entry  = pointer-value-address(entries, index: i);
	fill-accelerator-entry(gadget, accel, entry)
      end;
      check-result("CreateAcceleratorTable", CreateAcceleratorTable(entries, n))
    end
  else
    $null-HACCEL
  end
end method make-accelerator-table;

define sealed method destroy-accelerator-table
    (sheet :: <top-level-sheet>) => ()
  let accelerator-table = accelerator-table(sheet);
  when (accelerator-table & ~null-handle?(accelerator-table))
    DestroyAcceleratorTable(accelerator-table)
  end;
  let mirror = sheet-direct-mirror(sheet);
  mirror.%accelerator-table := #f
end method destroy-accelerator-table;
*/

define method note-accelerators-changed
    (framem :: <gtk-frame-manager>, frame :: <basic-frame>) => ()
  // Force the accelerators to be recomputed
  let top-sheet = top-level-sheet(frame);
  when (top-sheet)
    ignoring("note-accelerators-changed")
  end
end method note-accelerators-changed;


/// Dialog handling

define method mirror-registered-dialogs
    (mirror :: <top-level-mirror>) => (dialogs :: <sequence>)
  mirror.%dialog-mirrors
end method mirror-registered-dialogs;

define method register-dialog-mirror
    (frame :: <simple-frame>, dialog-mirror :: <dialog-mirror>) => ()
  let top-sheet = top-level-sheet(frame);
  when (top-sheet)
    let top-mirror = sheet-direct-mirror(top-sheet);
    add!(top-mirror.%dialog-mirrors, dialog-mirror)
  end
end method register-dialog-mirror;

define method unregister-dialog-mirror
    (frame :: <simple-frame>, dialog-mirror :: <dialog-mirror>) => ()
  let top-sheet = top-level-sheet(frame);
  when (top-sheet)
    let top-mirror = sheet-direct-mirror(top-sheet);
    remove!(top-mirror.%dialog-mirrors, dialog-mirror)
  end
end method unregister-dialog-mirror;


/// Top level sheets

define open abstract class <gtk-top-level-sheet-mixin>
    (<standard-repainting-mixin>,
     <permanent-medium-mixin>,
     <gtk-pane-mixin>)
end class <gtk-top-level-sheet-mixin>;

define sealed class <gtk-top-level-sheet>
    (<gtk-top-level-sheet-mixin>,
     <top-level-sheet>)
end class <gtk-top-level-sheet>;

define sealed method class-for-make-pane
    (framem :: <gtk-frame-manager>, class == <top-level-sheet>, #key)
 => (class :: <class>, options :: false-or(<sequence>))
  values(<gtk-top-level-sheet>, #f)
end method class-for-make-pane;

// Like a top-level sheet, but for embedded apps such as OLE parts
define sealed class <gtk-embedded-top-level-sheet>
    (<gtk-top-level-sheet-mixin>,
     <embedded-top-level-sheet>)
end class <gtk-embedded-top-level-sheet>;

define sealed method class-for-make-pane
    (framem :: <gtk-frame-manager>, class == <embedded-top-level-sheet>, #key)
 => (class :: <class>, options :: false-or(<sequence>))
  values(<gtk-embedded-top-level-sheet>, #f)
end method class-for-make-pane;

define sealed method make-gtk-mirror
    (sheet :: <gtk-top-level-sheet-mixin>)
 => (mirror :: <top-level-mirror>)
  let frame = sheet-frame(sheet);
  make-top-level-mirror(sheet, frame)
end method make-gtk-mirror;

define sealed method make-top-level-mirror
    (sheet :: <top-level-sheet>, frame :: <basic-frame>)
 => (mirror :: <top-level-mirror>)
  let widget = GTK-WINDOW(gtk-window-new($GTK-WINDOW-TOPLEVEL));
  make(<top-level-mirror>,
       widget: widget,
       sheet:  sheet)
end method make-top-level-mirror;

define method update-mirror-attributes
    (sheet :: <top-level-sheet>, mirror :: <top-level-mirror>)
 => ()
  next-method();
  let frame = sheet-frame(sheet);
  let widget = mirror-widget(mirror);
  let modal? = frame-mode(frame) == #"modal";
  let title = frame-title(frame) | $default-window-title;
  with-c-string (c-string = title)
    gtk-window-set-title(widget, c-string)
  end;
  gtk-window-set-modal(widget, if (modal?) $true else $false end);
  gtk-container-set-border-width(GTK-CONTAINER(widget), $top-level-border);
end method update-mirror-attributes;

define method install-event-handlers
    (sheet :: <gtk-top-level-sheet-mixin>, mirror :: <top-level-mirror>) => ()
  next-method();
  install-named-handlers(mirror,
			 #[#"delete_event", #"configure_event"])
end method install-event-handlers;


define sealed method map-mirror
    (_port :: <gtk-port>, sheet :: <gtk-top-level-sheet-mixin>,
     mirror :: <top-level-mirror>)
 => ()
  let widget = mirror-widget(mirror);
  gtk-widget-show(widget)
end method map-mirror;

define sealed method unmap-mirror
    (_port :: <gtk-port>,
     sheet :: <gtk-top-level-sheet-mixin>, mirror :: <top-level-mirror>)
 => ()
  let widget = mirror-widget(mirror);
  gtk-widget-hide(widget)
end method unmap-mirror;

define sealed method raise-mirror 
    (_port :: <gtk-port>, sheet :: <gtk-top-level-sheet-mixin>,
     mirror :: <top-level-mirror>,
     #key activate? :: <boolean> = #f)
 => ()
  ignoring("raise-mirror")
end method raise-mirror;

define sealed method lower-mirror
    (_port :: <gtk-port>, sheet :: <gtk-top-level-sheet-mixin>, 
     mirror :: <top-level-mirror>)
 => ()
  ignoring("lower-mirror")
end method lower-mirror;

define sealed method handle-gtk-delete-event
    (sheet :: <top-level-sheet>, widget :: <GtkWidget*>,
     event :: <GdkEventAny*>)
 => (handled? :: <boolean>)
  let frame  = sheet-frame(sheet);
  let controller = frame & frame-controlling-frame(frame);
  when (controller)
    debug-message("Exiting frame");
    exit-frame(frame, destroy?: #t)
  end;
  debug-message("Handled delete event");
  #t
end method handle-gtk-delete-event;

define sealed method destroy-mirror 
    (_port :: <gtk-port>,
     sheet :: <gtk-top-level-sheet-mixin>, mirror :: <top-level-mirror>)
 => ()
  debug-message("destroy-mirror of %=", mirror);
  let widget = mirror-widget(mirror);
  gtk-widget-destroy(widget);
  next-method();
end method destroy-mirror;


/// Top level layout

define class <top-level-layout> 
    (<mirrored-sheet-mixin>, 
     <single-child-wrapping-pane>)
end class <top-level-layout>;

define method frame-wrapper
    (framem :: <gtk-frame-manager>, 
     frame :: <simple-frame>,
     layout :: false-or(<sheet>))
 => (wrapper :: false-or(<top-level-layout>))
  with-frame-manager (framem)
    make(<top-level-layout>,
	 child: top-level-layout-child(framem, frame, layout))
  end
end method frame-wrapper;

define method top-level-layout-child
    (framem :: <gtk-frame-manager>, 
     frame :: <simple-frame>,
     layout :: false-or(<sheet>))
 => (layout :: false-or(<column-layout>))
  let menu-bar      = frame-menu-bar(frame);
  let tool-bar   = frame-tool-bar(frame);
  let status-bar = frame-status-bar(frame);
  with-frame-manager (framem)
    let indented-children
      = make-children(tool-bar & tool-bar-decoration(tool-bar), layout);
    let indented-children-layout
      = unless (empty?(indented-children))
	  with-spacing (spacing: 2)
	    make(<column-layout>,
		 children: indented-children,
		 y-spacing: $top-level-y-spacing)
          end
        end;
    make(<column-layout>,
	 children: make-children(menu-bar, indented-children-layout, status-bar),
	 y-spacing: $top-level-y-spacing)
  end
end method top-level-layout-child;

define function make-children
    (#rest maybe-children)
 => (children :: <sequence>)
  let children :: <stretchy-object-vector> = make(<stretchy-vector>);
  for (child in maybe-children)
    when (child)
      add!(children, child)
    end
  end;
  children
end function make-children;


define method update-frame-layout
    (framem :: <gtk-frame-manager>, frame :: <simple-frame>) => ()
  let top-sheet = top-level-sheet(frame);
  let wrapper = sheet-child(top-sheet);
  let layout = frame-layout(frame);
  let new-child = top-level-layout-child(framem, frame, layout);
  sheet-child(wrapper) := new-child;
  relayout-parent(new-child)
end method update-frame-layout;

define sealed method update-frame-wrapper
    (framem :: <gtk-frame-manager>, frame :: <simple-frame>) => ()
  let top-sheet = top-level-sheet(frame);
  if (top-sheet)
    let wrapper = sheet-child(top-sheet);
    let layout = frame-layout(frame);
    let new-child = top-level-layout-child(framem, frame, layout);
    sheet-child(wrapper) := new-child;
    relayout-parent(new-child)
  end
end method update-frame-wrapper;


/// Geometry updating

define sealed method handle-move
    (sheet :: <top-level-sheet>, mirror :: <top-level-mirror>,
     x :: <integer>, y :: <integer>)
 => (handled? :: <boolean>)
  let (old-x, old-y) = sheet-position(sheet);
  unless (x = old-x & y = old-y)
    let frame = sheet-frame(sheet);
    duim-debug-message("Sheet %= moved to %=, %= (from %=, %=)",
		       sheet, x, y, old-x, old-y);
    set-sheet-position(sheet, x, y)
  end;
  #t
end method handle-move;

define sealed method handle-gtk-configure-event
    (sheet :: <top-level-sheet>, widget :: <GtkWidget*>,
     event :: <GdkEventConfigure*>)
 => (handled? :: <boolean>)
  let frame  = sheet-frame(sheet);
  let left   = event.x-value;
  let top    = event.y-value;
  let width  = event.width-value;
  let height = event.height-value;
  let region = make-bounding-box(left, top, left + width, top + height);
  let (old-width, old-height) = box-size(sheet-region(sheet));
  //---*** Switch back to duim-debug-message
  debug-message("Resizing %= to %dx%d -- was %dx%d",
		sheet, width, height, old-width, old-height);
  distribute-event(port(sheet),
		   make(<window-configuration-event>,
			sheet: sheet,
			region: region));
  #t
end method handle-gtk-configure-event;
