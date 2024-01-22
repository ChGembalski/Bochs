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
extern unsigned int crc32buf(const unsigned char * buf, size_t len);

// static void print_buf(const unsigned char *buf, size_t buf_len)
// {
//   NSString *lout;
//
//     size_t i = 0;
//     lout = @"\n";
//
//     for(i = 0; i < buf_len; ++i) {
//       lout = [NSString stringWithFormat:@"%@%02X%s", lout, buf[i], ( i + 1 ) % 16 == 0 ? "\r\n" : " " ];
//     }
//     BXL_INFO((lout));
// }
//
// static void print_buf_bits(const unsigned char *buf, size_t buf_len) {
//
//   NSString *lout;
//   unsigned char mask;
//
//     size_t i = 0;
//     lout = @"\n";
//
//     for(i = 0; i < buf_len; ++i) {
//
//       for (mask = 0x80; mask != 0; mask >>=1) {
//         if (buf[i] & mask) {
//           lout = [NSString stringWithFormat:@"%@1", lout];
//         } else {
//           lout = [NSString stringWithFormat:@"%@0", lout];
//         }
//       }
//
//       lout = [NSString stringWithFormat:@"%@\r\n", lout];
//     }
//     BXL_INFO((lout));
//
// }














@implementation BXVGAImageView

NSImage * VGAdisplayBuffer;
// id VGAdisplayContent;
CGFloat VGAdisplayContentScale;
BOOL VGAdisplayBufferChanged;
NSRect VGAdirty;

/**
 * BXVGAImageView CTor
 */
- (instancetype)initWithFrame:(NSRect) frameRect bits:(unsigned) bpp {
  self = [super initWithFrame:frameRect];
  if(self) {

    self.bpp = bpp;
    self.stride = frameRect.size.width * bpp / 8;
    self.bitsPerComponent = bpp < 16 ? bpp : 8;
    VGAdirty = frameRect;

    BXL_INFO(([NSString stringWithFormat:@"initWithFrame bpp=%d bpc=%d stride=%d w=%d h=%d",
      self.bpp, self.bitsPerComponent, self.stride, (unsigned)frameRect.size.width, (unsigned)frameRect.size.height]));

    // allocate screen buffer
    self.VGAdisplay = (unsigned char *)realloc(NULL, (self.stride * (unsigned)frameRect.size.height) * sizeof(unsigned char));
    NSAssert(self.VGAdisplay != NULL, @"VGAdisplay [%p]: allocate memory failed.", self.VGAdisplay);

    // create buffer
    VGAdisplayBuffer = [[NSImage alloc] initWithSize:frameRect.size];
    VGAdisplayBufferChanged = NO;
    // VGAdisplayContent = nil;

    // self.layer.drawsAsynchronously = YES;

  }
  return self;
}

// /**
//  * BXVGAImageView DTor
//  */
// - (void)dealloc {
//   free(self.VGAdisplay);
//
//   [VGAdisplayBuffer release];
//   [super dealloc];
// }

/**
 * disable the mouse events on this view
 * now window has control over the events
 */
- (NSView *)hitTest:(NSPoint)point {
  return nil;
}

/**
 * updateWithFrame
 */
- (void)updateWithFrame:(NSSize) frameSize bits:(unsigned) bpp {

  [self setFrameSize:frameSize];
  // self.columns = frameSize.width / cw;
  // self.rows = frameSize.height / ch;
  // self.tileSize = NSMakeSize(cw, ch);
  self.bpp = bpp;
  self.stride = frameSize.width * bpp / 8;
  self.bitsPerComponent = bpp < 16 ? bpp : 8;
  VGAdirty = NSMakeRect(0, 0, frameSize.width, frameSize.height);

  BXL_INFO(([NSString stringWithFormat:@"updateWithFrame bpp=%d bpc=%d stride=%d w=%d h=%d",
    self.bpp, self.bitsPerComponent, self.stride, (unsigned)frameSize.width, (unsigned)frameSize.height]));

  // allocate screen buffer
  self.VGAdisplay = (unsigned char *)realloc(self.VGAdisplay, (self.stride * (unsigned)frameSize.height) * sizeof(unsigned char));
  NSAssert(self.VGAdisplay != NULL, @"VGAdisplay [%p]: allocate memory failed.", self.VGAdisplay);

  // // recreate buffer
  // [VGAdisplayBuffer release];
  VGAdisplayBuffer = [[NSImage alloc] initWithSize:frameSize];
  VGAdisplayBufferChanged = NO;
  // VGAdisplayContent = nil;

}

