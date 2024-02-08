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


////////////////////////////////////////////////////////////////////////////////
// BXVGAImageView
////////////////////////////////////////////////////////////////////////////////
@implementation BXVGAImageView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect) frameRect {

  self = [super initWithFrame:frameRect];
  if(self) {

    // create screen context
    self.VGAcolorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);
    self.VGAcontext = CGBitmapContextCreate(NULL, (unsigned)frameRect.size.width, (unsigned)frameRect.size.height, 8, 4*(unsigned)frameRect.size.width, self.VGAcolorspace, kCGImageAlphaNoneSkipLast | kCGImageByteOrder32Big);
    NSAssert(self.VGAcontext != NULL, @"VGAcontext allocate failed.");
    
    self.bpp = CGBitmapContextGetBitsPerPixel(self.VGAcontext);
    self.stride = CGBitmapContextGetBytesPerRow(self.VGAcontext);
    self.bitsPerComponent = CGBitmapContextGetBitsPerComponent(self.VGAcontext);
    
    self.VGAdisplay = (unsigned char *)CGBitmapContextGetData(self.VGAcontext);

    self.VGAimage = CGBitmapContextCreateImage(self.VGAcontext);
    self.layer.contents = (id)self.VGAimage;
    
    // create dirty list
    self.dirtyRegions = [[NSMutableArray alloc] init];
    [self updateVGA:frameRect];

  }

  return self;

}

/**
 * dealloc
 */
- (void)dealloc {

  CGImageRelease(self.VGAimage);
  CFRelease(self.VGAcontext);
  CGColorSpaceRelease(self.VGAcolorspace);
  
}

/**
 * disable the mouse events on this view
 * now window has control over the events
 */
- (NSView * _Nullable)hitTest:(NSPoint)point {
  
  return nil;
  
}

/**
 * wantsUpdateLayer
 */
 - (BOOL)wantsUpdateLayer {
   
   return YES;
   
 }

/**
 * updateWithFrame
 */
- (void)updateWithFrame:(NSSize) frameSize {

  CGImageRef oldref;
  
  [self setFrameSize:frameSize];

  if (self.VGAcontext != NULL) {
    CFRelease(self.VGAcontext);
  }
  self.VGAcontext = CGBitmapContextCreate(NULL, (unsigned)frameSize.width, (unsigned)frameSize.height, 8, 4*(unsigned)frameSize.width, self.VGAcolorspace, kCGImageAlphaNoneSkipLast | kCGImageByteOrder32Big);
  NSAssert(self.VGAcontext != NULL, @"VGAcontext allocate failed.");
  
  self.bpp = CGBitmapContextGetBitsPerPixel(self.VGAcontext);
  self.stride = CGBitmapContextGetBytesPerRow(self.VGAcontext);
  self.bitsPerComponent = CGBitmapContextGetBitsPerComponent(self.VGAcontext);
  
  self.VGAdisplay = (unsigned char *)CGBitmapContextGetData(self.VGAcontext);

  oldref = self.VGAimage;
  self.VGAimage = CGBitmapContextCreateImage(self.VGAcontext);
  self.layer.contents = (id)self.VGAimage;
  if (oldref != NULL) {
    CGImageRelease(oldref);
  }
  
  [self.dirtyRegions removeAllObjects];
  [self updateVGA:NSMakeRect(0, 0, frameSize.width, frameSize.height)];
  
}

/**
 * renderVGAdisplayContent
 */
- (void)renderVGAdisplayContent {
  
  CGImageRef oldref;
  
  oldref = self.VGAimage;
  self.VGAimage = CGBitmapContextCreateImage(self.VGAcontext);
  self.layer.contents = (id)self.VGAimage;
  
  if (oldref != NULL) {
    CGImageRelease(oldref);
  }

  // now update the rects
  
  for (NSValue * vrect in self.dirtyRegions) {
    
    NSRect region;
    
    region = vrect.rectValue;
    [self setNeedsDisplayInRect:region];
    // if full redraw we are done
    if (CGRectEqualToRect(region, self.frame)) {
      break;
    }
    
  }
  [self.dirtyRegions removeAllObjects];
  
}

/**
 * updateVGA
 */
- (void)updateVGA:(NSRect) dirty {

  NSValue * vrect;
  
  vrect = [NSValue value:&dirty withObjCType:@encode(NSRect)];

  [self.dirtyRegions addObject:vrect];
  
}

@end


////////////////////////////////////////////////////////////////////////////////
// BXVGAdisplay
////////////////////////////////////////////////////////////////////////////////
@implementation BXVGAdisplay

/**
 * init
 */
