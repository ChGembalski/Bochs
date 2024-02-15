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

  #define BX_ALERT_MSG_STYLE_INFO             1
  #define BX_ALERT_MSG_STYLE_WARN             2
  #define BX_ALERT_MSG_STYLE_CRIT             3

  #if BX_SUPPORT_X86_64
    #define BOCHS_WINDOW_NAME @"Bochs x86-64 emulator MacOS X"
    #define BOCHS_WINDOW_CONFIG_NAME @"Bochs x86-64 configurator MacOS X"
    #define BOCHS_WINDOW_LOGGER_NAME @"Bochs x86-64 logger MacOS X"
    #define BOCHS_WINDOW_DEBUGGER_NAME @"Bochs x86-64 debugger MacOS X"
    #define BOCHS_WINDOW_DEBUGGER_CONFIG_NAME @"Bochs x86-64 debugger config MacOS X"
  #else
    #define BOCHS_WINDOW_NAME @"Bochs x86 emulator MacOS X"
    #define BOCHS_WINDOW_CONFIG_NAME @"Bochs x86 configurator MacOS X"
    #define BOCHS_WINDOW_LOGGER_NAME @"Bochs x86 logger MacOS X"
    #define BOCHS_WINDOW_DEBUGGER_NAME @"Bochs x86 debugger MacOS X"
    #define BOCHS_WINDOW_DEBUGGER_CONFIG_NAME @"Bochs x86 debugger config MacOS X"
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

    @property (nonatomic, readwrite, strong) NSMutableDictionary<NSString *, NSNumber *> * _Nonnull map;

    - (instancetype _Nonnull)init;

    - (void)setProperty:(NSString * _Nonnull) name value:(NSInteger) val;
    - (NSInteger)getProperty:(NSString * _Nonnull) name;
    - (NSInteger)peekProperty:(NSString * _Nonnull) name;

  @end


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
    @property (nonatomic, readwrite, strong) NSCondition * _Nonnull event_condition;
    @property (nonatomic, readwrite) BOOL event_lock;

    - (instancetype _Nonnull)init:(UInt8) headerbar_y VGAxRes:(UInt16) vga_xres VGAyRes:(UInt16) vga_yres;
    - (void)dealloc;

    + (void)showModalInfoDialog:(UInt8) level Title:(NSString * _Nonnull) title Message:(NSString * _Nonnull) msg;
    + (int)showModalQuestionDialog:(UInt8) level Title:(NSString * _Nonnull) title Message:(NSString * _Nonnull) msg;
    + (int)showModalParamRequestDialog:(void * _Nonnull) param;
    + (int)showModalAboutDialog;

    - (void)onBochsThreadExit;

