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

#ifndef BX_GUI_COCOA_APPLICATION_H

  #define BX_GUI_COCOA_APPLICATION_H

  #include "cocoa_windows.h"

  @interface BXBochsThread : NSThread

    - (instancetype)init;
    - (void)main;

  @end

  @interface BXNSApplication : NSApplication

    @property (nonatomic, readwrite, strong) BXNSWindowController * bx_window_controller;

    - (void)finishLaunching;
    - (void)terminate:(id)sender;


  @end

  // C++ Wrapper for BXNSApplication
  struct BXNSApplicationImpl {
    BXNSApplication * BXNSApp;
  };

#endif /* BX_GUI_COCOA_APPLICATION_H */
