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













@implementation BXVGATile

/**
 * BXVGATile CTor
 */
- (instancetype)initWithSize:(NSSize)size {
  self = [super initWithSize:size];
  if(self) {
    self.isDirty = YES;
    self.crc = 0;
  }
  return self;
}

/**
 * BXVGATile CTor
 */
- (instancetype)initWithCGImage:(CGImageRef)cgImage size:(NSSize)size crc:(UInt32) crc32 {
  self = [super initWithCGImage:cgImage size:size];
  if(self) {
    self.isDirty = YES;
    self.crc = crc32;
  }
  return self;
}

/**
 * BXVGATile DTor
 */
- (void)dealloc {
  [super dealloc];
}

@end


@implementation BXVGAImageView

NSMutableArray<NSMutableArray<BXVGATile *> *> * table = nil;
NSMutableArray<BXVGATile *> * cache = nil;
NSImage * viewbuffer = nil;


/**
 * BXVGAImageView CTor
 */
- (instancetype)initWithFrame:(NSRect) frameRect col_width:(unsigned) cw col_height:(unsigned) ch bits:(unsigned) bpp {
  self = [super initWithFrame:frameRect];
  if(self) {

    self.columns = frameRect.size.width / cw;
    self.rows = frameRect.size.height / ch;
    self.tileSize = NSMakeSize(cw, ch);
    self.bpp = bpp;
    self.stride = self.tileSize.width * bpp / 8;
    self.bitsPerComponent = bpp < 16 ? bpp : 8;

    // create all arrays
    [self constructArray:self.rows width:self.columns];

    // create cache
    cache = [[NSMutableArray alloc] init];

    // create buffer
    viewbuffer = [[NSImage alloc] initWithSize:frameRect.size];

  }
  return self;
}

/**
 * BXVGAImageView DTor
 */
- (void)dealloc {
  [self destructArray];
  [self clearCache];
  [cache release];
  [viewbuffer release];
  [super dealloc];
}

/**
 * disable the mouse events on this view
 * now window has control over the events
 */
- (NSView *)hitTest:(NSPoint)point {
  return nil;
}

/**
 * property getter hasUpdate
 */
- (BOOL)hasUpdate {
  return [cache count] != 0;
}

/**
 * updateWithFrame
 */
- (void)updateWithFrame:(NSSize) frameSize col_width:(unsigned) cw col_height:(unsigned) ch bits:(unsigned) bpp {

  // TODO : verify if we have real changes ... if not do nothing

  [self setFrameSize:frameSize];
  self.columns = frameSize.width / cw;
  self.rows = frameSize.height / ch;
  self.tileSize = NSMakeSize(cw, ch);
  self.bpp = bpp;
  self.stride = self.tileSize.width * bpp / 8;
  self.bitsPerComponent = bpp < 16 ? bpp : 8;

  // recreate all arrays
  [self destructArray];
  [self constructArray:self.rows width:self.columns];

  // invalidate cache
  [self clearCache];

  // recreate buffer
  [viewbuffer release];
  viewbuffer = [[NSImage alloc] initWithSize:frameSize];

}

/**
 * construct table array
 */
- (void)constructArray:(unsigned)h width:(unsigned) w {

  table = [[NSMutableArray alloc] initWithCapacity:h];

  for (unsigned y=0; y<h; y++) {
    NSMutableArray<BXVGATile *> * cols;

    cols = [[NSMutableArray alloc] initWithCapacity:w];
    for (unsigned x=0; x<w; x++) {
      [cols addObject:[[[BXVGATile alloc] initWithSize:NSMakeSize(0,0)] autorelease]];
    }
    [table addObject:cols];
  }

}

/**
 * destruct table array
 */
- (void)destructArray {

  [table enumerateObjectsUsingBlock:^(id object, NSUInteger idxy, BOOL *stop) {
    NSMutableArray<BXVGATile *> * cols;
    cols = [table objectAtIndex:idxy];
    [cols enumerateObjectsUsingBlock:^(id object, NSUInteger idxx, BOOL *stop) {
      [[cols objectAtIndex:idxx] release];
    }];
    [cols release];
  }];
  [table release];
  table = nil;

}