/**
 * render the byte array to NSImage
 * avoid massive updates due performance
 */
- (void)renderVGAdisplay:(unsigned char *) palette size:(unsigned) palette_size {

  if (NSIsEmptyRect(VGAdirty)) {
    return;
  }

  CGColorSpaceRef colorspace;
  CFDataRef data;
  CGDataProviderRef provider;
  CGImageRef rgbImageRef;

  colorspace = CGColorSpaceCreateIndexed(CGColorSpaceCreateDeviceRGB(), palette_size-1, palette);
  NSAssert(colorspace != NULL, @"create colorspace failed.");
  data = CFDataCreate(NULL, self.VGAdisplay, (self.stride * self.frame.size.height));
  provider = CGDataProviderCreateWithCFData(data);
  rgbImageRef = CGImageCreate(self.frame.size.width, self.frame.size.height, self.bitsPerComponent, self.bpp, self.stride, colorspace, kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
  // [VGAdisplayBuffer release];
  VGAdisplayBuffer = [[NSImage alloc] initWithCGImage:rgbImageRef size:NSZeroSize];
  if (VGAdisplayBuffer.valid) {
    [self renderVGAdisplayContent];
  }
  CGImageRelease(rgbImageRef);
  CGDataProviderRelease(provider);
  CFRelease(data);
  CGColorSpaceRelease(colorspace);

  VGAdisplayBufferChanged = YES;
  // BXL_INFO((@"renderVGAdisplay done"));

}

/**
 * render the VGAdisplay to NSImage
 */
- (void)renderVGAdisplayRGB {

  if (NSIsEmptyRect(VGAdirty)) {
    return;
  }

  CGColorSpaceRef colorspace;
  CFDataRef data;
  CGDataProviderRef provider;
  CGImageRef rgbImageRef;

  colorspace = CGColorSpaceCreateDeviceRGB();
  NSAssert(colorspace != NULL, @"create colorspace failed.");
  data = CFDataCreate(NULL, self.VGAdisplay, (self.stride * self.frame.size.height));
  provider = CGDataProviderCreateWithCFData(data);
  rgbImageRef = CGImageCreate(self.frame.size.width, self.frame.size.height, self.bitsPerComponent, self.bpp, self.stride, colorspace, kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
  // [VGAdisplayBuffer release];
  VGAdisplayBuffer = [[NSImage alloc] initWithCGImage:rgbImageRef size:NSZeroSize];
  if (VGAdisplayBuffer.valid) {
    [self renderVGAdisplayContent];
  }
  CGImageRelease(rgbImageRef);
  CGDataProviderRelease(provider);
  CFRelease(data);
  CGColorSpaceRelease(colorspace);

  VGAdisplayBufferChanged = YES;
  // BXL_INFO((@"renderVGAdisplayRGB done"));
}

/**
 * renderVGAdisplayContent
 */
- (void)renderVGAdisplayContent {

  CGFloat windowScaleFactor;

  windowScaleFactor = self.window.backingScaleFactor;

  VGAdisplayContentScale = [VGAdisplayBuffer recommendedLayerContentsScale:windowScaleFactor];
  // VGAdisplayContent = [VGAdisplayBuffer layerContentsForContentsScale:VGAdisplayContentScale];
  // BXL_INFO((@"renderVGAdisplayContent done"));
}

// - (BOOL)isOpaque {
//     return YES;
// }

- (BOOL)wantsLayer {
  return YES;
}
- (BOOL)wantsUpdateLayer {
  return YES;
}

- (void)updateLayer {

//   CGFloat windowScaleFactor;
//   CGFloat imageScaleFactor;
//
//   if (VGAdisplayBufferChanged) {
//
//     windowScaleFactor = self.window.backingScaleFactor;
//     imageScaleFactor = [VGAdisplayBuffer recommendedLayerContentsScale:windowScaleFactor];
//
//     self.layer.contents = [VGAdisplayBuffer layerContentsForContentsScale:imageScaleFactor];
//     self.layer.contentsScale = imageScaleFactor;
//
//     VGAdisplayBufferChanged = NO;
//
//   }

  // if (VGAdisplayContent == nil) return;

  // if (self.layer.contents != VGAdisplayContent) {
  if (VGAdisplayBufferChanged) {
    // BXL_INFO((@"updateLayer"));
    self.layer.contents = VGAdisplayBuffer;//VGAdisplayContent;
    self.layer.contentsScale = VGAdisplayContentScale;
    // VGAdisplayContent = nil;
    VGAdirty = NSZeroRect;
    VGAdisplayBufferChanged = NO;
    // BXL_INFO((@"updateLayer done"));
  }

}

// - (void)setNeedsDisplayInRect:(NSRect)invalidRect {
// //   // BXL_INFO(([NSString stringWithFormat:@"setNeedsDisplayInRect x=%d y=%d w=%d h=%d",
// //   //   (unsigned)invalidRect.origin.x, (unsigned)invalidRect.origin.y, (unsigned)invalidRect.size.width, (unsigned)invalidRect.size.height]));
// //     [super setNeedsDisplayInRect:invalidRect];
//   [self.layer setNeedsDisplayInRect:invalidRect];
// }
// - (void)displayRectIgnoringOpacity:(NSRect)rect {
//
// }
// - (void)displayRectIgnoringOpacity:(NSRect)rect inContext:(NSGraphicsContext *)context {
//
// }
// - (void)displayIfNeeded {
//
// }
// - (void)displayIfNeededInRect:(NSRect)rect {
//
// }
// - (void)displayIfNeededIgnoringOpacity {
//
// }
// - (void)displayIfNeededInRectIgnoringOpacity:(NSRect)rect {
//
// }

- (void)drawRect:(NSRect)dirtyRect {

//   // if (!NSIsEmptyRect(VGAdirty)) {
//   //
//   //   NSRect paintFROMTO;
//   //
//   //   paintFROMTO = [self dirtyVGAView];
//   //
//   //   BXL_INFO(([NSString stringWithFormat:@"drawRect VGAdirty x=%d y=%d w=%d h=%d opaque=%s",
//   //     (unsigned)VGAdirty.origin.x, (unsigned)VGAdirty.origin.y, (unsigned)VGAdirty.size.width, (unsigned)VGAdirty.size.height,
//   //     self.opaque?"YES":"NO"
//   //   ]));
//   //   BXL_INFO(([NSString stringWithFormat:@"drawRect dirtyRect x=%d y=%d w=%d h=%d",
//   //     (unsigned)dirtyRect.origin.x, (unsigned)dirtyRect.origin.y, (unsigned)dirtyRect.size.width, (unsigned)dirtyRect.size.height]));
//   //
//   //   [VGAdisplayBuffer drawInRect:paintFROMTO fromRect:paintFROMTO operation:NSCompositingOperationCopy fraction:1];
//   //
//   //   VGAdirty = NSZeroRect;
//   //   // usleep(500000);
//   // } else {
//     [VGAdisplayBuffer drawInRect:dirtyRect fromRect:dirtyRect operation:NSCompositingOperationCopy fraction:1];
//     VGAdirty = NSZeroRect;
//   // }
//
//   BXL_INFO((@"drawRect done"));
//
//   // const NSRect *rects;
//   // NSInteger count;
//   //
//   // [self getRectsBeingDrawn:&rects count:&count];
//   //
//   // if (count) {
//   //
//   //   for (int i = 0; i < count; i++) {
//   //     BXL_INFO(([NSString stringWithFormat:@"drawRect count[%d] rects[%d] x=%d y=%d w=%d h=%d",
//   //       (unsigned)count, i, (unsigned)rects[i].origin.x, (unsigned)rects[i].origin.y, (unsigned)rects[i].size.width, (unsigned)rects[i].size.height]));
//   //     [VGAdisplayBuffer drawInRect:rects[i] fromRect:rects[i] operation:NSCompositingOperationCopy fraction:1];
//   //   }
//   //
//   // } else {
//   //   BXL_INFO(([NSString stringWithFormat:@"drawRect dirtyRect x=%d y=%d w=%d h=%d",
//   //     (unsigned)dirtyRect.origin.x, (unsigned)dirtyRect.origin.y, (unsigned)dirtyRect.size.width, (unsigned)dirtyRect.size.height]));
//   //   [VGAdisplayBuffer drawInRect:dirtyRect];
//   // }
//
//   VGAdisplayBufferChanged = NO;
  BXL_INFO((@"drawRect done"));
}

/**
 * updateVGA
 */
- (void)updateVGA:(NSRect) dirty {

  if (NSIsEmptyRect(VGAdirty)) {
    VGAdirty = dirty;
  } else {
    VGAdirty = NSUnionRect(VGAdirty, dirty);
  }
  [self setNeedsDisplayInRect:dirty];

}

// - (NSRect)dirtyVGAView {
//
//   return NSMakeRect(VGAdirty.origin.x, self.frame.size.height - VGAdirty.origin.y, VGAdirty.size.width, VGAdirty.size.height);
//
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

    imgview = [[BXVGAImageView alloc] initWithFrame:NSMakeRect(0, 0, self.width, self.height) bits:bpp];
    imgview.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
    [v addSubview:imgview];

    BXL_INFO(([NSString stringWithFormat:@"display bpp=%d colors=%d width=%d height=%d font width=%d height=%d stride=%d bitsPerComponent=%d dirty=%s",
    self.bpp, self.palette_size, self.width, self.height, self.font_width, self.font_height, self.stride, self.bitsPerComponent, self.dirty?"YES":"NO"]));

    self.dirty = YES;

  }
  return self;
}

