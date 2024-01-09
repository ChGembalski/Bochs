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

#ifndef BX_GUI_COCOA_HEADERBAR_H

  #define BX_GUI_COCOA_HEADERBAR_H

  #define BX_GUI_GRAVITY_LEFT   10
  #define BX_GUI_GRAVITY_RIGHT  11
  #define BX_GUI_GAP_SIZE       10

  @interface BXVGAdisplay : NSObject
    @property (nonatomic, readwrite) unsigned width;
    @property (nonatomic, readwrite) unsigned height;
    @property (nonatomic, readwrite) unsigned font_width;
    @property (nonatomic, readwrite) unsigned font_height;
    @property (nonatomic, readwrite) unsigned bpp;
    - (instancetype)init:(unsigned) bpp width:(unsigned) w height:(unsigned) h font_width:(unsigned) fw font_height:(unsigned) fh;
  @end

  @interface BXHeaderbarButtonData : NSObject
    @property (nonatomic, readwrite) CFDataRef data;
    @property (nonatomic, readwrite) unsigned width;
    @property (nonatomic, readwrite) unsigned height;
    @property (nonatomic, readwrite) size_t size;
    - (instancetype)init:(const unsigned char *) data width:(unsigned) w height:(unsigned) h;
    - (void)dealloc;
  @end

  @interface BXHeaderbarButton : NSObject
    @property (nonatomic, readwrite, assign) NSUInteger data_id;
    @property (nonatomic, readwrite) unsigned alignment;
    @property (nonatomic, readwrite) NSPoint position;
    @property (nonatomic, readwrite) NSSize size;
    @property (nonatomic, readwrite) void * func;
    @property (nonatomic, readwrite, strong) NSButton * button;
    - (instancetype)init:(NSUInteger) data_id width:(size_t) w height:(size_t) h alignment:(char) align top:(size_t) y left:(size_t) x image:(NSImage *) img func:(void (*)()) f;
    - (void)dealloc;
    - (void)mouseEvent: (NSButton*)button;
  @end

  @interface BXHeaderbar : NSObject
    @property (nonatomic, readwrite) unsigned height;
    @property (nonatomic, readwrite) unsigned width;
    @property (nonatomic, readwrite) unsigned yofs;
    - (instancetype)init:(unsigned) headerbar_y width:(unsigned) w yofs:(unsigned) y;
    - (void)dealloc;
    -(unsigned) createBXBitmap:(const unsigned char *)bmap xdim:(unsigned) x ydim:(unsigned) y;
    -(unsigned) headerbarBXBitmap:(unsigned) bmap_id alignment:(unsigned) align func:(void (*)()) f;
    -(void) headerbarCreate:(NSView *) view;
    -(void) headerbarUpdate:(BXVGAdisplay *) vga;
  @end

#endif /* BX_GUI_COCOA_HEADERBAR_H */
