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

#ifndef BX_GUI_COCOA_WINDOWS_H

  #define BX_GUI_COCOA_WINDOWS_H

  #include "cocoa_headerbar.h"

  #define MACOS_NSEventModifierFlagKeyUp      0x8000000000000000
  #define MACOS_NSEventModifierFlagMouse      0x4000000000000000

  #define BX_ALERT_MSG_STYLE_INFO             1
  #define BX_ALERT_MSG_STYLE_WARN             2
  #define BX_ALERT_MSG_STYLE_CRIT             3

  #if BX_SUPPORT_X86_64
    #define BOCHS_WINDOW_NAME @"Bochs x86-64 emulator MacOS X"
  #else
    #define BOCHS_WINDOW_NAME @"Bochs x86 emulator MacOS X"
  #endif

  @interface BXNSEventQueue : NSObject

    @property (nonatomic, readonly, getter=isEmpty) BOOL isEmpty;

    - (instancetype)init;
    // - (void)dealloc;

    - (void)enqueue:(UInt64) value;
    - (UInt64)dequeue;
    - (BOOL)isEmpty;

  @end

  @interface BXGuiCocoaNSWindow : NSWindow <NSApplicationDelegate>

    @property (nonatomic, readwrite, strong) BXVGAdisplay * BXVGA;
    @property (nonatomic, readonly, getter=hasEvent) BOOL hasEvent;
    @property (nonatomic, readwrite) BOOL MouseCaptureAbsolute;
    @property (nonatomic, readwrite) BOOL MouseCaptureActive;
    - (instancetype)init:(unsigned) headerbar_y VGAsize:(NSSize) vga;
    // - (void)dealloc;

    - (void)getMaxScreenResolution:(unsigned char *) bpp width:(unsigned int *) w height:(unsigned int *) h;

    - (void)showAlertMessage:(const char *) msg style:(const char) type;

    - (void)captureMouse:(BOOL) grab;
    - (void)captureMouseXY:(NSPoint) XY;

    - (NSImage *)createIconXPM;
    - (unsigned)createBXBitmap:(const unsigned char *)bmap xdim:(unsigned) x ydim:(unsigned) y;
    - (unsigned)headerbarBXBitmap:(unsigned) bmap_id alignment:(unsigned) align func:(void (*)()) f;
    - (void)headerbarCreate;
    - (void)headerbarUpdate;
    - (void)headerbarSwitchBXBitmap:(unsigned) btn_id data_id:(unsigned) bmap_id;
    - (unsigned)getHeaderbarHeight;
    - (void)renderVGA;
    - (BOOL)changeVGApalette:(unsigned)index red:(char) r green:(char) g blue:(char) b;
    - (void)clearVGAscreen;
    - (void)charmapVGA:(unsigned char *) dataA charmap:(unsigned char *) dataB width:(unsigned char)w height:(unsigned char) h;
    - (void)charmapVGAat:(unsigned) pos isFont2:(BOOL)font2 map:(unsigned char *) data;
    - (void)paintcharVGA:(unsigned short int) charpos isCrsr:(BOOL) crsr font2:(BOOL) f2 bgcolor:(unsigned char) bg fgcolor:(unsigned char) fg position:(NSRect) rect;
    - (BOOL)hasEvent;
    - (UInt64)getEvent;
    - (void)handleMouse:(NSEvent *)event;
    - (void)clipRegionVGA:(unsigned char *) src position:(NSRect) rect;
    - (const unsigned char *) getVGAMemory;
    - (void)clipRegionVGAPosition:(NSRect) rect;

  // -(NSButton *)createNSButtonWithImage:(const unsigned char *) data width:(size_t) w height:(size_t) h;
  // -(NSArray<NSButton *> *)createToolbar;
  // -(void)updateToolbar:(NSSize) size;
  @end






  // struct BXGuiCocoaWindowImpl;
  //
  // class BXGuiCocoaWindow {
  //
  // private:
  //   BXGuiCocoaWindowImpl * BXCocoaWindow;
  //
  // public:
  //   BXGuiCocoaWindow(unsigned x, unsigned y, unsigned headerbar_y);
  //   ~BXGuiCocoaWindow();
  //
  //   void getScreenConfiguration(unsigned int * width, unsigned int * height, unsigned char * bpp);
  //
  //   void showAlertMessage(const char *msg, const char type);
  //
  //   void captureMouse(bool cap, unsigned x, unsigned y);
  //   void captureMouse(unsigned x, unsigned y);
  //   bool hasMouseCapture(void);
  //
  //   void * createIconXPM(void);
  //   unsigned create_bitmap(const unsigned char *bmap, unsigned xdim, unsigned ydim);
  //   unsigned headerbar_bitmap(unsigned bmap_id, unsigned alignment, void (*f)(void));
  //   void show_headerbar(void);
  //   void dimension_update(unsigned x, unsigned y, unsigned fwidth, unsigned fheight, unsigned bpp);
  //   void render(void);
  //   bool palette_change(unsigned char index, unsigned char red, unsigned char green, unsigned char blue);
  //   void clear_screen(void);
  //   void replace_bitmap(unsigned hbar_id, unsigned bmap_id);
  //   void setup_charmap(unsigned char *charmapA, unsigned char *charmapB, unsigned char w, unsigned char h);
  //   void set_font(bool font2, unsigned pos, unsigned char *charmap);
  //   void draw_char(bool crsr, bool font2, unsigned char fgcolor, unsigned char bgcolor, unsigned short int charpos, unsigned short int x, unsigned short int y, unsigned char w, unsigned char h);
  //   bool hasEvent(void);
  //   void setEventMouseABS(bool abs);
  //   unsigned long getEvent(void);
  //   void graphics_tile_update(unsigned char *tile, unsigned x, unsigned y, unsigned w, unsigned h);
  //   const unsigned char * getVGAdisplayPtr(void);
  //   void graphics_tile_update_in_place(unsigned x, unsigned y, unsigned w, unsigned h);
  //
  // };





#endif /* BX_GUI_COCOA_WINDOWS_H */
