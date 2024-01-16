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

#define UPDC32(octet,crc) (crc_32_tab[((crc)\
     ^ ((UInt8)octet)) & 0xff] ^ ((crc) >> 8))

static UInt32 crc_32_tab[] = { /* CRC polynomial 0xedb88320 */
  0x00000000, 0x77073096, 0xee0e612c, 0x990951ba, 0x076dc419, 0x706af48f,
  0xe963a535, 0x9e6495a3, 0x0edb8832, 0x79dcb8a4, 0xe0d5e91e, 0x97d2d988,
  0x09b64c2b, 0x7eb17cbd, 0xe7b82d07, 0x90bf1d91, 0x1db71064, 0x6ab020f2,
  0xf3b97148, 0x84be41de, 0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7,
  0x136c9856, 0x646ba8c0, 0xfd62f97a, 0x8a65c9ec, 0x14015c4f, 0x63066cd9,
  0xfa0f3d63, 0x8d080df5, 0x3b6e20c8, 0x4c69105e, 0xd56041e4, 0xa2677172,
  0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b, 0x35b5a8fa, 0x42b2986c,
  0xdbbbc9d6, 0xacbcf940, 0x32d86ce3, 0x45df5c75, 0xdcd60dcf, 0xabd13d59,
  0x26d930ac, 0x51de003a, 0xc8d75180, 0xbfd06116, 0x21b4f4b5, 0x56b3c423,
  0xcfba9599, 0xb8bda50f, 0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924,
  0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d, 0x76dc4190, 0x01db7106,
  0x98d220bc, 0xefd5102a, 0x71b18589, 0x06b6b51f, 0x9fbfe4a5, 0xe8b8d433,
  0x7807c9a2, 0x0f00f934, 0x9609a88e, 0xe10e9818, 0x7f6a0dbb, 0x086d3d2d,
  0x91646c97, 0xe6635c01, 0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e,
  0x6c0695ed, 0x1b01a57b, 0x8208f4c1, 0xf50fc457, 0x65b0d9c6, 0x12b7e950,
  0x8bbeb8ea, 0xfcb9887c, 0x62dd1ddf, 0x15da2d49, 0x8cd37cf3, 0xfbd44c65,
  0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2, 0x4adfa541, 0x3dd895d7,
  0xa4d1c46d, 0xd3d6f4fb, 0x4369e96a, 0x346ed9fc, 0xad678846, 0xda60b8d0,
  0x44042d73, 0x33031de5, 0xaa0a4c5f, 0xdd0d7cc9, 0x5005713c, 0x270241aa,
  0xbe0b1010, 0xc90c2086, 0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
  0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4, 0x59b33d17, 0x2eb40d81,
  0xb7bd5c3b, 0xc0ba6cad, 0xedb88320, 0x9abfb3b6, 0x03b6e20c, 0x74b1d29a,
  0xead54739, 0x9dd277af, 0x04db2615, 0x73dc1683, 0xe3630b12, 0x94643b84,
  0x0d6d6a3e, 0x7a6a5aa8, 0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1,
  0xf00f9344, 0x8708a3d2, 0x1e01f268, 0x6906c2fe, 0xf762575d, 0x806567cb,
  0x196c3671, 0x6e6b06e7, 0xfed41b76, 0x89d32be0, 0x10da7a5a, 0x67dd4acc,
  0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5, 0xd6d6a3e8, 0xa1d1937e,
  0x38d8c2c4, 0x4fdff252, 0xd1bb67f1, 0xa6bc5767, 0x3fb506dd, 0x48b2364b,
  0xd80d2bda, 0xaf0a1b4c, 0x36034af6, 0x41047a60, 0xdf60efc3, 0xa867df55,
  0x316e8eef, 0x4669be79, 0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236,
  0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f, 0xc5ba3bbe, 0xb2bd0b28,
  0x2bb45a92, 0x5cb36a04, 0xc2d7ffa7, 0xb5d0cf31, 0x2cd99e8b, 0x5bdeae1d,
  0x9b64c2b0, 0xec63f226, 0x756aa39c, 0x026d930a, 0x9c0906a9, 0xeb0e363f,
  0x72076785, 0x05005713, 0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38,
  0x92d28e9b, 0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21, 0x86d3d2d4, 0xf1d4e242,
  0x68ddb3f8, 0x1fda836e, 0x81be16cd, 0xf6b9265b, 0x6fb077e1, 0x18b74777,
  0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c, 0x8f659eff, 0xf862ae69,
  0x616bffd3, 0x166ccf45, 0xa00ae278, 0xd70dd2ee, 0x4e048354, 0x3903b3c2,
  0xa7672661, 0xd06016f7, 0x4969474d, 0x3e6e77db, 0xaed16a4a, 0xd9d65adc,
  0x40df0b66, 0x37d83bf0, 0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
  0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6, 0xbad03605, 0xcdd70693,
  0x54de5729, 0x23d967bf, 0xb3667a2e, 0xc4614ab8, 0x5d681b02, 0x2a6f2b94,
  0xb40bbe37, 0xc30c8ea1, 0x5a05df1b, 0x2d02ef8d
};