// /**
//  * BXVGAdisplay DTor
//  */
// - (void)dealloc {
//   free((void *)self.FontA);
//   free((void *)self.FontB);
//   free((void *)self.palette);
//
//   [imgview release];
//   [super dealloc];
// }


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
    self.palette = (unsigned char *)realloc(self.palette, (self.palette_size * 3) * sizeof(unsigned char));
    NSAssert(self.palette != NULL, @"palette [%p]: allocate memory failed.", self.palette);
  }
  // calculate the number of bytes of memory for each horizontal row of the bitmap
  self.stride = w * bpp / 8;
  if ((self.bpp != bpp) | (self.width != w) | (self.height != h)) {
    self.width = w;
    self.height = h;
    // reconstruct view
    [imgview updateWithFrame:NSMakeSize(self.width, self.height) bits:bpp];
  }

  if ((self.font_width != fw) | (self.font_height != fh)) {
    self.font_width = fw;
    self.font_height = fh;
    NSAssert(((self.font_width * self.font_height * 256)/CHARACTER_WORDS) <= (FONT_DATA_SIZE * sizeof(unsigned short int)), @"font [%d,%d,%d,%d]: fontbuffer overflow.",
    ((self.font_width * self.font_height * 256)/CHARACTER_WORDS), (unsigned)(FONT_DATA_SIZE * sizeof(unsigned short int)), self.font_width, self.font_height);
  }

  self.dirty = YES;

  BXL_INFO(([NSString stringWithFormat:@"display bpp=%d colors=%d width=%d height=%d font width=%d height=%d stride=%d bitsPerComponent=%d dirty=%s",
  self.bpp, self.palette_size, self.width, self.height, self.font_width, self.font_height, self.stride, self.bitsPerComponent, self.dirty?"YES":"NO"]));

}

