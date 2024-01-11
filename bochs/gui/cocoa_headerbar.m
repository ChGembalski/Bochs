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

unsigned char BXPalette_ColorBW[3*2] = {
  0xFF, 0xFF, 0xFF,
  0x00, 0x00, 0x00
};

extern unsigned char flip_byte(unsigned char b);


/**
 * only holding the converted data and size of image data
 */
@implementation BXHeaderbarButtonData

/**
 * BXHeaderbarButtonData CTor
 */
- (instancetype)init:(const unsigned char *) data width:(unsigned) w height:(unsigned) h {
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
 * BXHeaderbarButtonData DTor
 */
- (void)dealloc {
  CFRelease(self.data);
  [super dealloc];
}

@end

@implementation BXHeaderbarButton

/**
 * BXHeaderbarButton CTor
 */
- (instancetype)init:(NSUInteger) data_id width:(size_t) w height:(size_t) h alignment:(char) align top:(size_t) y left:(size_t) x image:(NSImage *) img func:(void (*)()) f {
  self = [super init];
  if(self) {

    self.data_id = data_id;
    self.alignment = align;
    self.position = NSMakePoint(x, y);
    self.size = NSMakeSize(w, h);
    self.func = f;
    self.button = [[NSButton alloc] initWithFrame:NSMakeRect(x, y, w, h)];
    [self.button setImage:img];
    [self.button setImagePosition:NSImageOnly];
    [self.button setTarget:self];
    [self.button setAction:@selector(mouseEvent:)];

  }
  return self;
}

/**
 * BXHeaderbarButton DTor
 */
- (void)dealloc {
  [self.button dealloc];
  [super dealloc];
}

- (void)mouseEvent: (NSButton*)button {
  if (self.func != nil) {
    BXL_DEBUG((@"Mouse Event Button"));
    ((void (*)())self.func)();
  }
}

@end

@implementation BXHeaderbar

NSMutableArray<BXHeaderbarButtonData *> * button_data;
NSMutableArray<BXHeaderbarButton *> * buttons;
unsigned last_lx;
unsigned last_rx;

/**
 * BXHeaderbar CTor
 */
- (instancetype)init:(unsigned) headerbar_y width:(unsigned) w yofs:(unsigned) y {
  self = [super init];
  if(self) {
    self.height = headerbar_y;
    self.width = w;
    self.yofs = y;
    self.visible = NO;
    last_lx = 0;
    last_rx = self.width;
    buttons = [[NSMutableArray alloc] init];
    button_data = [[NSMutableArray alloc] init];
  }
  return self;
}

/**
 * BXHeaderbar DTor
 */
- (void)dealloc {
  [button_data dealloc];
  [buttons dealloc];
  [super dealloc];
}

/**
 * createBXBitmap
 */
- (unsigned)createBXBitmap:(const unsigned char *)bmap xdim:(unsigned) x ydim:(unsigned) y {
  BXL_DEBUG(([NSString stringWithFormat:@"createBXBitmap xdim=%d ydim=%d", x, y]));

  __block NSUInteger curIdx;

  curIdx = 0;
  // get last data number
  [button_data enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
    if (idx >= curIdx) {
      curIdx = idx + 1;
    }
  }];

  [button_data addObject:[[BXHeaderbarButtonData alloc] init:bmap width:x height:y]];

  BXL_DEBUG(([NSString stringWithFormat:@"createBXBitmap idx=%lu", curIdx]));
  return curIdx;

}

/**
 * headerbarBXBitmap
 */