- (instancetype _Nonnull)init:(unsigned) bpp width:(unsigned) w height:(unsigned) h font_width:(unsigned) fw font_height:(unsigned) fh view:(NSView * _Nonnull) v {

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
    self.bitsPerComponent = bpp % 8 == 0 ? 8 : bpp;

    // allocate palette buffer
    self.palette_size = pow(2, bpp);
    NSAssert(self.palette_size != 0, @"palette_size [%d]: invalid palette size.", self.palette_size);
    self.palette = (UInt32 *)malloc((self.palette_size) * sizeof(UInt32));
    NSAssert(self.palette != NULL, @"palette [%p]: allocate memory failed.", self.palette);

    // allocate font memory
    self.FontA = (unsigned short int *)malloc(FONT_DATA_SIZE * sizeof(unsigned short int));
    NSAssert(self.FontA != NULL, @"FontA [%p]: allocate memory failed.", self.FontA);
    memset((void *)self.FontA, 0, FONT_DATA_SIZE * sizeof(unsigned short int));
    self.FontB = (unsigned short int *)malloc(FONT_DATA_SIZE * sizeof(unsigned short int));
    NSAssert(self.FontB != NULL, @"FontB [%p]: allocate memory failed.", self.FontB);
    memset((void *)self.FontB, 0, FONT_DATA_SIZE * sizeof(unsigned short int));

    self.imgview = [[BXVGAImageView alloc] initWithFrame:NSMakeRect(0, 0, self.width, self.height)];
    self.imgview.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
    [v addSubview:self.imgview];
    v.needsDisplay = YES;

    self.dirty = YES;

  }

  return self;

}

/**
 * dealloc
 */
- (void)dealloc {

  free((void *)self.FontA);
  free((void *)self.FontB);
  free((void *)self.palette);

}


/**
 * change display mode
 */
- (void)changeBPP:(unsigned) bpp width:(unsigned) w height:(unsigned) h font_width:(unsigned) fw font_height:(unsigned) fh {

  if (self.bpp != bpp) {
    self.bpp = bpp;
    // calculate the number of bits for each component in a source pixel
    self.bitsPerComponent = bpp % 8 == 0 ? 8 : bpp;
    self.palette_size = pow(2, bpp);
    NSAssert(self.palette_size != 0, @"palette_size [%d]: invalid palette size.", self.palette_size);
    // recreate palette buffer
    self.palette = (UInt32 *)realloc(self.palette, self.palette_size * sizeof(UInt32));
    NSAssert(self.palette != NULL, @"palette [%p]: allocate memory failed.", self.palette);
  }
  // calculate the number of bytes of memory for each horizontal row of the bitmap
  self.stride = w * bpp / 8;
  if ((self.bpp != bpp) || (self.width != w) || (self.height != h)) {
    self.width = w;
    self.height = h;
    // reconstruct view
    [self.imgview updateWithFrame:NSMakeSize(self.width, self.height)];
  }

  if ((self.font_width != fw) || (self.font_height != fh)) {
    self.font_width = fw;
    self.font_height = fh;
    NSAssert(((self.font_width * self.font_height * 256)/CHARACTER_WORDS) <= (FONT_DATA_SIZE * sizeof(unsigned short int)), @"font [%d,%d,%d,%d]: fontbuffer overflow.",
    ((self.font_width * self.font_height * 256)/CHARACTER_WORDS), (unsigned)(FONT_DATA_SIZE * sizeof(unsigned short int)), self.font_width, self.font_height);
  }

  self.dirty = YES;

}

/**
 * render the image
 */
- (void)render {

  // do not render if not needed
  if (!self.dirty) {
    return;
  }

  [self.imgview renderVGAdisplayContent];

  self.dirty = NO;

}

/**
 * set one entry in palette
 */
- (BOOL)setPaletteRGB:(unsigned)index red:(unsigned char) r green:(unsigned char) g blue:(unsigned char) b {

  // do not overwrite ...
  if (index >= self.palette_size) {
    BXL_ERROR(([NSString stringWithFormat:@"setPaletteRGB index overflow max=%d index=%d", self.palette_size-1, index]));
    return NO;
  }

  self.palette[index] = (0x00000000 | (b << 16) | (g << 8) | r );
  
  return YES;

}

/**
 * fill screen with 0
 */
- (void)clearScreen {
  memset((void *)self.imgview.VGAdisplay, 0, (self.imgview.stride * self.height) * sizeof(unsigned char));
}

/**
 * init FontA & FontB with default values
 */
