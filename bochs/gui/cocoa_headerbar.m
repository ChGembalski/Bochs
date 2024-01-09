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

unsigned char flip_byte(unsigned char b) {
   b = (b & 0xF0) >> 4 | (b & 0x0F) << 4;
   b = (b & 0xCC) >> 2 | (b & 0x33) << 2;
   b = (b & 0xAA) >> 1 | (b & 0x55) << 1;
   return b;
}

@implementation BXVGAdisplay

/**
 * BXHeaderbarButtonData CTor
 */
- (instancetype)init:(unsigned) bpp width:(unsigned) w height:(unsigned) h font_width:(unsigned) fw font_height:(unsigned) fh {
  self = [super init];
  if(self) {

    self.width = w;
    self.height = h;
    self.font_width = fw;
    self.font_height = fh;

  }
  return self;
}

/**
 * BXHeaderbarButtonData DTor
 */
- (void)dealloc {
  [super dealloc];
}

@end


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
  [super dealloc];
  CFRelease(self.data);
}

@end

@implementation BXHeaderbarButton

/**
 * BXHeaderbarButton CTor
 */
- (instancetype)init:(NSUInteger) data_id width:(size_t) w height:(size_t) h alignment:(char) align top:(size_t) y left:(size_t) x image:(NSImage *) img {
  self = [super init];
  if(self) {

    self.data_id = data_id;
    self.alignment = align;
    self.position = NSMakePoint(x, y);
    self.size = NSMakeSize(w, h);
    self.button = [[NSButton alloc] initWithFrame:NSMakeRect(x, y, w, h)];
    [self.button setImage:img];
    [self.button setImagePosition:NSImageOnly];

  }
  return self;
}

/**
 * BXHeaderbarButton DTor
 */
- (void)dealloc {
  [super dealloc];
  [self.button dealloc];
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
  [super dealloc];
  [buttons dealloc];
  [button_data dealloc];
}

/**
 * createBXBitmap
 */
- (unsigned)createBXBitmap:(const unsigned char *)bmap xdim:(unsigned) x ydim:(unsigned) y {
  BX_LOG(([NSString stringWithFormat:@"createBXBitmap xdim=%d ydim=%d", x, y]));

  __block NSUInteger curIdx;

  curIdx = 0;
  // get last data number
  [button_data enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
    if (idx >= curIdx) {
      curIdx = idx + 1;
    }
  }];

  [button_data addObject:[[BXHeaderbarButtonData alloc] init:bmap width:x height:y]];

  BX_LOG(([NSString stringWithFormat:@"createBXBitmap idx=%lu", curIdx]));
  return curIdx;

}

/**
 * headerbarBXBitmap
 */
- (unsigned)headerbarBXBitmap:(unsigned) bmap_id alignment:(unsigned) align func:(void (*)()) f {
  BX_LOG(([NSString stringWithFormat:@"headerbarBXBitmap bmap_id=%d alignment=%d func:%p", bmap_id, align, f]));

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
    x = last_rx;
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

  [buttons addObject: [[BXHeaderbarButton alloc] init:bmap_id width:rgbData.width height:rgbData.height alignment:align top:y left:x image:image]];

  BX_LOG(([NSString stringWithFormat:@"headerbarBXBitmap idx=%lu x=%d y=%d", curIdx, x, y]));
  return (curIdx);
}

/**
 * headerbarCreate
 */
-(void) headerbarCreate:(NSView *) view {

  [buttons enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
    BXHeaderbarButton * btn;
    BX_LOG(([NSString stringWithFormat:@"headerbarUpdate enable idx=%lu ", idx]));
    btn = [buttons objectAtIndex:idx];
    [view addSubview:btn.button];
  }];

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

  BX_LOG(([NSString stringWithFormat:@"headerbarUpdate width=%lu yofs=%d", self.width, self.yofs]));

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
      x = last_rx;
      last_rx -= (BX_GUI_GAP_SIZE + btn.size.width);
    }
    y = self.yofs;

    btn.position = NSMakePoint(x, y);
    [btn.button setFrameOrigin:btn.position];

  }];

}


@end
