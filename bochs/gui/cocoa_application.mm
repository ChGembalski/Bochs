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
    self.name = @"bochs";

  }
  return self;
}

/**
 * main
 */
- (void)main {

  bxmain();

  // force app terminate ? direct or bypass it delayed on the main thread?
  dispatch_sync(dispatch_get_main_queue(), ^(void){
    [NSApp terminate:nil];
  });

}

@end

/////////////////////////////////
// BXNSApplication
/////////////////////////////////

@implementation BXNSApplication

vga_settings_t default_vga_settings = {
  32, 640, 480
};

/**
 * finishLaunching
 */
- (void)finishLaunching {

  // Basic App setup
  [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
  NSApp.applicationIconImage = nil;

  // Window Controller
  self.bx_window_controller = [[BXNSWindowController alloc] init:default_vga_settings.headerbar_y VGAxRes:default_vga_settings.xres VGAyRes:default_vga_settings.yres];

  // Startup NSThread running the bochs core
  self.bochsThread = [[BXBochsThread alloc] init];
  [self.bochsThread start];

  [super finishLaunching];

}

/**
 * terminate
 */
- (void)terminate:(id _Nullable)sender {

  if (self.bochsThread != nil) {
    if (self.bochsThread.executing) {
      [self.bochsThread cancel];
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

}

/**
 * beep
 */
- (void)beep {
  NSBeep();
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
    dispatch_sync(dispatch_get_main_queue(), ^(void){
      [BXCocoaApplication->BXNSApp.bx_window_controller onBochsThreadExit];
    });
}


/**
 * showWindow
 */
void BXGuiCocoaApplication::showWindow(gui_window_type_t window, bool bShow) {
  dispatch_sync(dispatch_get_main_queue(), ^(void){
    [BXCocoaApplication->BXNSApp.bx_window_controller showWindow:window doShow:bShow];
  });
}

/**
 * activateWindow
 */
void BXGuiCocoaApplication::activateWindow(gui_window_type_t window) {
  dispatch_sync(dispatch_get_main_queue(), ^(void){
    [BXCocoaApplication->BXNSApp.bx_window_controller activateWindow:window];
  });
}

/**
 * activateMenu
 */
void BXGuiCocoaApplication::activateMenu(property_t type, bool bActivate) {
  dispatch_sync(dispatch_get_main_queue(), ^(void){
    [BXCocoaApplication->BXNSApp.bx_window_controller activateMenu:type doActivate:bActivate];
  });
}

/**
 * getProperty
 */
int BXGuiCocoaApplication::getProperty(property_t property, bool bWait) {

  NSMutableArray<NSNumber *> * nsproperties;

  if (!bWait) {
    return [BXCocoaApplication->BXNSApp.bx_window_controller getProperty:property];
  }

  // wait part
  nsproperties = [[NSMutableArray alloc] init];
  [nsproperties addObject:[NSNumber numberWithInt:property]];

  [BXCocoaApplication->BXNSApp.bx_window_controller waitPropertySet:nsproperties];
  return [BXCocoaApplication->BXNSApp.bx_window_controller getProperty:property];

}

/**
 * waitPropertySet
 */
void BXGuiCocoaApplication::waitPropertySet(unsigned cnt, unsigned property, ...) {

  NSMutableArray<NSNumber *> * nsproperties;
  va_list propList;

  nsproperties = [[NSMutableArray alloc] init];
  va_start(propList, property);
  [nsproperties addObject:[NSNumber numberWithInt:property]];
  for (int no=1; no<cnt; no++) {
    [nsproperties addObject:[NSNumber numberWithInt:(unsigned)va_arg(propList, unsigned)]];
  }
  va_end(propList);

  [BXCocoaApplication->BXNSApp.bx_window_controller waitPropertySet:nsproperties];

}

/**
 * setProperty
 */
void BXGuiCocoaApplication::setProperty(property_t property, int value) {
  [BXCocoaApplication->BXNSApp.bx_window_controller setProperty:property Value:value];
}



/**
 * setSimulationState
 */
void BXGuiCocoaApplication::setSimulationState(simulation_state_t new_state) {
  
  simulation_state_t old_state;
  
  old_state = BXCocoaApplication->BXNSApp.bx_window_controller.simulation_state;
  BXCocoaApplication->BXNSApp.bx_window_controller.simulation_state = new_state;
  // special case prior state was SIM_INIT
  if (old_state == SIM_INIT) {
    dispatch_sync(dispatch_get_main_queue(), ^(void){
      [[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_CONFIGURATION] config].SIMavailable = YES;
      [[[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_CONFIGURATION] config] loadColumnZero];
    });
  }
  
}

/**
 * showModalInfo
 */
void BXGuiCocoaApplication::showModalInfo(unsigned char level, const char * prefix, const char * msg) {

  dispatch_sync(dispatch_get_main_queue(), ^(void){
    NSString * Sprefix;
    NSString * Smsg;

    Sprefix = prefix==NULL ? @"Notification" : [NSString stringWithUTF8String:prefix];
    Smsg = msg==NULL ? @"Sorry bothering you ..." : [NSString stringWithUTF8String:msg];

    [BXNSWindowController showModalInfoDialog:level Title:Sprefix Message:Smsg];
  });

}

/**
 * showModalQuestion
 */
void BXGuiCocoaApplication::showModalQuestion(unsigned char level, const char * prefix, const char * msg, int * result) {

  dispatch_sync(dispatch_get_main_queue(), ^(void){
    NSString * Sprefix;
    NSString * Smsg;

    Sprefix = prefix==NULL ? @"Notification" : [NSString stringWithUTF8String:prefix];
    Smsg = msg==NULL ? @"Sorry bothering you ..." : [NSString stringWithUTF8String:msg];

    *result = [BXNSWindowController showModalQuestionDialog:level Title:Sprefix Message:Smsg];
  });

}


/**
 * showModalParamRequest
 */
void BXGuiCocoaApplication::showModalParamRequest(void * vparam, int * result) {

  bx_param_c * param;

  param = (bx_param_c *)vparam;

  dispatch_sync(dispatch_get_main_queue(), ^(void){
    *result = [BXNSWindowController showModalParamRequestDialog:param];
  });

}


/**
 * postLogMessage
 */
void BXGuiCocoaApplication::postLogMessage(unsigned char level, unsigned char mode, const char * prefix, const char * msg) {

  NSString * msg_str;
  
  if (msg == NULL) {
    return;
  }
  if (BXCocoaApplication->BXNSApp.bx_window_controller.simulation_state == SIM_TERMINATE) {
    return;
  }
  msg_str = [NSString stringWithUTF8String:msg];
  dispatch_async(dispatch_get_main_queue(), ^(void){
    [BXCocoaApplication->BXNSApp.bx_window_controller.bx_log_queue enqueueSplit:msg_str LogLevel:level LogMode:mode];
  });
  
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
    
    if ([[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] inFullscreen]) {
      
      [[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] restoreWindowState];
      
    }
    
    // Change VGA display
    [[[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] BXVGA] changeBPP:bpp width:x height:y font_width:fwidth font_height:fheight];
 
    // prepare window
    [[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] setContentSize:NSMakeSize(x, y + [[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] BXToolbar].height)];
    
    [[[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] BXToolbar] headerbarUpdate: [[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] BXVGA]];
    
    if ([[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] inFullscreen]) {
      
      [[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] backupWindowState];
      [[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] resizeByRatio];
      
    }
    
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
unsigned BXGuiCocoaApplication::headerbar_bitmap(unsigned bmap_id, unsigned alignment, ButtonHandler handler) {
  return [[[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] BXToolbar] headerbarBXBitmap:bmap_id alignment:alignment func:handler];
}

/**
 * replace_bitmap
 */
void BXGuiCocoaApplication::replace_bitmap(unsigned hbar_id, unsigned bmap_id) {
  dispatch_async(dispatch_get_main_queue(), ^(void){
    [[[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] BXToolbar] headerbarBXBitmap:hbar_id data_id:bmap_id];
  });
}

/**
 * show_headerbar
 */
void BXGuiCocoaApplication::show_headerbar(void) {
  dispatch_async(dispatch_get_main_queue(), ^(void){
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
  dispatch_async(dispatch_get_main_queue(), ^(void){
    [[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] captureMouse:cap];
    [[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] captureMouseXY:NSMakePoint(x, y)];
  });
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

/**
 * get_clipboard_text
 */
int BXGuiCocoaApplication::get_clipboard_text(unsigned char **bytes, int *nbytes) {
  return [BXCocoaApplication->BXNSApp.bx_window_controller getClipboardText:bytes Size:nbytes];
}

/**
 * set_clipboard_text
 */
int BXGuiCocoaApplication::set_clipboard_text(char *text_snapshot, int len) {
  return [BXCocoaApplication->BXNSApp.bx_window_controller setClipboardText:text_snapshot Size:len];
}

/**
 * beep
 */
void BXGuiCocoaApplication::beep(void) {
  [BXCocoaApplication->BXNSApp beep];
}

/**
 * show_ips
 */
void BXGuiCocoaApplication::show_ips(unsigned ips_count) {
  dispatch_async(dispatch_get_main_queue(), ^(void){
    [[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] updateIPS:ips_count];
  });
}

/**
 * toggle_fullscreen
 */
void BXGuiCocoaApplication::toggle_fullscreen(bool enable) {
  dispatch_async(dispatch_get_main_queue(), ^(void){
    [[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] toggleFullscreen:enable];
  });
}


/**
 * set_tooltip
 */
void BXGuiCocoaApplication::set_tooltip(unsigned hbar_id, const char * tip) {
  dispatch_async(dispatch_get_main_queue(), ^(void){
    [[[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_VGA_DISPLAY] BXToolbar] setTooltip:hbar_id Text:tip];
  });
}





// DEBUGGER
#if BX_DEBUGGER && BX_NEW_DEBUGGER_GUI

/**
 * dbg_addOutputText
 */
void BXGuiCocoaApplication::dbg_addOutputText(char * txt) {
  NSLog(@"dbg_addOutputText");
  dispatch_sync(dispatch_get_main_queue(), ^(void){
  [[[BXCocoaApplication->BXNSApp.bx_window_controller getWindow:BX_GUI_WINDOW_DEBUGGER] outputView] appendText:[NSString stringWithUTF8String:txt]];
});
}




#endif /* BX_DEBUGGER && BX_NEW_DEBUGGER_GUI */

// EOF
