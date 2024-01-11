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

#define FONT_DATA_SIZE 0x2000

extern unsigned char flip_byte(unsigned char b);


static void print_buf(const unsigned char *buf, size_t buf_len)
{
  NSString *lout;

    size_t i = 0;
    lout = @"\n";

    for(i = 0; i < buf_len; ++i) {
      lout = [NSString stringWithFormat:@"%@%02X%s", lout, buf[i], ( i + 1 ) % 16 == 0 ? "\r\n" : " " ];
    }
    BXL_INFO((lout));
}


@implementation BXVGAImageView

/**
 * BXVGAImageView
 */
- (instancetype)initWithFrame:(NSRect)frameRect {
  self = [super initWithFrame:frameRect];
  if(self) {

  }
  return self;
}

/**
 * BXVGAImageView DTor
 */
- (void)dealloc {
  [super dealloc];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
};

// - (void)keyDown:(NSEvent *)theEvent {
//
//   BXL_INFO(([NSString stringWithFormat:@"keyDown pressed VGA"]));
//
// }
//
// - (void)keyUp:(NSEvent *)event {
//   BXL_INFO(([NSString stringWithFormat:@"keyUp pressed VGA"]));
// }

- (void)mouseEvent: (NSButton*)button {
  BXL_INFO(([NSString stringWithFormat:@"mouseEvent pressed VGA"]));
}

- (void) mouseDown:(NSEvent*)event {
  BXL_INFO(([NSString stringWithFormat:@"mouseDown pressed VGA"]));
}
- (void) mouseDragged:(NSEvent*)event {
  BXL_INFO(([NSString stringWithFormat:@"mouseDragged pressed VGA"]));
}
- (void) mouseUp:(NSEvent*)event {
  BXL_INFO(([NSString stringWithFormat:@"mouseUp pressed VGA"]));
}

// -(void)mouseEntered:(NSEvent *)theEvent {
//     BXL_INFO((@"Mouse entered"));
// }
//
// -(void)mouseExited:(NSEvent *)theEvent
// {
//     BXL_INFO((@"Mouse exited"));
// }
// NSTrackingArea *updateTrackingAreas;
// -(void)updateTrackingAreas
// {
//     [super updateTrackingAreas];
//     if(trackingArea != nil) {
//         [self removeTrackingArea:trackingArea];
//         [trackingArea release];
//     }
//
//     int opts = (NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways);
//     trackingArea = [ [NSTrackingArea alloc] initWithRect:[self bounds]
//                                                  options:opts
//                                                    owner:self
//                                                 userInfo:nil];
//     [self addTrackingArea:trackingArea];
// }


@end


@implementation BXVGAdisplay

@synthesize width;
@synthesize height;
@synthesize font_width;


BXVGAImageView * imgview;

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
    self.screen = (unsigned char *)malloc((self.stride * h) * sizeof(unsigned char));
    // allocate palette buffer
    self.palette_size = pow(2, bpp);
    self.palette = (unsigned char *)malloc((self.palette_size * 3) * sizeof(unsigned char));

    // allocate font memory
    self.FontA = (unsigned char *)malloc(FONT_DATA_SIZE * sizeof(unsigned char));
    self.FontB = (unsigned char *)malloc(FONT_DATA_SIZE * sizeof(unsigned char));




    self.dirty = YES;

    imgview = [[BXVGAImageView alloc] initWithFrame:NSMakeRect(0, 0, self.width, self.height)];
    [v addSubview:imgview];

    BXL_DEBUG(([NSString stringWithFormat:@"init bpp=%d colors=%d width=%d height=%d font width=%d height=%d stride=%d bitsPerComponent=%d", bpp, self.palette_size, w, h, fw, fh, self.stride, self.bitsPerComponent]));
  }
  return self;
}

/**
 * BXVGAdisplay DTor
 */
