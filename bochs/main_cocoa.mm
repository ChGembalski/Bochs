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

// main_cocoa.mm -- bochs file for MacOS X with Cocoa API
// written by Christoph Gembalski <christoph@gembalski.de>

// This file replace the main entry point so we start as an MacOS App
// on main thread and have a valid Event Queue running
// args provided are kept and redirected to bochs main
// bochs runs on a separate thread while Cocoa needs the main thread
// handling events and the other gui stuff ...

// BOCHS INCLUDES
#include "config.h"

#if BX_WITH_COCOA

#include <Cocoa/Cocoa.h>
#include "gui/cocoa_application.h"

int main_argc;
char ** main_argv;

// the one and only MacOS entry point
int main(int argc, char *argv[]) {
  main_argc = argc;
  main_argv = argv;
  [BXNSApplication sharedApplication];
  [NSApp run];
}

#endif /* BX_WITH_COCOA */
