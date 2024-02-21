////////////////////////////////////////////////////////////////////////
// $Id$
/////////////////////////////////////////////////////////////////////////
//
//  Copyright (C) 2001-2024  The Bochs Project
//
//  This library is free software; you can redistribute it and/or
//  modify it under the terms of the GNU Lesser General Public
//  License as published by the Free Software Foundation; either
//  version 2 of the License, or (at your option) any later version.
//
//  This library is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//  Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public
//  License along with this library; if not, write to the Free Software
//  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
//
////////////////////////////////////////////////////////////////////////

// cocoa -- bochs GUI file for MacOS X with Cocoa API
// written by Christoph Gembalski <christoph@gembalski.de>

#include "config.h"

#if BX_DEBUGGER && BX_NEW_DEBUGGER_GUI

  #include "cocoa_bochs.h"

  #include "new_dbg.h"

class bx_cocoa_dbg_gui_c : public bx_dbg_gui_c {

public:
  // bx_cocoa_dbg_gui_c(void);
  // ~bx_cocoa_dbg_gui_c(void);
protected:


DECLARE_GUI_DEBUGGER_VIRTUAL_METHODS();

};

// Create the new Gui Debugger class
IMPLEMENT_GUI_DEBUGGER(bx_cocoa_dbg_gui_c);

// /**
//  * CTor maybe not needed
//  */
// bx_cocoa_dbg_gui_c::bx_cocoa_dbg_gui_c(void):bx_dbg_gui_c() {
//
// }
//
// /**
//  * DTor maybe not needed
//  */
// bx_cocoa_dbg_gui_c::~bx_cocoa_dbg_gui_c(void) {
//
// }

/**
 * init_os_depended
 */
void bx_cocoa_dbg_gui_c::init_os_depended(void) {
  bxcocoagui->createDebuggerUI();
  bxcocoagui->showWindow(BX_GUI_WINDOW_DEBUGGER, true);
}

/**
 * gui_command_finished
 */
bool bx_cocoa_dbg_gui_c::gui_command_finished(int cpu) {
  bxcocoagui->updateDebugger(cpu);
  return true;
}

#endif /* BX_DEBUGGER && BX_NEW_DEBUGGER_GUI */