- (void)dealloc {
  free((void *)self.FontA);
  free((void *)self.FontB);
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
    self.screen = (unsigned char *)malloc((self.stride * h) * sizeof(unsigned char));
  }
  self.bpp = bpp;
  self.width = w;
  self.height = h;
  self.font_width = fw;
  self.font_height = fh;

  // calculate the number of bits for each component in a source pixel
  self.bitsPerComponent = bpp < 16 ? bpp : 8;
  // self.screen = (const unsigned char *)malloc((w*h/bpp) * sizeof(unsigned char));
  self.dirty = YES;

  [imgview setFrameSize:NSMakeSize(w, h)];

  BXL_DEBUG(([NSString stringWithFormat:@"changeBPP bpp=%d colors=%d width=%d height=%d font width=%d height=%d stride=%d bitsPerComponent=%d", bpp, self.palette_size, w, h, fw, fh, self.stride, self.bitsPerComponent]));

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
  BXL_DEBUG(([NSString stringWithFormat:@"colorspace size=%d palette=%p", self.palette_size-1, self.palette]));
  colorspace = CGColorSpaceCreateIndexed(CGColorSpaceCreateDeviceRGB(), self.palette_size-1, self.palette);
  if (colorspace == NULL) {
    BXL_FATAL((@"colorspace failed."));
  }
  data = CFDataCreate(NULL, self.screen, (self.stride * self.height));
  provider = CGDataProviderCreateWithCFData(data);
  BXL_DEBUG(([NSString stringWithFormat:@"image width=%d height=%d", self.width, self.height]));
  rgbImageRef = CGImageCreate(self.width, self.height, self.bitsPerComponent, self.bpp, self.stride, colorspace, kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
  CGDataProviderRelease(provider);
  CGColorSpaceRelease(colorspace);
  image = [[[NSImage alloc] initWithCGImage:rgbImageRef size:NSZeroSize] autorelease];
  CGImageRelease(rgbImageRef);

  BXL_DEBUG((@"render done."));

  // BX_LOG(([NSString stringWithFormat:@"vaild %s", image.isValid?"YES":"NO"]));
  //
  // BX_LOG(([NSString stringWithFormat:@"render width=%d height=%d", self.width, self.height]));

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

/**
 * init FontA & FontB with default values
 */
- (void)initFonts:(unsigned char *) dataA second:(unsigned char *) dataB {

  BXL_INFO(([NSString stringWithFormat:@"initFonts data1=%p data2=%p", dataA, dataB]));
  if (dataA != NULL) {
    for (unsigned c = 0; c<256*self.font_height; c++) {
      self.FontA[c] = flip_byte(dataA[c]);
    }
  }
  if (dataB != NULL) {
    for (unsigned c = 0; c<256*self.font_height; c++) {
      self.FontB[c] = flip_byte(dataA[c]);
    }
  }

}

/**
 * update font at position
 */
- (void)updateFontAt:(unsigned) pos first:(unsigned char *) dataA second:(unsigned char *) dataB {

  unsigned ofs;


  // BXL_INFO(([NSString stringWithFormat:@"updateFontAt pos=%d data1=%p data2=%p", pos, dataA, dataB]));

  ofs = pos * (self.font_width / 8) * self.font_height;
  // uintptr_t fa;
  // fa = ((uintptr_t)self.FontA + ofs);

  NSAssert((self.FontA + ofs) < (self.FontA + FONT_DATA_SIZE), @"update FontA %p min %p max %p pos %d fw %d fh %d ofs %d",
    self.FontA, (self.FontA + ofs), (self.FontA + FONT_DATA_SIZE), pos, (self.font_width / 8), self.font_height, ofs);
  NSAssert((self.FontB + ofs) < (self.FontB + FONT_DATA_SIZE), @"update FontB %p min %p max %p pos %d fw %d fh %d ofs %d",
    self.FontB, (self.FontB + ofs), (self.FontB + FONT_DATA_SIZE), pos, (self.font_width / 8), self.font_height, ofs);

  // this currently destroys the font ...

  // for (unsigned p = 0; p<self.font_height; p++) {
  //   (self.FontA + ofs)[p] = flip_byte((dataA + ofs)[p]);
  //   (self.FontB + ofs)[p] = flip_byte((dataB + ofs)[p]);
  // }

}

/**
 * paint char with FontA or FontB with fg and bg colors at position
 */
- (void)paintChar:(unsigned short int) charpos font2:(BOOL) f2 bgcolor:(unsigned char) bg fgcolor:(unsigned char) fg position:(NSRect) rect {

  unsigned char * chardata;
  unsigned char * screenofs;
  unsigned char * screencharofs;
  unsigned char mask;

  // do not allow write outside screen
  if ((unsigned)rect.origin.x >= self.width) {
    // BXL_ERROR(([NSString stringWithFormat:@"invalid x=%d max=%d", (unsigned)rect.origin.x, self.width]));
    return;
  }
  if ((unsigned)rect.origin.y >= self.height) {
    // BXL_ERROR(([NSString stringWithFormat:@"invalid y=%d max=%d", (unsigned)rect.origin.y, self.height]));
    return;
  }

  chardata = f2 ? &self.FontB[charpos] : &self.FontA[charpos];
  screenofs = self.screen + ((unsigned)(rect.origin.y) * self.stride) + ((unsigned)rect.origin.x);
  screencharofs = screenofs;
  //print_buf(chardata, rect.size.width * rect.size.height*4);

  NSAssert(charpos < 255 * self.font_height, @"charpos out of range %d", charpos);
  NSAssert(screenofs < self.screen + self.stride * self.height, @"screenofs out of range %p min %p max %p x %d y %d",
    screenofs, self.screen, self.screen + self.stride * self.height, (unsigned)rect.origin.x, (unsigned)rect.origin.y);

  // each row
  for (unsigned y=0; y<(unsigned)rect.size.height; y++) {
    // each bit of chardata
    for (mask = 0x80; mask != 0; mask >>=1) {
      if (*chardata & mask) {
        *screencharofs = fg;
      } else {
        *screencharofs = bg;
      }
      screencharofs++;
    }
    chardata++;
    screencharofs = screenofs + ((unsigned)self.stride * y);
  }


  self.dirty = YES;// maybe define as atomic?
  // BXL_INFO(([NSString stringWithFormat:@"paintChar charpos=%d font2=%s fgcolor=%d bgcolor=%d", charpos, f2?"YES":"NO", fg, bg]));
  // BXL_INFO(([NSString stringWithFormat:@"paintChar chardata=%p screenofs=%p fgcolor=%d bgcolor=%d", chardata, screenofs, fg, bg]));
  // BXL_INFO(([NSString stringWithFormat:@"paintChar screenofs=%p x=%d y=%d", chardata, (unsigned)rect.origin.x, (unsigned)rect.origin.y]));
  // BXL_INFO(([NSString stringWithFormat:@"paintChar chardata=%p screenofs=%p rect.origin.x=%f", chardata, screenofs, rect.origin.x]));

}














@end
