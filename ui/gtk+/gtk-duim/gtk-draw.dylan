Module:       gtk-duim
Synopsis:     GTK drawing implementation
Author:       Andy Armstrong, Scott McKay
Copyright:    Original Code is Copyright (c) 1999-2000 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// GTK graphics

define constant $2pi-in-64ths-of-degree :: <integer> = 360 * 64;
define constant $supports-titled-ellipses = #f;

define sealed method draw-point
    (medium :: <gtk-medium>, x, y) => (record)
  let (drawable :: <GdkDrawable*>, gcontext :: <GdkGC*>)
    = update-drawing-state(medium);
  let transform = medium-device-transform(medium);
  with-device-coordinates (transform, x, y)
    let thickness = pen-width(medium-pen(medium));
    if (thickness < 2)
      gdk-draw-point(drawable, gcontext, x, y)
    else 
      let thickness/2 = truncate/(thickness, 2);
      gdk-draw-arc(drawable, gcontext, $true,
		   x - thickness/2, y - thickness/2, thickness, thickness,
		   0, $2pi-in-64ths-of-degree)
    end
  end;
  #f
end method draw-point;

define sealed method draw-points
    (medium :: <gtk-medium>, coord-seq :: <coordinate-sequence>) => (record)
  let (drawable :: <GdkDrawable*>, gcontext :: <GdkGC*>)
    = update-drawing-state(medium);
  let transform = medium-device-transform(medium);
  let thickness = pen-width(medium-pen(medium));
  if (thickness < 2)
    do-coordinates
      (method (x, y)
	 with-device-coordinates (transform, x, y)
	   //---*** Use gdk-draw-points
	   gdk-draw-point(drawable, gcontext, x, y)
	 end
       end,
       coord-seq)
  else
    let thickness/2 = truncate/(thickness, 2);
    do-coordinates
      (method (x, y)
	 with-device-coordinates (transform, x, y)
	   gdk-draw-arc(drawable, gcontext, $true,
			x - thickness/2, y - thickness/2, thickness, thickness,
			0, $2pi-in-64ths-of-degree)
	 end
       end,
       coord-seq)
  end;
  #f
end method draw-points;


/// Pixel graphics

//---*** Do an efficient version of this
define sealed method set-pixel
    (medium :: <gtk-medium>, color :: <rgb-color>, x, y) => (record)
  with-drawing-options (medium, brush: color)
    draw-point(medium, x, y)
  end;
  #f
end method set-pixel;

//---*** Do an efficient version of this
define sealed method set-pixels
    (medium :: <gtk-medium>, color :: <rgb-color>, 
     coord-seq :: <coordinate-sequence>)
 => (record)
  with-drawing-options (medium, brush: color)
    draw-points(medium, coord-seq)
  end;
  #f
end method set-pixels;


define sealed method draw-line
    (medium :: <gtk-medium>, x1, y1, x2, y2) => (record)
  let (drawable :: <GdkDrawable*>, gcontext :: <GdkGC*>)
    = update-drawing-state(medium, pen: medium-pen(medium));
  let transform = medium-device-transform(medium);
  with-device-coordinates (transform, x1, y1, x2, y2)
    gdk-draw-line(drawable, gcontext, x1, y1, x2, y2)
  end;
  #f
end method draw-line;

define sealed method draw-lines
    (medium :: <gtk-medium>, coord-seq :: <coordinate-sequence>) => (record)
  let (drawable :: <GdkDrawable*>, gcontext :: <GdkGC*>)
    = update-drawing-state(medium, pen: medium-pen(medium));
  let transform = medium-device-transform(medium);
  //---*** Use gdk-draw-segments
  do-endpoint-coordinates
    (method (x1, y1, x2, y2)
       with-device-coordinates (transform, x1, y1, x2, y2)
	 gdk-draw-line(drawable, gcontext, x1, y1, x2, y2)
       end
     end,
     coord-seq);
  #f
end method draw-lines;