/**
 * render the image
 */
- (void)render {

  // do not render if not needed
  if (!self.dirty) {
    return;
  }

  if (self.bpp > 16) {
    [imgview renderVGAdisplayRGB];
  } else {
    [imgview renderVGAdisplay:self.palette size:self.palette_size];
  }

  // [imgview drawRect:NSZeroRect];

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

  BXL_DEBUG(([NSString stringWithFormat:@"setPaletteRGB index=%d red=%d green=%d blue=%d", index, r, g, b]));

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
  memset((void *)imgview.VGAdisplay, 0, (self.stride * self.height) * sizeof(unsigned char));
}

/**
 * init FontA & FontB with default values
 */
- (void)initFonts:(unsigned char *) dataA second:(unsigned char *) dataB width:(unsigned char)w height:(unsigned char) h {

  BXL_DEBUG(([NSString stringWithFormat:@"initFonts data1=%p data2=%p width=%d height=%d", dataA, dataB, w, h]));

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
      }
    }
  } else if (dataB != NULL) {
    for (unsigned c = 0; c<256; c++) {
      for (unsigned cr=0; cr<h; cr++) {
        self.FontB[(c * CHARACTER_WORDS) + cr] = flip_byte(dataA[c*h+cr])<<8;
      }
    }
  }

}

