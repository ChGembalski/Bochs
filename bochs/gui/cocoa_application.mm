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
#include "cocoa_menu.h"

#include "bochs.h"
#include "siminterface.h"

extern int bxmain(void);

/////////////////////////////////
// BXBochsThread
/////////////////////////////////

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

/////////////////////////////////
// BXNSApplication
/////////////////////////////////

@implementation BXNSApplication

BXNSMenuBar * menubar;
BXBochsThread * bochsThread;


/**
 * finishLaunching
 */
- (void)finishLaunching {

  // Basic App setup
  [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
  NSApp.applicationIconImage = nil;//(NSImage *) BXwindow->createIconXPM();

  // Window Controller
  self.bx_window_controller = [[BXNSWindowController alloc] init];

  // Menue Bar
  menubar = [[BXNSMenuBar alloc] init:self.bx_window_controller];
  [BXNSMenuBar showMenu:@"Debugger" doShow:NO];







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




/**
 * getMaxScreenResolution
 */
- (void)getMaxScreenResolution:(unsigned char * _Nonnull) bpp width:(unsigned int * _Nonnull) w height:(unsigned int * _Nonnull) h {

  NSArray * screens;

  screens = [NSScreen screens];

  [screens enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {

    NSScreen * screen;
    NSRect frame;
    NSInteger sBpp;

    screen = [screens objectAtIndex: idx];
    frame = [screen visibleFrame];
    sBpp = NSBitsPerPixelFromDepth(screen.depth);

    if (((unsigned int)frame.size.width > *w) | ((unsigned int)frame.size.height > *h) | (sBpp > *bpp)) {
      *bpp = (unsigned char)sBpp;
      *w = (unsigned int)frame.size.width;
      *h = (unsigned int)frame.size.height;
    }

  }];

  // BXL_DEBUG(([NSString stringWithFormat:@"ScreenResolution bpp=%d width=%d height=%d", *bpp, *w, *h]));

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
 * showWindow
 */
void BXGuiCocoaApplication::showWindow(gui_window_type_t window, bool bShow) {
  NSLog(@"BXGuiCocoaApplication::showWindow");
  dispatch_sync(dispatch_get_main_queue(), ^(void){
    [BXCocoaApplication->BXNSApp.bx_window_controller showWindow:window doShow:bShow];
  });
}

/**
 * activateWindow
 */
void BXGuiCocoaApplication::activateWindow(gui_window_type_t window) {
  NSLog(@"BXGuiCocoaApplication::activateWindow");
  dispatch_sync(dispatch_get_main_queue(), ^(void){
    [BXCocoaApplication->BXNSApp.bx_window_controller activateWindow:window];
  });
}

/**
 * getProperty
 */
int BXGuiCocoaApplication::getProperty(property_t property, bool bWait) {

  int result;

  if (!bWait) {
    return [BXCocoaApplication->BXNSApp.bx_window_controller getProperty:property];
  }

  while (bWait) {
    result = [BXCocoaApplication->BXNSApp.bx_window_controller getProperty:property];
    usleep(10000);
    bWait = result == BX_PROPERTY_UNDEFINED ? true : false;
  }

  return result;

}


/**
 * postLogMessage
 */
void BXGuiCocoaApplication::postLogMessage(unsigned char level, unsigned char mode, const char * prefix, const char * msg) {

  if (msg == NULL) {
    return;
  }

  [BXCocoaApplication->BXNSApp.bx_window_controller.bx_log_queue enqueueSplit:[NSString stringWithUTF8String:msg] LogLevel:level LogMode:mode];

  // NSLog(@"level=%d mode=%d prefix=%@ msg=%@",
  //   level, mode, prefix==NULL?@"null":[NSString stringWithUTF8String:prefix], msg==NULL?@"null":[NSString stringWithUTF8String:msg]);
}




/**
 * getScreenConfiguration
 */
void BXGuiCocoaApplication::getScreenConfiguration(unsigned int * width, unsigned int * height, unsigned char * bpp) {
  [BXCocoaApplication->BXNSApp getMaxScreenResolution:bpp width:width height:height];
}











// EOF