define sealed method draw-rectangle
    (medium :: <gtk-medium>, x1, y1, x2, y2,
     #key filled? = #t) => (record)
  let transform = medium-device-transform(medium);
  if (~rectilinear-transform?(transform))
    with-stack-vector (coords = x1, y1, x2, y1, x2, y2, x1, y2)
      draw-polygon(medium, coords, filled?: filled?, closed?: #t)
    end
  else
    let (drawable :: <GdkDrawable*>, gcontext :: <GdkGC*>)
      = update-drawing-state(medium, pen: ~filled? & medium-pen(medium));
    //---*** Might need to use 'gdk-gc-set-ts-origin' to set tile/stipple origin to x1/y1
    with-device-coordinates (transform, x1, y1, x2, y2)
      gdk-draw-rectangle(drawable, gcontext,
			 if (filled?) $true else $false end,
			 x1, y1, x2 - x1, y2 - y1)
    end
  end;
  #f
end method draw-rectangle;

define sealed method draw-rectangles
    (medium :: <gtk-medium>, coord-seq :: <coordinate-sequence>,
     #key filled? = #t) => (record)
  let transform = medium-device-transform(medium);
  if (~rectilinear-transform?(transform))
    draw-transformed-rectangles(medium, coord-seq, filled?: filled?)
  else
    let (drawable :: <GdkDrawable*>, gcontext :: <GdkGC*>)
      = update-drawing-state(medium, pen: ~filled? & medium-pen(medium));
    let transform = medium-device-transform(medium);
    do-endpoint-coordinates
      (method (x1, y1, x2, y2)
	 with-device-coordinates (transform, x1, y1, x2, y2)
	   gdk-draw-rectangle(drawable, gcontext, 
			      if (filled?) $true else $false end,
			      x1, y1, x2 - x1, y2 - y1)
	 end
       end,
       coord-seq);
  end;
  #f
end method draw-rectangles;

define sealed method draw-transformed-rectangles
    (medium :: <gtk-medium>, coord-seq :: <coordinate-sequence>,
     #rest keys, #key filled? = #t) => (record)
  dynamic-extent(keys);
  ignore(filled?);
  let ncoords :: <integer> = size(coord-seq);
  assert(zero?(modulo(ncoords, 4)),
	 "The coordinate sequence has the wrong number of elements");
  local method draw-one (x1, y1, x2, y2) => ()
	  with-stack-vector (coords = x1, y1, x2, y1, x2, y2, x1, y2)
	    apply(draw-polygon, medium, coords, closed?: #t, keys)
	  end
        end method;
  dynamic-extent(draw-one);
  without-bounds-checks
    for (i :: <integer> = 0 then i + 4, until: i = ncoords)
      draw-one(coord-seq[i + 0], coord-seq[i + 1],
	       coord-seq[i + 2], coord-seq[i + 3])
    end
  end;
  #f
end method draw-transformed-rectangles;

define sealed method draw-rounded-rectangle
    (medium :: <gtk-medium>, x1, y1, x2, y2,
     #key filled? = #t, radius) => (record)
  let (drawable :: <GdkDrawable*>, gcontext :: <GdkGC*>)
    = update-drawing-state(medium, pen: ~filled? & medium-pen(medium));
  let transform = medium-device-transform(medium);
  with-device-coordinates (transform, x1, y1, x2, y2)
    unless (radius)
      let width  = x2 - x1;
      let height = y2 - y1;
      radius := max(truncate/(min(width, height), 3), 2)
    end;
    //---*** DO THIS FOR REAL
    draw-rectangle(medium, x1, y1, x2, y2, filled?: filled?)
  end;
  #f
end method draw-rounded-rectangle;

define sealed method draw-polygon
    (medium :: <gtk-medium>, coord-seq :: <coordinate-sequence>,
     #key closed? = #t, filled? = #t) => (record)
  let (drawable :: <GdkDrawable*>, gcontext :: <GdkGC*>)
    = update-drawing-state(medium, pen: ~filled? & medium-pen(medium));
  let transform = medium-device-transform(medium);
  let scoords :: <integer> = size(coord-seq);
  let ncoords :: <integer> = size(coord-seq);
  let npoints :: <integer> = floor/(ncoords, 2) + if (closed? & ~filled?) 1 else 0 end;
  with-stack-structure (points :: <GdkPoint*>, element-count: npoints)
    //--- Can't use without-bounds-checks until it works on FFI 'element-setter' calls
    // without-bounds-checks
      for (i :: <integer> from 0 below ncoords by 2,
	   j :: <integer> from 0)
	let x = coord-seq[i + 0];
	let y = coord-seq[i + 1];
	with-device-coordinates (transform, x, y)
	  //---*** This doesn't work in the FFI!
	  // let point = points[j];
	  let point = pointer-value-address(points, index: j);
	  point.x-value := x;
	  point.y-value := y;
	end;
      finally
	when (closed? & ~filled?)
	  //---*** This doesn't work in the FFI!
	  // let point = points[0];
	  let first-point = pointer-value-address(points, index: 0);
	  let last-point  = pointer-value-address(points, index: npoints - 1);
	  last-point.x-value := first-point.x-value;
	  last-point.y-value := first-point.y-value;
	end
      end;
    // end;
    if (filled?)
      gdk-draw-polygon(drawable, gcontext, 
                       $true,
                       points, npoints)
    else
// ---*** gdk-draw-lines doesn't work on Win32 for some reason so use kludge instead.
// ---*** Kludge draws each line in turn after frigging the gcontext so that
// ---*** the line ends don't go over the start of the next line.
// ---*** Unfortunately, drawing to a copied gcontext seemed to cause crashes
// ---*** (I tried both Dylan stack allocated and gdk-gc-new gcontexts)
// ---*** so the code has to frig a potentially shared gcontext (= not good).
//      gdk-draw-lines(drawable, gcontext, points, npoints)
      with-stack-structure (gcontext-values :: <GdkGCValues*>)
        let old-cap-style = #f;
        block ()
          gdk-gc-get-values(gcontext, gcontext-values);
          old-cap-style := gcontext-values.cap-style-value;
          gdk-gc-set-line-attributes(gcontext,
                                     gcontext-values.line-width-value,
                                     gcontext-values.line-style-value,
                                     $gdk-cap-butt, // NB short lines for better joins
                                     gcontext-values.join-style-value);
          let previous-p = pointer-value-address(points, index: 0);
          for (i from 1 below npoints)
            let previous-x :: <integer> = previous-p.x-value;
            let previous-y :: <integer> = previous-p.y-value;
            let p = pointer-value-address(points, index: i);
            let x = p.x-value;
            let y = p.y-value;
            gdk-draw-line(drawable, gcontext, previous-x, previous-y, x, y);
            previous-p := p;
          end;
        cleanup
          if (old-cap-style)
            gdk-gc-set-line-attributes(gcontext,
                                       gcontext-values.line-width-value,
                                       gcontext-values.line-style-value,
                                       old-cap-style,
                                       gcontext-values.join-style-value);
          end;
        end block;
      end with-stack-structure;
    end
  end;
  #f
end method draw-polygon;

define sealed method draw-ellipse
    (medium :: <gtk-medium>, center-x, center-y,
     radius-1-dx, radius-1-dy, radius-2-dx, radius-2-dy,
     #key start-angle, end-angle, filled? = #t) => (record)
  let (drawable :: <GdkDrawable*>, gcontext :: <GdkGC*>)
    = update-drawing-state(medium, pen: ~filled? & medium-pen(medium));
  let transform = medium-device-transform(medium);
  with-device-coordinates (transform, center-x, center-y)
    with-device-distances (transform, radius-1-dx, radius-1-dy, radius-2-dx, radius-2-dy)
      let (angle-2, x-radius, y-radius, angle-1)
	= singular-value-decomposition-2x2(radius-1-dx, radius-2-dx, radius-1-dy, radius-2-dy);
      if (~$supports-titled-ellipses
	  | x-radius = abs(y-radius)		// a circle - rotations are irrelevant
	  | zero?(angle-1))			// axis-aligned ellipse
	let (angle, delta-angle)
	  = if (start-angle & end-angle)
	      let start-angle = modulo(start-angle, $2pi);
	      let end-angle   = modulo(end-angle, $2pi);
	      when (end-angle < start-angle)
		end-angle := end-angle + $2pi
	      end;
	      values(round($2pi-in-64ths-of-degree * (($2pi - start-angle) / $2pi)),
		     round($2pi-in-64ths-of-degree * ((start-angle - end-angle) / $2pi)))
	    else
	      values(0, $2pi-in-64ths-of-degree)
	    end;
	x-radius := abs(x-radius);
	y-radius := abs(y-radius);
	gdk-draw-arc(drawable, gcontext, 
		     if (filled?) $true else $false end,
		     center-x - x-radius, center-y - y-radius,
		     x-radius * 2, y-radius * 2, angle, delta-angle)
      else
	ignoring("draw-ellipse for tilted ellipses");
	#f
      end;
      // SelectObject(hDC, old-object)
    end
  end;
  #f
end method draw-ellipse;

// GTK bitmaps and icons are handled separately
define sealed method draw-image
    (medium :: <gtk-medium>, image :: <image>, x, y) => (record)
  let (drawable :: <GdkDrawable*>, gcontext :: <GdkGC*>)
    = update-drawing-state(medium);
  let transform = medium-device-transform(medium);
  with-device-coordinates (transform, x, y)
    let width  = image-width(image);
    let height = image-height(image);
    ignoring("draw-image");
    //---*** DRAW THE IMAGE, BUT FOR NOW DRAW A RECTANGLE
    // let (pixel, fill-style, operation, pattern)
    //   = convert-ink-to-DC-components(medium, hDC, image);
    // let old-object :: <HANDLE> = SelectObject(hDC, $null-hpen);
    // Rectangle(hDC, x, y, x + width, y + height);
    // SelectObject(hDC, old-object)
  end;
  #f
end method draw-image;


/// Path graphics

define sealed method start-path
    (medium :: <gtk-medium>) => (record)
  ignoring("GTK does not support path-based graphics")
end method start-path;

define sealed method end-path
    (medium :: <gtk-medium>) => (record)
  ignoring("GTK does not support path-based graphics")
end method end-path;

define sealed method abort-path
    (medium :: <gtk-medium>) => (record)
  ignoring("GTK does not support path-based graphics")
end method abort-path;

define sealed method close-path
    (medium :: <gtk-medium>) => (record)
  ignoring("GTK does not support path-based graphics")
end method close-path;

define sealed method stroke-path
    (medium :: <gtk-medium>, #key filled?) => (record)
  ignoring("GTK does not support path-based graphics")
end method stroke-path;

define sealed method fill-path
    (medium :: <gtk-medium>) => (record)
  ignoring("GTK does not support path-based graphics")
end method fill-path;

define sealed method clip-from-path
    (medium :: <gtk-medium>, #key function = $boole-and) => (record)
  ignoring("GTK does not support path-based graphics")
end method clip-from-path;

define sealed method save-clipping-region
    (medium :: <gtk-medium>) => (record)
  ignoring("GTK does not support path-based graphics")
end method save-clipping-region;

define sealed method restore-clipping-region
    (medium :: <gtk-medium>) => (record)
  ignoring("GTK does not support path-based graphics")
end method restore-clipping-region;

define sealed method move-to
    (medium :: <gtk-medium>, x, y) => (record)
  ignoring("GTK does not support path-based graphics")
end method move-to;

define sealed method line-to
    (medium :: <gtk-medium>, x, y) => (record)
  ignoring("GTK does not support path-based graphics")
end method line-to;

define sealed method arc-to
    (medium :: <gtk-medium>, center-x, center-y,
     radius-1-dx, radius-1-dy, radius-2-dx, radius-2-dy,
     #key start-angle, end-angle) => (record)
  ignoring("GTK does not support path-based graphics")
end method arc-to;

define sealed method curve-to
    (medium :: <gtk-medium>, x1, y1, x2, y2, x3, y3) => (record)
  ignoring("GTK does not support path-based graphics")
end method curve-to;


/// 'draw-pixmap', etc

define sealed method draw-pixmap
    (medium :: <gtk-medium>, pixmap :: <pixmap>, x, y,
     #key function = $boole-1) => (record)
  do-copy-area(pixmap, 0, 0, image-width(pixmap), image-height(pixmap),
	       medium, x, y)
end method draw-pixmap;

define sealed method clear-box
    (medium :: <gtk-medium>, left, top, right, bottom) => ()
  let (drawable :: <GdkDrawable*>, gcontext :: <GdkGC*>)
    = get-gcontext(medium);
  let sheet = medium-sheet(medium);
  let transform = sheet-device-transform(sheet);
  with-device-coordinates (transform, left, top, right, bottom)
    gdk-window-clear-area(drawable, left, top, right - left, bottom - top)
  end
end method clear-box;


/// Text drawing

define sealed method draw-text
    (medium :: <gtk-medium>, character :: <character>, x, y,
     #rest keys,
     #key start: _start, end: _end,
          align-x = #"left", align-y = #"baseline", do-tabs? = #f,
          towards-x, towards-y, transform-glyphs?) => (record)
  ignore(_start, _end, align-x, align-y, do-tabs?,
          towards-x, towards-y, transform-glyphs?);
  let string = make(<string>, size: 1, fill: character);
  apply(draw-text, medium, string, x, y, keys)
end method draw-text;

//---*** What do we do about Unicode strings?
define sealed method draw-text
    (medium :: <gtk-medium>, string :: <string>, x, y,
     #key start: _start :: <integer> = 0, end: _end :: <integer> = size(string),
          align-x = #"left", align-y = #"baseline", do-tabs? = #f,
          towards-x, towards-y, transform-glyphs?) => (record)
  let text-style :: <text-style> = medium-merged-text-style(medium);
  let font :: <gtk-font> = text-style-mapping(port(medium), text-style);
  let length :: <integer> = size(string);
  let (drawable :: <GdkDrawable*>, gcontext :: <GdkGC*>)
    = update-drawing-state(medium, font: font);
  let transform = medium-device-transform(medium);
  with-device-coordinates (transform, x, y)
    when (towards-x & towards-y)
      convert-to-device-coordinates!(transform, towards-x, towards-y)
    end;
    //---*** What about x and y alignment?
    if (do-tabs?)
      ignoring("draw-text with do-tabs?: #t");
      /*---*** Not yet implemented!
      let tab-width  = text-size(medium, " ") * 8;
      let tab-origin = if (do-tabs? == #t) x else do-tabs? end;
      let x = 0;
      let s = _start;
      block (break)
	while (#t)
	  let e = position(string, '\t', start: s, end: _end);
	  //---*** It would be great if 'with-c-string' took start & end!
	  let substring = copy-sequence(string, start: s, end: e);
	  with-c-string (c-string = substring)
	    gdk-draw-text(drawable, font, gcontext,
			  tab-origin + x, y, string, e - s)
	  end;
	  if (e = _end)
	    break()
	  else
	    let (x1, y1, x2, y2) = GET-STRING-EXTENT(drawable, string, font, s, e);
	    ignore(x1, y1, y2);
	    x := floor/(x + x2 + tab-width, tab-width) * tab-width;
	    s := min(e + 1, _end)
	  end
	end
      end
      */
    else
      ignoring("draw-text");
      /*---*** Fonts not working yet!
      //---*** It would be great if 'with-c-string' took start & end!
      let substring
	= if (_start = 0 & _end = length) string
	  else copy-sequence(string, start: _start, end: _end) end;
      with-c-string (c-string = substring)
	gdk-draw-string(drawable, font, gcontext,
			x, y, c-string)
      end
      */
    end
  end
end method draw-text;
