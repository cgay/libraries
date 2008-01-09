Module:    dylan-user
Synopsis:  Definitions shared by the XML-RPC client and server
Author:    Carl Gay
Copyright: (C) 2002, Carl L Gay.  All rights reserved.
License:   Functional Objects Library Public License Version 1.0
Warranty:  Distributed WITHOUT WARRANTY OF ANY KIND

define library xml-rpc-common
  use common-dylan;
  use io,
    import: { streams, format };
  use system,
    import: { date };
  use xml-parser,
    import: { xml-parser };
  use dylan-basics;
  use base64;
  export xml-rpc-common;
end;

define module xml-rpc-common
  use dylan;
  use common-extensions,
    exclude: { format-to-string };
  use format;
  use streams;
  use date,
    import: { <date>,
              as-iso8601-string };
  use xml-parser,
    prefix: "xml$";
  use dylan-basics,
    exclude: { split };
  use base64,
    import: { base64-decode };
  export
    <xml-rpc-error>,
    <xml-rpc-parse-error>, xml-rpc-parse-error,
    <xml-rpc-fault>, xml-rpc-fault, fault-code,
    to-xml,
    from-xml,
    find-child,
    *debugging-xml-rpc*,
    set-strict-mode,
end;


