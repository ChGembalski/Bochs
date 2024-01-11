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
#include "cocoa_logging.h"
#include "cocoa_window.h"
#include "cocoa_headerbar.h"


// #define BX_NAVBAR_HEIGHT 32
//
// unsigned char BXpalette_colorBW[3*2] = {
//   0xFF, 0xFF, 0xFF,
//   0x00, 0x00, 0x00
// };

// unsigned char reverse(unsigned char b) {
//    b = (b & 0xF0) >> 4 | (b & 0x0F) << 4;
//    b = (b & 0xCC) >> 2 | (b & 0x33) << 2;
//    b = (b & 0xAA) >> 1 | (b & 0x55) << 1;
//    return b;
// }

@interface BXGuiCocoaNSWindow : NSWindow <NSApplicationDelegate>
  @property (nonatomic, readwrite, assign) BXVGAdisplay * BXVGA;
  - (instancetype)init:(unsigned) headerbar_y VGAsize:(NSSize) vga;
  - (void)dealloc;

  - (unsigned)createBXBitmap:(const unsigned char *)bmap xdim:(unsigned) x ydim:(unsigned) y;
  - (unsigned)headerbarBXBitmap:(unsigned) bmap_id alignment:(unsigned) align func:(void (*)()) f;
  - (void)headerbarCreate;
  - (void)headerbarUpdate;
  - (void)headerbarSwitchBXBitmap:(unsigned) btn_id data_id:(unsigned) bmap_id;
  - (unsigned)getHeaderbarHeight;
  - (void)renderVGA;
  - (BOOL)changeVGApalette:(unsigned)index red:(char) r green:(char) g blue:(char) b;
  - (void)clearVGAscreen;
  - (void)charmapVGA:(unsigned char *) dataA charmap:(unsigned char *) dataB;
  - (void)charmapVGAat:(unsigned) pos first:(unsigned char *) dataA second:(unsigned char *) dataB;
  - (void)paintcharVGA:(unsigned short int) charpos font2:(BOOL) f2 bgcolor:(unsigned char) bg fgcolor:(unsigned char) fg position:(NSRect) rect;


// -(NSButton *)createNSButtonWithImage:(const unsigned char *) data width:(size_t) w height:(size_t) h;
// -(NSArray<NSButton *> *)createToolbar;
// -(void)updateToolbar:(NSSize) size;
@end

@implementation BXGuiCocoaNSWindow

BXHeaderbar * BXToolbar;

/**
 * BXGuiCocoaNSWindow CTor
 */
- (instancetype)init:(unsigned) headerbar_y VGAsize:(NSSize) vga {

  BXL_DEBUG(@"BXGuiCocoaNSWindow::init");

  [super initWithContentRect:NSMakeRect(0, 0, vga.width, vga.height + headerbar_y)
         styleMask: NSWindowStyleMaskTitled |
                    NSWindowStyleMaskClosable |
                    NSWindowStyleMaskMiniaturizable
           backing: NSBackingStoreBuffered
             defer: NO
  ];
// |                    NSWindowStyleMaskResizable
  [NSApp setDelegate:self];
  [NSApp setDelegate:[self contentView]];
  [self setTitle:@"Bochs for MacOsX"];

  // Setup VGA display
  self.BXVGA = [[BXVGAdisplay alloc] init:8 width:vga.width height:vga.height font_width:0 font_height:0 view:[self contentView]];

  // setup Toolbar
  BXToolbar = [[BXHeaderbar alloc] init:headerbar_y width:self.BXVGA.width yofs:self.BXVGA.height];



  [self center];
  [self setIsVisible:YES];
  [self makeKeyAndOrderFront:self];
  // [self makeFirstResponder: [self contentView] ];


  BXL_INFO(([NSString stringWithFormat:@"keyWindow %s", self.keyWindow?"YES":"NO"]));

  return self;
}

/**
 * BXGuiCocoaNSWindow DTor
 */
