module: command-line

define open class <nnv-shell-mode> (<shell-mode>)
end class <nnv-shell-mode>;

define method mode-name
    (mode :: <nnv-shell-mode>) => (name :: <byte-string>)
  "NNV shell"
end method mode-name;

define method shell-input-complete?
    (mode :: <nnv-shell-mode>,
     buffer :: <basic-shell-buffer>, section :: <basic-shell-section>)
 => (complete? :: <boolean>, message :: false-or(<string>))
  //--- This is where DylanWorks mode decides if there's a complete form
  values(#t, #f)
end method shell-input-complete?;

define method do-process-shell-input
    (mode :: <nnv-shell-mode>,
     buffer :: <basic-shell-buffer>, section :: <basic-shell-section>,
     #key window = frame-window(*editor-frame*)) => ()
  let text = as(<string>, section);
  let bp = line-end(section-end-line(section));
  queue-redisplay(window, $display-text);
  shell-execute-code(window, text, bp);
  move-point!(bp, window: window)
end method do-process-shell-input;

define method shell-execute-code
    (pane :: <nnv-shell-gadget>, command-line :: <string>, bp :: <basic-bp>) => ()
  let server = pane.command-line-server;
//  let debugger? = release-internal?();
  let stream = server.server-output-stream;
  let buffer = pane.window-buffer;
  stream-position(stream) := buffer.interval-end-bp;
  block ()
    let handler (<serious-condition>)
      = method (condition :: <serious-condition>, next-handler :: <function>)
	  if (#t /* debugger? */)
	    next-handler()
	  else
	    display-condition(server.server-context, condition);
	    abort();
	  end
	end;
    let exit? = execute-command-line(server, command-line);
    // exit? & exit-frame(sheet-frame(pane))
  exception (<abort>)
    #f
  end
end method shell-execute-code;


define variable *nnv-shell-count* :: <integer> = 0;

define method make-shell
    (#key name, anonymous? = #f,
	  buffer-class  = <simple-shell-buffer>,
	  major-mode    = find-mode(<nnv-shell-mode>),
	  section-class = <simple-shell-section>,
	  editor        = $nnv-editor)
 => (buffer :: <basic-shell-buffer>)
  unless (name)
    inc!(*nnv-shell-count*);
    name := format-to-string("NNV shell %d", *nnv-shell-count*)
  end;
  make-empty-buffer(buffer-class,
                    name:       name,
                    major-mode: major-mode,
                    anonymous?: anonymous?,
                    section-class: section-class,
                    editor: editor);
end method make-shell;

define class <nnv-editor> (<basic-editor>) end;
define constant $nnv-editor :: <nnv-editor> = make(<nnv-editor>);
define class <nnv-shell-gadget> (<deuce-gadget>, <deuce-pane>)
  slot command-line-server :: false-or(<command-line-server>);
  keyword editor: = $nnv-editor;
end;

define function make-nnv-shell-pane
    (#rest initargs,
     #key class = <nnv-shell-gadget>,
          frame, buffer, #all-keys)
 => (window :: <nnv-shell-gadget>)
  let window = apply(make, class, initargs);
  dynamic-bind (*editor-frame* = window)
    let buffer = buffer | make-shell();
    let stream
      = make(<interval-stream>,
             interval: buffer,
             direction: #"output");
    let server
      = make-command-line-server
        (input-stream: stream,	// ignored, so this is safe!
        output-stream: stream);
    window.command-line-server := server;
    dynamic-bind (*buffer* = buffer)
      select-buffer(window, buffer)
    end;
  end;
  window
end function;


define class <nnv-context> (<server-context>)
  keyword banner: = "Network Night Vision";
  slot nnv-context;
end;

define method make-command-line-server
    (#key banner :: false-or(<string>) = #f,
          input-stream :: <stream>,
          output-stream :: <stream>,
          echo-input? :: <boolean> = #f,
          profile-commands? :: <boolean> = #f)
 => (server :: <command-line-server>)
  let context = make(<nnv-context>, banner: banner);
  make(<command-line-server>,
       context:           context,
       input-stream:      input-stream,
       output-stream:     output-stream,
       echo-input?:       echo-input?,
       profile-commands?: profile-commands?)
end method make-command-line-server;





 










