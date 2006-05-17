module: xmpp
synopsis: 
author: 
copyright:

define class <xmpp-client> (<object>)
  slot jid :: <jid>,
    required-init-keyword: jid:;
  slot socket :: <tcp-socket>,
    init-keyword: socket:;
  slot state :: one-of(#"disconnected", #"authenticating", #"connected");
  virtual slot password;
end class <xmpp-client>;

define method connect (client :: <xmpp-client>, #key port :: <integer> = 5222)
  start-sockets();
  client.socket := make(<tcp-socket>, host: client.jid.domain, port: port);
  client.state := #"connected";
  format-out("TEST: %s\n", real-name("foo:bar"));
  make(<thread>, priority: $background-priority, function: curry(listen, client));
end method connect;

define method listen (client :: <xmpp-client>)

block ()
//  let parser-depth = 0;
  let stream-running? = #f;
  let parsing-tag? = #f;
  let parser-buffer = "";
  let current-element = #f;
  
  // keep watching that start tags match end tags
  let tag-queue = make(<deque>);
  
  while (~ stream-at-end?(client.socket))
    let received = read-element(client.socket);

    block(read-next)
        if (parsing-tag? = #f)
          if (received = '<')
            parsing-tag? := #t;
            parser-buffer := add!(parser-buffer, received);
            read-next();
          elseif (size(tag-queue) = 0 & received ~= '\n')
            //!!! error: not well-formed xml: chars not contained in root element
            format-out("!!! error: not well-formed xml: chars not contained in root element\n");
          elseif (size(tag-queue) > 0 & current-element & received ~= '\n')
            //!!! collect chars into text of current-element!!!
            current-element.text := add!(current-element.text, received); 
          end if;
        else
          if (received = '>')
            // seems as we got an element
            parser-buffer := add!(parser-buffer, received);
            format-out(">>> %s\n", parser-buffer);

            // could be the start tag of an element
            let (index, start-tag, attributes, opened-element?) = scan-start-tag(parser-buffer);
            if (start-tag & opened-element?)
              format-out("!!! (start)  %s\n", start-tag);
              // should be closed later
              push-last(tag-queue, start-tag);
              format-out("!!! now at depth: %d\n", size(tag-queue));
              // dispatch  
              let element = make(<element>, name: as(<string>, start-tag));
              for (attribute in attributes)
                add-attribute(element, attribute);
              end for;
              if (current-element)
                add-element(current-element, element);
              end if;
              current-element := element;
              format-out("!!! (current element) %=\n", current-element);
              if (current-element.name = #"stream:stream" & size(tag-queue) = 1 & ~ stream-running?)
                stream-running? := #t;
                //!!! do something
                current-element := #f;
              end if;
              // cleanup
              parser-buffer := "";
              parsing-tag? := #f;
              read-next();
            elseif (start-tag & ~ opened-element?)
              format-out("!!! (empty)  %s\n", start-tag);
              // dispatch
              let element = make(<element>, name: as(<string>, start-tag));
              for (attribute in attributes)
                add-attribute(element, attribute);
              end for;
              if (current-element)
                add-element(current-element, element);
              end if;
              // empty stanza
              if (size(tag-queue) = 1)
                format-out("!!! (X) %=\n", element);
              end if;
              // cleanup
              parser-buffer := "";
              parsing-tag? := #f;
              read-next();
            end if;
            
            // could be the end tag of an element
            let (index, end-tag, opened-element?) = scan-end-tag(parser-buffer);
            if (end-tag)
              format-out("!!! (end)  %s\n", end-tag);
              // should close the last started tag
              if (as(<symbol>, end-tag) = last(tag-queue))
                format-out("!!! (successful end)  %s\n", end-tag);
                pop-last(tag-queue);  
                format-out("!!! now at depth: %d\n", size(tag-queue));
                // dispatch
                if (end-tag = "stream:stream" & ~ current-element)
                  stream-running? := #f;
                  //!!! shutdown
                else
                  format-out("!!! (-) %=\n", current-element);
                  format-out("!!! (+) %=\n", current-element.element-parent);
//                if (~ current-element.element-parent)
                  if (size(tag-queue) = 1)
                    format-out("!!! (X) %=\n", current-element);
                    //!!! do something!!!
                  end if;
                  //@listener.receive wird ausgeführt wenn @current keinen parent hat
                  current-element := current-element.element-parent;
                end if;
                // cleanup
                parser-buffer := "";
                parsing-tag? := #f;
                read-next();
              else
                //!!! error: not-well formed xml: start/end tag mismatch
                format-out("!!! (WANTED end)  %s (%s)\n", last(tag-queue), real-name(last(tag-queue)));
              end if;
            end if;
            
            // could be a xml declaration
            let (index, processing-instruction) = scan-xml-decl(parser-buffer);
            if (processing-instruction)
              format-out("!!! %=: %s\n", object-class(processing-instruction), processing-instruction.name);
              parser-buffer := "";
              parsing-tag? := #f;
              read-next();
            end if;
    
          else
            //XXX we allow everything in a tag
            if (received ~= '\n')
              parser-buffer := add!(parser-buffer, received);
            end if;
            read-next();
          end if;
        end if;
    end block;
   
  end while;
  format-out("!!! OOOOHHHH! NOOOOO!");
exception (condition :: <condition>)
  disconnect(client);
  format-out("client: listen: Error: %=", condition);
end block;

end method listen;

define method disconnect (client :: <xmpp-client>)
  close(client.socket);
  client.state := #"disconnected";
end method disconnect;

define method send (client :: <xmpp-client>, data)
  write-line(client.socket, as(<string>, data));
  force-output(client.socket);
  format-out("<<< %s\n", data);
end method send;

define method password-setter (password, client :: <xmpp-client>)
 => (res);

  password;
end method password-setter;

/*
define meta start-of-tag(elt-name, sym-name, attribs, s) => (elt-name, attribs)
  "<", scan-name(elt-name), scan-s?(s), scan-xml-attributes(attribs), ">"
//  (push(*tag-name-with-proper-capitalization*, elt-name)),
//set!(sym-name, as(<symbol>, elt-name))
end meta start-of-tag;

define meta start-tag
//(name, s, attribs) => (name)
  "<", ">"
//, scan-name(name), scan-s?(s), scan-xml-attributes(attribs), ">"
end meta start-tag;

define meta end-tag (name, s) => (name)
  "</", scan-name(name), scan-s?(s), ">"
end meta end-tag;
*/             
/*
define method valid-xmpp-data? (data :: <string>)
 => (res :: <boolean>);
  if (parse-document(data))
    #t;
  else
    #f;
  end if;
end method valid-xmpp-data?;
*/

/*
define meta start-tag (elt-name, sym-name, attribs, s) => (elt-name, atts)
  "<", scan-name(elt-name), scan-s?(s), scan-xml-attributes(attribs), ">"
end meta start-tag;
*/

/*
define collector maybe-elements (c) => (c) 
  loop([scan-maybe-element(c), do(collect(c))])
end collector maybe-element;

define collector maybe-element (c) => (c)
 "<", loop({[">", do(collect('>')), finish()], [accept(c), do(collect(c))]})
end collector elements;
*/
