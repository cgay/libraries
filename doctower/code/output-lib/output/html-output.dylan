module: output


define constant $html-templates = #[
   #"html-redirect",
   #"html-toc",
   #"html-toc-recursion",
   #"html-topic",
   #"html-section",
   #"html-catalog",
   #"html-unordered-list",
   #"html-defn-list"
];


define method output-templates (output == #"html") => (templates :: <sequence>)
   $html-templates
end method;


define method output-file-info
   (output == #"html", doc-tree :: <ordered-tree>)
=> (topic-files :: <table>, special-files :: <table>, file-info :: <sequence>)
   // Doc-tree includes #f as root, so effective size is one less and its first
   // element should be ignored.
   
   let file-info = make(<stretchy-vector>);
   let topic-count = max(0, doc-tree.size - 1);
   let topic-files = make(<table>, size: topic-count);
   let special-files = make(<table>, size: 4);
   let html-dir = as(<directory-locator>, "html");

   // Topic files
   
   let topic-digits = topic-count.digits;
   let topic-idx = 0;
   for (topic in doc-tree)
      unless (~topic)
         let prefix-part = format-to-string("%0*d", topic-digits, topic-idx + 1);
         let title-part = as-filename-part(topic.title.stringify-title);
         let base-name = format-to-string("%s_%s", prefix-part, title-part);
         let locator = make(<file-locator>,
               directory: html-dir, base: base-name, extension: "html");
         let topic-file = make(<topic-output-file>, file: locator, topic: topic);
         topic-files[topic] := topic-file;
         file-info := add!(file-info, topic-file);
         topic-idx := topic-idx + 1;
      end unless;
   end for;
   
   // TOC file

   let toc-locator = make(<file-locator>,
         directory: html-dir, base: "contents", extension: "html");
   let toc-file = make(<toc-output-file>, tree: doc-tree, file: toc-locator);
   special-files[#"toc"] := toc-file;
   file-info := add!(file-info, toc-file);

   // Index file

   let top-level-keys = doc-tree.root-key.inf-key-sequence;
   let index-dest =
         if (top-level-keys.size > 0)
            let home-topic = doc-tree[top-level-keys.first];
            topic-files[home-topic]
         else
            toc-file
         end if;
   let index-locator = make(<file-locator>, base: "index", extension: "html");
   let index-file = make(<redirect-output-file>, dest: index-dest,
         file: index-locator);
   special-files[#"home"] := index-dest;
   file-info := add!(file-info, index-file);
   
   // CSS file
   
   let css-locator = make(<file-locator>,
         directory: html-dir, base: "stylesheet", extension: "css");
   let css-origin = make(<file-locator>,
         directory: *template-directory*, base: "default-stylesheet", extension: "css");
   let css-file = make(<copied-output-file>, origin: css-origin, file: css-locator);
   special-files[#"css"] := css-file;
   file-info := add!(file-info, css-file);
   
   // General index file
   
   let gen-index-locator = make(<file-locator>,
         directory: html-dir, base: "general-index", extension: "html");
   let gen-index-file = make(<index-output-file>, file: gen-index-locator);
   special-files[#"index"] := gen-index-file;
   file-info := add!(file-info, gen-index-file);
   
   values(topic-files, special-files, file-info)
end method;


define method target-link-info
   (output == #"html", doc-tree :: <ordered-tree>,
    fallback-ids :: <table>, file-info :: <table>)
=> (target-info :: <table>)
   let target-info = make(<table>);
   for (topic in doc-tree)
      unless (~topic) // Root of doc-tree is #f
         visit-targets(topic, add-html-link-info, target-info: target-info,
               current-topic: topic, fallback-ids: fallback-ids,
               output-file: file-info[topic])
      end unless
   end for;
   target-info
end method;


define method add-html-link-info
   (object :: <object>,
    #key setter, visited, target-info, current-topic, fallback-ids, output-file)
=> (visit-slots? :: <boolean>)
   #t
end method;


define method add-html-link-info
   (topic :: <topic>,
    #key setter, visited, target-info, current-topic, fallback-ids, output-file)
=> (visit-slots? :: <boolean>)
   let raw-topic-id = topic.id | fallback-ids[topic];
   let raw-title-id = format-to-string("%s/:Title", raw-topic-id);
   let raw-shortdesc-id = format-to-string("%s/:Synopsis", raw-topic-id);
   let topic-id = raw-topic-id.sanitized-id;
   let title-id = raw-title-id.sanitized-id;
   let shortdesc-id = raw-shortdesc-id.sanitized-id;
   let filename = output-file.locator.sanitized-url-path;
   let topic-href = format-to-string("%s#%s", filename, topic-id);
   let title-href = format-to-string("%s#%s", filename, title-id);
   let shortdesc-href = format-to-string("%s#%s", filename, shortdesc-id);
   target-info[topic] := make(<topic-target>,
         id: topic-id, href: topic-href, markup-id: raw-topic-id,
         title-id: title-id, title-href: title-href, title-markup-id: raw-title-id,
         shortdesc-id: shortdesc-id, shortdesc-href: shortdesc-href,
         shortdesc-markup-id: raw-shortdesc-id);
   #t
end method;


define method add-html-link-info
   (sect :: <section>,
    #key setter, visited, target-info, current-topic, fallback-ids, output-file)
=> (visit-slots? :: <boolean>)
   let raw-topic-id = current-topic.id | fallback-ids[current-topic];
   let raw-section-id = sect.id | fallback-ids[sect];
   let raw-target-id = format-to-string("%s/%s", raw-topic-id, raw-section-id);
   let raw-title-id = format-to-string("%s/:Title(%s)", raw-topic-id, raw-section-id);
   let section-id = raw-target-id.sanitized-id;
   let title-id = raw-title-id.sanitized-id;
   let filename = output-file.locator.sanitized-url-path;
   let section-href = format-to-string("%s#%s", filename, section-id);
   let title-href = format-to-string("%s#%s", filename, title-id);
   target-info[sect] := make(<section-target>,
         id: section-id, href: section-href, markup-id: raw-target-id,
         title-id: title-id, title-href: title-href, title-markup-id: raw-title-id);
   #t
end method;


define method add-html-link-info
   (content :: type-union(<footnote>, <ph-marker>),
    #key setter, visited, target-info, current-topic, fallback-ids, output-file)
=> (visit-slots? :: <boolean>)
   let raw-topic-id = current-topic.id | fallback-ids[current-topic];
   let raw-content-id = format-to-string("%s/%s", raw-topic-id, fallback-ids[content]);
   let content-id = raw-content-id.sanitized-id;
   let filename = output-file.locator.sanitized-url-path;
   let content-href = format-to-string("%s#%s", filename, content-id);
   let info-class =
         select (content by instance?)
            <footnote> => <footnote-target>;
            <ph-marker> => <ph-marker-target>;
         end select;
   target-info[content] := make(info-class, id: content-id, href: content-href);
   #t
end method;


define method write-output-file
   (output == #"html", file-info :: <redirect-output-file>,
    link-map :: <table>, target-info :: <table>, special-file-info :: <table>)
=> ()
   let var-table = table(<case-insensitive-string-table>,
         "destination" => file-info.destination.locator.sanitized-url-path
         );
   output-from-template(#"html-redirect", file-info, variables: var-table);
end method;


define method write-output-file
   (output == #"html", file-info :: <toc-output-file>,
    link-map :: <table>, target-info :: <table>, special-file-info :: <table>)
=> ()
   let var-table = table(<case-insensitive-string-table>,
         "css-file" => special-file-info[#"css"].locator.sanitized-url-path,
         "home-file" => special-file-info[#"home"].locator.sanitized-url-path,
         "index-file" => special-file-info[#"index"].locator.sanitized-url-path,
         "package-title" => *package-title*,
         "root-topics" => file-info.tree.root-key.inf-key-sequence
         );

   let ops-table = table(<case-insensitive-string-table>,
         "size" => size,
         "href" =>
               method (key :: <ordered-tree-key>) => (href :: <string>)
                  let topic = file-info.tree[key];
                  target-info[topic].target-href
               end method,
         "id" =>
               method (key :: <ordered-tree-key>) => (id :: <string>)
                  let topic = file-info.tree[key];
                  target-info[topic].target-id
               end method,
         "markup-id" =>
               method (key :: <ordered-tree-key>) => (id :: <string>)
                  let topic = file-info.tree[key];
                  target-info[topic].markup-id
               end method,
         "shortdesc" =>
               method (key :: <ordered-tree-key>) => (desc :: <string>)
                  let topic = file-info.tree[key];
                  if (topic.shortdesc)
                     topic.shortdesc.content.stringify-markup
                  else
                     ""
                  end if
               end method,
         "formatted-title" =>
               method (key :: <ordered-tree-key>) => (title :: <string>)
                  let topic = file-info.tree[key];
                  html-content(topic.title, target-info)
               end method,
         "title" =>
               method (key :: <ordered-tree-key>) => (title :: <string>)
                  let topic = file-info.tree[key];
                  topic.title.stringify-title
               end method,
         "child-recursion" =>
               identity /* this is replaced with local method below */
         );

   local method do-child-recursion (key :: <ordered-tree-key>) => (text :: <string>)
            let child-keys = key.inf-key-sequence;
            let vars = table(<case-insensitive-string-table>,
                  "children" => child-keys);
            text-from-template(#"html-toc-recursion",
                  variables: vars, operations: ops-table)
         end method;
   
   ops-table["child-recursion"] := do-child-recursion;
   output-from-template(#"html-toc", file-info,
         variables: var-table, operations: ops-table);
end method;


define method write-output-file
   (output == #"html", file-info :: <index-output-file>,
    link-map :: <table>, target-info :: <table>, special-file-info :: <table>)
=> ()
   // TODO: General index
end method;


define method write-output-file
   (output == #"html", file-info :: <topic-output-file>,
    link-map :: <table>, target-info :: <table>, special-file-info :: <table>)
=> ()
   let var-table = table(<case-insensitive-string-table>,
         "css-file" => special-file-info[#"css"].locator.sanitized-url-path,
         "home-file" => special-file-info[#"home"].locator.sanitized-url-path,
         "toc-file" => special-file-info[#"toc"].locator.sanitized-url-path,
         "index-file" => special-file-info[#"index"].locator.sanitized-url-path,
         "topic-file" => file-info.locator.sanitized-url-path,
         "package-title" => *package-title*,
         "topic" => file-info.topic
         );
   
   let ops-table = table(<case-insensitive-string-table>,
         "href" =>
               method (topic :: type-union(<topic>, <url>)) => (href :: <string>)
                  if (instance?(topic, <topic>))
                     target-info[topic].target-href
                  else
                     topic
                  end if
               end method,
         "id" =>
               method (topic :: <topic>) => (id :: <string>)
                  target-info[topic].target-id
               end method,
         "markup-id" =>
               method (topic :: <topic>) => (id :: <string>)
                  target-info[topic].markup-id
               end method,
         "shortdesc" =>
               method (topic :: type-union(<topic>, <url>)) => (desc :: <string>)
                  if (instance?(topic, <topic>) & topic.shortdesc)
                     topic.shortdesc.content.stringify-markup
                  else
                     ""
                  end if
               end method,
         "title" =>
               method (topic :: type-union(<topic>, <url>)) => (title :: <string>)
                  if (instance?(topic, <topic>))
                     topic.title.stringify-title
                  else
                     topic
                  end if
               end method,
         "child-topic" =>
               method (topic :: <topic>) => (child :: false-or(<topic>))
                  let children = link-map[topic].child-topics;
                  ~children.empty? & children.first
               end method,
         "prev-topic" =>
               method (topic :: <topic>) => (prev :: false-or(<topic>))
                  link-map[topic].prev-topic
               end method,
         "next-topic" =>
               method (topic :: <topic>) => (next :: false-or(<topic>))
                  link-map[topic].next-topic
               end method,
         "parent-topics" =>
               method (topic :: <topic>) => (parents :: <sequence>)
                  link-map[topic].parent-topics
               end method,
         "formatted-title" =>
               method (topic :: <topic>) => (html :: <string>)
                  html-content(topic.title, target-info)
               end method,
         "formatted-shortdesc" =>
               method (topic :: <topic>) => (html :: <string>)
                  html-content(topic.shortdesc | "", target-info)
               end method,
         "main-body" =>
               method (topic :: <topic>) => (html :: <string>)
                  html-main-body(topic, target-info)
               end method,
         "declarations-section" =>
               rcurry(html-section, declarations-section, target-info),
         "syntax-section" =>
               rcurry(html-section, syntax-section, target-info),
         "adjectives-section" =>
               rcurry(html-section, adjectives-section, target-info),
         "conds-section" =>
               rcurry(html-section, conds-section, target-info),
         "args-section" =>
               rcurry(html-section, args-section, target-info),
         "vals-section" =>
               rcurry(html-section, vals-section, target-info),
         "keywords-section" =>
               rcurry(html-section, keywords-section, target-info),
         "value-section" =>
               rcurry(html-section, value-section, target-info),
         "inheritables-section" =>
               rcurry(html-section, inheritables-section, target-info),
         "supers-section" =>
               rcurry(html-section, supers-section, target-info),
         "subs-section" =>
               rcurry(html-section, subs-section, target-info),
         "funcs-on-section" =>
               rcurry(html-section, funcs-on-section, target-info),
         "funcs-returning-section" =>
               rcurry(html-section, funcs-returning-section, target-info),
         "modules-section" =>
               rcurry(html-section, modules-section, target-info),
         "bindings-section" =>
               rcurry(html-section, bindings-section, target-info),
         "subtopics" =>
               method (topic :: <topic>) => (subtopics :: <sequence>)
                  link-map[topic].child-topics
               end method,
         "related-links" =>
               method (topic :: <topic>) => (html-links :: <sequence>)
                  map(rcurry(html-content, target-info), topic.related-links)
               end method,
         "footnotes" => footnotes,
         "size" => size
         );

   output-from-template(#"html-topic", file-info,
         variables: var-table, operations: ops-table);
end method;


define method html-catalog-content (topic :: <catalog-topic>, target-info)
=> (html :: <string>)
   let api-refs = map(rcurry(html-content, target-info), topic.api-xrefs);
   if (api-refs.empty?)
      ""
   else
      let vars = table(<case-insensitive-string-table>, "items" => api-refs);
      text-from-template(#"html-catalog", variables: vars)
   end if
end method;


define method html-main-body (topic :: <topic>, target-info)
=> (html :: <string>)
   html-content(topic.content, target-info)
end method;


define method html-main-body (topic :: <catalog-topic>, target-info)
=> (html :: <string>)
   if (topic.topic-type = #"catalog")
      concatenate(next-method(), html-catalog-content(topic, target-info))
   else
      next-method()
   end if
end method;


define method html-section
   (topic :: <topic>, accessor :: <function>, target-info,
    #key prepend :: <string> = "")
=> (html :: <string>)
   let html = 
         if (applicable-method?(accessor, topic))
            let sect :: false-or(<section>) = topic.accessor;
            if (sect)
               let section-content =
                     concatenate(prepend, html-content(sect.content, target-info));
               if (~section-content.empty?)
                  let vars = table(<case-insensitive-string-table>,
                        "id" =>
                              target-info[sect].target-id,
                        "markup-id" =>
                              target-info[sect].markup-id,
                        "formatted-title" =>
                              html-content(sect.title, target-info),
                        "content" =>
                              section-content
                        );
                  text-from-template(#"html-section", variables: vars);
               end if
            end if
         end if;
   html | ""
end method;


define method html-section
   (topic :: <library-doc>, accessor == modules-section, target-info, #key)
=> (html :: <string>)
   next-method(topic, accessor, target-info,
         prepend: html-catalog-content(topic, target-info))
end method;


define method html-section
   (topic :: <module-doc>, accessor == bindings-section, target-info, #key)
=> (html :: <string>)
   next-method(topic, accessor, target-info,
         prepend: html-catalog-content(topic, target-info))
end method;


define method html-content (obj :: <object>, target-info)
=> (html :: <string>)
   /**/
   format-to-string("%=", obj).sanitized-xml;
end method;


define method html-content (seq :: <sequence>, target-info)
=> (html :: <string>)
   let html-elems = map-as(<vector>, rcurry(html-content, target-info), seq);
   reduce(concatenate, "", html-elems)
end method;


define method html-content (str :: <string>, target-info)
=> (html :: <string>)
   sanitized-xml(str)
end method;


define method html-content (char :: <character>, target-info)
=> (html :: <string>)
   sanitized-xml(as(<string>, char))
end method;


define method html-content (sect :: <section>, target-info)
=> (html :: <string>)
   let section-content = html-content(sect.content, target-info);
   if (~section-content.empty?)
      let vars = table(<case-insensitive-string-table>,
            "id" =>
                  target-info[sect].target-id,
            "markup-id" =>
                  target-info[sect].markup-id,
            "formatted-title" =>
                  html-content(sect.title, target-info),
            "content" =>
                  section-content
            );
      text-from-template(#"html-section", variables: vars)
   else
      ""
   end if
end method;


define method html-content (xref :: <xref>, target-info)
=> (html :: <string>)
   let title = html-content(xref.text, target-info);
   select (xref.target by instance?)
      <url> =>
         let href = xref.target.sanitized-url.sanitized-xml;
         format-to-string("<a href=\"%s\">%s</a>", href, title);
      <topic> =>
         let href = target-info[xref.target].target-href.sanitized-xml;
         let desc =
               if (xref.target.shortdesc)
                  xref.target.shortdesc.content.stringify-markup.sanitized-xml
               else
                  ""
               end if;
         format-to-string("<a href=\"../%s\" title=\"%s\">%s</a>", href, desc, title);
      <section> =>
         let href = target-info[xref.target].target-href.sanitized-xml;
         format-to-string("<a href=\"../%s\">%s</a>", href, title);
      otherwise =>
         // TODO: Xref output for footnotes and ph-markers.
         next-method();
   end select
end method;


define method html-content (conref :: <conref>, target-info)
=> (html :: <string>)
   if (conref.style = #"title")
      html-content(conref.target.title, target-info)
   else
      html-content(conref.target.shortdesc, target-info)
   end if
end method;


define method html-content (link :: <topic-ref>, target-info)
=> (html :: <string>)
   select (link.target by instance?)
      <url> =>
         let title = as(<string>, link.target).sanitized-xml;
         let href = link.target.sanitized-url.sanitized-xml;
         format-to-string("<a href=\"%s\">%s</a>", href, title);
      <topic> =>
         let title = html-content(link.target.title, target-info);
         let href = target-info[link.target].target-href.sanitized-xml;
         let desc =
               if (link.target.shortdesc)
                  link.target.shortdesc.content.stringify-markup.sanitized-xml
               else
                  ""
               end if;
         format-to-string("<a href=\"../%s\" title=\"%s\">%s</a>",
               href, desc, title);
   end select
end method;


define method html-content (ul :: <unordered-list>, target-info)
=> (html :: <string>)
   let html-items = map(rcurry(html-content, target-info), ul.items);
   let vars = table(<case-insensitive-string-table>, "items" => html-items);
   text-from-template(#"html-unordered-list", variables: vars)
end method;


define method html-content (defn-list :: <defn-list>, target-info)
=> (html :: <string>)
   // BUGFIX: Map can't create an <array>. Bug #7473.
   let html-items = make(<array>, dimensions: defn-list.items.dimensions);
   map-into(html-items, rcurry(html-content, target-info), defn-list.items);
   let vars = table(<case-insensitive-string-table>,
         "class" =>
               if (instance?(defn-list, <one-line-defn-list>))
                  "one-line"
               else
                  "many-line"
               end if,
         "items" =>
               range(from: 0, below: dimension(html-items, 0))
         );
   let ops = table(<case-insensitive-string-table>,
         "term" =>
               method (i :: <integer>) => (html :: <string>)
                  html-items[i, 0]
               end,
         "defn" =>
               method (i :: <integer>) => (html :: <string>)
                  html-items[i, 1]
               end
         );
   text-from-template(#"html-defn-list", variables: vars, operations: ops)
end method;


define method html-content (code :: type-union(<code-block>, <pre>), target-info)
=> (html :: <string>)
   html-entag("pre", code.content, target-info)
end method;


define method html-content (raw :: <dita-content>, target-info)
=> (html :: <string>)
   ""
end method;


define method html-content (raw :: <html-content>, target-info)
=> (html :: <string>)
   raw.content
end method;


define method html-content (ent :: <entity>, target-info)
=> (html :: <string>)
   format-to-string("&#%d;", ent.code)
end method;


define method html-content (parm :: <api/parm-name>, target-info)
=> (html :: <string>)
   html-entag("var", parm.text, target-info)
end method;


define method html-content (term :: <term>, target-info)
=> (html :: <string>)
   html-entag("dfn", term.text, target-info)
end method;


define method html-content (term :: <term-style>, target-info)
=> (html :: <string>)
   enspan("term", term.text, target-info)
end method;


define method html-content (code :: <code-phrase>, target-info)
=> (html :: <string>)
   html-entag("code", code.text, target-info)
end method;


define method html-content (cite :: <cite>, target-info)
=> (html :: <string>)
   html-entag("cite", cite.text, target-info)
end method;


define method html-content (bold :: <bold>, target-info)
=> (html :: <string>)
   html-entag("b", bold.text, target-info)
end method;


define method html-content (ital :: <italic>, target-info)
=> (html :: <string>)
   html-entag("i", ital.text, target-info)
end method;


define method html-content (und :: <underline>, target-info)
=> (html :: <string>)
   html-entag("u", und.text, target-info)
end method;


define method html-content (em :: <emphasis>, target-info)
=> (html :: <string>)
   html-entag("strong", em.text, target-info)
end method;


define method html-content (para :: <paragraph>, target-info)
=> (html :: <string>)
   concatenate(html-entag("p", para.content, target-info), "\n");
end method;


define method enspan (span-class :: <string>, content, target-info)
=> (html :: <string>)
   concatenate("<span class=\"", span-class.sanitized-xml, "\"",
         html-content(content, target-info),
         "</span>")
end method;


define method html-entag (tag :: <string>, content, target-info)
=> (html :: <string>)
   concatenate("<", tag, ">",
         html-content(content, target-info),
         "</", tag, ">")
end method;
