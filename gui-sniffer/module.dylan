Module:    dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see license.txt in this directory

define module hex-view
  use common-dylan, exclude: { format-to-string };
  use streams;
  use format;
  use format-out;
  use deuce;
  use deuce-internals;

  export show-hexdump, set-highlight, hexdump, remove-highlight;
end;

define module command-line
  use common-dylan, exclude: { format-to-string };
  use streams;
  use format;
  use format-out;
  use deuce;
  use deuce-internals;
  use duim-deuce-internals;
  use threads;
  use commands;
  use command-lines;

  export make-nnv-shell-pane, command-line-server, nnv-context, nnv-context-setter, <nnv-context>,
     chop;
end;

define module layer-commands
  use common-dylan, exclude: { format-to-string };
  use new-layer;
  use command-line;
  use commands;
  use command-lines;
  use format;
  use arp, import: { arp-resolve, print-arp-table  };
  use ipv4, import: { <ipv4-address> };
  use file-system, import: { with-open-file };
  use operating-system, import: { environment-variable };
  use ip;
  use cidr;

  export $layer-command-group;
end;


define module gui-sniffer
  use common-dylan, exclude: { format-to-string };
  use dylan-extensions, import: { debug-name };
  use threads;
  use duim, exclude: { <frame>, frame-size };
//  use win32-duim;
  use deuce;
  use duim-deuce;
  use format;
  use format-out;
  use standard-io;
  use streams;
  use date;
  use file-system;
  use operating-system;
  use packetizer, exclude: { hexdump };
  use packet-filter;
  use network-flow;
  use flow;
  use command-line;
  use layer-commands;
  use commands;
  use command-lines;
  use hex-view;
  use ethernet, import: { <ethernet-frame> };
  use pcap, import: { make-unix-time, <pcap-packet>, decode-unix-time, timestamp };
  use prism2, import: { <prism2-frame> };
  use ipv4, import: { <ipv4-frame>, <udp-frame>, source-port, destination-port,
                      acknowledgement-number, sequence-number, ipv4-address, <ipv4-address>, udp-frame };
  use icmp, import: { <icmp-frame>, icmp-echo-request };
  use dhcp, import: { <dhcp-message>, <dhcp-subnet-mask>, <dhcp-router-option>, subnet-mask, addresses, your-ip-address };
  use dns, import: { dns-frame, dns-question, <domain-name> };
  use cidr;
  use tcp;
  use ipv6;
  use deuce-internals, prefix: "deuce/";
  use network-interfaces;
  use layer;
  use timer;
  use new-layer, prefix: "new-";
  use socket, prefix: "new-";
  use flow-printer;
end module gui-sniffer;
