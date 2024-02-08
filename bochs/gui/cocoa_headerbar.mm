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
#include "cocoa_headerbar.h"
#include "icon_bochs.xpm"

unsigned char BXPalette_ColorBW[3*2] = {
  0xFF, 0xFF, 0xFF,
  0x00, 0x00, 0x00
};

extern unsigned char flip_byte(unsigned char b);


////////////////////////////////////////////////////////////////////////////////
// BXNSHeaderBarButtonData
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSHeaderBarButtonData

/**
 * init
 */
- (instancetype _Nonnull)init:(const unsigned char * _Nonnull) data width:(unsigned) w height:(unsigned) h {

  self = [super init];
  if(self) {
    
    unsigned char flip_buffer[(w*h)/8];

    self.width = w;
    self.height = h;
    self.size = (w*h/8);

    // must flip the buffer content first
    for (int i=0; i<(self.size);i++) {
      flip_buffer[i] = flip_byte(data[i]);
    }

    self.data = CFDataCreate(NULL, flip_buffer, self.size);
    
  }

  return self;

}

/**
 * dealloc
 */
- (void)dealloc {

  CFRelease(self.data);

}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSHeaderBarButton
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSHeaderBarButton

/**
 * init
 */
- (instancetype)init:(NSUInteger) data_id width:(size_t) w height:(size_t) h alignment:(char) align top:(size_t) y left:(size_t) x image:(NSImage * _Nonnull) img func:(ButtonHandler _Nullable) handler {

  self = [super init];
  if(self) {

    self.data_id = data_id;
    self.alignment = align;
    self.position = NSMakePoint(x, y);
    self.size = NSMakeSize(w, h);
    self.handler = handler;
    self.button = [[NSButton alloc] initWithFrame:NSMakeRect(x, y, w, h)];
    [self.button setImage:img];
    [self.button setImagePosition:NSImageOnly];
    [self.button setTarget:self];
    [self.button setAction:@selector(mouseEvent:)];

  }

  return self;

}

/**
 * mouseEvent
 */
- (void)mouseEvent: (NSButton* _Nonnull)button {

  if (self.handler != nil) {
    [[[NSThread alloc] initWithBlock:^{
      self.handler();
    }] start];
  }

}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSHeaderBarView
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSHeaderBarView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {
    
    [self setWantsLayer:YES];
    [self.layer setBackgroundColor:[NSColor.controlColor CGColor]];
    
  }

  return self;

}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSHeaderBar
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSHeaderBar






/**
 * init
 */
- (instancetype _Nonnull)init:(unsigned) headerbar_y width:(unsigned) w yofs:(unsigned) y {

  self = [super init];
  if(self) {
    
    self.height = headerbar_y;
    self.width = w;
    self.yofs = y;
    self.created = NO;
    self.last_lx = 0;
    self.last_rx = self.width;
    self.button_view = [[BXNSHeaderBarView alloc] initWithFrame:NSMakeRect(0, y, w, headerbar_y)];
    self.buttons = [[NSMutableArray alloc] init];
    self.button_data = [[NSMutableArray alloc] init];
    
  }

  return self;

}

/**
 * createBXBitmap
 */
- (unsigned)createBXBitmap:(const unsigned char * _Nonnull)bmap xdim:(unsigned) x ydim:(unsigned) y {

  __block NSUInteger curIdx;

  curIdx = 0;
  // get last data number
  [self.button_data enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
    if (idx >= curIdx) {
      curIdx = idx + 1;
    }
  }];

  [self.button_data addObject:[[BXNSHeaderBarButtonData alloc] init:bmap width:x height:y]];

  BXL_DEBUG(([NSString stringWithFormat:@"createBXBitmap xdim=%d ydim=%d idx=%lu", x, y, curIdx]));

  return curIdx;

}

/**
 * headerbarBXBitmap
 */
