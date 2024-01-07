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
#include "cocoa_window.h"

// @interface BXGuiCocoaNSWindow : NSWindow <NSApplicationDelegate>
// @end

@implementation BXGuiCocoaNSWindow

NSTextField* label;

- (instancetype)init {
  label = [[[NSTextField alloc] initWithFrame:NSMakeRect(5, 100, 290, 100)] autorelease];
  [label setStringValue:@"Hello Bochs!"];
  [label setBezeled:NO];
  [label setDrawsBackground:NO];
  [label setEditable:NO];
  [label setSelectable:NO];
  [label setTextColor:[NSColor colorWithSRGBRed:0.0 green:0.5 blue:0.0 alpha:1.0]];
  [label setFont:[[NSFontManager sharedFontManager] convertFont:[[NSFontManager sharedFontManager] convertFont:[NSFont fontWithName:[[label font] fontName] size:45] toHaveTrait:NSFontBoldTrait] toHaveTrait:NSFontItalicTrait]];

  [super initWithContentRect:NSMakeRect(0, 0, 300, 300) styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable backing:NSBackingStoreBuffered defer:NO];
  [self setTitle:@"Hello bochs (label)"];
  [[self contentView] addSubview:label];
  [self center];
  [self setIsVisible:YES];
  //[self makeKeyAndOrderFront:nil];
  NSLog(@"Done init");

  return self;
}

- (BOOL)windowShouldClose:(id)sender {
  [NSApp terminate:sender];
  return YES;
}

@end

// C++ Wrapper for BXGuiCocoaNSWindow : NSWindow

struct BXGuiCocoaWindowImpl {
  BXGuiCocoaNSWindow * BXWindow;
};

// Class BXGuiCocoaWindow

/**
 * BXGuiCocoaWindow CTor
 */
BXGuiCocoaWindow::BXGuiCocoaWindow(BXGuiCocoaView * view) : BXCocoaWindow(new BXGuiCocoaWindowImpl) {
  BXCocoaWindow->BXWindow = [[[BXGuiCocoaNSWindow alloc] init] autorelease];

}

/**
 * BXGuiCocoaWindow DTor
 */
BXGuiCocoaWindow::~BXGuiCocoaWindow() {
  if (BXCocoaWindow)
    [BXCocoaWindow->BXWindow release];
}

BXGuiCocoaNSWindow * BXGuiCocoaWindow::getWindow(void) {
  return (BXCocoaWindow->BXWindow);
}
