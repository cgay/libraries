Module:       gtk-duim
Synopsis:     GTK pixmap implementation
Author:       Andy Armstrong, Scott McKay
Copyright:    Original Code is Copyright (c) 1999-2000 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// GTK pixmaps
/*---*** Not doing pixmaps yet!

define sealed class <gtk-pixmap> (<pixmap>)
  sealed slot %pixmap :: false-or(<GdkPixmap*>) = #f,
    init-keyword: pixmap:;
  sealed slot %medium :: <gtk-medium>,
    required-init-keyword: medium:;
end class <gtk-pixmap>;

define sealed domain make (singleton(<gtk-pixmap>));
define sealed domain initialize (<gtk-pixmap>);

define sealed method do-make-pixmap
    (_port :: <gtk-port>, medium :: <gtk-medium>, 
     width :: <integer>, height :: <integer>)
 => (pixmap :: <gtk-pixmap>)
  make(<gtk-pixmap>, medium: medium, width: width, height: height)
end method do-make-pixmap;

define sealed method initialize
    (pixmap :: <gtk-pixmap>, #key width, height, medium) => ()
  next-method();
  let x-display = port(pixmap).%display;
  let x-screen  = x/ScreenOfDisplay(sheet-direct-mirror(display(medium)));
  let drawable  = medium-drawable(medium);
  let depth     = x/DefaultDepthOfScreen(x-screen);
  let x-pixmap  = gdk-pixmap-new(window, width, height, depth);
  let pixmap    = make(<xmeduim-pixmap>, port: port, x-pixmap: x-pixmap);
  //---*** Do we have to call 'gdk-pixmap-ref'???
  pixmap.%pixmap := x-pixmap
end method initialize;

define sealed method destroy-pixmap
    (pixmap :: <gtk-pixmap>) => ()
  let x-pixmap  = pixmap.%pixmap;
  pixmap.%pixmap := #f;
  gdk-pixmap-unref(x-pixmap)
end method destroy-pixmap;

define sealed method port 
    (pixmap :: <gtk-pixmap>) => (port :: <gtk-port>)
  port(pixmap.%medium)
end method port;

define sealed method pixmap-drawable
    (pixmap :: <gtk-pixmap>) => (drawable)
  pixmap
end method pixmap-drawable;

define sealed method image-width 
    (pixmap :: <gtk-pixmap>) => (width :: <integer>)
  let x-display = port(pixmap).%display;
  let x-pixmap  = pixmap.%pixmap;
  let (success?, root, x, y, width, height, border, depth)
    = x/XGetGeometry(x-display, x-pixmap);
  ignore(success?, root, x, y, height, border, depth);
  width
end method image-width;

define sealed method image-height 
    (pixmap :: <gtk-pixmap>) => (height :: <integer>)
  let x-display = port(pixmap).%display;
  let x-pixmap  = pixmap.%pixmap;
  let (success?, root, x, y, width, height, border, depth)
    = x/XGetGeometry(x-display, x-pixmap);
  ignore(success?, root, x, y, width, border, depth);
  height
end method image-height;

define sealed method image-depth 
    (pixmap :: <gtk-pixmap>) => (depth :: <integer>)
  let x-display = port(pixmap).%display;
  let x-pixmap  = pixmap.%pixmap;
  let (success?, root, x, y, width, height, border, depth)
    = x/XGetGeometry(x-display, x-pixmap);
  ignore(success?, root, x, y, width, height, border);
  depth
end method image-depth;


/// GTK pixmap mediums

define sealed class <gtk-pixmap-medium>
    (<gtk-medium>, 
     <basic-pixmap-medium>)
end class <gtk-pixmap-medium>;

define sealed domain make (singleton(<gtk-pixmap-medium>));
define sealed domain initialize (<gtk-pixmap-medium>);

define sealed method make-pixmap-medium
    (_port :: <gtk-port>, sheet :: <sheet>, #key width, height)
 => (medium :: <gtk-pixmap-medium>)
  with-sheet-medium (medium = sheet)
    let pixmap = do-make-pixmap(_port, medium, width, height);
    let medium = make(<gtk-pixmap-medium>,
		      port: _port,
		      sheet: sheet,
		      pixmap: pixmap);
    medium-drawable(medium) := pixmap;
    medium
  end
end method make-pixmap-medium;


/// BitBlt

//---*** THESE ALL NEED TO GET A GC TO DO THE COPYING ON AND ESTABLISH THE COPYING GCONTEXT

define sealed method do-copy-area
    (from-medium :: <gtk-medium>, from-x :: <integer>, from-y :: <integer>,
     width :: <integer>, height :: <integer>,
     to-medium :: <gtk-medium>, to-x :: <integer>, to-y :: <integer>,
     #key function = $boole-1) => ()
  if (from-medium == to-medium)
    let sheet     = medium-sheet(from-medium);
    let transform = sheet-device-transform(sheet);
    let drawable  = medium-drawable(from-medium);
    with-device-coordinates (transform, from-x, from-y, to-x, to-y)
      with-device-distances (transform, width, height)
	gdk-window-copy-area(drawable, gcontext, to-x, to-y,
			     drawable, from-x, from-y, width, height)
      end
    end
  else
    let from-sheet     = medium-sheet(from-medium);
    let from-transform = sheet-device-transform(from-sheet);
    let from-drawable  = medium-drawable(from-medium);
    let to-sheet       = medium-sheet(to-medium);
    let to-transform   = sheet-device-transform(to-sheet);
    let to-drawable    = medium-drawable(to-medium);
    with-device-coordinates (from-transform, from-x, from-y)
      with-device-coordinates (to-transform, to-x, to-y)
	with-device-distances (from-transform, width, height)
	  gdk-window-copy-area(to-drawable, gcontext, to-x, to-y,
			       from-drawable, from-x, from-y, width, height)
	end
      end
    end
  end
end method do-copy-area;

define sealed method do-copy-area
    (from-medium :: <gtk-medium>, from-x :: <integer>, from-y :: <integer>,
     width :: <integer>, height :: <integer>,
     to-medium :: <gtk-pixmap-medium>, to-x :: <integer>, to-y :: <integer>,
     #key function = $boole-1) => ()
  let from-transform = sheet-device-transform(medium-sheet(from-medium));
  let from-drawable  = medium-drawable(from-medium);
  let to-drawable    = medium-drawable(to-medium);
  with-device-coordinates (from-transform, from-x, from-y)
    with-device-distances (from-transform, width, height)
      gdk-window-copy-area(to-drawable, gcontext, to-x, to-y,
			   from-drawable, from-x, from-y, width, height)
    end
  end
end method do-copy-area;

define sealed method do-copy-area
    (from-medium :: <gtk-medium>, from-x :: <integer>, from-y :: <integer>,
     width :: <integer>, height :: <integer>,
     pixmap :: <gtk-pixmap>, to-x :: <integer>, to-y :: <integer>,
     #key function = $boole-1) => ()
  let from-transform = sheet-device-transform(medium-sheet(from-medium));
  let from-drawable  = medium-drawable(from-medium);
  let to-drawable    = pixmap.%pixmap;
  with-device-coordinates (from-transform, from-x, from-y)
    with-device-distances (from-transform, width, height)
      gdk-window-copy-area(to-drawable, gcontext, to-x, to-y,
			   from-drawable, from-x, from-y, width, height)
    end
  end
end method do-copy-area;

define sealed method do-copy-area
    (from-medium :: <gtk-pixmap-medium>, from-x :: <integer>, from-y :: <integer>,
     width :: <integer>, height :: <integer>,
     to-medium :: <gtk-medium>, to-x :: <integer>, to-y :: <integer>,
     #key function = $boole-1) => ()
  let to-transform  = sheet-device-transform(medium-sheet(to-medium));
  let from-drawable = medium-drawable(from-medium);
  let to-drawable   = medium-drawable(to-medium);
  with-device-coordinates (to-transform, to-x, to-y)
    gdk-window-copy-area(to-drawable, gcontext, to-x, to-y,
			 from-drawable, from-x, from-y, width, height)
  end
end method do-copy-area;

define sealed method do-copy-area
    (pixmap :: <gtk-pixmap>, from-x :: <integer>, from-y :: <integer>,
     width :: <integer>, height :: <integer>,
     to-medium :: <gtk-medium>, to-x :: <integer>, to-y :: <integer>,
     #key function = $boole-1) => ()
  let to-transform  = sheet-device-transform(medium-sheet(to-medium));
  let from-drawable = pixmap.%pixmap;
  let to-drawable   = medium-drawable(to-medium);
  with-device-coordinates (to-transform, to-x, to-y)
    gdk-window-copy-area(to-drawable, gcontext, to-x, to-y,
			 from-drawable, from-x, from-y, width, height)
  end
end method do-copy-area;

define sealed method do-copy-area
    (from-medium :: <gtk-pixmap-medium>, from-x :: <integer>, from-y :: <integer>,
     width :: <integer>, height :: <integer>,
     to-medium :: <gtk-pixmap-medium>, to-x :: <integer>, to-y :: <integer>,
     #key function = $boole-1) => ()
  let from-drawable = medium-drawable(from-medium);
  let to-drawable   = medium-drawable(to-medium);
  gdk-window-copy-area(to-drawable, gcontext, to-x, to-y,
		       from-drawable, from-x, from-y, width, height)
end method do-copy-area;

define sealed method do-copy-area
    (from-pixmap :: <gtk-pixmap>, from-x :: <integer>, from-y :: <integer>,
     width :: <integer>, height :: <integer>,
     to-pixmap :: <gtk-pixmap>, to-x :: <integer>, to-y :: <integer>,
     #key function = $boole-1) => ()
  let from-drawable = from-pixmap.%pixmap;
  let to-drawable   = to-pixmap.%pixmap;
  gdk-window-copy-area(to-drawable, gcontext, to-x, to-y,
		       from-drawable, from-x, from-y, width, height)
end method do-copy-area;
*/