/**
 * update font at position
 */
- (void)updateFontAt:(unsigned) pos isFont2:(BOOL)font2 map:(unsigned char *) data {

  unsigned short int * selectedFont;
  unsigned short int * selectedChar;
  unsigned char * srcData;

  // Font format
  // 8bit hi 8bit lo - repeated h times

  BXL_DEBUG(([NSString stringWithFormat:@"updateFontAt pos=%d data=%p font_width=%d font_height=%d", pos, data, self.font_width, self.font_height]));

  selectedFont = font2 ? self.FontB : self.FontA;
  selectedChar = &selectedFont[pos * CHARACTER_WORDS];

  // erase first
  memset((void *)selectedChar, 0, CHARACTER_WORDS * sizeof(unsigned short int));

  srcData = data;

  // TODO : width is currently ignored

  for (unsigned cr=0; cr<self.font_height; cr++) {

    selectedChar[cr] = flip_byte(srcData[cr]) <<8 | flip_byte(srcData[cr + self.font_height]);

  }

}

/**
 * paint char with FontA or FontB with fg and bg colors at position
 */
- (void)paintChar:(unsigned short int) charpos isCrsr:(BOOL) crsr font2:(BOOL) f2 bgcolor:(unsigned char) bg fgcolor:(unsigned char) fg position:(NSRect) rect {

  unsigned short int * selectedFont;
  unsigned short int * selectedChar;
  unsigned screenStartY;
  unsigned screenStartXbytes;
  unsigned screenStartXbits;
  unsigned char noOfComponents;
  unsigned char vgaAccessMode;
  unsigned charMaxHeight;

  // Font format
  // 8bit hi 8bit lo - repeated h times

  NSAssert(charpos < 256 , @"charpos out of range %d", charpos);

  // do not allow write outside screen
  NSAssert(((unsigned)rect.origin.x + (unsigned)rect.size.width) <= self.width, @"paintChar x out of range [%d]", ((unsigned)rect.origin.x + (unsigned)rect.size.width));
  NSAssert(((unsigned)rect.origin.y + (unsigned)rect.size.height) <= self.height, @"paintChar y out of range [%d]", ((unsigned)rect.origin.y + (unsigned)rect.size.height));

  selectedFont = f2 ? self.FontB : self.FontA;
  selectedChar = &selectedFont[charpos * CHARACTER_WORDS];
  NSAssert(selectedChar < (selectedFont + (FONT_DATA_SIZE * sizeof(unsigned short int))), @"paintChar char out of range [%d]", charpos);

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
        screenMemory = (unsigned char *)(imgview.VGAdisplay + screenStartY + screenStartXbytes);

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

  // BXL_INFO(([NSString stringWithFormat:@"paintChar rect x=%d y=%d w=%d h=%d",
  //   (unsigned)rect.origin.x, (unsigned)rect.origin.y, (unsigned)rect.size.width, (unsigned)rect.size.height]));
  [imgview updateVGA:rect];
  self.dirty = YES;

}

