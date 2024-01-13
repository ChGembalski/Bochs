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

// buffer fits 16bits x 16bytes of char data
#define FONT_DATA_SIZE 0x1000
#define CHARACTER_WORDS 16
#define VGA_ACCESS_MODE_BYTE  1
#define VGA_ACCESS_MODE_WORD  2
#define VGA_ACCESS_MODE_DWORD 4
#define VGA_WORD_BIT_MASK 0x8000

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

static void print_buf_bits(const unsigned char *buf, size_t buf_len) {

  NSString *lout;
  unsigned char mask;

    size_t i = 0;
    lout = @"\n";

    for(i = 0; i < buf_len; ++i) {

      for (mask = 0x80; mask != 0; mask >>=1) {
        if (buf[i] & mask) {
          lout = [NSString stringWithFormat:@"%@1", lout];
        } else {
          lout = [NSString stringWithFormat:@"%@0", lout];
        }
      }

      lout = [NSString stringWithFormat:@"%@\r\n", lout];
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
    NSAssert(self.screen != NULL, @"screen [%p]: allocate memory failed.", self.screen);
    // allocate palette buffer
    self.palette_size = pow(2, bpp);
    NSAssert(self.palette_size != 0, @"palette_size [%d]: invalid palette size.", self.palette_size);
    self.palette = (unsigned char *)malloc((self.palette_size * 3) * sizeof(unsigned char));
    NSAssert(self.palette != NULL, @"palette [%p]: allocate memory failed.", self.palette);

    // allocate font memory
    self.FontA = (unsigned short int *)malloc(FONT_DATA_SIZE * sizeof(unsigned short int));
    NSAssert(self.FontA != NULL, @"FontA [%p]: allocate memory failed.", self.FontA);
    memset((void *)self.FontA, 0, FONT_DATA_SIZE * sizeof(unsigned short int));
    self.FontB = (unsigned short int *)malloc(FONT_DATA_SIZE * sizeof(unsigned short int));
    NSAssert(self.FontB != NULL, @"FontB [%p]: allocate memory failed.", self.FontB);
    memset((void *)self.FontB, 0, FONT_DATA_SIZE * sizeof(unsigned short int));



    self.dirty = YES;

    imgview = [[BXVGAImageView alloc] initWithFrame:NSMakeRect(0, 0, self.width, self.height)];
    [v addSubview:imgview];

    BXL_INFO(([NSString stringWithFormat:@"display bpp=%d colors=%d width=%d height=%d font width=%d height=%d stride=%d bitsPerComponent=%d dirty=%s",
    self.bpp, self.palette_size, self.width, self.height, self.font_width, self.font_height, self.stride, self.bitsPerComponent, self.dirty?"YES":"NO"]));

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

  if (self.bpp != bpp) {
    self.bpp = bpp;
    // calculate the number of bits for each component in a source pixel
    self.bitsPerComponent = bpp < 16 ? bpp : 8;
    self.palette_size = pow(2, bpp);
    NSAssert(self.palette_size != 0, @"palette_size [%d]: invalid palette size.", self.palette_size);
    // recreate palette buffer
    free((void *)self.palette);
    self.palette = (unsigned char *)malloc((self.palette_size * 3) * sizeof(unsigned char));
    NSAssert(self.palette != NULL, @"palette [%p]: allocate memory failed.", self.palette);
  }
  // calculate the number of bytes of memory for each horizontal row of the bitmap
  self.stride = w * bpp / 8;
  if ((self.bpp != bpp) | (self.width != w) | (self.height != h)) {
    self.width = w;
    self.height = h;

    // recreate screen buffer
    free((void *)self.screen);
    self.screen = (unsigned char *)malloc((self.stride * h) * sizeof(unsigned char));
    NSAssert(self.screen != NULL, @"screen [%p]: allocate memory failed.", self.screen);
  }

  if ((self.font_width != fw) | (self.font_height != fh)) {
    self.font_width = fw;
    self.font_height = fh;
    NSAssert(((self.font_width * self.font_height * 256)/CHARACTER_WORDS) <= (FONT_DATA_SIZE * sizeof(unsigned short int)), @"font [%d,%d,%d,%d]: fontbuffer overflow.",
    ((self.font_width * self.font_height * 256)/CHARACTER_WORDS), (unsigned)(FONT_DATA_SIZE * sizeof(unsigned short int)), self.font_width, self.font_height);
  }




  self.dirty = YES;

  [imgview setFrameSize:NSMakeSize(w, h)];

  BXL_INFO(([NSString stringWithFormat:@"display bpp=%d colors=%d width=%d height=%d font width=%d height=%d stride=%d bitsPerComponent=%d dirty=%s",
  self.bpp, self.palette_size, self.width, self.height, self.font_width, self.font_height, self.stride, self.bitsPerComponent, self.dirty?"YES":"NO"]));

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

  BXL_INFO(([NSString stringWithFormat:@"setPaletteRGB index=%d red=%d green=%d blue=%d", index, r, g, b]));

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
- (void)initFonts:(unsigned char *) dataA second:(unsigned char *) dataB width:(unsigned char)w height:(unsigned char) h {

  BXL_INFO(([NSString stringWithFormat:@"initFonts data1=%p data2=%p width=%d height=%d", dataA, dataB, w, h]));

  // Font format
  // 8bit hi 8bit lo - repeated h times

  NSAssert(w==8, @"unsupported initial font size %d", w);
  if (dataA != NULL) {
    for (unsigned c = 0; c<256; c++) {
      for (unsigned cr=0; cr<h; cr++) {
        self.FontA[(c * CHARACTER_WORDS) + cr] = flip_byte(dataA[c*h+cr])<<8;
        if (dataB == dataA) {
          self.FontB[(c * CHARACTER_WORDS) + cr] = self.FontA[(c * CHARACTER_WORDS) + cr];
        } else {
          self.FontB[(c * CHARACTER_WORDS) + cr] = flip_byte(dataA[c*h+cr])<<8;
        }
        // self.FontA[(c * CHARACTER_BYTES) + (CHARACTER_BYTES/2) + cr] = flip_byte(dataA[c*h+cr]);
        // if (dataB == dataA) {
        //   self.FontB[(c * CHARACTER_BYTES) + (CHARACTER_BYTES/2) + cr] = self.FontA[(c * CHARACTER_BYTES) + (CHARACTER_BYTES/2) + cr];
        // } else {
        //   self.FontB[(c * CHARACTER_BYTES) + (CHARACTER_BYTES/2) + cr] = flip_byte(dataA[c*h+cr]);
        // }
      }
    }
  }

}

/**
 * update font at position
 */
- (void)updateFontAt:(unsigned) pos first:(unsigned char *) dataA second:(unsigned char *) dataB {

  unsigned ofs;


  BXL_INFO(([NSString stringWithFormat:@"updateFontAt pos=%d data1=%p data2=%p font_width=%d font_height=%d", pos, dataA, dataB, self.font_width, self.font_height]));

  ofs = pos * (self.font_width / 8) * self.font_height;
  // uintptr_t fa;
  // fa = ((uintptr_t)self.FontA + ofs);

  // print_buf_bits(dataA+ofs, self.font_width * self.font_height/8);



  NSAssert((self.FontA + ofs) < (self.FontA + FONT_DATA_SIZE), @"update FontA %p min %p max %p pos %d fw %d fh %d ofs %d",
    self.FontA, (self.FontA + ofs), (self.FontA + FONT_DATA_SIZE), pos, (self.font_width / 8), self.font_height, ofs);
  NSAssert((self.FontB + ofs) < (self.FontB + FONT_DATA_SIZE), @"update FontB %p min %p max %p pos %d fw %d fh %d ofs %d",
    self.FontB, (self.FontB + ofs), (self.FontB + FONT_DATA_SIZE), pos, (self.font_width / 8), self.font_height, ofs);

  // this currently destroys the font ...

  for (unsigned p = 0; p<self.font_height; p++) {
    // (self.FontA + ofs)[p] = flip_byte((dataA + ofs)[p]);
    // (self.FontB + ofs)[p] = flip_byte((dataB + ofs)[p]);
  }

}

/**
 * paint char with FontA or FontB with fg and bg colors at position
 */
- (void)paintChar:(unsigned short int) charpos isCrsr:(BOOL) crsr font2:(BOOL) f2 bgcolor:(unsigned char) bg fgcolor:(unsigned char) fg position:(NSRect) rect {

  unsigned short int * selectedFont;
  unsigned short int * selectedChar;
  unsigned char * screenStart;
  unsigned screenStartY;
  unsigned screenStartXbytes;
  unsigned screenStartXbits;
  unsigned char noOfComponents;
  unsigned char vgaAccessMode;
  unsigned charMaxHeight;

  unsigned char * currentScreenOfs;

  // Font format
  // 8bit hi 8bit lo - repeated h times



  NSAssert(charpos < 256 , @"charpos out of range %d", charpos);

  // do not allow write outside screen (must be a bug in gui.cc sending one more x and y as is should)
  NSAssert(((unsigned)rect.origin.x + (unsigned)rect.size.width) <= self.width, @"paintChar x out of range [%d]", ((unsigned)rect.origin.x + (unsigned)rect.size.width));
  NSAssert(((unsigned)rect.origin.y + (unsigned)rect.size.height) <= self.height, @"paintChar y out of range [%d]", ((unsigned)rect.origin.y + (unsigned)rect.size.height));

  selectedFont = f2 ? self.FontB : self.FontA;
  selectedChar = &selectedFont[charpos * CHARACTER_WORDS];
  NSAssert(selectedChar < (selectedFont + (FONT_DATA_SIZE * sizeof(unsigned short int))), @"paintChar char out of range [%d]", charpos);


  // screenStartY not affected by bpp
  // screenStartY = ((unsigned)(rect.origin.y) * self.stride);



  if (self.bitsPerComponent == 8) {
    noOfComponents = self.bpp / self.bitsPerComponent;
    screenStartXbytes = ((unsigned)rect.origin.x) * noOfComponents;
    screenStartXbits = 0;
    vgaAccessMode = noOfComponents >= 3 ? VGA_ACCESS_MODE_DWORD : noOfComponents;
  } else {
    noOfComponents = 0;
    screenStartXbits = 0;
    NSAssert(NO, @"Not yet implemented.");
  }

  // screenStart = self.screen + screenStartY + screenStartXbytes;
  // NSAssert(screenStart < self.screen + self.stride * self.height, @"screenStart out of range %p min %p max %p x %d y %d",
  //   screenStart, self.screen, self.screen + self.stride * self.height, (unsigned)rect.origin.x, (unsigned)rect.origin.y);

  charMaxHeight = ((unsigned)rect.size.height > self.font_height) ? self.font_height : (unsigned)rect.size.height;

  // depending on bpp <=8 <=16 <=32 - different access to screen memory
  switch (vgaAccessMode) {
    case VGA_ACCESS_MODE_BYTE: {

      unsigned short int maskend;
      unsigned char * screenMemory;

      maskend = VGA_WORD_BIT_MASK>>(unsigned)rect.size.width;

      for (unsigned charRow=0; charRow<charMaxHeight; charRow++) {

        unsigned short int mask;

        screenStartY = (((unsigned)(rect.origin.y) + charRow) * self.stride);
        screenMemory = (unsigned char *)(self.screen + screenStartY + screenStartXbytes);

        // each bit of selectedChar
        for (mask = VGA_WORD_BIT_MASK; mask != maskend; mask >>=1) {
          if ((*selectedChar & mask) | crsr) {
            *screenMemory = fg;
          } else {
            *screenMemory = bg;
          }
          screenMemory++;
        }

        selectedChar++;

      }

      break;
    }
    case VGA_ACCESS_MODE_WORD: {
      NSAssert(NO, @"Not yet implemented.");
      break;
    }
    case VGA_ACCESS_MODE_DWORD: {
      NSAssert(NO, @"Not yet implemented.");
      break;
    }
  }







  // screenStart = self.screen + ((unsigned)(rect.origin.y) * self.stride) + ((unsigned)rect.origin.x);
  // NSAssert(screenStart < self.screen + self.stride * self.height, @"screenStart out of range %p min %p max %p x %d y %d",
  //   screenStart, self.screen, self.screen + self.stride * self.height, (unsigned)rect.origin.x, (unsigned)rect.origin.y);
  // currentScreenOfs = screenStart;
  //
  // // font_width > 8
  // if (self.font_width > 8) {
  //   selectedChar += CHARACTER_BYTES/2;
  // } else {
  //   selectedChar += CHARACTER_BYTES/2;
  // }
  //
  // // font_width <= 8
  //
  // for (unsigned crow=0; crow<(unsigned)rect.size.height; crow++) {
  //
  //   unsigned char mask;
  //
  //   // speedup if all 0 or 1
  //   if (*selectedChar == 0x00) {
  //     memset(currentScreenOfs, bg, 8 * sizeof(unsigned char));
  //     selectedChar++;
  //     currentScreenOfs = screenStart + ((unsigned)self.stride * crow);
  //     continue;
  //   }
  //   if (*selectedChar == 0xFF) {
  //     memset(currentScreenOfs, fg, 8 * sizeof(unsigned char));
  //     selectedChar++;
  //     currentScreenOfs = screenStart + ((unsigned)self.stride * crow);
  //     continue;
  //   }
  //
  //   // each bit of chardata
  //   for (mask = 0x80; mask != 0; mask >>=1) {
  //     if (*selectedChar & mask) {
  //       *currentScreenOfs = fg;
  //     } else {
  //       *currentScreenOfs = bg;
  //     }
  //     currentScreenOfs++;
  //   }
  //
  //   selectedChar++;
  //   currentScreenOfs = screenStart + ((unsigned)self.stride * crow);
  //
  // }



  self.dirty = YES;

}














@end
