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
#include "cocoa_display.h"

// unsigned char BXPalette_ColorBW[3*2] = {
//   0xFF, 0xFF, 0xFF,
//   0x00, 0x00, 0x00
// };

extern unsigned char flip_byte(unsigned char b);

int gcd(int a, int b) {
    if (b == 0) return a;
    return gcd(b, a % b);
}

unsigned int kgV( int a, int b)
{
  return a * b / gcd( a, b);
}

@implementation BXVGAdisplay

NSImageView * imgview;

/**
 * BXVGAdisplay CTor
 */
- (instancetype)init:(unsigned) bpp width:(unsigned) w height:(unsigned) h font_width:(unsigned) fw font_height:(unsigned) fh view:(NSView *) v {
  self = [super init];
  if(self) {

    self.bpp = bpp;
    self.width = w;
    self.height = h;
    self.font_width = fw;
    self.font_height = fh;
    // calculate the number of bytes of memory for each horizontal row of the bitmap
    self.stride = w * bpp / 8;
    // calculate the number of bits for each component in a source pixel
    self.bitsPerComponent = bpp < 16 ? bpp : 8;

    // allocate screen buffer
    self.screen = (const unsigned char *)malloc((self.stride * h) * sizeof(unsigned char));
    // allocate palette buffer
    self.palette_size = pow(2, bpp);
    self.palette = (unsigned char *)malloc((self.palette_size * 3) * sizeof(unsigned char));
    self.dirty = YES;

    imgview = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, self.width, self.height)];
    [v addSubview:imgview];

    BX_LOG(([NSString stringWithFormat:@"init bpp=%d colors=%d width=%d height=%d font width=%d height=%d stride=%d bitsPerComponent=%d", bpp, self.palette_size, w, h, fw, fh, self.stride, self.bitsPerComponent]));
  }
  return self;
}

/**
 * BXVGAdisplay DTor
 */
- (void)dealloc {
  free((void *)self.palette);
  free((void *)self.screen);
  [imgview dealloc];
  [super dealloc];
}


/**
 * change display mode
 */
- (void)changeBPP:(unsigned) bpp width:(unsigned) w height:(unsigned) h font_width:(unsigned) fw font_height:(unsigned) fh {

  self.palette_size = pow(2, bpp);

  if (self.bpp != bpp) {
    // recreate palette buffer
    free((void *)self.palette);
    self.palette = (unsigned char *)malloc((self.palette_size * 3) * sizeof(unsigned char));
  }
  // calculate the number of bytes of memory for each horizontal row of the bitmap
  self.stride = w * bpp / 8;
  if ((self.bpp != bpp) && (self.width != w) && (self.height != h)) {
    // recreate screen buffer
    free((void *)self.screen);
    self.screen = (const unsigned char *)malloc((self.stride * h) * sizeof(unsigned char));
  }
  self.bpp = bpp;
  self.width = w;
  self.height = h;
  self.font_width = fw;
  self.font_height = fh;

  // calculate the number of bits for each component in a source pixel
  self.bitsPerComponent = bpp < 16 ? bpp : 8;
  self.screen = (const unsigned char *)malloc((w*h/bpp) * sizeof(unsigned char));
  self.dirty = YES;

  [imgview setFrameSize:NSMakeSize(w, h)];

  BX_LOG(([NSString stringWithFormat:@"changeBPP bpp=%d colors=%d width=%d height=%d font width=%d height=%d stride=%d bitsPerComponent=%d", bpp, self.palette_size, w, h, fw, fh, self.stride, self.bitsPerComponent]));

}

/**
 * render the image
 */
- (void)render {

  CGColorSpaceRef colorspace;
  CFDataRef data;
  CGDataProviderRef provider;
  CGImageRef rgbImageRef;
  NSImage * image;

  // do not render if not needed
  if (!self.dirty) {
    return;
  }

  // create colorspace
  BX_LOG(([NSString stringWithFormat:@"colorspace size=%d palette=%p", self.palette_size-1, self.palette]));
  colorspace = CGColorSpaceCreateIndexed(CGColorSpaceCreateDeviceRGB(), self.palette_size-1, self.palette);
  if (colorspace == NULL) {
    BX_LOG((@"colorspace failed."));
  }
  data = CFDataCreate(NULL, self.screen, (self.stride * self.height));
  provider = CGDataProviderCreateWithCFData(data);
  BX_LOG(([NSString stringWithFormat:@"image width=%d height=%d", self.width, self.height]));
  rgbImageRef = CGImageCreate(self.width, self.height, self.bitsPerComponent, self.bpp, self.stride, colorspace, kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
  CGDataProviderRelease(provider);
  CGColorSpaceRelease(colorspace);
  image = [[[NSImage alloc] initWithCGImage:rgbImageRef size:NSZeroSize] autorelease];
  CGImageRelease(rgbImageRef);

  BX_LOG((@"render done."));

  BX_LOG(([NSString stringWithFormat:@"vaild %s", image.isValid?"YES":"NO"]));

  BX_LOG(([NSString stringWithFormat:@"render width=%d height=%d", self.width, self.height]));

  [imgview setImage:image];

  CFRelease(data);

  self.dirty = NO;

}

/**
 * set one entry in palette
 */
- (BOOL)setPaletteRGB:(unsigned)index red:(char) r green:(char) g blue:(char) b {

  unsigned ofs;

  // do not overwrite ...
  if (index >= self.palette_size) {
    return NO;
  }

  // calc ofs
  ofs = index * 3;
  self.palette[ofs] = r;
  self.palette[ofs+1] = g;
  self.palette[ofs+2] = b;

  return NO;

}

/**
 * fill screen with 0
 */
- (void)clearScreen {
  memset((void *)self.screen, 0, (self.stride * self.height) * sizeof(unsigned char));
}














@end
