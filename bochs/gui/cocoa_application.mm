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

/////////////////////////////////
// BXBochsThread
/////////////////////////////////

@implementation BXBochsThread

/**
 * BXBochsThread CTor
 */
- (instancetype _Nonnull)init {
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

BXBochsThread * bochsThread;
vga_settings_t default_vga_settings = {
  32, 640, 480
};

/**
 * finishLaunching
 */
- (void)finishLaunching {

  // Basic App setup
  [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
  NSApp.applicationIconImage = nil;//(NSImage *) BXwindow->createIconXPM();

  // Window Controller
  self.bx_window_controller = [[BXNSWindowController alloc] init:default_vga_settings.headerbar_y VGAxRes:default_vga_settings.xres VGAyRes:default_vga_settings.yres];









  // TODO : setup everithing else
  // Startup NSThread running the bochs core
  bochsThread = [[BXBochsThread alloc] init];
  [bochsThread start];

  [super finishLaunching];

}

/**
 * terminate
 */
- (void)terminate:(id _Nullable)sender {

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
 * onBochsThreadExit
 */
void BXGuiCocoaApplication::onBochsThreadExit() {
  NSLog(@"BXGuiCocoaApplication::onBochsThreadExit");
  dispatch_sync(dispatch_get_main_queue(), ^(void){
    [BXCocoaApplication->BXNSApp.bx_window_controller onBochsThreadExit];
  });
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
 * activateMenu
 */
void BXGuiCocoaApplication::activateMenu(property_t type, bool bActivate) {
  NSLog(@"BXGuiCocoaApplication::activateMenu");
  dispatch_sync(dispatch_get_main_queue(), ^(void){
    [BXCocoaApplication->BXNSApp.bx_window_controller activateMenu:type doActivate:bActivate];
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

/**
 * dimension_update
 */
void BXGuiCocoaApplication::dimension_update(unsigned x, unsigned y, unsigned fwidth, unsigned fheight, unsigned bpp) {

    dispatch_sync(dispatch_get_main_queue(), ^(void){

    // Change VGA display
    [[[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] BXVGA] changeBPP:bpp width:x height:y font_width:fwidth font_height:fheight];

    // prepare window
    [[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] setContentSize:NSMakeSize(x, y + [[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] BXToolbar].height)];

    [[[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] BXToolbar] headerbarUpdate: [[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] BXVGA]];
  });
}

/**
 * clear_screen
 */
void BXGuiCocoaApplication::clear_screen(void) {
  [[[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] BXVGA] clearScreen];
}





/**
 * create_bitmap
 */
unsigned BXGuiCocoaApplication::create_bitmap(const unsigned char *bmap, unsigned xdim, unsigned ydim) {
  return [[[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] BXToolbar] createBXBitmap:bmap xdim:xdim ydim:ydim];
}

/**
 * headerbar_bitmap
 */
unsigned BXGuiCocoaApplication::headerbar_bitmap(unsigned bmap_id, unsigned alignment, void (*f)(void)) {
  return [[[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] BXToolbar] headerbarBXBitmap:bmap_id alignment:alignment func:f];
}

/**
 * replace_bitmap
 */
void BXGuiCocoaApplication::replace_bitmap(unsigned hbar_id, unsigned bmap_id) {
  [[[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] BXToolbar] headerbarBXBitmap:hbar_id data_id:bmap_id];
}

/**
 * show_headerbar
 */
void BXGuiCocoaApplication::show_headerbar(void) {
  dispatch_sync(dispatch_get_main_queue(), ^(void){
    [[[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] BXToolbar] headerbarCreate:[[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] contentView]];
  });
}




/**
 * setup_charmap
 */
void BXGuiCocoaApplication::setup_charmap(unsigned char *charmapA, unsigned char *charmapB, unsigned char w, unsigned char h) {
  [[[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] BXVGA] initFonts:charmapA second:charmapB width:w height:h];
}

/**
 * set_font
 */
void BXGuiCocoaApplication::set_font(bool font2, unsigned pos, unsigned char *charmap) {
  [[[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] BXVGA] updateFontAt:pos isFont2:font2 map:charmap];
}

/**
 * draw_char
 */
void BXGuiCocoaApplication::draw_char(bool crsr, bool font2, unsigned char fgcolor, unsigned char bgcolor, unsigned short int charpos, unsigned short int x, unsigned short int y, unsigned char w, unsigned char h) {
  [[[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] BXVGA] paintChar:charpos isCrsr:crsr font2:font2 bgcolor:bgcolor fgcolor:fgcolor position:NSMakeRect(x, y, w, h)];
}

/**
 * palette_change
 */
bool BXGuiCocoaApplication::palette_change(unsigned char index, unsigned char red, unsigned char green, unsigned char blue) {
  return [[[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] BXVGA] setPaletteRGB:index red:red green:green blue:blue];
}



/**
 * graphics_tile_update
 */
void BXGuiCocoaApplication::graphics_tile_update(unsigned char *tile, unsigned x, unsigned y, unsigned w, unsigned h) {
  [[[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] BXVGA] clipRegion:tile position:NSMakeRect(x, y, w, h)];
}

/**
 * getVGAdisplayPtr
 */
const unsigned char * BXGuiCocoaApplication::BXGuiCocoaApplication::getVGAdisplayPtr(void) {
  return [[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] BXVGA].VGAdisplayRAM;
}

/**
 * graphics_tile_update_in_place
 */
void BXGuiCocoaApplication::graphics_tile_update_in_place(unsigned x, unsigned y, unsigned w, unsigned h) {
  [[[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] BXVGA] clipRegionPosition:NSMakeRect(x, y, w, h)];
}





/**
 * render
 */
void BXGuiCocoaApplication::render(void) {
  dispatch_sync(dispatch_get_main_queue(), ^(void){
    [[[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] BXVGA] render];
  });
}


/**
 * captureMouse
 */
void BXGuiCocoaApplication::captureMouse(bool cap, unsigned x, unsigned y) {
  [[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] captureMouse:cap];
  [[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] captureMouseXY:NSMakePoint(x, y)];
}

/**
 * hasMouseCapture
 */
bool BXGuiCocoaApplication::hasMouseCapture(void) {
  return [[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] MouseCaptureActive];
}

/**
 * hasEvent
 */
bool BXGuiCocoaApplication::hasEvent(void) {
  return [[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] hasEvent];
}

/**
 * getEvent
 */
unsigned long BXGuiCocoaApplication::getEvent(void) {
  return [[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] getEvent];
}



// EOF