- (void)initFonts:(unsigned char * _Nonnull) dataA second:(unsigned char * _Nonnull) dataB width:(unsigned char)w height:(unsigned char) h {

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
- (void)updateFontAt:(unsigned) pos isFont2:(BOOL)font2 map:(unsigned char * _Nonnull) data {

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
  UInt32 bg_abgr;
  UInt32 fg_abgr;
  unsigned charMaxHeight;
  unsigned short int maskend;
  unsigned screenStartXbytes;

  // Font format
  // 8bit hi 8bit lo - repeated h times

  NSAssert(charpos < 256 , @"charpos out of range %d", charpos);

  // do not allow write outside screen
  NSAssert(((unsigned)rect.origin.x + (unsigned)rect.size.width) <= self.width, @"paintChar x out of range [%d]", ((unsigned)rect.origin.x + (unsigned)rect.size.width));
  NSAssert(((unsigned)rect.origin.y + (unsigned)rect.size.height) <= self.height, @"paintChar y out of range [%d]", ((unsigned)rect.origin.y + (unsigned)rect.size.height));

  selectedFont = f2 ? self.FontB : self.FontA;
  selectedChar = &selectedFont[charpos * CHARACTER_WORDS];
  NSAssert(selectedChar < (selectedFont + (FONT_DATA_SIZE * sizeof(unsigned short int))), @"paintChar char out of range [%d]", charpos);
  bg_abgr = self.palette[bg];
  fg_abgr = self.palette[fg];
  
  // destination is 4 byte each pixel
  
  charMaxHeight = ((unsigned)rect.size.height > self.font_height) ? self.font_height : (unsigned)rect.size.height;
  maskend = VGA_WORD_BIT_MASK >> (unsigned)rect.size.width;
  screenStartXbytes = ((unsigned)rect.origin.x) * 4;
  
  for (unsigned charRow=0; charRow<charMaxHeight; charRow++) {
    
    unsigned short int mask;
    unsigned screenStartY;
    UInt32 * screenMemory;
    
    screenStartY = (((unsigned)(rect.origin.y) + charRow) * self.imgview.stride);
    screenMemory = (UInt32 *)(self.imgview.VGAdisplay + screenStartY + screenStartXbytes);
    
    // each bit of selectedChar
    for (mask = VGA_WORD_BIT_MASK; mask != maskend; mask >>=1) {
      
      if ((*selectedChar & mask) | crsr) {
        *screenMemory = fg_abgr;
      } else {
        *screenMemory = bg_abgr;
      }
      screenMemory++;
    }
    
    selectedChar++;
    
  }
  
  [self clipRegionPosition:rect];

}

/**
 * clip gfx region into screen
 */
- (void)clipRegion:(unsigned char * _Nonnull) src position:(NSRect) rect {
  
  unsigned x_overflow;
  unsigned y_overflow;
  
  // bug in vgacore
  // sending regions outside screen
  // until this is fixed we can't assert !!!
//  NSAssert(((unsigned)rect.origin.x + (unsigned)rect.size.width) <= self.width, @"clipRegion x out of range max[%d] is[%d]", self.width, ((unsigned)rect.origin.x + (unsigned)rect.size.width));
//  NSAssert(((unsigned)rect.origin.y + (unsigned)rect.size.height) <= self.height, @"clipRegion y out of range max[%d] is[%d]", self.height, ((unsigned)rect.origin.y + (unsigned)rect.size.height));
  
  x_overflow = ((unsigned)rect.origin.x + (unsigned)rect.size.width) > self.width ? ((unsigned)rect.origin.x + (unsigned)rect.size.width) - self.width : 0;
  y_overflow = ((unsigned)rect.origin.y + (unsigned)rect.size.height) > self.height ? ((unsigned)rect.origin.y + (unsigned)rect.size.height) - self.height : 0;
  
  switch (self.bitsPerComponent) {
      
    case 8: {
      
      unsigned char noOfComponents;
      unsigned screenStartXbytes;
      
      noOfComponents = self.bpp / self.bitsPerComponent;
      screenStartXbytes = ((unsigned)rect.origin.x) * (self.imgview.bpp / self.imgview.bitsPerComponent);
      
      switch (noOfComponents) {
        case 1: { // 8 bit
          
          unsigned char * srcMemory;
          unsigned screenStartY;
          UInt32 * screenMemory;
          
          srcMemory = src;
          for (unsigned blitRow=0; blitRow < ((unsigned)rect.size.height - y_overflow); blitRow++) {
            
            screenStartY = (((unsigned)(rect.origin.y) + blitRow) * self.imgview.stride);
            screenMemory = (UInt32 *)(self.imgview.VGAdisplay + screenStartY + screenStartXbytes);
            
            for (unsigned blitCol=0; blitCol < ((unsigned)rect.size.width - x_overflow); blitCol++) {
              *screenMemory = self.palette[*srcMemory];
              srcMemory++;
              screenMemory++;
            }
            if (x_overflow) {
              srcMemory = src + (blitRow * (unsigned)rect.size.width);
            }
            
          }
          
          break;
        }
        case 2: { // 16 bit
          NSAssert(NO, @"Not yet implemented.");
        }
        case 3: { // 24 bit
          NSAssert(NO, @"Not yet implemented.");
        }
        case 4: { // 32 bit
          NSAssert(NO, @"Not yet implemented.");
        }
        default: {
          NSAssert(NO, @"illegal no of components [%d]", noOfComponents);
        }
      }
      break;
    }
    default: {
      NSAssert(NO, @"Not yet implemented.");
    }
  }
  
  [self clipRegionPosition:rect];
  
}

/**
 * VGAdisplayRAM Ptr
 */
- (const unsigned char * _Nonnull)VGAdisplayRAM {
  
  return (const unsigned char *)self.imgview.VGAdisplay;
  
}

/**
 * clipRegionPosition
 */
- (void)clipRegionPosition:(NSRect) rect {

  NSRect udrect;
  
  udrect = NSMakeRect(rect.origin.x, self.height - (rect.origin.y + rect.size.height), rect.size.width, rect.size.height);

  [self.imgview updateVGA:udrect];
  self.dirty = YES;
  
}

@end
