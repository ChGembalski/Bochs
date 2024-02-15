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

#ifndef BX_GUI_COCOA_LOGGING_H

  #define BX_GUI_COCOA_LOGGING_H

  #if __cplusplus
    extern "C" {
  #endif

#if BX_NO_LOGGING

  #define BXL_INFO(x)
  #define BXL_DEBUG(x)
  #define BXL_ERROR(x)
  #define BXL_PANIC(x)
  #define BXL_FATAL(x)

#else /* BX_NO_LOGGING */

  extern void bx_cocoa_gui_c_log_info(const char *data);
  extern void bx_cocoa_gui_c_log_debug(const char *data);
  extern void bx_cocoa_gui_c_log_error(const char *data);
  extern void bx_cocoa_gui_c_log_panic(const char *data);
  extern void bx_cocoa_gui_c_log_fatal(const char *data);

  #define BXL_INFO(x) bx_cocoa_gui_c_log_info([x UTF8String])
  #define BXL_DEBUG(x) bx_cocoa_gui_c_log_debug([x UTF8String])
  #define BXL_ERROR(x) bx_cocoa_gui_c_log_error([x UTF8String])
  #define BXL_PANIC(x) bx_cocoa_gui_c_log_panic([x UTF8String])
  #define BXL_FATAL(x) bx_cocoa_gui_c_log_fatal([x UTF8String])

#endif /* BX_NO_LOGGING */

  #if __cplusplus
    }   // Extern C
  #endif

#endif /* BX_GUI_COCOA_LOGGING_H */
