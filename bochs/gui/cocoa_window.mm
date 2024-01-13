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


#if BX_SUPPORT_X86_64
  #define BOCHS_WINDOW_NAME @"Bochs x86-64 emulator MacOS X"
#else
  #define BOCHS_WINDOW_NAME @"Bochs x86 emulator MacOS X"
#endif


@interface BXNSEventQueue : NSObject

  @property (nonatomic, readonly, getter=isEmpty) BOOL isEmpty;

  - (instancetype)init;
  - (void)dealloc;

  - (void)enqueue:(UInt64) value;
  - (UInt64)dequeue;
  - (BOOL)isEmpty;

@end

@implementation BXNSEventQueue

NSMutableArray<NSNumber *> * queue;

/**
 * BXNSEventQueue
 */
- (instancetype)init {
  self = [super init];
  if(self) {

    queue = [[NSMutableArray alloc] init];

  }
  return self;
}

/**
 * BXNSEventQueue DTor
 */
- (void)dealloc {
  [queue dealloc];
  [super dealloc];
}

- (void)enqueue:(UInt64) value {
  NSNumber *obj;

  obj = [NSNumber initWithUnsignedLong:value];
  [queue addObject:obj];
}

- (UInt64)dequeue {
  NSNumber *obj;

  if ([queue count] == 0) {
    return (0);
  }
  obj = [queue objectAtIndex:0];
  if (obj == nil) {
    return (0);
  }

  [[obj retain] autorelease];
  [queue removeObjectAtIndex:0];

  return obj.unsignedLongValue;

}

- (BOOL)isEmpty {
  return [queue count] == 0;
}

@end


@interface BXGuiCocoaNSWindow : NSWindow <NSApplicationDelegate>

  @property (nonatomic, readwrite, assign) BXVGAdisplay * BXVGA;
  @property (nonatomic, readonly, getter=hasKeyEvent) BOOL hasKeyEvent;
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
  - (void)charmapVGA:(unsigned char *) dataA charmap:(unsigned char *) dataB width:(unsigned char)w height:(unsigned char) h;
  - (void)charmapVGAat:(unsigned) pos isFont2:(BOOL)font2 map:(unsigned char *) data;
  - (void)paintcharVGA:(unsigned short int) charpos isCrsr:(BOOL) crsr font2:(BOOL) f2 bgcolor:(unsigned char) bg fgcolor:(unsigned char) fg position:(NSRect) rect;
  - (BOOL)hasKeyEvent;
  - (unsigned)getKeyEvent;
  - (void)clipRegionVGA:(unsigned char *) src position:(NSRect) rect;

// -(NSButton *)createNSButtonWithImage:(const unsigned char *) data width:(size_t) w height:(size_t) h;
// -(NSArray<NSButton *> *)createToolbar;
// -(void)updateToolbar:(NSSize) size;
@end

@implementation BXGuiCocoaNSWindow

BXHeaderbar * BXToolbar;
BXNSEventQueue * BXEventQueue;

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
  [self setTitle:BOCHS_WINDOW_NAME];

  BXEventQueue = [[BXNSEventQueue alloc] init];

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
  [BXEventQueue dealloc];
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

- (void)keyDown:(NSEvent *)event {

  // modifiers
  BXL_INFO(([NSString stringWithFormat:@"keyDown window event.keyCode=%x char=%c event.modifierFlags=%lx",
    event.keyCode,
    event.charactersIgnoringModifiers==nil?'?':event.charactersIgnoringModifiers.length ==0?'?':[event.characters characterAtIndex:0],
    (unsigned long)event.modifierFlags
  ]));
  [BXEventQueue enqueue:((unsigned long)event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask) | event.keyCode];






  // UInt32 mdf;
  //
  // mdf = event.modifierFlags;
  // BXL_INFO((@"event.modifierFlags"));
  // print_buf_bits(&mdf, 1);

  // NSString *chars;
  //
  // chars = event.charactersIgnoringModifiers;
  // if (chars != nil) {
  //   if (chars.length >0) {
  //     unichar c = [event.characters characterAtIndex:0];
      // [BXEventQueue enqueue:event.keyCode];
  //   }
  // }

  // BXL_INFO(([NSString stringWithFormat:@"keyDown pressed window event.keyCode=%x char=%s", event.keyCode, event.charactersIgnoringModifiers]));
  // unichar c = [event.characters characterAtIndex:0];
  //
  // [BXEventQueue enqueue:c];

}

