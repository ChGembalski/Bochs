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

#ifndef BX_GUI_COCOA_DISPLAY_H

  #define BX_GUI_COCOA_DISPLAY_H

  @interface BXVGAImageView : NSImageView

    - (instancetype)initWithFrame:(NSRect)frameRect;
    - (void)dealloc;

  @end

  @interface BXVGAdisplay : NSObject
    @property (nonatomic, readwrite) unsigned width;
    @property (nonatomic, readwrite) unsigned height;
    @property (nonatomic, readwrite) unsigned font_width;
    @property (nonatomic, readwrite) unsigned font_height;
    @property (nonatomic, readwrite) unsigned bpp;
    @property (nonatomic, readwrite) unsigned stride;
    @property (nonatomic, readwrite) unsigned bitsPerComponent;
    @property (nonatomic, readwrite) unsigned char * screen;
    @property (nonatomic, readwrite) unsigned char * palette;
    @property (nonatomic, readwrite) unsigned palette_size;
    @property (nonatomic, readwrite) BOOL dirty;
    @property (nonatomic, readwrite) unsigned short int *FontA;
    @property (nonatomic, readwrite) unsigned short int *FontB;

    - (instancetype)init:(unsigned) bpp width:(unsigned) w height:(unsigned) h font_width:(unsigned) fw font_height:(unsigned) fh view:(NSView *) v;
    - (void)dealloc;
    - (void)changeBPP:(unsigned) bpp width:(unsigned) w height:(unsigned) h font_width:(unsigned) fw font_height:(unsigned) fh;
    - (void)render;
    - (BOOL)setPaletteRGB:(unsigned) index red:(char) r green:(char) g blue:(char) b;
    - (void)clearScreen;
    - (void)initFonts:(unsigned char *) dataA second:(unsigned char *) dataB width:(unsigned char)w height:(unsigned char) h;
    - (void)updateFontAt:(unsigned) pos first:(unsigned char *) dataA second:(unsigned char *) dataB;
    - (void)paintChar:(unsigned short int) charpos isCrsr:(BOOL) crsr font2:(BOOL) f2 bgcolor:(unsigned char) bg fgcolor:(unsigned char) fg position:(NSRect) rect;
  @end

#endif /* BX_GUI_COCOA_DISPLAY_H */
