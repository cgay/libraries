Module:       Dylan-User
Synopsis:     DUIM core + GTK back-end
Author:       Andy Armstrong, Scott McKay
Copyright:    Original Code is Copyright (c) 1999-2000 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define library duim
  use dylan;

  // Use the DUIM core and re-export all its modules, then add
  // the GTK back-end and re-export all its modules as well
  use duim-core,  export: all;
  use gtk-duim, export: all;
end library duim;