- (void)dealloc {
  [self.BXVGA dealloc];
  [BXToolbar dealloc];
  [super dealloc];
}

- (BOOL)windowShouldClose:(id)sender {
  [NSApp terminate:sender];
  return YES;
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (BOOL)canBecomeMainWindow {
    return YES;
}

- (void)keyDown:(NSEvent *)theEvent {

  BXL_INFO(([NSString stringWithFormat:@"keyDown pressed window"]));

}

- (void)keyUp:(NSEvent *)event {
  BXL_INFO(([NSString stringWithFormat:@"keyUp pressed window"]));
}


/**
 * createBXBitmap forwarding
 */
- (unsigned)createBXBitmap:(const unsigned char *)bmap xdim:(unsigned) x ydim:(unsigned) y {
  return ([BXToolbar createBXBitmap:bmap xdim:x ydim:y]);
}

/**
 * headerbarBXBitmap forwarding
 */
- (unsigned)headerbarBXBitmap:(unsigned) bmap_id alignment:(unsigned) align func:(void (*)()) f {
  return ([BXToolbar headerbarBXBitmap:bmap_id alignment:align func:f]);
}

/**
 * create new headerbar
 * multiple calls allowed
 */
- (void)headerbarCreate {
  [BXToolbar headerbarCreate:[self contentView]];
}

/**
 * update headerbar
 */
- (void)headerbarUpdate {
  [BXToolbar headerbarUpdate:self.BXVGA];
}

/**
 * change image in headerbar
 */
- (void)headerbarSwitchBXBitmap:(unsigned) btn_id data_id:(unsigned) bmap_id {
  [BXToolbar headerbarBXBitmap:btn_id data_id:bmap_id];
}

- (unsigned)getHeaderbarHeight {
  return (BXToolbar.height);
}

/**
 * render VGA display
 */
- (void)renderVGA {
  [self.BXVGA render];
}

/**
 * change one VGA palette entry
 */
- (BOOL)changeVGApalette:(unsigned)index red:(char) r green:(char) g blue:(char) b {
  return [self.BXVGA setPaletteRGB:index red:r green:g blue:b];
}

/**
 * clear the VGA screen
 */
- (void)clearVGAscreen {
  [self.BXVGA clearScreen];
}

/**
 * init charmap data
 */
- (void)charmapVGA:(unsigned char *) dataA charmap:(unsigned char *) dataB {
  [self.BXVGA initFonts:dataA second:dataB];
}

/**
 * update charmap data at
 */
- (void)charmapVGAat:(unsigned) pos first:(unsigned char *) dataA second:(unsigned char *) dataB {
  [self.BXVGA updateFontAt:pos first:dataA second:dataB];
}

/**
 * paint char on VGA display
 */
- (void)paintcharVGA:(unsigned short int) charpos font2:(BOOL) f2 bgcolor:(unsigned char) bg fgcolor:(unsigned char) fg position:(NSRect) rect {
  [self.BXVGA paintChar:charpos font2:f2 bgcolor:bg fgcolor:fg position:rect];
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
BXGuiCocoaWindow::BXGuiCocoaWindow(unsigned x, unsigned y, unsigned headerbar_y) : BXCocoaWindow(new BXGuiCocoaWindowImpl) {
  BXCocoaWindow->BXWindow = [[[BXGuiCocoaNSWindow alloc] init:headerbar_y VGAsize:NSMakeSize(x, y)] autorelease];
  // [BXCocoaWindow->BXWindow makeKeyWindow];
  // [self makeMainWindow];

}

/**
 * BXGuiCocoaWindow DTor
 */
BXGuiCocoaWindow::~BXGuiCocoaWindow() {
  if (BXCocoaWindow) {
    // [BXCocoaWindow->BXWindow release];
    [BXCocoaWindow->BXWindow performClose:nil];
  }
}

/**
 * create_bitmap
 */
unsigned BXGuiCocoaWindow::create_bitmap(const unsigned char *bmap, unsigned xdim, unsigned ydim) {
  return ([BXCocoaWindow->BXWindow createBXBitmap:bmap xdim:xdim ydim:ydim]);
}

/**
 * headerbar_bitmap
 */
unsigned BXGuiCocoaWindow::headerbar_bitmap(unsigned bmap_id, unsigned alignment, void (*f)(void)) {
  return ([BXCocoaWindow->BXWindow headerbarBXBitmap:bmap_id alignment:alignment func:f]);
}

/**
 * show_headerbar
 */
void BXGuiCocoaWindow::show_headerbar(void) {
  [BXCocoaWindow->BXWindow headerbarCreate];
}

/**
 * dimension_update
 */
void BXGuiCocoaWindow::dimension_update(unsigned x, unsigned y, unsigned fheight, unsigned fwidth, unsigned bpp) {

  NSRect windowFrame;
  NSRect newWindowFrame;

  // Change VGA display
  [BXCocoaWindow->BXWindow.BXVGA changeBPP:bpp width:x height:y font_width:fheight font_height:fwidth];

  // prepare window
  windowFrame = [BXCocoaWindow->BXWindow contentRectForFrameRect:[BXCocoaWindow->BXWindow frame]];
  newWindowFrame = [BXCocoaWindow->BXWindow frameRectForContentRect:NSMakeRect( NSMinX( windowFrame ), NSMinY( windowFrame ), x, y + BXCocoaWindow->BXWindow.getHeaderbarHeight)];

  [BXCocoaWindow->BXWindow setContentSize:NSMakeSize(x, y + BXCocoaWindow->BXWindow.getHeaderbarHeight)];

  [BXCocoaWindow->BXWindow headerbarUpdate];

  //[BXCocoaWindow->BXWindow setFrame:newWindowFrame display:YES animate:[BXCocoaWindow->BXWindow isVisible]];

}

/**
 * render
 */
void BXGuiCocoaWindow::render(void) {
  [BXCocoaWindow->BXWindow renderVGA];
}

/**
 * palette_change
 */
bool BXGuiCocoaWindow::palette_change(unsigned char index, unsigned char red, unsigned char green, unsigned char blue) {
  return ([BXCocoaWindow->BXWindow changeVGApalette:index red:red green:green blue:blue]);
}

/**
 * clear_screen
 */
void BXGuiCocoaWindow::clear_screen(void) {
  [BXCocoaWindow->BXWindow clearVGAscreen];
}

/**
 * replace_bitmap
 */
void BXGuiCocoaWindow::replace_bitmap(unsigned hbar_id, unsigned bmap_id) {
  [BXCocoaWindow->BXWindow headerbarSwitchBXBitmap:hbar_id data_id:bmap_id];
}

/**
 * setup_charmap
 */
void BXGuiCocoaWindow::setup_charmap(unsigned char *charmapA, unsigned char *charmapB) {
  [BXCocoaWindow->BXWindow charmapVGA:charmapA charmap:charmapB];
}

/**
 * set_font
 */
void BXGuiCocoaWindow::set_font(unsigned pos, unsigned char *charmapA, unsigned char *charmapB) {
  [BXCocoaWindow->BXWindow charmapVGAat:pos first:charmapA second:charmapB];
}


/**
 * draw_char
 */
void BXGuiCocoaWindow::draw_char(bool font2, unsigned char fgcolor, unsigned char bgcolor, unsigned short int charpos, unsigned short int x, unsigned short int y, unsigned char w, unsigned char h) {
  // BXL_INFO(([NSString stringWithFormat:@"draw_char x=%d y=%d Rx=%f Ry=%f", x, y, (NSMakeRect(x, y, w, h).origin.x), (NSMakeRect(x, y, w, h).origin.y)]));
  [BXCocoaWindow->BXWindow paintcharVGA:charpos font2:font2 bgcolor:bgcolor fgcolor:fgcolor position:NSMakeRect(x, y, w, h)];
}













// EOF