- (void)keyUp:(NSEvent *)event {
  // NSString *chars;
  //
  // chars = event.charactersIgnoringModifiers;
  // if (chars != nil) {
  //   if (chars.length >0) {
  //     unichar c = [event.characters characterAtIndex:0];
      // BXL_INFO(([NSString stringWithFormat:@"keyUp pressed window event.keyCode=%x char=%c ascii=%x fake=%x", event.keyCode, c, c, (c-77)]));
      BXL_INFO(([NSString stringWithFormat:@"keyUp window event.keyCode=%x char=%c event.modifierFlags=%lx",
        event.keyCode,
        event.charactersIgnoringModifiers==nil?'?':event.charactersIgnoringModifiers.length ==0?'?':[event.characters characterAtIndex:0],
        (unsigned long)event.modifierFlags
      ]));
      [BXEventQueue enqueue:MACOS_NSEventModifierFlagKeyUp | ((unsigned long)event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask) | event.keyCode];
      // [BXEventQueue enqueue:BX_KEY_RELEASED | event.keyCode];
    // }
  // }



  // BXL_INFO(([NSString stringWithFormat:@"keyUp pressed window event.keyCode=%x char=%s", event.keyCode, event.characters]));
  // unichar c = [event.characters characterAtIndex:0];
  //
  // [BXEventQueue enqueue:BX_KEY_RELEASED | c];

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
- (void)charmapVGA:(unsigned char *) dataA charmap:(unsigned char *) dataB width:(unsigned char)w height:(unsigned char) h {
  [self.BXVGA initFonts:dataA second:dataB width:w height:h];
}

/**
 * update charmap data at
 */
- (void)charmapVGAat:(unsigned) pos isFont2:(BOOL)font2 map:(unsigned char *) data {
  [self.BXVGA updateFontAt:pos isFont2:font2 map:data];
}

/**
 * paint char on VGA display
 */
- (void)paintcharVGA:(unsigned short int) charpos isCrsr:(BOOL) crsr font2:(BOOL) f2 bgcolor:(unsigned char) bg fgcolor:(unsigned char) fg position:(NSRect) rect {
  [self.BXVGA paintChar:charpos isCrsr:crsr font2:f2 bgcolor:bg fgcolor:fg position:rect];
}

/**
 * getter hasKeyEvent
 */
- (BOOL)hasKeyEvent {
  return !BXEventQueue.isEmpty;
}

/**
 * return the keyEvent
 * if none exist return 0
 */
- (unsigned)getKeyEvent {
  return [BXEventQueue dequeue];
}

/**
 * clip bitmap region into VGA display
 */
- (void)clipRegionVGA:(unsigned char *)src position:(NSRect) rect {
  [self.BXVGA clipRegion:src position:rect];
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
void BXGuiCocoaWindow::dimension_update(unsigned x, unsigned y, unsigned fwidth, unsigned fheight, unsigned bpp) {

  NSRect windowFrame;
  NSRect newWindowFrame;

  // Change VGA display
  [BXCocoaWindow->BXWindow.BXVGA changeBPP:bpp width:x height:y font_width:fwidth font_height:fheight];

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
void BXGuiCocoaWindow::setup_charmap(unsigned char *charmapA, unsigned char *charmapB, unsigned char w, unsigned char h) {
  [BXCocoaWindow->BXWindow charmapVGA:charmapA charmap:charmapB width:w height:h];
}

/**
 * set_font
 */
void BXGuiCocoaWindow::set_font(bool font2, unsigned pos, unsigned char *charmap) {
  [BXCocoaWindow->BXWindow charmapVGAat:pos isFont2:font2 map:charmap];
}


/**
 * draw_char
 */
void BXGuiCocoaWindow::draw_char(bool crsr, bool font2, unsigned char fgcolor, unsigned char bgcolor, unsigned short int charpos, unsigned short int x, unsigned short int y, unsigned char w, unsigned char h) {
  [BXCocoaWindow->BXWindow paintcharVGA:charpos isCrsr:crsr font2:font2 bgcolor:bgcolor fgcolor:fgcolor position:NSMakeRect(x, y, w, h)];
}

/**
 * hasKeyEvent
 */
bool BXGuiCocoaWindow::hasKeyEvent() {
  return (BXCocoaWindow->BXWindow.hasKeyEvent);
}

/**
 * getKeyEvent
 */
unsigned BXGuiCocoaWindow::getKeyEvent() {
  return ([BXCocoaWindow->BXWindow getKeyEvent]);
}

/**
 * graphics_tile_update
 */
void BXGuiCocoaWindow::graphics_tile_update(unsigned char *tile, unsigned x, unsigned y, unsigned w, unsigned h) {
  [BXCocoaWindow->BXWindow clipRegionVGA:tile position:NSMakeRect(x, y, w, h)];
}








// EOF
