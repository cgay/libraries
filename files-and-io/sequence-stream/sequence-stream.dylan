module: sequence-stream
author: Dustin Voss


define open primary class <sequence-stream> (<basic-stream>, <positionable-stream>)

   // Storage
   slot stream-storage :: <vector>;
   slot stream-start :: <integer>;
   slot stream-end :: <integer>;
   constant slot stream-element-type :: <type>, init-keyword: element-type:;
   constant slot stream-fill :: <object>, init-keyword: fill:;

   // State
   slot stream-open? :: <boolean> = #t;
   slot stream-position :: <integer> = 0;
   slot stream-unread-from :: false-or(<integer>) = #f;
   constant slot stream-direction :: one-of(#"input", #"output", #"input-output"),
         init-keyword: direction:;
   
   // Keywords
   keyword contents: = make(<vector>);
   keyword start:;
   keyword end:;
   keyword element-type: = <object>;
   keyword fill: = #f;
   keyword direction: = #"input";
   keyword outer-stream:;
end class;


define open primary class <string-stream> (<sequence-stream>)
   keyword contents: = make(<string>), type: <string>;
   keyword element-type: = <character>, type: <type>;
   keyword fill: = ' ', type: <character>;
end class;


define sealed primary class <byte-string-stream> (<string-stream>)
   keyword contents: = make(<byte-string>), type: <byte-string>;
   keyword element-type: = <byte-character>, type: <type>;
   keyword fill: = as(<byte-character>, ' '), type: <byte-character>;
end class;


define method make
   (class == <sequence-stream>, #rest keys, #key contents, #all-keys)
=> (inst :: <sequence-stream>)
   select (contents by instance?)
      <string> => apply(make, <string-stream>, keys);
      otherwise => next-method();
   end select
end method;


define method make
   (class == <string-stream>, #rest keys, #key contents, #all-keys)
=> (inst :: <sequence-stream>)
   select (contents by instance?)
      <byte-string> => apply(make, <byte-string-stream>, keys);
      otherwise => next-method();
   end select
end method;


define method initialize
   (stream :: <sequence-stream>, #key
    direction :: <symbol>, contents :: <sequence>,
    start: start-pos :: <integer> = 0,
    end: end-pos :: <integer> = contents.size)
=> ()
   next-method();
   stream.stream-storage :=
         if (direction = #"input")
            make-storage(stream, <vector>, contents)
         else
            check-fill-type(stream);
            make-storage(stream, <stretchy-vector>, contents)
         end if;
   stream.stream-start := start-pos;
   stream.stream-end := end-pos;
end method;


define sealed domain make (singleton(<byte-string-stream>));
define sealed domain initialize (<byte-string-stream>);


//
// Client methods
//


define method ext-stream-open? (stream :: <sequence-stream>)
=> (open? :: <boolean>)
   stream.stream-open?
end method;


define method ext-close (stream :: <sequence-stream>, #key, #all-keys) => ()
   stream.stream-open? := #f;
   stream.stream-storage := #[];
end method;


define method ext-stream-at-end? (stream :: <sequence-stream>)
=> (at-end? :: <boolean>)
   check-stream-open(stream);
   stream.stream-at-end?
end method;


define method ext-stream-contents
   (stream :: <sequence-stream>, #key clear-contents? :: <boolean> = #t)
=> (contents :: <sequence>)
   check-stream-open(stream);
   let copy = copy-sequence(stream.stream-storage,
                            start: stream.stream-start,
                            end: stream.stream-end);
   when (clear-contents? &
         stream.stream-direction ~= #"input")
      reset-stream(stream);
   end when;
   copy
end method;


define method ext-stream-contents-as
   (type :: subclass(<sequence>), stream :: <sequence-stream>, #rest keys,
    #key clear-contents?)
=> (contents :: <sequence>)
   as(type, apply(ext-stream-contents, stream.outer-stream, keys))
end method;


define method ext-stream-element-type (stream :: <sequence-stream>)
=> (type :: <type>)
   check-stream-open(stream);
   stream.stream-element-type
end method;


//
// Client position methods
//


define method ext-stream-size (stream :: <sequence-stream>)
=> (size :: <integer>)
   check-stream-open(stream);
   stream.stream-size
end method;


define inline method ext-stream-limit (stream :: <sequence-stream>)
=> (limit :: <integer>)
   stream.outer-stream.ext-stream-size
end method;


define method ext-adjust-stream-position
   (stream :: <sequence-stream>, delta :: <integer>, #rest keys, #key from)
=> (new-position :: <integer>)
   check-stream-open(stream);
   apply(adjust-stream-position, stream, delta, keys)
end method;


define method ext-stream-position (stream :: <sequence-stream>)
=> (position :: <integer>)
   check-stream-open(stream);
   stream.stream-position
end method;


define method ext-stream-position-setter
   (position :: <integer>, stream :: <sequence-stream>)
=> (position :: <integer>)
   check-stream-open(stream);
   
   if (position < 0 | position > stream.stream-size)
      position-range-error(stream);
   else
      adjust-stream-position(stream, position, from: #"start");
   end if;
end method;


define method ext-stream-position-setter
   (position == #"start", stream :: <sequence-stream>)
=> (position :: <integer>)
   check-stream-open(stream);
   adjust-stream-position(stream, 0, from: #"start");
end method;


define method ext-stream-position-setter
   (position == #"end", stream :: <sequence-stream>)
=> (position :: <integer>)
   check-stream-open(stream);
   adjust-stream-position(stream, 0, from: #"end");
end method;


//
// Internal methods
//


define method adjust-stream-position
   (stream :: <sequence-stream>, delta :: <integer>,
    #key from :: one-of(#"current", #"start", #"end") = #"current")
=> (new-position :: <integer>)
   // Compute position.
   let base-pos :: <integer> = 
         select (from)
            #"current" => stream.stream-position;
            #"start" => 0;
            #"end" => stream.stream-size;
         end select;
   let new-pos = base-pos + delta;

   // Grow stream if necessary.
   if (new-pos > stream.stream-size)
      if (stream.stream-direction = #"input")
         cannot-grow-error(stream);
      else
         let grow-data = make(<vector>, size: new-pos - stream.stream-size,
                              fill: stream.stream-fill);
         replace-stream-elements(stream, grow-data);
      end if;
   end if;
   
   // Set position and return.
   stream.stream-unread-from := #f;
   stream.stream-position := max(0, new-pos);
end method;


define inline method stream-size (stream :: <sequence-stream>)
=> (size :: <integer>)
   stream.stream-end - stream.stream-start
end method;


define inline method stream-at-end? (stream :: <sequence-stream>)
=> (at-end? :: <boolean>)
   stream.stream-position >= stream.stream-size
end method;


define method peek
   (stream :: <sequence-stream>, #key on-end-of-stream = unsupplied())
=> (elem-or-eof :: <object>)
   case
      ~stream.stream-at-end? =>
         stream.stream-storage[stream.stream-position + stream.stream-start];
      on-end-of-stream.supplied? =>
         on-end-of-stream;
      otherwise =>
         eos-error(stream);
   end case
end method;


define method read-element
   (stream :: <sequence-stream>, #key on-end-of-stream = unsupplied())
=> (elem-or-eof :: <object>)
   case
      ~stream.stream-at-end? =>
         let pos = stream.stream-position;
         let elem = stream.stream-storage[pos + stream.stream-start];
         adjust-stream-position(stream, +1);
         stream.stream-unread-from := stream.stream-position;
         elem;
      on-end-of-stream.supplied? =>
         on-end-of-stream;
      otherwise =>
         eos-error(stream);
   end case
end method;


define method read-through
   (stream :: <sequence-stream>, to-elem :: <object>,
    #key on-end-of-stream = unsupplied(), test = \==, keep-term :: <boolean> = #t)
=> (elements-or-eof :: <object>, found? :: <boolean>)

   if (stream.stream-at-end?)
      case
         on-end-of-stream.supplied? => values(on-end-of-stream, #f);
         otherwise => eos-error(stream);
      end case
   else
      let start-idx = stream.stream-position + stream.stream-start;
      let found-idx = #f;
      let end-idx =
            for (idx from start-idx below stream.stream-end, until: found-idx)
               if (test(stream.stream-storage[idx], to-elem))
                  found-idx := idx
               end if
            finally
               idx
            end for;
      
      // Compute new stream position.
      stream.stream-position := end-idx - stream.stream-start;
      
      // Copy and return read elements.
      if (found-idx & ~keep-term)
         end-idx := max(start-idx, end-idx - 1)
      end if;
      values(copy-sequence(stream.stream-storage, start: start-idx, end: end-idx),
             found-idx.true?)
   end if;
end method;


define method replace-stream-elements
   (stream :: <sequence-stream>, insert-seq :: <sequence>,
    #key start: start-idx :: <integer> = stream.stream-end,
         end: end-idx :: <integer> = stream.stream-end)
=> ()
   let start-idx = min(start-idx, stream.stream-end);
   let end-idx = min(end-idx, stream.stream-end);
   
   // Trim down size of sequence to make any later resizing faster.

   when (stream.stream-end < stream.stream-storage.size)
      stream.stream-storage := 
            replace-subsequence!(stream.stream-storage, #[], start: stream.stream-end);
   end when;

   when (stream.stream-start > 0)
      stream.stream-storage := 
            replace-subsequence!(stream.stream-storage, #[], end: stream.stream-end);
      let adjustment = stream.stream-start;
      stream.stream-position := stream.stream-position - adjustment;
      stream.stream-end := stream.stream-end - adjustment;
      start-idx := start-idx - adjustment;
      end-idx := end-idx - adjustment;
   end when;
   
   // Replace and resize if necessary.

   stream.stream-storage :=
         replace-subsequence!(stream.stream-storage, insert-seq,
                              start: start-idx, end: end-idx);
   stream.stream-end := stream.stream-storage.size;
end method;


define method make-storage
   (stream :: <sequence-stream>, class :: <class>, contents :: <sequence>)
=> (storage :: <vector>)
   let storage = make(class, size: contents.size, fill: stream.stream-fill);
   map-into(storage, identity, contents)
end method;


define method reset-stream (stream :: <sequence-stream>) => ()
   replace-stream-elements(stream, #[], start: 0, end: stream.stream-size);
   adjust-stream-position(stream, 0, from: #"start");
end method;


//
// Checks and errors
//


define method check-stream-open (stream :: <sequence-stream>) => ()
   unless (stream.stream-open?)
      error(make(<stream-closed-error>, stream: stream))
   end unless;
end method;


define method check-stream-readable (stream :: <sequence-stream>) => ()
   unless (stream.stream-direction = #"input" |
           stream.stream-direction = #"input-output")
      error(make(<stream-not-readable>, stream: stream))
   end unless;
end method;


define method check-stream-writable (stream :: <sequence-stream>) => ()
   unless (stream.stream-direction = #"output" |
           stream.stream-direction = #"input-output")
      error(make(<stream-not-writable>, stream: stream))
   end unless;
end method;


define method check-element-type (stream :: <sequence-stream>, elem :: <object>)
=> ()
   unless (instance?(elem, stream.stream-element-type))
      error("Stream does not accept element type %=", elem.object-class)
   end unless;
end method;


define method check-fill-type (stream :: <sequence-stream>)
=> ()
   unless (instance?(stream.stream-fill, stream.stream-element-type))
      error("Stream filler %= is not correct element type", stream.stream-fill)
   end unless;
end method;


define inline function eos-error (stream :: <sequence-stream>) => ()
   error(make(<end-of-stream-error>, stream: stream))
end function;


define inline function incomplete-error
   (stream :: <sequence-stream>, partial :: <sequence>)
=> ()
   error(make(<incomplete-read-error>, stream: stream, count: partial.size,
              sequence: partial));
end function;


define inline function cannot-grow-error (stream :: <sequence-stream>) => ()
   error("Cannot grow input stream");
end function;


define inline function position-range-error (stream :: <sequence-stream>) => ()
   error("Stream position past end of stream");
end function;


define inline function cannot-unread-error (stream :: <sequence-stream>) => ()
   error("Cannot unread element")
end function;