/**
 * clearCache
 */
- (void)clearCache {
  [cache removeAllObjects];
}

/**
 * cacheFullRedraw
 */
- (void)cacheFullRedraw {
  [table enumerateObjectsUsingBlock:^(id object, NSUInteger idxy, BOOL *stop) {
    NSMutableArray<BXVGATile *> * cols;
    cols = [table objectAtIndex:idxy];
    [cols enumerateObjectsUsingBlock:^(id object, NSUInteger idxx, BOOL *stop) {
      [cache addObject:[cols objectAtIndex:idxx]];
    }];
  }];
}

- (void)cacheRender {

  if (self.hasUpdate) {

    [viewbuffer lockFocus];

    // only drawing from cache
    [cache enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
      BXVGATile * tile;
      NSRect tilePos;

      tile = [cache objectAtIndex:idx];
      tilePos = NSMakeRect(tile.XY.x, tile.XY.y, tile.size.width, tile.size.height);

      [tile drawInRect:tilePos fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0f];
    }];

    [self clearCache];

    [viewbuffer unlockFocus];

  }

}

/**
 * updateTile
 */
- (void)updateTile:(BXVGATile *) tile x:(unsigned) col y:(unsigned) row {

  NSMutableArray<BXVGATile *> * cols;
  UInt32 tilecrc;

  cols = [table objectAtIndex:row];

  tilecrc = [cols objectAtIndex:col].crc;
  if ((tilecrc == 0) | (tilecrc != tile.crc)) {
    // calculate tile XY
    tile.XY = NSMakePoint(col*self.tileSize.width, row*self.tileSize.height);
    [[cols objectAtIndex:col] release];
    [cols replaceObjectAtIndex:col withObject:tile];
    [cache addObject:tile];
  }

}

/**
 * updateTileCFData
 */
