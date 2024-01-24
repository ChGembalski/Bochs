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

#ifndef BX_GUI_COCOA_BOCHS_H

  #define BX_GUI_COCOA_BOCHS_H

  struct BXNSApplicationImpl;

  typedef enum {
    BX_GUI_WINDOW_UNDEFINED,
    BX_GUI_WINDOW_CONFIGURATION,
    BX_GUI_WINDOW_VGA_DISPLAY,
    BX_GUI_WINDOW_LOGGING,
    BX_GUI_WINDOW_DEBUGGER
  } gui_window_type_t;

  typedef enum {
    BX_WINDOW_PROPERTY_UNDEFINED = -1,
    BX_WINDOW_PROPERTY_START_SIM,
    BX_WINDOW_PROPERTY_EXIT_SIM,
  } window_property_t;

  class BXGuiCocoaApplication {

  private:
    BXNSApplicationImpl * BXCocoaApplication;

  public:
    BXGuiCocoaApplication();
    ~BXGuiCocoaApplication();

    void showWindow(gui_window_type_t window, bool bShow);
    int getWindowProperty(gui_window_type_t window, window_property_t property, bool bWait);

    

  };

  extern BXGuiCocoaApplication * bxcocoagui;
  extern int main_argc;
  extern char ** main_argv;

#endif /* BX_GUI_COCOA_BOCHS_H */
