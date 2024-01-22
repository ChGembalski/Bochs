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
#include "cocoa_bochs.h"
#include "cocoa_application.h"
#include "bochs.h"
#include "siminterface.h"

extern int bxmain(void);
extern int main_argc;
extern char ** main_argv;

@implementation BXBochsThread

/**
 * BXBochsThread CTor
 */
- (instancetype)init {
  self = [super init];
  if(self) {

    bx_startup_flags.argc = main_argc;
    bx_startup_flags.argv = main_argv;


  }
  return self;
}


/**
 * main
 */
- (void)main {

  NSLog(@"bochs thread started");
  bxmain();
  NSLog(@"bochs thread stopped");

}


@end

@implementation BXNSApplication

BXBochsThread * bochsThread;


/**
 * finishLaunching
 */
- (void)finishLaunching {

  // Basic App setup
  [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
  NSApp.applicationIconImage = nil;//(NSImage *) BXwindow->createIconXPM();

  // Menue Bar
  id menubar = [NSMenu new];
  id appMenuItem = [NSMenuItem new];
  id editMenuItem = [NSMenuItem new];
  id windowMenuItem = [NSMenuItem new];
  [menubar addItem:appMenuItem];
  [menubar addItem:editMenuItem];
  [menubar addItem:windowMenuItem];
  [NSApp setMainMenu:menubar];

  // Then we add the quit item to the menu. Fortunately the action is simple since terminate: is
  // already implemented in NSApplication and the NSApplication is always in the responder chain.
  id appMenu = [NSMenu new];
  id appName = [[NSProcessInfo processInfo] processName];
  id quitTitle = [@"Quit " stringByAppendingString:appName];
  id quitMenuItem = [[NSMenuItem alloc] initWithTitle:quitTitle
                                                action:@selector(terminate:) keyEquivalent:@"q"];
                                                // MUST CALL BX_EXIT(exitcode) !!!!!!!!!!!!!!

  [appMenu addItem:quitMenuItem];
  [appMenuItem setSubmenu:appMenu];

  id editMenu = [[NSMenu new] initWithTitle:@"Edit"];
  id clipboardgetMenuItem = [[NSMenuItem alloc] initWithTitle:@"get Clipboard" action: nil keyEquivalent:@""];
  id clipboardsetMenuItem = [[NSMenuItem alloc] initWithTitle:@"set Clipboard" action: nil keyEquivalent:@""];

  [editMenu addItem:clipboardgetMenuItem];
  [editMenu addItem:clipboardsetMenuItem];
  [editMenuItem setSubmenu:editMenu];

  // TODO : Need some Menus like Window -> VGA Display, Console? , Logging, Debugger
  id windowMenu = [[NSMenu new] initWithTitle:@"Window"];
  id vgadisplayMenuItem = [[NSMenuItem alloc] initWithTitle:@"VGA display" action: nil keyEquivalent:@""];
  id consoleMenuItem = [[NSMenuItem alloc] initWithTitle:@"Console" action: nil keyEquivalent:@""];
  id loggingMenuItem = [[NSMenuItem alloc] initWithTitle:@"Logging" action: nil keyEquivalent:@""];
  id debuggerMenuItem = [[NSMenuItem alloc] initWithTitle:@"Debugger" action: nil keyEquivalent:@""];

  [windowMenu addItem:vgadisplayMenuItem];
  [windowMenu addItem:consoleMenuItem];
  [windowMenu addItem:loggingMenuItem];
  [windowMenu addItem:debuggerMenuItem];
  [windowMenuItem setSubmenu:windowMenu];



  // TODO : setup everithing else
  // Startup NSThread running the bochs core
  bochsThread = [[BXBochsThread alloc] init];
  [bochsThread start];

  [super finishLaunching];

}

/**
 * terminate
 */
- (void)terminate:(id)sender {

  // TODO : cleanup everithing else
  if (bochsThread != nil) {
    NSLog(@"bochs thread executing %s", bochsThread.executing?"YES":"NO");
    if (bochsThread.executing) {
      [bochsThread cancel];
    }
  }
  [super terminate:sender];

}














- (void)testWnd {

NSLog(@"bochs thread testWnd");
  NSRect frame = NSMakeRect(0, 0, 200, 200);
NSWindow* window  = [[NSWindow alloc] initWithContentRect:frame
                    styleMask:NSWindowStyleMaskTitled |
                               NSWindowStyleMaskClosable |
                               NSWindowStyleMaskMiniaturizable
                    backing:NSBackingStoreBuffered
                    defer:NO];
[window setTitle:@"test Window"];
[window setBackgroundColor:[NSColor blueColor]];
[window center];
[window setIsVisible:YES];
[window makeKeyAndOrderFront:self];
[window setAcceptsMouseMovedEvents:YES];

NSLog(@"bochs thread testWnd done");

}








@end

/////////////////////////////////
// Class BXGuiCocoaApplication //
/////////////////////////////////

/**
 * BXGuiCocoaApplication CTor
 */
BXGuiCocoaApplication::BXGuiCocoaApplication() : BXCocoaApplication(new BXNSApplicationImpl) {

  BXCocoaApplication->BXNSApp = NSApp;

}

/**
 * BXGuiCocoaApplication DTor
 */
BXGuiCocoaApplication::~BXGuiCocoaApplication() {

}

/**
 * createVGAdisplayWindow
 */
void BXGuiCocoaApplication::createVGAdisplayWindow(unsigned x, unsigned y, unsigned headerbar_y) {
// [[[BXGuiCocoaNSWindow alloc] init:headerbar_y VGAsize:NSMakeSize(x, y)] autorelease];
}
















// EOF
