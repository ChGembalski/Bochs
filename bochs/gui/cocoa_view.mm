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

#include <Cocoa/Cocoa.h>
#include "cocoa_view.h"

@interface BXGuiCocoaNSView : NSView
-(void)drawRect:(NSRect)rect;
@end

@implementation BXGuiCocoaNSView
-(void) drawRect:(NSRect)rect {
  [[NSColor grayColor] set];
  NSRectFill([self bounds]);
}
@end

// C++ Wrapper for NSRect

struct BXGuiCocoaViewRect {
  NSRect BXViewRect = NSMakeRect(100.0,100.0,300.0,300.0);
};

// C++ Wrapper for BXGuiCocoaNSView : NSView

struct BXGuiCocoaViewImpl {
  BXGuiCocoaNSView * BXView;
};

// Class BXGuiCocoaView

/**
 * BXGuiCocoaView CTor
 */
BXGuiCocoaView::BXGuiCocoaView() : BXCocoaView(new BXGuiCocoaViewImpl), BXCocoaViewRect(new BXGuiCocoaViewRect) {
    BXCocoaView->BXView = [[BXGuiCocoaNSView alloc] initWithFrame:BXCocoaViewRect->BXViewRect];
}

/**
 * BXGuiCocoaView DTor
 */
BXGuiCocoaView::~BXGuiCocoaView() {
  if (BXCocoaView)
    [BXCocoaView->BXView release];
}
