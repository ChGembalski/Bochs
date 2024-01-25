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

  #include "cocoa_bochs.h"
  #include "cocoa_headerbar.h"

  #define MACOS_NSEventModifierFlagKeyUp      0x8000000000000000
  #define MACOS_NSEventModifierFlagMouse      0x4000000000000000

  #define BX_ALERT_MSG_STYLE_INFO             1
  #define BX_ALERT_MSG_STYLE_WARN             2
  #define BX_ALERT_MSG_STYLE_CRIT             3

  #if BX_SUPPORT_X86_64
    #define BOCHS_WINDOW_NAME @"Bochs x86-64 emulator MacOS X"
    #define BOCHS_WINDOW_LOGGER_NAME @"Bochs x86-64 logger MacOS X"
  #else
    #define BOCHS_WINDOW_NAME @"Bochs x86 emulator MacOS X"
    #define BOCHS_WINDOW_LOGGER_NAME @"Bochs x86 logger MacOS X"
  #endif

  typedef struct {
    gui_window_type_t           name;
    id                _Nullable window;
  } gui_window_t;

  typedef struct {
    property_t                  type;
    NSString *        _Nonnull  name;
  } property_entry_t;

  @interface BXNSPropertyCollection : NSObject

    - (instancetype _Nonnull)init;

    - (NSString * _Nullable)propertyToString:(property_t) property;
    - (void)setProperty:(NSString * _Nonnull) name value:(NSInteger) val;
    - (NSInteger)getProperty:(NSString * _Nonnull) name;

  @end


  @interface BXNSLogEntry : NSObject

    @property (nonatomic, readwrite) UInt8 level;
    @property (nonatomic, readwrite) UInt8 mode;
    @property (nonatomic, readwrite, strong) NSString * _Nonnull timecode;
    @property (nonatomic, readwrite, strong) NSString * _Nonnull module;
    @property (nonatomic, readwrite, strong) NSString * _Nonnull msg;

    - (instancetype _Nonnull)init:(UInt8) level LogMode:(UInt8) mode LogTimeCode:(NSString * _Nonnull) timecode LogModule:(NSString * _Nonnull) module LogMsg:(NSString * _Nonnull) msg;

  @end


  @interface BXNSLogQueue : NSObject

    @property (nonatomic, readonly, getter=isEmpty) BOOL isEmpty;

    - (instancetype _Nonnull)init;

    - (void)enqueue:(BXNSLogEntry * _Nonnull) entry;
    - (void)enqueueSplit:(NSString * _Nonnull) msg LogLevel:(UInt8) level LogMode:(UInt8) mode;
    - (BXNSLogEntry * _Nullable)dequeue;
    - (BOOL)isEmpty;

  @end


  @interface BXNSWindowController : NSObject

    @property (nonatomic, readwrite, strong) BXNSPropertyCollection * _Nonnull bx_p_col;
    @property (nonatomic, readwrite, strong) BXNSLogQueue * _Nonnull bx_log_queue;

    - (instancetype _Nonnull)init;
    - (void)dealloc;
    - (void)showWindow:(gui_window_type_t) window doShow:(BOOL) show;
    - (void)activateWindow:(gui_window_type_t) window;
    - (id _Nullable)getWindow:(gui_window_type_t) window;
    - (int)getProperty:(property_t) p;

    - (void)onMenuEvent:(id _Nonnull) sender;

  @end


  @interface BXNSGenericWindow : NSWindow <NSApplicationDelegate>

    @property (nonatomic, readwrite) BXNSWindowController * _Nonnull bx_controller;

    - (instancetype _Nonnull)initWithBXController:(BXNSWindowController * _Nonnull) controller contentRect:(NSRect) rect styleMask:(NSWindowStyleMask) style backing:(NSBackingStoreType) backingStoreType defer:(BOOL) flag;

    - (BOOL)windowShouldClose:(NSWindow * _Nonnull)sender;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // TEMP Configuration Window
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSConfigurationWindow : BXNSGenericWindow <NSApplicationDelegate>

    - (instancetype _Nonnull)init:(BXNSWindowController * _Nonnull) controller;

  @end

  ////////////////////////////////////////////////////////////////////////////////
  // TEMP Simulation Window
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSSimulationWindow : BXNSGenericWindow <NSApplicationDelegate>

    @property (nonatomic, readwrite) BOOL MouseCaptureAbsolute;

    - (instancetype _Nonnull)init:(BXNSWindowController * _Nonnull) controller;

  @end

  ////////////////////////////////////////////////////////////////////////////////
  // TEMP Logging Window
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSLoggingWindow : BXNSGenericWindow <NSApplicationDelegate>

    @property (nonatomic, readwrite) BXNSLogQueue * _Nonnull queue;

    - (instancetype _Nonnull)init:(BXNSWindowController * _Nonnull) controller LogQueue:(BXNSLogQueue * _Nonnull) queue;

    - (void)refreshFromQueue;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // TEMP Debugger Window
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSDebuggerWindow : BXNSGenericWindow <NSApplicationDelegate>

    - (instancetype _Nonnull)init:(BXNSWindowController * _Nonnull) controller;

  @end





















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
