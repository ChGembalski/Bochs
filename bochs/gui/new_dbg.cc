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

// BOCHS NEW DEBUGGER Ver 1.0
// written by Christoph Gembalski <christoph@gembalski.de>

#include "config.h"

#if BX_DEBUGGER && !BX_DEBUGGER_GUI && BX_NEW_DEBUGGER_GUI

  #include "new_dbg.h"
  #include "bochs.h"
  #include "siminterface.h"

  extern void new_dbg_handler_custom(bool init);

  static bxevent_handler old_callback = NULL;
  static void * old_callback_arg = NULL;


  // internal callback handler
  BxEvent *new_dbg_notify_callback(void *unused, BxEvent *event)
  {
    switch (event->type)
    {
      default: {
        return (*old_callback)(old_callback_arg, event);
      }
    }
  }

  // internal setup
  void InitDebugDialog() {
    new_dbg_handler_custom(true);

    // setup new callback
    SIM->get_notify_callback(&old_callback, &old_callback_arg);
    assert (old_callback != NULL);
    SIM->set_notify_callback(new_dbg_notify_callback, NULL);

  }

  // internal cleanup
  void CloseDebugDialog() {
    new_dbg_handler_custom(false);
    
    // restore old callback
    SIM->set_notify_callback(old_callback, old_callback_arg);

  }

////////////////////////////////////////////////////////////////////////////////
// bx_dbg_gui_c
////////////////////////////////////////////////////////////////////////////////

/**
 * CTor
 */
bx_dbg_gui_c::bx_dbg_gui_c(void) {

}

/**
 * DTor
 */
bx_dbg_gui_c::~bx_dbg_gui_c(void) {

}







#endif
