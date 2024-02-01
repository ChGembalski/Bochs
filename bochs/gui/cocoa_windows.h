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
    #define BOCHS_WINDOW_CONFIG_NAME @"Bochs x86-64 configurator MacOS X"
    #define BOCHS_WINDOW_LOGGER_NAME @"Bochs x86-64 logger MacOS X"
    #define BOCHS_WINDOW_DEBUGGER_NAME @"Bochs x86-64 debugger MacOS X"
  #else
    #define BOCHS_WINDOW_NAME @"Bochs x86 emulator MacOS X"
    #define BOCHS_WINDOW_CONFIG_NAME @"Bochs x86 configurator MacOS X"
    #define BOCHS_WINDOW_LOGGER_NAME @"Bochs x86 logger MacOS X"
    #define BOCHS_WINDOW_DEBUGGER_NAME @"Bochs x86 debugger MacOS X"
  #endif

  typedef struct {
    gui_window_type_t           name;
    id                _Nullable window;
    NSString *        _Nullable menu_name;
  } gui_window_t;

  typedef struct {
    NSString *    _Nullable title;
    const char *  _Nullable param;
  } edit_opts_t;


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSPropertyCollection
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSPropertyCollection : NSObject

    - (instancetype _Nonnull)init;

    - (void)setProperty:(NSString * _Nonnull) name value:(NSInteger) val;
    - (NSInteger)getProperty:(NSString * _Nonnull) name;

  @end


  // // Log level defines
  // typedef enum {
  //   LOGLEV_DEBUG = 0,
  //   LOGLEV_INFO,
  //   LOGLEV_ERROR,
  //   LOGLEV_PANIC,
  //   N_LOGLEV
  // } bx_log_levels;

  ////////////////////////////////////////////////////////////////////////////////
  // BXNSLogEntry
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSLogEntry : NSObject

    @property (nonatomic, readwrite) UInt8 level;
    @property (nonatomic, readwrite) UInt8 mode;
    @property (nonatomic, readwrite, strong) NSString * _Nonnull timecode;
    @property (nonatomic, readwrite, strong) NSString * _Nonnull module;
    @property (nonatomic, readwrite, strong) NSString * _Nonnull msg;

    - (instancetype _Nonnull)init:(UInt8) level LogMode:(UInt8) mode LogTimeCode:(NSString * _Nonnull) timecode LogModule:(NSString * _Nonnull) module LogMsg:(NSString * _Nonnull) msg;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSLogQueue
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSLogQueue : NSObject

    @property (nonatomic, readonly, getter=isEmpty) BOOL isEmpty;

    - (instancetype _Nonnull)init;

    - (void)enqueue:(BXNSLogEntry * _Nonnull) entry;
    - (void)enqueueSplit:(NSString * _Nonnull) msg LogLevel:(UInt8) level LogMode:(UInt8) mode;
    - (BXNSLogEntry * _Nullable)dequeue;
    - (BOOL)isEmpty;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSEventQueue
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSEventQueue : NSObject

    @property (nonatomic, readonly, getter=isEmpty) BOOL isEmpty;

    - (instancetype _Nonnull)init;

    - (void)enqueue:(UInt64) value;
    - (UInt64)dequeue;
    - (BOOL)isEmpty;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSWindowController
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSWindowController : NSObject

    @property (atomic, readwrite) simulation_state_t simulation_state;
    @property (nonatomic, readwrite, strong) BXNSPropertyCollection * _Nonnull bx_p_col;
    @property (nonatomic, readwrite, strong) BXNSLogQueue * _Nonnull bx_log_queue;

    - (instancetype _Nonnull)init:(UInt8) headerbar_y VGAxRes:(UInt16) vga_xres VGAyRes:(UInt16) vga_yres;
    - (void)dealloc;

    + (void)showModalInfoDialog:(UInt8) level Title:(NSString * _Nonnull) title Message:(NSString * _Nonnull) msg;
    + (int)showModalQuestionDialog:(UInt8) level Title:(NSString * _Nonnull) title Message:(NSString * _Nonnull) msg;

    - (void)onBochsThreadExit;

    - (void)showWindow:(gui_window_type_t) window doShow:(BOOL) show;
    - (void)activateWindow:(gui_window_type_t) window;
    - (id _Nullable)getWindow:(gui_window_type_t) window;
    - (NSString * _Nullable)getWindowMenuName:(gui_window_type_t) window;
    - (gui_window_type_t)getWindowType:(NSString * _Nonnull) name;
    - (void)activateMenu:(property_t) type doActivate:(BOOL) activate;
    - (int)getProperty:(property_t) p;

    - (void)onMenuEvent:(id _Nonnull) sender;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSGenericWindow
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSGenericWindow : NSWindow <NSApplicationDelegate>

    @property (nonatomic, readwrite) BXNSWindowController * _Nonnull bx_controller;

    - (instancetype _Nonnull)initWithBXController:(BXNSWindowController * _Nonnull) controller contentRect:(NSRect) rect styleMask:(NSWindowStyleMask) style backing:(NSBackingStoreType) backingStoreType defer:(BOOL) flag;

    - (BOOL)windowShouldClose:(NSWindow * _Nonnull)sender;
    - (BOOL)onMenuEvent:(NSString * _Nonnull) path;
    - (void)setEnabled:(BOOL)enabled;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSConfigurationWindow
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSBrowserCell : NSBrowserCell

    @property (nonatomic, readwrite) BOOL isLeaf;
    @property (nonatomic, readwrite) NSString * _Nonnull path;
    @property (nonatomic, readwrite) const char * _Nullable param_name;
    // @property (nonatomic, readwrite) bx_param_c * _Nullable pred_param;

    - (instancetype _Nonnull)initTextCell:(NSString *)string;
    - (instancetype _Nonnull)initTextCell:(NSString *)string isLeaf:(BOOL) leaf PredPath:(NSString * _Nonnull) path SimParamName:(const char * _Nonnull) param_name;

  @end

  @interface BXNSBrowser : NSBrowser <NSBrowserDelegate>

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

    // - (void)browser:(NSBrowser * _Nonnull)sender createRowsForColumn:(NSInteger)column inMatrix:(NSMatrix * _Nonnull)matrix;
    - (NSInteger)browser:(NSBrowser * _Nonnull)browser numberOfChildrenOfItem:(id _Nullable)item;
    - (id)browser:(NSBrowser * _Nonnull)browser child:(NSInteger)index ofItem:(id _Nullable)item;
    - (BOOL)browser:(NSBrowser * _Nonnull)browser isLeafItem:(id _Nullable)item;

  @end

  @interface BXNSConfigurationWindow : BXNSGenericWindow <NSApplicationDelegate>

    @property (nonatomic, readwrite, strong) BXNSBrowser * _Nonnull config;

    - (instancetype _Nonnull)init:(BXNSWindowController * _Nonnull) controller;

  @end

  ////////////////////////////////////////////////////////////////////////////////
  // BXNSSimulationWindow
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSSimulationWindow : BXNSGenericWindow <NSApplicationDelegate>

    @property (nonatomic, readwrite) BXNSHeaderBar * _Nonnull BXToolbar;
    @property (nonatomic, readwrite, strong) BXVGAdisplay * _Nonnull BXVGA;
    @property (nonatomic, readonly, getter=hasEvent) BOOL hasEvent;
    @property (nonatomic, readwrite) BOOL MouseCaptureAbsolute;
    @property (nonatomic, readwrite) BOOL MouseCaptureActive;

    - (instancetype _Nonnull)init:(BXNSWindowController * _Nonnull) controller HeaderBarHeight:(UInt8) headerbar_y VGAxRes:(UInt16) vga_xres VGAyRes:(UInt16) vga_yres;

    - (BOOL)hasEvent;
    - (UInt64)getEvent;
    - (void)captureMouse:(BOOL) grab;
    - (void)captureMouseXY:(NSPoint) XY;

    - (void)keyDown:(NSEvent * _Nonnull)event;
    - (void)keyUp:(NSEvent * _Nonnull)event;

    - (void)handleMouse:(NSEvent * _Nonnull)event;
    - (void)mouseMoved:(NSEvent * _Nonnull)event;
    - (void)mouseDragged:(NSEvent* _Nonnull)event;
    - (void)rightMouseDragged:(NSEvent * _Nonnull)event;
    - (void)otherMouseDragged:(NSEvent * _Nonnull)event;
    - (void)mouseDown:(NSEvent* _Nonnull)event;
    - (void)rightMouseDown:(NSEvent * _Nonnull)event;
    - (void)otherMouseDown:(NSEvent * _Nonnull)event;
    - (void)mouseUp:(NSEvent* _Nonnull)event;
    - (void)rightMouseUp:(NSEvent * _Nonnull)event;
    - (void)otherMouseUp:(NSEvent * _Nonnull)event;

  @end

  ////////////////////////////////////////////////////////////////////////////////
  // BXNSLoggingWindow
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSLoggingWindow : BXNSGenericWindow <NSApplicationDelegate>

    @property (nonatomic, readwrite) BXNSLogQueue * _Nonnull queue;

    - (instancetype _Nonnull)init:(BXNSWindowController * _Nonnull) controller LogQueue:(BXNSLogQueue * _Nonnull) queue;

    - (void)refreshFromQueue;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSDebuggerWindow
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSVerticalSplitView : NSSplitView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

  @end

  @interface BXNSHorizontalSplitView : NSSplitView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

  @end

  @interface BXNSTabView : NSTabView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

  @end

  @interface BXNSMemoryView : NSView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

  @end

  @interface BXNSGDTView : NSView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

  @end

  @interface BXNSIDTView : NSView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

  @end

  @interface BXNSLDTView : NSView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

  @end

  @interface BXNSPagingView : NSView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

  @end

  @interface BXNStackView : NSView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

  @end

  @interface BXNSInstructionView : NSView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

  @end

  @interface BXNSBreakpointView : NSView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

  @end

  @interface BXNSRegisterView : NSView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

  @end

  @interface BXNSOutputView : NSView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

    - (void)appendText:(NSString * _Nonnull) msg;

  @end


  @interface BXNSDebuggerWindow : BXNSGenericWindow <NSApplicationDelegate>

    @property (nonatomic, readwrite, strong) BXNSOutputView * _Nonnull outputView;

    - (instancetype _Nonnull)init:(BXNSWindowController * _Nonnull) controller;

    - (BOOL)onMenuEvent:(NSString * _Nonnull) path;

  @end























  // @interface BXGuiCocoaNSWindow : NSWindow <NSApplicationDelegate>
  //
  //   @property (nonatomic, readwrite, strong) BXVGAdisplay * BXVGA;
  //   @property (nonatomic, readonly, getter=hasEvent) BOOL hasEvent;
  //   @property (nonatomic, readwrite) BOOL MouseCaptureAbsolute;
  //   @property (nonatomic, readwrite) BOOL MouseCaptureActive;
  //   - (instancetype)init:(unsigned) headerbar_y VGAsize:(NSSize) vga;
  //   // - (void)dealloc;
  //
  //   - (void)getMaxScreenResolution:(unsigned char *) bpp width:(unsigned int *) w height:(unsigned int *) h;
  //
  //   - (void)showAlertMessage:(const char *) msg style:(const char) type;
  //
  //   - (void)captureMouse:(BOOL) grab;
  //   - (void)captureMouseXY:(NSPoint) XY;
  //
  //   - (NSImage *)createIconXPM;
  //   - (unsigned)createBXBitmap:(const unsigned char *)bmap xdim:(unsigned) x ydim:(unsigned) y;
  //   - (unsigned)headerbarBXBitmap:(unsigned) bmap_id alignment:(unsigned) align func:(void (*)()) f;
  //   - (void)headerbarCreate;
  //   - (void)headerbarUpdate;
  //   - (void)headerbarSwitchBXBitmap:(unsigned) btn_id data_id:(unsigned) bmap_id;
  //   - (unsigned)getHeaderbarHeight;
  //   - (void)renderVGA;
  //   - (BOOL)changeVGApalette:(unsigned)index red:(char) r green:(char) g blue:(char) b;
  //   - (void)clearVGAscreen;
  //   - (void)charmapVGA:(unsigned char *) dataA charmap:(unsigned char *) dataB width:(unsigned char)w height:(unsigned char) h;
  //   - (void)charmapVGAat:(unsigned) pos isFont2:(BOOL)font2 map:(unsigned char *) data;
  //   - (void)paintcharVGA:(unsigned short int) charpos isCrsr:(BOOL) crsr font2:(BOOL) f2 bgcolor:(unsigned char) bg fgcolor:(unsigned char) fg position:(NSRect) rect;
  //   - (BOOL)hasEvent;
  //   - (UInt64)getEvent;
  //   - (void)handleMouse:(NSEvent *)event;
  //   - (void)clipRegionVGA:(unsigned char *) src position:(NSRect) rect;
  //   - (const unsigned char *) getVGAMemory;
  //   - (void)clipRegionVGAPosition:(NSRect) rect;
  //
  // // -(NSButton *)createNSButtonWithImage:(const unsigned char *) data width:(size_t) w height:(size_t) h;
  // // -(NSArray<NSButton *> *)createToolbar;
  // // -(void)updateToolbar:(NSSize) size;
  // @end






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