- (void)updateTileCFData:(CFMutableDataRef) cfRef DataRefSize:(unsigned) cfSize colorspace:(CGColorSpaceRef) csRef xpos:(unsigned) x ypos:(unsigned) y {

  BXVGATile * tile;
  CGDataProviderRef provider;
  CGImageRef rgbImageRef;
  UInt32 tilecrc;

  provider = CGDataProviderCreateWithCFData(cfRef);
  BXL_DEBUG(([NSString stringWithFormat:@"image width=%d height=%d", (unsigned)self.tileSize.width, (unsigned)self.tileSize.height]));
  rgbImageRef = CGImageCreate(self.tileSize.width, self.tileSize.height, self.bitsPerComponent, self.bpp, self.stride, csRef, kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
  CGDataProviderRelease(provider);
  // calc crc32
  tilecrc = crc32buf((const unsigned char *)CFDataGetMutableBytePtr(cfRef), cfSize);
  // tile = [[[BXVGATile alloc] initWithCGImage:rgbImageRef size:NSZeroSize] autorelease];
  tile = [[BXVGATile alloc] initWithCGImage:rgbImageRef size:self.tileSize crc:tilecrc];
  CGImageRelease(rgbImageRef);

  [self updateTile:tile x:x/self.tileSize.width y:y/self.tileSize.height];

}

- (BOOL)wantsLayer {
  return YES;
}
- (BOOL)wantsUpdateLayer {
  return YES;
}

- (void)updateLayer {

  CGFloat windowScaleFactor;
  CGFloat imageScaleFactor;

  windowScaleFactor = self.window.backingScaleFactor;
  imageScaleFactor = [viewbuffer recommendedLayerContentsScale:windowScaleFactor];

  self.layer.contents = [viewbuffer layerContentsForContentsScale:imageScaleFactor];
  self.layer.contentsScale = imageScaleFactor;

}

/**
 * drawRect
 */
- (void)drawRect:(NSRect)dirtyRect {

  BXL_INFO(([NSString stringWithFormat:@"execute drawRect"]));
//
//   // NSRect viewbufferRect;
//
//   if (self.hasUpdate) {
//
//     [viewbuffer lockFocus];
//
//     // only drawing from cache
//     [cache enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
//       BXVGATile * tile;
//       NSRect tilePos;
//
//       tile = [cache objectAtIndex:idx];
//       tilePos = NSMakeRect(tile.XY.x, tile.XY.y, tile.size.width, tile.size.height);
//
//       [tile drawInRect:tilePos fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0f];
//     }];
//
//     [self clearCache];
//
//     [viewbuffer unlockFocus];
//
//   }
//
//   // // now draw the cache
//   // viewbufferRect = NSMakeRect(0 , 0, [viewbuffer size].width, [viewbuffer size].height);
//   // [viewbuffer drawInRect:viewbufferRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0f];
//
}

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

    // // allocate screen buffer
    // self.screen = (unsigned char *)malloc((self.stride * h) * sizeof(unsigned char));
    // NSAssert(self.screen != NULL, @"screen [%p]: allocate memory failed.", self.screen);
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

    imgview = [[BXVGAImageView alloc] initWithFrame:NSMakeRect(0, 0, self.width, self.height) col_width:fw col_height:fh bits:bpp];
    imgview.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
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
  // free((void *)self.screen);
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

    // // recreate screen buffer
    // free((void *)self.screen);
    // self.screen = (unsigned char *)malloc((self.stride * h) * sizeof(unsigned char));
    // NSAssert(self.screen != NULL, @"screen [%p]: allocate memory failed.", self.screen);
    // reconstruct view
    [imgview updateWithFrame:NSMakeSize(self.width, self.height) col_width:fw col_height:fh bits:bpp];
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

  if (imgview.hasUpdate) {
    [imgview cacheRender];

    [imgview setNeedsDisplay:YES];
  }

  // CGColorSpaceRef colorspace;
  // CFDataRef data;
  // CGDataProviderRef provider;
  // CGImageRef rgbImageRef;
  // NSImage * image;
  //
  // // do not render if not needed
  // if (!self.dirty) {
  //   return;
  // }
  //
  // // create colorspace
  // BXL_DEBUG(([NSString stringWithFormat:@"colorspace size=%d palette=%p", self.palette_size-1, self.palette]));
  // colorspace = CGColorSpaceCreateIndexed(CGColorSpaceCreateDeviceRGB(), self.palette_size-1, self.palette);
  // if (colorspace == NULL) {
  //   BXL_FATAL((@"colorspace failed."));
  // }
  // data = CFDataCreate(NULL, self.screen, (self.stride * self.height));
  // provider = CGDataProviderCreateWithCFData(data);
  // BXL_DEBUG(([NSString stringWithFormat:@"image width=%d height=%d", self.width, self.height]));
  // rgbImageRef = CGImageCreate(self.width, self.height, self.bitsPerComponent, self.bpp, self.stride, colorspace, kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
  // CGDataProviderRelease(provider);
  // CGColorSpaceRelease(colorspace);
  // image = [[[NSImage alloc] initWithCGImage:rgbImageRef size:NSZeroSize] autorelease];
  // CGImageRelease(rgbImageRef);
  //
  // BXL_DEBUG((@"render done."));
  //
  // // BX_LOG(([NSString stringWithFormat:@"vaild %s", image.isValid?"YES":"NO"]));
  // //
  // // BX_LOG(([NSString stringWithFormat:@"render width=%d height=%d", self.width, self.height]));
  //
  // [imgview setImage:image];
  //
  // CFRelease(data);

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
  // imgview.fullRedraw = YES;
  // self.dirty = YES;
  // BXL_INFO((@"clearScreen"));
  // BXL_INFO(([NSString stringWithFormat:@"imgview.wantsLayer=%s", imgview.wantsLayer?"YES":"NO"]));
  // memset((void *)self.screen, 0, (self.stride * self.height) * sizeof(unsigned char));
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
  unsigned charMaxHeight;
  unsigned char noOfComponents;
  unsigned char vgaAccessMode;
  CGColorSpaceRef colorspace;

  // Font format
  // 8bit hi 8bit lo - repeated h times

  // BXL_INFO(([NSString stringWithFormat:@"paintChar pos=%d isCrsr=%d font2=%d bg=%d fg=%d x=%d y=%d w=%d h=%d",
  //   charpos, crsr, f2, bg, fg, (unsigned)rect.origin.x, (unsigned)rect.origin.y, (unsigned)rect.size.width, (unsigned)rect.size.height]));

  NSAssert(charpos < 256 , @"charpos out of range %d", charpos);

  // do not allow write outside screen
  NSAssert(((unsigned)rect.origin.x + (unsigned)rect.size.width) <= self.width, @"paintChar x out of range [%d]", ((unsigned)rect.origin.x + (unsigned)rect.size.width));
  NSAssert(((unsigned)rect.origin.y + (unsigned)rect.size.height) <= self.height, @"paintChar y out of range [%d]", ((unsigned)rect.origin.y + (unsigned)rect.size.height));

  selectedFont = f2 ? self.FontB : self.FontA;
  selectedChar = &selectedFont[charpos * CHARACTER_WORDS];
  NSAssert(selectedChar < (selectedFont + (FONT_DATA_SIZE * sizeof(unsigned short int))), @"paintChar char out of range [%d]", charpos);

  if (self.bitsPerComponent == 8) {
    noOfComponents = self.bpp / self.bitsPerComponent;
    // screenStartXbytes = ((unsigned)rect.origin.x) * noOfComponents;
    // screenStartXbits = 0;
    vgaAccessMode = noOfComponents >= 3 ? VGA_ACCESS_MODE_DWORD : noOfComponents;
  } else {
    // noOfComponents = 0;
    // screenStartXbits = 0;
    NSAssert(NO, @"Not yet implemented.");
  }

  charMaxHeight = ((unsigned)rect.size.height > self.font_height) ? self.font_height : (unsigned)rect.size.height;

  switch (vgaAccessMode) {
    case VGA_ACCESS_MODE_BYTE: {
      // CFMutableDataRef cfdata;
      NSMutableData * data;
      unsigned datasize;
      unsigned short int maskend;
      unsigned char * screenMemory;

      // cfdata = CFDataCreateMutable(kCFAllocatorDefault, noOfComponents * (unsigned)rect.size.width * (unsigned)rect.size.height);
      datasize = noOfComponents * (unsigned)rect.size.width * (unsigned)rect.size.height;
      data = [[[NSMutableData alloc] initWithLength:datasize] autorelease];
      // (CFMutableDataRef)[[NSMutableData alloc] initWithLength:(noOfComponents * (unsigned)rect.size.width * (unsigned)rect.size.height)];
      // NSAssert(cfdata != NULL, @"CFData allocate failed.");
      maskend = VGA_WORD_BIT_MASK>>(unsigned)rect.size.width;
      screenMemory = data.mutableBytes; //CFDataGetMutableBytePtr(data);
      NSAssert(screenMemory != NULL, @"CFData allocate failed.");

      for (unsigned charRow=0; charRow<charMaxHeight; charRow++) {

        unsigned short int mask;

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

      // create colorspace
      BXL_DEBUG(([NSString stringWithFormat:@"colorspace size=%d palette=%p", self.palette_size-1, self.palette]));
      colorspace = CGColorSpaceCreateIndexed(CGColorSpaceCreateDeviceRGB(), self.palette_size-1, self.palette);
      if (colorspace == NULL) {
        BXL_FATAL((@"colorspace failed."));
      }

      [imgview updateTileCFData:(CFMutableDataRef)data DataRefSize:datasize colorspace:colorspace xpos:(unsigned)rect.origin.x ypos:(self.height - (unsigned)rect.size.height) - (unsigned)rect.origin.y];

      CGColorSpaceRelease(colorspace);
      // CFRelease(cfdata);

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










  // unsigned short int * selectedFont;
  // unsigned short int * selectedChar;
  // unsigned screenStartY;
  // unsigned screenStartXbytes;
  // unsigned screenStartXbits;
  // unsigned char noOfComponents;
  // unsigned char vgaAccessMode;
  // unsigned charMaxHeight;
  //
  //
  // // Font format
  // // 8bit hi 8bit lo - repeated h times
  //
  // NSAssert(charpos < 256 , @"charpos out of range %d", charpos);
  //
  // // do not allow write outside screen
  // NSAssert(((unsigned)rect.origin.x + (unsigned)rect.size.width) <= self.width, @"paintChar x out of range [%d]", ((unsigned)rect.origin.x + (unsigned)rect.size.width));
  // NSAssert(((unsigned)rect.origin.y + (unsigned)rect.size.height) <= self.height, @"paintChar y out of range [%d]", ((unsigned)rect.origin.y + (unsigned)rect.size.height));
  //
  // selectedFont = f2 ? self.FontB : self.FontA;
  // selectedChar = &selectedFont[charpos * CHARACTER_WORDS];
  // NSAssert(selectedChar < (selectedFont + (FONT_DATA_SIZE * sizeof(unsigned short int))), @"paintChar char out of range [%d]", charpos);
  //
  //
  // // screenStartY not affected by bpp
  // // screenStartY = ((unsigned)(rect.origin.y) * self.stride);
  //
  //
  //
  // if (self.bitsPerComponent == 8) {
  //   noOfComponents = self.bpp / self.bitsPerComponent;
  //   screenStartXbytes = ((unsigned)rect.origin.x) * noOfComponents;
  //   screenStartXbits = 0;
  //   vgaAccessMode = noOfComponents >= 3 ? VGA_ACCESS_MODE_DWORD : noOfComponents;
  // } else {
  //   noOfComponents = 0;
  //   screenStartXbits = 0;
  //   NSAssert(NO, @"Not yet implemented.");
  // }
  //
  // // screenStart = self.screen + screenStartY + screenStartXbytes;
  // // NSAssert(screenStart < self.screen + self.stride * self.height, @"screenStart out of range %p min %p max %p x %d y %d",
  // //   screenStart, self.screen, self.screen + self.stride * self.height, (unsigned)rect.origin.x, (unsigned)rect.origin.y);
  //
  // charMaxHeight = ((unsigned)rect.size.height > self.font_height) ? self.font_height : (unsigned)rect.size.height;
  //
  // // depending on bpp <=8 <=16 <=32 - different access to screen memory
  // switch (vgaAccessMode) {
  //   case VGA_ACCESS_MODE_BYTE: {
  //
  //     unsigned short int maskend;
  //     unsigned char * screenMemory;
  //
  //     maskend = VGA_WORD_BIT_MASK>>(unsigned)rect.size.width;
  //
  //     for (unsigned charRow=0; charRow<charMaxHeight; charRow++) {
  //
  //       unsigned short int mask;
  //
  //       screenStartY = (((unsigned)(rect.origin.y) + charRow) * self.stride);
  //       screenMemory = (unsigned char *)(self.screen + screenStartY + screenStartXbytes);
  //
  //       // each bit of selectedChar
  //       for (mask = VGA_WORD_BIT_MASK; mask != maskend; mask >>=1) {
  //         if ((*selectedChar & mask) | crsr) {
  //           *screenMemory = fg;
  //         } else {
  //           *screenMemory = bg;
  //         }
  //         screenMemory++;
  //       }
  //
  //       selectedChar++;
  //
  //     }
  //
  //     break;
  //   }
  //   case VGA_ACCESS_MODE_WORD: {
  //     NSAssert(NO, @"Not yet implemented.");
  //     break;
  //   }
  //   case VGA_ACCESS_MODE_DWORD: {
  //     NSAssert(NO, @"Not yet implemented.");
  //     break;
  //   }
  // }
  //
  self.dirty = YES;

}

/**
 * clip gfx region into screen
 */
- (void)clipRegion:(unsigned char *) src position:(NSRect) rect {

BXL_INFO(([NSString stringWithFormat:@"clipRegion src=%p x=%d y=%d w=%d h=%d", src, (unsigned)rect.origin.x, (unsigned)rect.origin.y, (unsigned)rect.size.width, (unsigned)rect.size.height]));
  // unsigned screenStartY;
  // unsigned screenStartXbytes;
  // unsigned screenStartXbits;
  // unsigned char noOfComponents;
  // unsigned char vgaAccessMode;
  // unsigned blitMaxHeight;
  // unsigned char * srcMemory;
  //
  // // do not allow write outside screen
  // if (((unsigned)rect.origin.x + (unsigned)rect.size.width) > self.width) {
  //   return;
  // }
  // if (((unsigned)rect.origin.y + (unsigned)rect.size.height) > self.height) {
  //   return;
  // }
  // NSAssert(((unsigned)rect.origin.x + (unsigned)rect.size.width) <= self.width, @"clipRegion x out of range max[%d] is[%d]", self.width, ((unsigned)rect.origin.x + (unsigned)rect.size.width));
  // NSAssert(((unsigned)rect.origin.y + (unsigned)rect.size.height) <= self.height, @"clipRegion y out of range max[%d] is[%d]", self.height, ((unsigned)rect.origin.y + (unsigned)rect.size.height));
  //
  //
  // if (self.bitsPerComponent == 8) {
  //   noOfComponents = self.bpp / self.bitsPerComponent;
  //   screenStartXbytes = ((unsigned)rect.origin.x) * noOfComponents;
  //   screenStartXbits = 0;
  //   vgaAccessMode = noOfComponents >= 3 ? VGA_ACCESS_MODE_DWORD : noOfComponents;
  // } else {
  //   noOfComponents = 0;
  //   screenStartXbits = 0;
  //   NSAssert(NO, @"Not yet implemented.");
  // }
  //
  // // font height only set in text mode !!!
  // blitMaxHeight = (unsigned)rect.size.height;
  // //((unsigned)rect.size.height > self.font_height) ? self.font_height : (unsigned)rect.size.height;
  //
  // BXL_DEBUG(([NSString stringWithFormat:@"clipRegion vgaAccessMode=%d blitMaxHeight=%d font_height=%d", vgaAccessMode, blitMaxHeight, self.font_height]));
  //
  // // depending on bpp <=8 <=16 <=32 - different access to screen memory
  // switch (vgaAccessMode) {
  //   case VGA_ACCESS_MODE_BYTE: {
  //
  //     // print_buf(src, ((unsigned)rect.size.width * (unsigned)rect.size.height));
  //     // NSAssert(NO, @"Not yet implemented.");
  //
  //     // unsigned short int maskend;
  //     unsigned char * screenMemory;
  //     //
  //     // maskend = VGA_WORD_BIT_MASK>>(unsigned)rect.size.width;
  //     srcMemory = src;
  //     //
  //     for (unsigned blitRow=0; blitRow<blitMaxHeight; blitRow++) {
  //     //
  //     //   unsigned short int mask;
  //     //
  //       screenStartY = (((unsigned)(rect.origin.y) + blitRow) * self.stride);
  //       screenMemory = (unsigned char *)(self.screen + screenStartY + screenStartXbytes);
  //
  //       // first try memcopy
  //       memcpy((void *)screenMemory, srcMemory, (unsigned)rect.size.width * sizeof(unsigned char));
  //       // memset((void *)screenMemory, 0x34, (unsigned)rect.size.width * sizeof(unsigned char));
  //
  //     //
  //     //   // each bit of selectedChar
  //     //   for (mask = VGA_WORD_BIT_MASK; mask != maskend; mask >>=1) {
  //     //     if ((*selectedChar & mask) | crsr) {
  //     //       *screenMemory = fg;
  //     //     } else {
  //     //       *screenMemory = bg;
  //     //     }
  //     //     screenMemory++;
  //     //   }
  //     //
  //       srcMemory += (unsigned)rect.size.width;
  //     //
  //     }
  //
  //     break;
  //   }
  //   case VGA_ACCESS_MODE_WORD: {
  //     NSAssert(NO, @"Not yet implemented.");
  //     break;
  //   }
  //   case VGA_ACCESS_MODE_DWORD: {
  //     NSAssert(NO, @"Not yet implemented.");
  //     break;
  //   }
  // }
  //
  // self.dirty = YES;


}












@end