- (unsigned)headerbarBXBitmap:(unsigned) bmap_id alignment:(unsigned) align func:(void (*)()) f {
  BXL_DEBUG(([NSString stringWithFormat:@"headerbarBXBitmap bmap_id=%d alignment=%d func:%p", bmap_id, align, f]));

  CGColorSpaceRef colorspace;
  BXHeaderbarButtonData * rgbData;
  CGDataProviderRef provider;
  CGImageRef rgbImageRef;
  NSImage * image;
  unsigned x;
  unsigned y;
  __block NSUInteger curIdx;

  // create colorspace BW
  colorspace = CGColorSpaceCreateIndexed(CGColorSpaceCreateDeviceRGB(), 2, BXPalette_ColorBW);
  // get stored pixel
  rgbData = [button_data objectAtIndex:bmap_id];
  provider = CGDataProviderCreateWithCFData(rgbData.data);
  rgbImageRef = CGImageCreate(rgbData.width, rgbData.height, 1, 1, rgbData.width/8, colorspace, kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
  CGDataProviderRelease(provider);
  CGColorSpaceRelease(colorspace);
  image = [[[NSImage alloc] initWithCGImage:rgbImageRef size:NSZeroSize] autorelease];
  CGImageRelease(rgbImageRef);

  // calculate button position
  if (align == BX_GUI_GRAVITY_LEFT) {
    x = last_lx;
    last_lx += (BX_GUI_GAP_SIZE + rgbData.width);
  }
  if (align == BX_GUI_GRAVITY_RIGHT) {
    x = last_rx - rgbData.width;
    last_rx -= (BX_GUI_GAP_SIZE + rgbData.width);
  }
  y = self.yofs; // - self.height;

  curIdx = 0;
  // get last data number
  [buttons enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
    if (idx >= curIdx) {
      curIdx = idx + 1;
    }
  }];

  // BX_LOG(([NSString stringWithFormat:@"headerbarBXBitmap vaild %s", image.isValid?"YES":"NO"]));

  [buttons addObject: [[BXHeaderbarButton alloc] init:bmap_id width:rgbData.width height:rgbData.height alignment:align top:y left:x image:image func:f]];

  BXL_DEBUG(([NSString stringWithFormat:@"headerbarBXBitmap idx=%lu x=%d y=%d", curIdx, x, y]));
  return (curIdx);
}

/**
 * headerbarBXBitmap
 */
- (void)headerbarBXBitmap:(unsigned) btn_id data_id:(unsigned) bmap_id {

  CGColorSpaceRef colorspace;
  BXHeaderbarButtonData * rgbData;
  CGDataProviderRef provider;
  CGImageRef rgbImageRef;
  NSImage * image;
  BXHeaderbarButton * btn;

  // create colorspace BW
  colorspace = CGColorSpaceCreateIndexed(CGColorSpaceCreateDeviceRGB(), 2, BXPalette_ColorBW);
  // get stored pixel
  rgbData = [button_data objectAtIndex:bmap_id];
  provider = CGDataProviderCreateWithCFData(rgbData.data);
  rgbImageRef = CGImageCreate(rgbData.width, rgbData.height, 1, 1, rgbData.width/8, colorspace, kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
  CGDataProviderRelease(provider);
  CGColorSpaceRelease(colorspace);
  image = [[[NSImage alloc] initWithCGImage:rgbImageRef size:NSZeroSize] autorelease];
  CGImageRelease(rgbImageRef);

  btn = [buttons objectAtIndex:btn_id];
  [btn.button setImage:image];

}

/**
 * headerbarCreate
 */
-(void) headerbarCreate:(NSView *) view {

  if (self.visible) {
    return;
  }

  [buttons enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
    BXHeaderbarButton * btn;
    BXL_DEBUG(([NSString stringWithFormat:@"headerbarCreate enable idx=%lu ", idx]));
    btn = [buttons objectAtIndex:idx];
    [view addSubview:btn.button];
  }];

  self.visible = YES;

}

/**
 * headerbarUpdate
 */
-(void) headerbarUpdate:(BXVGAdisplay *) vga {

  // update from vga
  self.width = vga.width;
  self.yofs = vga.height;
  last_lx = 0;
  last_rx = self.width;

  BXL_DEBUG(([NSString stringWithFormat:@"headerbarUpdate width=%d yofs=%d", self.width, self.yofs]));

  // update positions
  [buttons enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
    BXHeaderbarButton * btn;
    unsigned x;
    unsigned y;

    btn = [buttons objectAtIndex:idx];
    // calculate button position
    if (btn.alignment == BX_GUI_GRAVITY_LEFT) {
      x = last_lx;
      last_lx += (BX_GUI_GAP_SIZE + btn.size.width);
    }
    if (btn.alignment == BX_GUI_GRAVITY_RIGHT) {
      x = last_rx - btn.size.width;
      last_rx -= (BX_GUI_GAP_SIZE + btn.size.width);
    }
    y = self.yofs;

    btn.position = NSMakePoint(x, y);
    [btn.button setFrameOrigin:btn.position];

  }];

}


@end