/**
 * clip gfx region into screen
 */
- (void)clipRegion:(unsigned char *) src position:(NSRect) rect {

// BXL_INFO(([NSString stringWithFormat:@"clipRegion src=%p x=%d y=%d w=%d h=%d", src, (unsigned)rect.origin.x, (unsigned)rect.origin.y, (unsigned)rect.size.width, (unsigned)rect.size.height]));
  unsigned screenStartY;
  unsigned screenStartXbytes;
  unsigned screenStartXbits;
  unsigned char noOfComponents;
  unsigned char vgaAccessMode;
  unsigned blitMaxHeight;
  unsigned char * srcMemory;

  // do not allow write outside screen
  if (((unsigned)rect.origin.x + (unsigned)rect.size.width) > self.width) {
    return;
  }
  if (((unsigned)rect.origin.y + (unsigned)rect.size.height) > self.height) {
    return;
  }
  NSAssert(((unsigned)rect.origin.x + (unsigned)rect.size.width) <= self.width, @"clipRegion x out of range max[%d] is[%d]", self.width, ((unsigned)rect.origin.x + (unsigned)rect.size.width));
  NSAssert(((unsigned)rect.origin.y + (unsigned)rect.size.height) <= self.height, @"clipRegion y out of range max[%d] is[%d]", self.height, ((unsigned)rect.origin.y + (unsigned)rect.size.height));


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

  // font height only set in text mode !!!
  blitMaxHeight = (unsigned)rect.size.height;

  BXL_DEBUG(([NSString stringWithFormat:@"clipRegion vgaAccessMode=%d blitMaxHeight=%d font_height=%d", vgaAccessMode, blitMaxHeight, self.font_height]));

  // depending on bpp <=8 <=16 <=32 - different access to screen memory
  switch (vgaAccessMode) {
    case VGA_ACCESS_MODE_BYTE: {

      // print_buf(src, ((unsigned)rect.size.width * (unsigned)rect.size.height));
      // NSAssert(NO, @"Not yet implemented.");

      // unsigned short int maskend;
      unsigned char * screenMemory;
      //
      // maskend = VGA_WORD_BIT_MASK>>(unsigned)rect.size.width;
      srcMemory = src;
      //
      for (unsigned blitRow=0; blitRow<blitMaxHeight; blitRow++) {
      //
      //   unsigned short int mask;
      //
        screenStartY = (((unsigned)(rect.origin.y) + blitRow) * self.stride);
        screenMemory = (unsigned char *)(imgview.VGAdisplay + screenStartY + screenStartXbytes);

        // first try memcopy
        memcpy((void *)screenMemory, srcMemory, (unsigned)rect.size.width * sizeof(unsigned char));
        // memset((void *)screenMemory, 0x34, (unsigned)rect.size.width * sizeof(unsigned char));

      //
      //   // each bit of selectedChar
      //   for (mask = VGA_WORD_BIT_MASK; mask != maskend; mask >>=1) {
      //     if ((*selectedChar & mask) | crsr) {
      //       *screenMemory = fg;
      //     } else {
      //       *screenMemory = bg;
      //     }
      //     screenMemory++;
      //   }
      //
        srcMemory += (unsigned)rect.size.width;
      //
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

  [imgview updateVGA:rect];
  self.dirty = YES;


}

/**
 * VGAdisplayRAM Ptr
 */
- (const unsigned char *)VGAdisplayRAM {
  return (const unsigned char *)imgview.VGAdisplay;
}

/**
 * clipRegionPosition
 */
- (void)clipRegionPosition:(NSRect) rect {
  // BXL_INFO(([NSString stringWithFormat:@"clipRegionPosition rect x=%d y=%d w=%d h=%d",
  //   (unsigned)rect.origin.x, (unsigned)rect.origin.y, (unsigned)rect.size.width, (unsigned)rect.size.height]));

  [imgview updateVGA:rect];
  self.dirty = YES;
}








@end