- (void)createDebuggerUI;

    - (void)showWindow:(gui_window_type_t) window doShow:(BOOL) show;
    - (void)activateWindow:(gui_window_type_t) window;
    - (id _Nullable)getWindow:(gui_window_type_t) window;
    - (NSString * _Nullable)getWindowMenuName:(gui_window_type_t) window;
    - (gui_window_type_t)getWindowType:(NSString * _Nonnull) name;
    - (void)activateMenu:(property_t) type doActivate:(BOOL) activate;
    - (int)getProperty:(property_t) p;
    - (void)waitPropertySet:(NSMutableArray<NSNumber *> * _Nonnull) property_list;
    - (void)setProperty:(property_t) p Value:(int) val;
    - (int)getClipboardText:(unsigned char * _Nullable * _Nonnull) bytes Size:(int * _Nonnull) nbytes;
    - (int)setClipboardText:(char * _Nullable)text Size:(int) len;
    - (void)onMenuEvent:(id _Nonnull) sender;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSGenericWindow
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSGenericWindow : NSWindow <NSApplicationDelegate>

    @property (nonatomic, readwrite) BXNSWindowController * _Nonnull bx_controller;
    @property (nonatomic, readwrite) UInt32 cust_val;

    - (instancetype _Nonnull)initWithBXController:(BXNSWindowController * _Nonnull) controller contentRect:(NSRect) rect styleMask:(NSWindowStyleMask) style backing:(NSBackingStoreType) backingStoreType defer:(BOOL) flag Custom:(UInt32) cust_val;

    - (BOOL)windowShouldClose:(NSWindow * _Nonnull)sender;
    - (BOOL)onMenuEvent:(NSString * _Nonnull) path;
    - (void)setEnabled:(BOOL)enabled;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSBrowser
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSBrowser : NSBrowser <NSBrowserDelegate>

    @property (nonatomic, readwrite) BOOL SIMavailable;
    @property (nonatomic, readwrite) void * _Nullable fix_root;

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;
    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect Root:(void * _Nonnull) fix_root;

    - (NSInteger)browser:(NSBrowser * _Nonnull)browser numberOfChildrenOfItem:(id _Nullable)item;
    - (id _Nonnull)browser:(NSBrowser * _Nonnull)browser child:(NSInteger)index ofItem:(id _Nullable)item;
    - (BOOL)browser:(NSBrowser * _Nonnull)browser isLeafItem:(id _Nullable)item;
    - (id _Nonnull)browser:(NSBrowser * _Nonnull)browser objectValueForItem:(id _Nullable)item;
    - (NSViewController * _Nullable)browser:(NSBrowser * _Nonnull)browser previewViewControllerForLeafItem:(id _Nullable)item;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSAboutWindow
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSAboutWindow : NSWindow <NSApplicationDelegate>

    - (instancetype _Nonnull)init;

    - (void)onOKClick:(id _Nonnull)sender;
    - (BOOL) getWorksWhenModal;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSParamRequestWindow
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSParamRequestWindow : NSWindow <NSApplicationDelegate>

    - (instancetype _Nonnull)init:(void * _Nonnull) param;

    - (void)onOKClick:(id _Nonnull)sender;
    - (void)onCancelClick:(id _Nonnull)sender;
    - (BOOL) getWorksWhenModal;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSConfigurationWindow
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSConfigurationWindow : BXNSGenericWindow <NSApplicationDelegate, NSWindowDelegate>

    @property (nonatomic, readwrite, strong) BXNSBrowser * _Nonnull config;

    - (instancetype _Nonnull)init:(BXNSWindowController * _Nonnull) controller;

  @end

  ////////////////////////////////////////////////////////////////////////////////
  // BXNSSimulationWindow
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSSimulationWindow : BXNSGenericWindow <NSApplicationDelegate, NSWindowDelegate>

    @property (nonatomic, readwrite) BXNSHeaderBar * _Nonnull BXToolbar;
    @property (nonatomic, readwrite, strong) BXVGAdisplay * _Nonnull BXVGA;
    @property (nonatomic, readonly, getter=hasEvent) BOOL hasEvent;
    @property (nonatomic, readwrite) BOOL MouseCaptureAbsolute;
    @property (nonatomic, readwrite) BOOL MouseCaptureActive;
    @property (nonatomic, readwrite, strong) BXNSEventQueue * _Nonnull BXEventQueue;
    @property (nonatomic, readwrite) NSRect restoreSize;
    @property (nonatomic, readwrite) BOOL inFullscreen;

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
    - (void)updateIPS:(unsigned) val;
    - (void)toggleFullscreen:(BOOL) enable;
    - (void)backupWindowState;
    - (void)restoreWindowState;
    - (void)resizeByRatio;
    - (void)windowWillEnterFullScreen:(NSNotification * _Nullable)notification;
    - (void)windowWillExitFullScreen:(NSNotification * _Nullable)notification;

  @end

  ////////////////////////////////////////////////////////////////////////////////
  // BXNSLoggingWindow
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSLoggingWindow : BXNSGenericWindow <NSApplicationDelegate>

    @property (nonatomic, readwrite) BXNSLogQueue * _Nonnull queue;
    @property (nonatomic, readwrite, strong) NSTextView * _Nonnull messagesText;
    @property (nonatomic, readwrite, strong) NSDictionary * _Nonnull attributesText;
    @property (nonatomic, readwrite, strong) NSTimer * _Nonnull refreshTimer;
    @property (nonatomic, readwrite) UInt8 loglevelMask;

    - (instancetype _Nonnull)init:(BXNSWindowController * _Nonnull) controller LogQueue:(BXNSLogQueue * _Nonnull) queue;

    - (void)refreshFromQueue;
    - (void)onCheckboxClick:(id _Nonnull) sender;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSDebuggerWindow
  ////////////////////////////////////////////////////////////////////////////////
#if BX_DEBUGGER && BX_NEW_DEBUGGER_GUI


  @interface BXNSLDTView : NSView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

  @end

  

  @interface BXNSOutputView : NSView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

    - (void)appendText:(NSString * _Nonnull) msg;

  @end


  @interface BXNSDebuggerWindow : BXNSGenericWindow <NSApplicationDelegate>

    @property (nonatomic, readwrite, strong) BXNSDebugView * _Nonnull debug_view;




//    @property (nonatomic, readwrite, strong) BXNSOutputView * _Nonnull outputView;

    - (instancetype _Nonnull)init:(BXNSWindowController * _Nonnull) controller SmpInfo:(bx_smp_info_t *) smp;

    - (BOOL)onMenuEvent:(NSString * _Nonnull) path;

  @end

  ////////////////////////////////////////////////////////////////////////////////
  // BXNSDebuggerConfigWindow
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSDebuggerConfigWindow : BXNSGenericWindow <NSApplicationDelegate>

    @property (nonatomic, readwrite, strong) BXNSTabView * _Nonnull tabView;

    - (instancetype _Nonnull)init:(BXNSWindowController * _Nonnull) controller;

  @end

#endif /* BX_DEBUGGER && BX_NEW_DEBUGGER_GUI */

#endif /* BX_GUI_COCOA_WINDOWS_H */
