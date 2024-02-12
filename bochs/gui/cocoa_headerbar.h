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

  #include "cocoa_bochs.h"
  #include "cocoa_display.h"

  #define BX_GUI_GRAVITY_LEFT   10
  #define BX_GUI_GRAVITY_RIGHT  11
  #define BX_GUI_GAP_SIZE       10


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSHeaderBarButtonData
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSHeaderBarButtonData : NSObject

    @property (nonatomic, readwrite) CFDataRef _Nonnull data;
    @property (nonatomic, readwrite) unsigned width;
    @property (nonatomic, readwrite) unsigned height;
    @property (nonatomic, readwrite) size_t size;

    - (instancetype _Nonnull)init:(const unsigned char * _Nonnull) data width:(unsigned) w height:(unsigned) h;
    - (void)dealloc;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSHeaderBarButton
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSHeaderBarButton : NSObject

    @property (nonatomic, readwrite, assign) NSUInteger data_id;
    @property (nonatomic, readwrite) unsigned alignment;
    @property (nonatomic, readwrite) NSPoint position;
    @property (nonatomic, readwrite) NSSize size;
    @property (nonatomic, readwrite) ButtonHandler _Nullable handler;
    @property (nonatomic, readwrite, strong) NSButton * _Nonnull button;

    - (instancetype _Nonnull)init:(NSUInteger) data_id width:(size_t) w height:(size_t) h alignment:(char) align top:(size_t) y left:(size_t) x image:(NSImage * _Nonnull) img func:(ButtonHandler _Nullable) handler;

    - (void)mouseEvent: (NSButton* _Nonnull)button;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSHeaderBarView
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSHeaderBarView : NSView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSHeaderBar
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSHeaderBar : NSObject

    @property (nonatomic, readwrite, strong) BXNSHeaderBarView * _Nonnull button_view;
    @property (nonatomic, readwrite, strong) NSMutableArray<BXNSHeaderBarButtonData *> * _Nonnull button_data;
    @property (nonatomic, readwrite, strong) NSMutableArray<BXNSHeaderBarButton *> * _Nonnull buttons;
    @property (nonatomic, readwrite) unsigned height;
    @property (nonatomic, readwrite) unsigned width;
    @property (nonatomic, readwrite) unsigned yofs;
    @property (nonatomic, readwrite) BOOL created;
    @property (nonatomic, readwrite) unsigned last_lx;
    @property (nonatomic, readwrite) unsigned last_rx;

    - (instancetype _Nonnull)init:(unsigned) headerbar_y width:(unsigned) w yofs:(unsigned) y;

    - (unsigned)createBXBitmap:(const unsigned char * _Nonnull)bmap xdim:(unsigned) x ydim:(unsigned) y;
    - (unsigned)headerbarBXBitmap:(unsigned) bmap_id alignment:(unsigned) align func:(ButtonHandler _Nullable) handler;
    - (void)headerbarBXBitmap:(unsigned) btn_id data_id:(unsigned) bmap_id;
    - (void)headerbarCreate:(NSView * _Nonnull) view;
    - (void)headerbarUpdate:(BXVGAdisplay * _Nonnull) vga;
    - (void)setTooltip:(unsigned)btn_id Text:(const char * _Nonnull)tiptext;

  @end

#endif /* BX_GUI_COCOA_HEADERBAR_H */