- (unsigned)headerbarBXBitmap:(unsigned) bmap_id alignment:(unsigned) align func:(ButtonHandler _Nullable) handler {

  CGColorSpaceRef colorspace;
  BXNSHeaderBarButtonData * rgbData;
  CGDataProviderRef provider;
  CGImageRef rgbImageRef;
  NSImage * image;
  unsigned x;

  __block NSUInteger curIdx;

  // create colorspace BW
  colorspace = CGColorSpaceCreateIndexed(CGColorSpaceCreateDeviceRGB(), 2, BXPalette_ColorBW);
  // get stored pixel
  rgbData = [self.button_data objectAtIndex:bmap_id];
  provider = CGDataProviderCreateWithCFData(rgbData.data);
  rgbImageRef = CGImageCreate(rgbData.width, rgbData.height, 1, 1, rgbData.width/8, colorspace, kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
  CGDataProviderRelease(provider);
  CGColorSpaceRelease(colorspace);
  image = [[NSImage alloc] initWithCGImage:rgbImageRef size:NSZeroSize];
  CGImageRelease(rgbImageRef);

  // calculate button position
  if (align == BX_GUI_GRAVITY_LEFT) {
    x = self.last_lx;
    self.last_lx += (BX_GUI_GAP_SIZE + rgbData.width);
  }
  if (align == BX_GUI_GRAVITY_RIGHT) {
    x = self.last_rx - rgbData.width;
    self.last_rx -= (BX_GUI_GAP_SIZE + rgbData.width);
  }

  curIdx = 0;
  // get last data number
  [self.buttons enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
    if (idx >= curIdx) {
      curIdx = idx + 1;
    }
  }];

  [self.buttons addObject: [[BXNSHeaderBarButton alloc] init:bmap_id width:rgbData.width height:rgbData.height alignment:align top:0 left:x image:image func:handler]];
  BXL_DEBUG(([NSString stringWithFormat:@"headerbarBXBitmap bmap_id=%d alignment=%d func:%p idx=%lu x=%d", bmap_id, align, handler, curIdx, x]));

  return curIdx;

}

/**
 * headerbarBXBitmap
 */
- (void)headerbarBXBitmap:(unsigned) btn_id data_id:(unsigned) bmap_id {

  CGColorSpaceRef colorspace;
  BXNSHeaderBarButtonData * rgbData;
  CGDataProviderRef provider;
  CGImageRef rgbImageRef;
  NSImage * image;
  BXNSHeaderBarButton * btn;

  // create colorspace BW
  colorspace = CGColorSpaceCreateIndexed(CGColorSpaceCreateDeviceRGB(), 2, BXPalette_ColorBW);
  // get stored pixel
  rgbData = [self.button_data objectAtIndex:bmap_id];
  provider = CGDataProviderCreateWithCFData(rgbData.data);
  rgbImageRef = CGImageCreate(rgbData.width, rgbData.height, 1, 1, rgbData.width/8, colorspace, kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
  CGDataProviderRelease(provider);
  CGColorSpaceRelease(colorspace);
  image = [[NSImage alloc] initWithCGImage:rgbImageRef size:NSZeroSize];
  CGImageRelease(rgbImageRef);

  btn = [self.buttons objectAtIndex:btn_id];
  [btn.button setImage:image];

  BXL_DEBUG(([NSString stringWithFormat:@"headerbarBXBitmap bmap_id=%d btn_id=%d", bmap_id, btn_id]));

}

/**
 * headerbarCreate
 */
- (void)headerbarCreate:(NSView * _Nonnull) view {

  if (self.created) {
    return;
  }

  [view addSubview:self.button_view];

  [self.buttons enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
    BXNSHeaderBarButton * btn;
    BXL_DEBUG(([NSString stringWithFormat:@"headerbarCreate enable idx=%lu ", idx]));
    btn = [self.buttons objectAtIndex:idx];
    [self.button_view addSubview:btn.button];
  }];

  self.created = YES;

}

/**
 * headerbarUpdate
 */
- (void)headerbarUpdate:(BXVGAdisplay * _Nonnull) vga {

  // update from vga
  self.width = vga.width;
  self.yofs = vga.height;
  self.last_lx = 0;
  self.last_rx = self.width;

  BXL_DEBUG(([NSString stringWithFormat:@"headerbarUpdate width=%d yofs=%d", self.width, self.yofs]));

  self.button_view.frame = NSMakeRect(0, self.yofs, self.width, self.height);

  // update positions
  [self.buttons enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
    BXNSHeaderBarButton * btn;
    unsigned x;

    btn = [self.buttons objectAtIndex:idx];
    // calculate button position
    if (btn.alignment == BX_GUI_GRAVITY_LEFT) {
      x = self.last_lx;
      self.last_lx += (BX_GUI_GAP_SIZE + btn.size.width);
    }
    if (btn.alignment == BX_GUI_GRAVITY_RIGHT) {
      x = self.last_rx - btn.size.width;
      self.last_rx -= (BX_GUI_GAP_SIZE + btn.size.width);
    }

    btn.position = NSMakePoint(x, 0);
    [btn.button setFrameOrigin:btn.position];

  }];

}

@end
