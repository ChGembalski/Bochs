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

#ifndef BX_NEW_DBG_DEF_H
#define BX_NEW_DBG_DEF_H

#if BX_DEBUGGER && !BX_DEBUGGER_GUI && BX_NEW_DEBUGGER_GUI

#define IMPLEMENT_GUI_DEBUGGER(debugger_class) \
debugger_class * bx_dbg_new; \
void new_dbg_handler_custom(bool init) { \
  if (init) { \
    bx_dbg_new = new debugger_class(); \
  } else { \
    delete bx_dbg_new; \
  } \
}

class BOCHSAPI bx_dbg_gui_c {

public:
  bx_dbg_gui_c(void);
  virtual ~bx_dbg_gui_c(void);

protected:

private:

};



#endif /* BX_DEBUGGER && !BX_DEBUGGER_GUI && BX_NEW_DEBUGGER_GUI */

#endif /* BX_NEW_DBG_DEF_H */
