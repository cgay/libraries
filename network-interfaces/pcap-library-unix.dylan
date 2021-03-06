module: dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define library network-interfaces
  use common-dylan;
  use c-ffi;
  use io;
  use collection-extensions;
  use functional-dylan;
  use flow;
  use network;
  use packetizer;

  use protocols, import: { ethernet, ipv4, cidr };

  export network-interfaces;
end;

define module network-interfaces
  use common-dylan;
  use c-ffi;
  use unix-sockets, import: { sa-data-array, <timeval>,
                              <lpsockaddr>, <C-buffer-offset> };
  //use format-out;
  use standard-io;
  use subseq;
  use dylan-direct-c-ffi;
  use machine-words;
  use byte-vector;
  use flow;
  use print;
  use format;
  use ethernet, import: { <ethernet-frame> };
  use ipv4, import: { <ipv4-address> };
  use cidr, import: { <cidr>, netmask-from-byte-vector };
  use packetizer,
    import: { parse-frame,
              <frame>,
              assemble-frame,
              packet,
              <stretchy-vector-subsequence> };
  export <ethernet-interface>,
    interface-name,
    running?-setter,
    running?,
    find-all-devices;

  export <device>,
    device-name,
    device-cidrs;
end;