UInt32 crc32buf(const unsigned char * buf, size_t len) {
  register UInt32 oldcrc32;

  oldcrc32 = 0xFFFFFFFF;

  for ( ; len; --len, ++buf)
  {
    oldcrc32 = UPDC32(*buf, oldcrc32);
  }

  return ~oldcrc32;

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
    cache = [[[NSMutableArray alloc] init] autorelease];

    // create buffer
    viewbuffer = [[[NSImage alloc] initWithSize:frameRect.size] autorelease];

  }
  return self;
}

/**
 * BXVGAImageView DTor
 */
- (void)dealloc {
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

  [self setFrameSize:frameSize];
  self.columns = frameSize.width / cw;
  self.rows = frameSize.height / ch;
  self.tileSize = NSMakeSize(cw, ch);
  self.bpp = bpp;
  self.stride = self.tileSize.width * bpp / 8;
  self.bitsPerComponent = bpp < 16 ? bpp : 8;

  // recreate all arrays
  [self constructArray:self.rows width:self.columns];

  // invalidate cache
  [self clearCache];

  self.fullRedrawColor = [[NSColor blackColor] autorelease];

  // recreate buffer
  viewbuffer = [[[NSImage alloc] initWithSize:frameSize] autorelease];

}

/**
 * construct table array
 */
- (void)constructArray:(unsigned)h width:(unsigned) w {

  table = [[[NSMutableArray alloc] initWithCapacity:h] autorelease];

  for (unsigned y=0; y<h; y++) {
    NSMutableArray<BXVGATile *> * cols;

    cols = [[[NSMutableArray alloc] initWithCapacity:w] autorelease];
    for (unsigned x=0; x<w; x++) {
      [cols addObject:[[[BXVGATile alloc] initWithSize:NSMakeSize(0,0)] autorelease]];
    }
    [table addObject:cols];
  }

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
    [cols replaceObjectAtIndex:col withObject:tile];
    [cache addObject:tile];
  }

}

/**
 * updateTileCFData
 */
- (void)updateTileCFData:(CFMutableDataRef) cfRef colorspace:(CGColorSpaceRef) csRef xpos:(unsigned) x ypos:(unsigned) y {

  BXVGATile * tile;
  CGDataProviderRef provider;
  CGImageRef rgbImageRef;
  UInt32 tilecrc;

  provider = CGDataProviderCreateWithCFData(cfRef);
  BXL_DEBUG(([NSString stringWithFormat:@"image width=%d height=%d", (unsigned)self.tileSize.width, (unsigned)self.tileSize.height]));
  rgbImageRef = CGImageCreate(self.tileSize.width, self.tileSize.height, self.bitsPerComponent, self.bpp, self.stride, csRef, kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
  CGDataProviderRelease(provider);
  // calc crc32
  tilecrc = crc32buf((const unsigned char *)CFDataGetMutableBytePtr(cfRef), (self.stride * self.tileSize.height));
  // tile = [[[BXVGATile alloc] initWithCGImage:rgbImageRef size:NSZeroSize] autorelease];
  tile = [[[BXVGATile alloc] initWithCGImage:rgbImageRef size:self.tileSize crc:tilecrc] autorelease];
  CGImageRelease(rgbImageRef);

  [self updateTile:tile x:x/self.tileSize.width y:y/self.tileSize.height];

}

/**
 * drawRect
 */
- (void)drawRect:(NSRect)dirtyRect {

  NSRect viewbufferRect;

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

  // now draw the cache
  viewbufferRect = NSMakeRect(0 , 0, [viewbuffer size].width, [viewbuffer size].height);
  [viewbuffer drawInRect:viewbufferRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0f];

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
      unsigned short int maskend;
      unsigned char * screenMemory;

      // cfdata = CFDataCreateMutable(kCFAllocatorDefault, noOfComponents * (unsigned)rect.size.width * (unsigned)rect.size.height);
      data = [[[NSMutableData alloc] initWithLength:(noOfComponents * (unsigned)rect.size.width * (unsigned)rect.size.height)] autorelease];
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

      [imgview updateTileCFData:(CFMutableDataRef)data colorspace:colorspace xpos:(unsigned)rect.origin.x ypos:(self.height - (unsigned)rect.size.height) - (unsigned)rect.origin.y];

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
