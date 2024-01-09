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

  -(unsigned) createBXBitmap:(const unsigned char *)bmap xdim:(unsigned) x ydim:(unsigned) y;
  -(unsigned) headerbarBXBitmap:(unsigned) bmap_id alignment:(unsigned) align func:(void (*)()) f;
  -(void) headerbarCreate;
  -(void) headerbarUpdate;
  -(unsigned) getHeaderbarHeight;

// -(NSButton *)createNSButtonWithImage:(const unsigned char *) data width:(size_t) w height:(size_t) h;
// -(NSArray<NSButton *> *)createToolbar;
-(void)updateToolbar:(NSSize) size;
@end

@implementation BXGuiCocoaNSWindow

BXHeaderbar * BXToolbar;


// NSSize VGAsize;
// NSArray<NSButton *> * toolbar;
// NSToolbar * BXtoolbar;
// NSTextField* label;
// NSButton * BXbutton1;
// NSImage * BXbutton1image;
// NSData * BXbutton1imagedata;

/**
 * BXGuiCocoaNSWindow CTor
 */
- (instancetype)init:(unsigned) headerbar_y VGAsize:(NSSize) vga {

  BX_LOG(@"BXGuiCocoaNSWindow::init");

  [super initWithContentRect:NSMakeRect(0, 0, vga.width, vga.height + headerbar_y)
         styleMask: NSWindowStyleMaskTitled |
                    NSWindowStyleMaskClosable |
                    NSWindowStyleMaskMiniaturizable |
                    NSWindowStyleMaskResizable
           backing: NSBackingStoreBuffered
             defer: NO
  ];

  [NSApp setDelegate:self];
  [NSApp setDelegate:[self contentView]];
  [self setTitle:@"Bochs for MacOsX"];

  // Setup VGA display
  self.BXVGA = [[BXVGAdisplay alloc] init:8 width:vga.width height:vga.height font_width:0 font_height:0];

  // setup Toolbar
  BXToolbar = [[BXHeaderbar alloc] init:headerbar_y width:self.BXVGA.width yofs:self.BXVGA.height];

  // [[self contentView] addSubview:BXbutton1];
  // [[self contentView] addSubview:label];
  [self center];
  [self setIsVisible:YES];
  [self makeKeyAndOrderFront:self];


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

/**
 * createBXBitmap forwarding
 */
-(unsigned) createBXBitmap:(const unsigned char *)bmap xdim:(unsigned) x ydim:(unsigned) y {
  return ([BXToolbar createBXBitmap:bmap xdim:x ydim:y]);
}

/**
 * headerbarBXBitmap forwarding
 */
-(unsigned) headerbarBXBitmap:(unsigned) bmap_id alignment:(unsigned) align func:(void (*)()) f {
  return ([BXToolbar headerbarBXBitmap:bmap_id alignment:align func:f]);
}

/**
 * create new headerbar
 */
-(void) headerbarCreate {
  [BXToolbar headerbarCreate:[self contentView]];
}

-(void) headerbarUpdate {
  [BXToolbar headerbarUpdate:self.BXVGA];
  // [self display];
  // [[self contentView] setNeedsDisplay:YES];
  // [NSApp setWindowsNeedUpdate:YES];
}

-(unsigned) getHeaderbarHeight {
  return (BXToolbar.height);
}




// /**
//  * create a Button from char data
//  */
// -(NSButton *)createNSButtonWithImage:(const unsigned char *) data width:(size_t) w height:(size_t) h {
//
//   NSButton * result;
//   NSRect windowFrame;
//   NSImage * image;
//   CGColorSpaceRef colorspace;
//   CFDataRef rgbData;
//   CGDataProviderRef provider;
//   CGImageRef rgbImageRef;
//   unsigned char * flip_buffer;
//   size_t buttony;
//
//   windowFrame = [self contentRectForFrameRect:[self frame]];
//   // int screenHeight = [[NSScreen mainScreen] frame].size.height;
//   // int screenHeight = [ self.screen frame].size.height;
//   //screenHeight - y - windowHeight
//
//   if (VGAsize.height == 300) {
//     buttony = VGAsize.height - BX_NAVBAR_HEIGHT;
//   } else {
//     buttony = 150;
//   }
//
//   result = [[[NSButton alloc] initWithFrame:NSMakeRect(0, buttony, w, h)] autorelease];
//
//   flip_buffer = new unsigned char [(w * h)/8];
//   for (int i=0; i<(w * h)/8;i++) {
//     flip_buffer[i] = reverse(data[i]);
//   }
//
//   colorspace = CGColorSpaceCreateIndexed(CGColorSpaceCreateDeviceRGB(), 2, BXpalette_colorBW);
//   rgbData = CFDataCreate(NULL, flip_buffer, (w * h)/8);
//   provider = CGDataProviderCreateWithCFData(rgbData);
//   rgbImageRef = CGImageCreate(w, h, 1, 1, w/8, colorspace, kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
//   CFRelease(rgbData);
//   CGDataProviderRelease(provider);
//   CGColorSpaceRelease(colorspace);
//
//   image = [[[NSImage alloc] initWithCGImage:rgbImageRef size:NSZeroSize] autorelease];
//
//   CGImageRelease(rgbImageRef);
//   delete flip_buffer;
//
//   [result setImage:image];
//   [result setImagePosition:NSImageOnly];
//
//   return result;
// }



-(void)updateToolbar:(NSSize) size {
  BX_LOG(([NSString stringWithFormat:@"updateToolbar width=%d height=%d", (int)size.width, (int)size.height]));
  // BXbutton1.frame = NSMakeRect(0, VGAsize.height , 32, 32);
  // [BXbutton1 setHidden:YES];
}

// -(NSImage *)createFromByteArray {
//   NSImage * result;
//   CGColorSpaceRef colorspace;
//   CFDataRef rgbData;
//   CGDataProviderRef provider;
//   CGImageRef rgbImageRef;
//
//   unsigned char palette[3*2] = {
//     0xFF, 0xFF, 0xFF,
//     0x00, 0x00, 0x00
//   };
//
//   unsigned char * bx_power_bmap_flip = new unsigned char [(BX_POWER_BMAP_X * BX_POWER_BMAP_Y)/8];
//   for (int i=0; i<(BX_POWER_BMAP_X * BX_POWER_BMAP_Y)/8;i++) {
//     bx_power_bmap_flip[i] = reverse(bx_power_bmap[i]);
//   }
//   // colorspace = CGColorSpaceCreateDeviceRGB();
//   colorspace = CGColorSpaceCreateIndexed(CGColorSpaceCreateDeviceRGB(), 2, palette);
//   rgbData = CFDataCreate(NULL, bx_power_bmap_flip, (BX_POWER_BMAP_X * BX_POWER_BMAP_Y)/8);
//   // rgbData = CFDataCreate(NULL, bx_disk_amiga, 48 * 41 * 3);
//   provider = CGDataProviderCreateWithCFData(rgbData);
//   rgbImageRef = CGImageCreate(BX_POWER_BMAP_X, BX_POWER_BMAP_Y, 1, 1, BX_POWER_BMAP_X/8, colorspace, kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
//   // rgbImageRef = CGImageCreate(48, 41, 8, 24, 48*3, colorspace, kCGBitmapByteOrderDefault, provider, NULL, true, kCGRenderingIntentDefault);
//   CFRelease(rgbData);
//   CGDataProviderRelease(provider);
//   CGColorSpaceRelease(colorspace);
//
//   // use the created CGImage
//   result = [[NSImage alloc] initWithCGImage:rgbImageRef size:NSZeroSize];
//
//   CGImageRelease(rgbImageRef);
//   return result;
// }




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
}

/**
 * BXGuiCocoaWindow DTor
 */
BXGuiCocoaWindow::~BXGuiCocoaWindow() {
  if (BXCocoaWindow)
    [BXCocoaWindow->BXWindow release];
}

// BXGuiCocoaNSWindow * BXGuiCocoaWindow::getWindow(void) {
//   return (BXCocoaWindow->BXWindow);
// }

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

  // reallocate BXVGA ...
  [BXCocoaWindow->BXWindow.BXVGA dealloc];

  // Setup VGA display
  BXCocoaWindow->BXWindow.BXVGA = [[BXVGAdisplay alloc] init:bpp width:x height:y font_width:fheight font_height:fwidth];

  // prepare window
  windowFrame = [BXCocoaWindow->BXWindow contentRectForFrameRect:[BXCocoaWindow->BXWindow frame]];
  newWindowFrame = [BXCocoaWindow->BXWindow frameRectForContentRect:NSMakeRect( NSMinX( windowFrame ), NSMinY( windowFrame ), x, y + BXCocoaWindow->BXWindow.getHeaderbarHeight)];

  [BXCocoaWindow->BXWindow setContentSize:NSMakeSize(x, y + BXCocoaWindow->BXWindow.getHeaderbarHeight)];

  [BXCocoaWindow->BXWindow headerbarUpdate];

  //[BXCocoaWindow->BXWindow setFrame:newWindowFrame display:YES animate:[BXCocoaWindow->BXWindow isVisible]];

}








// /**
//  * setVGAsize
//  * set the new VGA size
//  */
// void BXGuiCocoaWindow::setVGAsize(unsigned x, unsigned y) {
//
//   NSRect windowFrame;
//   NSRect newWindowFrame;
//
//   BXCocoaWindow->BXWindow.BXVGA.width = x;
//   BXCocoaWindow->BXWindow.BXVGA.height = y;
//
//   windowFrame = [BXCocoaWindow->BXWindow contentRectForFrameRect:[BXCocoaWindow->BXWindow frame]];
//   newWindowFrame = [BXCocoaWindow->BXWindow frameRectForContentRect:NSMakeRect( NSMinX( windowFrame ), NSMinY( windowFrame ), x, y + BXCocoaWindow->BXWindow.getHeaderbarHeight)];
//   [BXCocoaWindow->BXWindow updateToolbar:VGAsize];
//   [BXCocoaWindow->BXWindow setFrame:newWindowFrame display:YES animate:[BXCocoaWindow->BXWindow isVisible]];
//
// }
