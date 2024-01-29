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
#include "cocoa_windows.h"
#include "cocoa_menu.h"


property_entry_t mapping[] = {
  {BX_PROPERTY_START_SIM,    @"Simulation.Start"},
  {BX_PROPERTY_EXIT_SIM,     @"Simulation.Stop"},
  {BX_PROPERTY_UNDEFINED,    @""}
};


@implementation BXNSPropertyCollection

NSMutableDictionary<NSString *, NSNumber *> * map;

/**
 * init
 */
- (instancetype _Nonnull)init {

  self = [super init];
  if (self) {
    map = [[NSMutableDictionary alloc] init];
  }
  return self;

}

/*
 * propertyToString
 */
- (NSString * _Nullable)propertyToString:(property_t) property {

  int i;

  i=0;
  while (mapping[i].type != BX_PROPERTY_UNDEFINED) {
    if (mapping[i].type == property) {
      return mapping[i].name;
    }
    i++;
  }

  return nil;

}

/**
 * setProperty
 */
- (void)setProperty:(NSString * _Nonnull) name value:(NSInteger) val {

  [map setObject:[NSNumber numberWithInteger:val] forKey:name];

}

/**
 * getProperty
 */
- (NSInteger)getProperty:(NSString * _Nonnull) name {

  NSNumber * value;

  value = [map objectForKey:name];
  if (value == nil) {
    return BX_PROPERTY_UNDEFINED;
  }
  [map removeObjectForKey:name];

  return value.integerValue;

}


@end


@implementation BXNSLogEntry

/**
 * init
 */
- (instancetype _Nonnull)init:(UInt8) level LogMode:(UInt8) mode LogTimeCode:(NSString * _Nonnull) timecode LogModule:(NSString * _Nonnull) module LogMsg:(NSString * _Nonnull) msg {

  self = [super init];
  if (self) {

    self.level = level;
    self.mode = mode;
    self.timecode = timecode;
    self.module = module;
    self.msg = msg;

  }

  return self;

}

@end


@implementation BXNSLogQueue

NSMutableArray<BXNSLogEntry *> * logqueue;

/**
 * init
 */
- (instancetype _Nonnull)init {

  self = [super init];
  if(self) {

    logqueue = [[NSMutableArray alloc] init];

  }

  return self;

}

/**
 * enqueueSplit
 */
- (void)enqueueSplit:(NSString * _Nonnull) msg LogLevel:(UInt8) level LogMode:(UInt8) mode {

  BXNSLogEntry * entry;
  NSString * timecode;
  NSString * module;
  NSString * lmsg;

  timecode = [msg substringToIndex:11];
  module = [msg substringWithRange:NSMakeRange(13, 6)];
  lmsg = [msg substringFromIndex:21];
  entry = [[BXNSLogEntry alloc] init:level LogMode:mode LogTimeCode:timecode LogModule:module LogMsg:lmsg];

  @synchronized(self) {
    [logqueue addObject:entry];
  }

}

/**
 * enqueue
 */
- (void)enqueue:(BXNSLogEntry * _Nonnull) entry {

  @synchronized(self) {
    [logqueue addObject:entry];
  }

}

/**
 * dequeue
 */
- (BXNSLogEntry * _Nullable)dequeue {

  BXNSLogEntry * obj;

  @synchronized(self) {
    if ([logqueue count] == 0) {
      return nil;
    }

    obj = [logqueue objectAtIndex:0];
    [logqueue removeObjectAtIndex:0];
  }

  return obj;

}

/**
 * isEmpty
 */
- (BOOL)isEmpty {

  @synchronized(self) {
    return [logqueue count] == 0;
  }

}

@end


@implementation BXNSEventQueue

NSMutableArray<NSNumber *> * queue;

/**
 * init
 */
- (instancetype _Nonnull)init {

  self = [super init];
  if(self) {

    queue = [[NSMutableArray alloc] init];

  }

  return self;

}

/**
 * enqueue
 */
- (void)enqueue:(UInt64) value {

  NSNumber *obj;

  obj = [NSNumber numberWithUnsignedLong:value];
  @synchronized(self) {
    [queue addObject:obj];
  }

}

/**
 * dequeue
 */
- (UInt64)dequeue {

  NSNumber *obj;

  @synchronized(self) {
    if ([queue count] == 0) {
      return (0);
    }
    obj = [queue objectAtIndex:0];
    if (obj == nil) {
      return (0);
    }

    [queue removeObjectAtIndex:0];
  }

  return obj.unsignedLongValue;

}

/**
 * isEmpty
 */
- (BOOL)isEmpty {

  @synchronized(self) {
    return [queue count] == 0;
  }

}

@end


@implementation BXNSWindowController

BXNSMenuBar * menubar;

gui_window_t window_list[] = {
  {BX_GUI_WINDOW_CONFIGURATION, NULL, @"Window.Configuration"},
  {BX_GUI_WINDOW_VGA_DISPLAY,   NULL, @"Window.VGA Display"},
  {BX_GUI_WINDOW_LOGGING,       NULL, @"Window.Logger"},
  {BX_GUI_WINDOW_DEBUGGER,      NULL, @"Window.Debugger"},
  {BX_GUI_WINDOW_UNDEFINED,     NULL, nil}
};

/**
 * init
 */
- (instancetype _Nonnull)init:(UInt8) headerbar_y VGAxRes:(UInt16) vga_xres VGAyRes:(UInt16) vga_yres {

  self = [super init];
  if(self) {

    // Menue Bar
    menubar = [[BXNSMenuBar alloc] init:self];

    self.bx_p_col = [[BXNSPropertyCollection alloc] init];

    self.bx_log_queue = [[BXNSLogQueue alloc] init];

    // init all windows we use
    // each window_list.window [[? alloc] init];

    window_list[0].window = [[BXNSConfigurationWindow alloc] init:self];
    [((NSWindow *)window_list[0].window) center];
    [window_list[0].window setIsVisible:NO];

    window_list[1].window = [[BXNSSimulationWindow alloc] init:self HeaderBarHeight:headerbar_y VGAxRes:vga_xres VGAyRes:vga_yres];
    [((NSWindow *)window_list[1].window) center];
    [window_list[1].window setIsVisible:NO];

    window_list[2].window = [[BXNSLoggingWindow alloc] init:self LogQueue:self.bx_log_queue];
    [((NSWindow *)window_list[2].window) center];
    [window_list[2].window setIsVisible:NO];

    window_list[3].window = [[BXNSDebuggerWindow alloc] init:self];
    [((NSWindow *)window_list[3].window) center];
    [window_list[3].window setIsVisible:NO];


  }

  return self;

}

/**
 * dealloc
 */
- (void)dealloc {

  int i;

  i=0;
  while (window_list[i].name != BX_GUI_WINDOW_UNDEFINED) {
    window_list[i].window = nil;
    i++;
  }

}

/**
 * onBochsThreadExit
 */
- (void)onBochsThreadExit {
  // TODO : set all to stop somehow ...
}

/**
 * showWindow
 */
- (void)showWindow:(gui_window_type_t) window doShow:(BOOL) show {

  BXNSGenericWindow * curWindow;
  NSString * curMenuName;
  NSMenuItem * curMenuItem;

  curWindow = [self getWindow:window];
  curMenuName = [self getWindowMenuName:window];
  curMenuItem = [BXNSMenuBar findMenuItem:curMenuName startAt:nil];

  if (curWindow != nil) {
    if (curMenuItem != nil) {
      [curMenuItem setState:show ? NSControlStateValueOn : NSControlStateValueOff];
    }
    [curWindow setIsVisible:show];
  }

}

/**
 * activateWindow
 */
- (void)activateWindow:(gui_window_type_t) window {

  BXNSGenericWindow * curWindow;

  curWindow = [self getWindow:window];
  if (curWindow != nil) {
    [curWindow makeKeyAndOrderFront:nil];
  }

}

/**
 * getWindow
 */
- (id _Nullable)getWindow:(gui_window_type_t) window {

  int i;

  i = 0;
  while (window_list[i].name != BX_GUI_WINDOW_UNDEFINED) {
    if (window_list[i].name == window) {
      return window_list[i].window;
    }
    i++;
  }

  return nil;

}

/**
 * getWindowMenuName
 */
- (NSString * _Nullable)getWindowMenuName:(gui_window_type_t) window {

  int i;

  i = 0;
  while (window_list[i].name != BX_GUI_WINDOW_UNDEFINED) {
    if (window_list[i].name == window) {
      return window_list[i].menu_name;
    }
    i++;
  }

  return nil;

}

/**
 * getWindowType
 */
- (gui_window_type_t)getWindowType:(NSString * _Nonnull) name {

  int i;

  i = 0;
  while (window_list[i].name != BX_GUI_WINDOW_UNDEFINED) {
    if ([name isEqualToString:window_list[i].menu_name]) {
      return window_list[i].name;
    }
    i++;
  }

  return BX_GUI_WINDOW_UNDEFINED;

}

/**
 * activateMenu
 */
- (void)activateMenu:(property_t) type doActivate:(BOOL) activate {

  NSString * menuPath;
  NSMenuItem * curMenuItem;

  menuPath = [BXNSMenuBar getMenuItemTypePath:type];
  if (menuPath == nil) {
    return;
  }

  curMenuItem = [BXNSMenuBar findMenuItem:menuPath startAt:nil];
  if (curMenuItem == nil) {
    return;
  }

  [curMenuItem setEnabled:activate];

}

/**
 * getProperty
 */
- (int)getProperty:(property_t) p {

  NSString * property;

  property = [self.bx_p_col propertyToString:p];
  if (property == nil) {
    return BX_PROPERTY_UNDEFINED;
  }

  return [self.bx_p_col getProperty:property];

}


/**
 * onMenuEvent
 */
- (void)onMenuEvent:(id _Nonnull) sender {

  NSString * senderPath;
  BXNSGenericWindow * curWindow;
  gui_window_type_t curWindowType;

  // resolve the sender
  senderPath = [BXNSMenuBar getMenuItemPath:(NSMenuItem *)sender];

  // spectial handling Window Menu
  curWindowType = [self getWindowType:senderPath];
  if (curWindowType != BX_GUI_WINDOW_UNDEFINED) {
    // Toggle Window visibility
    curWindow = [self getWindow:curWindowType];
    [self showWindow:curWindowType doShow:!curWindow.visible];
    return;
  }

  NSLog(@"Hit that menu %@", senderPath);
  [self.bx_p_col setProperty:senderPath value:1];

}

@end


@implementation BXNSGenericWindow

/**
 * initWithBXController
 */
- (instancetype _Nonnull)initWithBXController:(BXNSWindowController * _Nonnull) controller contentRect:(NSRect) rect styleMask:(NSWindowStyleMask) style backing:(NSBackingStoreType) backingStoreType defer:(BOOL) flag {

  self = [super initWithContentRect:rect styleMask:style backing:backingStoreType defer:flag];
  if (self) {
    self.bx_controller = controller;
  }

  return self;

}

/**
 * windowShouldClose
 */
- (BOOL)windowShouldClose:(NSWindow * _Nonnull)sender {
  [self setIsVisible:NO];
  return NO;
}

@end



////////////////////////////////////////////////////////////////////////////////
// TEMP Configuration Window
////////////////////////////////////////////////////////////////////////////////

@interface BXldata : NSObject <NSTableViewDataSource, NSTableViewDelegate>
@end

@implementation BXldata
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return 10;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  NSTextField *result = [tableView makeViewWithIdentifier:@"Col1" owner:self];
  if (result == nil) {
    result = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 100, 10)];
    result.identifier = @"Col1";
  }
  result.stringValue = @"Data for me";//[self.nameArray objectAtIndex:row];
  return result;
}
@end

@implementation BXNSConfigurationWindow

  NSBox * configBox;
  NSTableView * editOptionsTable;
  BXldata * eotdata;

  - (instancetype _Nonnull)init:(BXNSWindowController * _Nonnull) controller; {

    self = [super initWithBXController:controller
         contentRect: NSMakeRect(0, 0, 400, 200)
           styleMask: NSWindowStyleMaskTitled |
                      NSWindowStyleMaskClosable |
                      NSWindowStyleMaskMiniaturizable
             backing: NSBackingStoreBuffered
               defer: NO
    ];
  // |                    NSWindowStyleMaskResizable

    if (self) {
NSLog(@"init BXNSConfigurationWindow");
      configBox = [[NSBox alloc] init];
      [configBox setFrameFromContentFrame:NSMakeRect(20,100,100,50)];
      configBox.title = @"Configuration";

      [self.contentView addSubview:configBox];

      NSScrollView * tableContainer = [[NSScrollView alloc] initWithFrame:NSMakeRect(200,000,150,200)];

      editOptionsTable = [[NSTableView alloc] initWithFrame:NSMakeRect(200,000,150,200)];
      NSTableColumn * column1 = [[NSTableColumn alloc] initWithIdentifier:@"Col1"];
      [column1 setWidth:180];
      [editOptionsTable addTableColumn:column1];
      editOptionsTable.headerView = nil;

      eotdata = [[BXldata alloc] init];
      [editOptionsTable setDelegate:eotdata];
      [editOptionsTable setDataSource:eotdata];
      // editOptionsTable.dataSource = eotdata;
      [editOptionsTable reloadData];

      [tableContainer setDocumentView:editOptionsTable];
      [tableContainer setHasVerticalScroller:YES];

      [self.contentView addSubview:tableContainer];



      [NSApp setDelegate:self];
      [NSApp setDelegate:[self contentView]];
      [self setTitle:BOCHS_WINDOW_NAME];





    }

    return self;
  }




@end






////////////////////////////////////////////////////////////////////////////////
// TEMP Simulation Window
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSSimulationWindow

BXNSEventQueue * BXEventQueue;

/**
 * init
 */
- (instancetype _Nonnull)init:(BXNSWindowController * _Nonnull) controller HeaderBarHeight:(UInt8) headerbar_y VGAxRes:(UInt16) vga_xres VGAyRes:(UInt16) vga_yres {

  self = [super initWithBXController:controller
       contentRect: NSMakeRect(0, 0, vga_xres, vga_yres + headerbar_y)
         styleMask: NSWindowStyleMaskTitled |
                    NSWindowStyleMaskClosable |
                    NSWindowStyleMaskMiniaturizable
           backing: NSBackingStoreBuffered
             defer: NO
  ];

  if (self) {

    [self setTitle:BOCHS_WINDOW_NAME];

    BXEventQueue = [[BXNSEventQueue alloc] init];

    self.MouseCaptureAbsolute = NO;
    self.MouseCaptureActive = NO;

    // Setup VGA display
    self.BXVGA = [[BXVGAdisplay alloc] init:8 width:vga_xres height:vga_yres font_width:0 font_height:0 view:[self contentView]];

    // setup Toolbar
    self.BXToolbar = [[BXNSHeaderBar alloc] init:headerbar_y width:vga_xres yofs:vga_yres];


    [self setAcceptsMouseMovedEvents:YES];

  }

  return self;

}

/**
 * getter hasEvent
 */
- (BOOL)hasEvent {
  return !BXEventQueue.isEmpty;
}

/**
 * return the Event
 * if none exist return 0
 */
- (UInt64)getEvent {
  return [BXEventQueue dequeue];
}

/**
 * captureMouse ON / OFF
 */
- (void)captureMouse:(BOOL) grab {

  self.MouseCaptureActive = grab;
  if (self.MouseCaptureActive) {
    CGAssociateMouseAndMouseCursorPosition(NO);
    CGDisplayHideCursor(kCGDirectMainDisplay);
  } else {
    CGAssociateMouseAndMouseCursorPosition(YES);
    CGDisplayShowCursor(kCGDirectMainDisplay);
  }

}

/**
 * capture mouse to XY
 */
- (void)captureMouseXY:(NSPoint) XY {

  NSPoint screenXY;
  int y;

  y = XY.y;
  XY.y = 0;

  screenXY = [self convertPointToScreen:XY];
  CGWarpMouseCursorPosition(NSMakePoint(screenXY.x, self.screen.frame.size.height - screenXY.y + y - self.BXVGA.height));

}

/**
 * keyDown
 */
- (void)keyDown:(NSEvent * _Nonnull)event {

  BXL_DEBUG(([NSString stringWithFormat:@"keyDown window event.keyCode=%x char=%c event.modifierFlags=%lx",
    event.keyCode,
    event.charactersIgnoringModifiers==nil?'?':event.charactersIgnoringModifiers.length ==0?'?':[event.characters characterAtIndex:0],
    (unsigned long)event.modifierFlags
  ]));
  [BXEventQueue enqueue:((unsigned long)event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask) | event.keyCode];

}

/**
 * keyUp
 */
- (void)keyUp:(NSEvent * _Nonnull)event {

  BXL_DEBUG(([NSString stringWithFormat:@"keyUp window event.keyCode=%x char=%c event.modifierFlags=%lx",
    event.keyCode,
    event.charactersIgnoringModifiers==nil?'?':event.charactersIgnoringModifiers.length ==0?'?':[event.characters characterAtIndex:0],
    (unsigned long)event.modifierFlags
  ]));
  [BXEventQueue enqueue:MACOS_NSEventModifierFlagKeyUp | ((unsigned long)event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask) | event.keyCode];

}


/**
 * Mouse event handling
 */
- (void)handleMouse:(NSEvent * _Nonnull)event {

  NSPoint mouseXY;
  UInt64 evt;
  UInt64 mx;
  UInt64 my;
  UInt64 mb;
  UInt64 mf;
  NSUInteger mouseBTN;

  if (!self.MouseCaptureActive) {
    return;
  }

  mouseXY = event.locationInWindow;

  if (self.MouseCaptureAbsolute) {
    mouseXY.y = self.BXVGA.height - (unsigned)mouseXY.y;
    if (((UInt32)mouseXY.y < 0) || ((UInt32)mouseXY.y > self.BXVGA.height) || ((UInt32)mouseXY.x < 0) || ((UInt32)mouseXY.x > self.BXVGA.width))  {
     return;
    }
  } else {
    SInt32 dx;
    SInt32 dy;

    CGGetLastMouseDelta(&dx, &dy);
    if ((dx < -100) | (dx > 100) | (dy < -100) | (dy > 100)) {
      return;
    }
    mouseXY = NSMakePoint(dx, dy*-1);

  }
  mouseBTN = [NSEvent pressedMouseButtons];

  mf = (event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask) >> 16;

  mx = ((SInt16)mouseXY.x) & 0xFFFF;
  my = ((SInt16)mouseXY.y) & 0xFFFF;
  mb = (UInt8)(mouseBTN & 0xFF);

  evt = MACOS_NSEventModifierFlagMouse |
    mb << 48 |
    mf << 32 |
    mx << 16 |
    my;
  BXL_DEBUG(([NSString stringWithFormat:@"handleMouse x=%lld y=%lld btn=%llx flag=%llx evt=%llx abs=%s",
    mx, my, mb, mf, evt, self.MouseCaptureAbsolute?"YES":"NO"]));
  [BXEventQueue enqueue:evt];

}

/**
 * mouseMoved
 */
- (void)mouseMoved:(NSEvent * _Nonnull)event {
  [self handleMouse:event];
}

/**
 * mouseDragged
 */
- (void) mouseDragged:(NSEvent* _Nonnull)event {
  [self handleMouse:event];
}

/**
 * rightMouseDragged
 */
- (void)rightMouseDragged:(NSEvent * _Nonnull)event {
  [self handleMouse:event];
}

/**
 * otherMouseDragged
 */
- (void)otherMouseDragged:(NSEvent * _Nonnull)event {
  [self handleMouse:event];
}

/**
 * mouseDown
 */
- (void) mouseDown:(NSEvent* _Nonnull)event {
  [self handleMouse:event];
}

/**
 * rightMouseDown
 */
- (void)rightMouseDown:(NSEvent * _Nonnull)event {
  [self handleMouse:event];
}

/**
 * otherMouseDown
 */
- (void)otherMouseDown:(NSEvent * _Nonnull)event {
  [self handleMouse:event];
}

/**
 * mouseUp
 */
- (void) mouseUp:(NSEvent* _Nonnull)event {
  [self handleMouse:event];
}

/**
 * rightMouseUp
 */
- (void)rightMouseUp:(NSEvent * _Nonnull)event {
  [self handleMouse:event];
}

/**
 * otherMouseUp
 */
- (void)otherMouseUp:(NSEvent * _Nonnull)event {
  [self handleMouse:event];
}



@end

////////////////////////////////////////////////////////////////////////////////
// TEMP Logging Window
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSLoggingWindow

NSView * optionsView;
NSBox * optionsBox;
NSButton * panicOption;
NSButton * errorOption;
NSButton * infoOption;
NSButton * debugOption;
NSButton * refreshButton;
NSBox * messagesBox;
NSScrollView * messagesScrollView;
NSTextView * messagesText;
NSDictionary * attributesText;
NSTimer * refreshTimer;
UInt8 loglevelMask;

/**
 * init
 */
- (instancetype _Nonnull)init:(BXNSWindowController * _Nonnull) controller LogQueue:(BXNSLogQueue * _Nonnull) queue {

  self = [super initWithBXController:controller
       contentRect: NSMakeRect(0, 0, 400, 400)
         styleMask: NSWindowStyleMaskTitled |
                    NSWindowStyleMaskClosable |
                    NSWindowStyleMaskMiniaturizable |
                    NSWindowStyleMaskResizable
           backing: NSBackingStoreBuffered
             defer: NO
  ];

  if (self) {

    self.queue = queue;

    [self setTitle:BOCHS_WINDOW_LOGGER_NAME];

    loglevelMask = 0x00;

    self.contentView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

    optionsBox = [[NSBox alloc] init];
    [optionsBox setFrameFromContentFrame:NSMakeRect(20,350,360,20)];
    optionsBox.title = @"Logging Level";
    optionsBox.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;

    panicOption = [NSButton checkboxWithTitle:@"Panic" target:self action:nil];
    panicOption.frame = NSMakeRect(0, 0, 80, 20);
    [optionsBox addSubview:panicOption];
    errorOption = [NSButton checkboxWithTitle:@"Error" target:self action:nil];
    errorOption.frame = NSMakeRect(80, 0, 80, 20);
    [optionsBox addSubview:errorOption];
    infoOption = [NSButton checkboxWithTitle:@"Info" target:self action:nil];
    infoOption.frame = NSMakeRect(160, 0, 80, 20);
    [optionsBox addSubview:infoOption];
    debugOption = [NSButton checkboxWithTitle:@"Debug" target:self action:nil];
    debugOption.frame = NSMakeRect(240, 0, 80, 20);
    [optionsBox addSubview:debugOption];

    refreshButton = [NSButton buttonWithTitle:@"Refresh" target:self action:@selector(refreshFromQueue)];
    refreshButton.frame = NSMakeRect(320, 0, 80, 20);
    [optionsBox addSubview:refreshButton];

    messagesBox = [[NSBox alloc] init];
    [messagesBox setFrameFromContentFrame:NSMakeRect(20,20,360,290)];
    messagesBox.title = @"Logging Messages";
    messagesBox.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin | NSViewHeightSizable;

    messagesScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(10, 10, 340, 270)];
    messagesScrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [messagesScrollView setBorderType:NSNoBorder];
    [messagesScrollView setHasVerticalScroller:YES];

    messagesText = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 340, 270)];
    messagesText.autoresizingMask = NSViewWidthSizable;
    [messagesText setMinSize:NSMakeSize(0, 270)];
    [messagesText setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [messagesText setVerticallyResizable:YES];
    [messagesText setHorizontallyResizable:NO];
    [messagesText setTextColor:NSColor.textColor];
    [[messagesText textContainer] setContainerSize:NSMakeSize(340, FLT_MAX)];
    [[messagesText textContainer] setWidthTracksTextView:YES];
    [[messagesText textContainer] setHeightTracksTextView:NO];

    attributesText = @{NSForegroundColorAttributeName:NSColor.textColor,
    NSFontAttributeName:[NSFont monospacedSystemFontOfSize:12 weight:NSFontWeightRegular]};

    [messagesScrollView setDocumentView:messagesText];
    [messagesBox addSubview:messagesScrollView];

    [self.contentView addSubview:optionsBox];
    [self.contentView addSubview:messagesBox];

    refreshTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(refreshFromQueue) userInfo:nil repeats:YES];

  }

  return self;

}

/**
 * refreshFromQueue
 */
- (void)refreshFromQueue {

  if (self.queue.isEmpty) {
    return;
  }

  while (!self.queue.isEmpty) {

    BXNSLogEntry * entry;
    NSAttributedString * msg;
    NSString * fmsg;

    entry = [self.queue dequeue];

    // TODO : check flags
    fmsg = [[NSString alloc] initWithFormat:@"%@ (%d)[%@] %@", entry.timecode, entry.level, entry.module, entry.msg];
    msg = [[NSAttributedString alloc] initWithString:fmsg attributes:attributesText];

    [[messagesText textStorage] appendAttributedString:msg];
    [messagesText scrollRangeToVisible:NSMakeRange([[messagesText string] length], 0)];

  }

}


@end


////////////////////////////////////////////////////////////////////////////////
// TEMP Debugger Window
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSDebuggerWindow

/**
 * init
 */
- (instancetype _Nonnull)init:(BXNSWindowController * _Nonnull) controller {

  self = [super initWithBXController:controller
       contentRect: NSMakeRect(0, 0, 640, 480)
         styleMask: NSWindowStyleMaskTitled |
                    NSWindowStyleMaskClosable |
                    NSWindowStyleMaskMiniaturizable |
                    NSWindowStyleMaskResizable
           backing: NSBackingStoreBuffered
             defer: NO
  ];

  if (self) {

  }

  return self;

}

@end




















// #if BX_SUPPORT_X86_64
//   #define BOCHS_WINDOW_NAME @"Bochs x86-64 emulator MacOS X"
// #else
//   #define BOCHS_WINDOW_NAME @"Bochs x86 emulator MacOS X"
// #endif
//
//
// @interface BXNSEventQueue : NSObject
//
//   @property (nonatomic, readonly, getter=isEmpty) BOOL isEmpty;
//
//   - (instancetype)init;
//   - (void)dealloc;
//
//   - (void)enqueue:(UInt64) value;
//   - (UInt64)dequeue;
//   - (BOOL)isEmpty;
//
// @end




// @interface BXGuiCocoaNSWindow : NSWindow <NSApplicationDelegate>
//
//   @property (nonatomic, readwrite, assign) BXVGAdisplay * BXVGA;
//   @property (nonatomic, readonly, getter=hasEvent) BOOL hasEvent;
//   @property (nonatomic, readwrite) BOOL MouseCaptureAbsolute;
//   @property (nonatomic, readwrite) BOOL MouseCaptureActive;
//   - (instancetype)init:(unsigned) headerbar_y VGAsize:(NSSize) vga;
//   - (void)dealloc;
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

// @implementation BXGuiCocoaNSWindow
//
// // BXHeaderbar * BXToolbar;
// // BXNSEventQueue * BXEventQueue;
//
//
// /**
//  * BXGuiCocoaNSWindow CTor
//  */
// - (instancetype)init:(unsigned) headerbar_y VGAsize:(NSSize) vga {
//
//   BXL_DEBUG(@"BXGuiCocoaNSWindow::init");
//
//   self = [super initWithContentRect:NSMakeRect(0, 0, vga.width, vga.height + headerbar_y)
//          styleMask: NSWindowStyleMaskTitled |
//                     NSWindowStyleMaskClosable |
//                     NSWindowStyleMaskMiniaturizable
//            backing: NSBackingStoreBuffered
//              defer: NO
//   ];
// // |                    NSWindowStyleMaskResizable
//   [NSApp setDelegate:self];
//   [NSApp setDelegate:[self contentView]];
//   [self setTitle:BOCHS_WINDOW_NAME];
//
//   // [self contentView].wantsLayer = YES;
//
//   // BXEventQueue = [[BXNSEventQueue alloc] init];
//
//   self.MouseCaptureAbsolute = NO;
//
//   // Setup VGA display
//   self.BXVGA = [[BXVGAdisplay alloc] init:8 width:vga.width height:vga.height font_width:0 font_height:0 view:[self contentView]];
//
//   // setup Toolbar
//   // BXToolbar = [[BXHeaderbar alloc] init:headerbar_y width:self.BXVGA.width yofs:self.BXVGA.height];
//
//
//
//   [self center];
//   [self setIsVisible:YES];
//   [self makeKeyAndOrderFront:self];
//   [self setAcceptsMouseMovedEvents:YES];
//   // [self makeFirstResponder: [self contentView] ];
//
//
//   BXL_INFO(([NSString stringWithFormat:@"keyWindow %s", self.keyWindow?"YES":"NO"]));
//
//   return self;
// }
//
// // /**
// //  * BXGuiCocoaNSWindow DTor
// //  */
// // - (void)dealloc {
// //   [BXEventQueue dealloc];
// //   [self.BXVGA dealloc];
// //   [BXToolbar dealloc];
// //   [super dealloc];
// // }
//
// - (BOOL)windowShouldClose:(id)sender {
//   [NSApp terminate:sender];
//   return YES;
// }
//
// - (BOOL)canBecomeKeyWindow {
//     return YES;
// }
//
// - (BOOL)canBecomeMainWindow {
//     return YES;
// }
//
// - (void)keyDown:(NSEvent *)event {
//
//   BXL_DEBUG(([NSString stringWithFormat:@"keyDown window event.keyCode=%x char=%c event.modifierFlags=%lx",
//     event.keyCode,
//     event.charactersIgnoringModifiers==nil?'?':event.charactersIgnoringModifiers.length ==0?'?':[event.characters characterAtIndex:0],
//     (unsigned long)event.modifierFlags
//   ]));
//   [BXEventQueue enqueue:((unsigned long)event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask) | event.keyCode];
//
// }
//
// - (void)keyUp:(NSEvent *)event {
//
//   BXL_DEBUG(([NSString stringWithFormat:@"keyUp window event.keyCode=%x char=%c event.modifierFlags=%lx",
//     event.keyCode,
//     event.charactersIgnoringModifiers==nil?'?':event.charactersIgnoringModifiers.length ==0?'?':[event.characters characterAtIndex:0],
//     (unsigned long)event.modifierFlags
//   ]));
//   [BXEventQueue enqueue:MACOS_NSEventModifierFlagKeyUp | ((unsigned long)event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask) | event.keyCode];
//
// }
//
// /**
//  * Mouse event handling
//  */
// - (void)handleMouse:(NSEvent *)event {
//   NSPoint mouseXY;
//   UInt64 evt;
//   UInt64 mx;
//   UInt64 my;
//   UInt64 mb;
//   UInt64 mf;
//   NSUInteger mouseBTN;
//
//   mouseXY = event.locationInWindow;
//
//   if (self.MouseCaptureAbsolute) {
//     mouseXY.y = self.BXVGA.height - (unsigned)mouseXY.y;
//     if (((UInt32)mouseXY.y < 0) || ((UInt32)mouseXY.y > self.BXVGA.height) || ((UInt32)mouseXY.x < 0) || ((UInt32)mouseXY.x > self.BXVGA.width))  {
//      return;
//     }
//   } else {
//     SInt32 dx;
//     SInt32 dy;
//
//     CGGetLastMouseDelta(&dx, &dy);
//     if ((dx < -100) | (dx > 100) | (dy < -100) | (dy > 100)) {
//       return;
//     }
//     mouseXY = NSMakePoint(dx, dy*-1);
//
//   }
//   mouseBTN = [NSEvent pressedMouseButtons];
//
//   mf = (event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask) >> 16;
//
//   mx = ((SInt16)mouseXY.x) & 0xFFFF;
//   my = ((SInt16)mouseXY.y) & 0xFFFF;
//   mb = (UInt8)(mouseBTN & 0xFF);
//
//   evt = MACOS_NSEventModifierFlagMouse |
//     mb << 48 |
//     mf << 32 |
//     mx << 16 |
//     my;
//   BXL_DEBUG(([NSString stringWithFormat:@"handleMouse x=%lld y=%lld btn=%llx flag=%llx evt=%llx abs=%s",
//     mx, my, mb, mf, evt, self.MouseCaptureAbsolute?"YES":"NO"]));
//   [BXEventQueue enqueue:evt];
//
// }
//
// - (void)mouseMoved:(NSEvent *)event {
//   [self handleMouse:event];
// }
// - (void) mouseDragged:(NSEvent*)event {
//   [self handleMouse:event];
// }
// - (void)rightMouseDragged:(NSEvent *)event {
//   [self handleMouse:event];
// }
// - (void)otherMouseDragged:(NSEvent *)event {
//   [self handleMouse:event];
// }
// - (void) mouseDown:(NSEvent*)event {
//   [self handleMouse:event];
// }
// - (void)rightMouseDown:(NSEvent *)event {
//   [self handleMouse:event];
// }
// - (void)otherMouseDown:(NSEvent *)event {
//   [self handleMouse:event];
// }
// - (void) mouseUp:(NSEvent*)event {
//   [self handleMouse:event];
// }
// - (void)rightMouseUp:(NSEvent *)event {
//   [self handleMouse:event];
// }
// - (void)otherMouseUp:(NSEvent *)event {
//   [self handleMouse:event];
// }
//
//
// /**
//  * showAlertMessage
//  * show a modal Alert Message
//  */
// - (void)showAlertMessage:(const char *) msg style:(const char) type {
//
//   NSAlert * alert;
//   NSString * aMsg;
//   NSAlertStyle aStyle;
//
//   if ((msg == NULL) | (msg == nil)) {
//     aMsg = @"No msg supplied ...";
//   } else {
//     BXL_INFO(([NSString stringWithFormat:@"showAlertMessage %s", msg]));
//     // NSMutableData * dmsg;
//     // dmsg = [[[NSMutableData alloc] initWithLength:(strlen(msg)+1)] autorelease];
//     // [dmsg replaceBytesInRange:NSMakeRange(0, strlen(msg)) withBytes:msg];
//     // aMsg = [[[NSString alloc] initWithData:(NSData *)dmsg encoding:NSUTF8StringEncoding] autorelease];
//     aMsg = @"No msg supplied ...";
//   }
//   switch (type) {
//     case BX_ALERT_MSG_STYLE_INFO: {
//       aStyle = NSAlertStyleInformational;
//       break;
//     }
//     case BX_ALERT_MSG_STYLE_CRIT: {
//       aStyle = NSAlertStyleCritical;
//       break;
//     }
//     default: {
//       aStyle = NSAlertStyleWarning;
//     }
//   }
//
//   alert = [[NSAlert alloc] init];
//   alert.alertStyle = aStyle;
//   alert.messageText = aMsg;
//   alert.informativeText = @"thats the Info!";
//   alert.icon = nil;
//
//   [alert runModal];
//
// }
//
//
// /**
//  * captureMouse ON / OFF
//  */
// - (void)captureMouse:(BOOL) grab {
//   self.MouseCaptureActive = grab;
//   if (self.MouseCaptureActive) {
//     CGAssociateMouseAndMouseCursorPosition(NO);
//     CGDisplayHideCursor(kCGDirectMainDisplay);
//   } else {
//     CGAssociateMouseAndMouseCursorPosition(YES);
//     CGDisplayShowCursor(kCGDirectMainDisplay);
//   }
// }
//
// /**
//  * capture mouse to XY
//  */
// - (void)captureMouseXY:(NSPoint) XY {
//   NSPoint screenXY;
//   int y;
//
//   y = XY.y;
//   XY.y = 0;
//
//   screenXY = [self convertPointToScreen:XY];
//   CGWarpMouseCursorPosition(NSMakePoint(screenXY.x, self.screen.frame.size.height - screenXY.y + y - self.BXVGA.height));
//   BXL_DEBUG(([NSString stringWithFormat:@"captureMouse x=%d y=%d orgx=%d orgy=%d w.y=%d s.h=%d",
//   (int)screenXY.x, (int)screenXY.y, (int)XY.x, (int)XY.y, (int)self.frame.origin.y, (int)self.screen.frame.size.height]));
//
// }
//
// /**
//  * getMaxScreenResolution
//  */
// - (void)getMaxScreenResolution:(unsigned char *) bpp width:(unsigned int *) w height:(unsigned int *) h {
//
//   NSArray * screens;
//
//   screens = [NSScreen screens];
//
//   [screens enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
//
//     NSScreen * screen;
//     NSRect frame;
//     NSInteger sBpp;
//
//     screen = [screens objectAtIndex: idx];
//     frame = [screen visibleFrame];
//     sBpp = NSBitsPerPixelFromDepth(screen.depth);
//
//     if (((unsigned int)frame.size.width > *w) | ((unsigned int)frame.size.height > *h) | (sBpp > *bpp)) {
//       *bpp = (unsigned char)sBpp;
//       *w = (unsigned int)frame.size.width;
//       *h = (unsigned int)frame.size.height;
//     }
//
//   }];
//
//   BXL_DEBUG(([NSString stringWithFormat:@"ScreenResolution bpp=%d width=%d height=%d", *bpp, *w, *h]));
//
// }
//
//
//
//
//
//
//
//
// /**
//  * createIconXPM forwarding
//  */
// - (NSImage *)createIconXPM {
//   // return [BXToolbar createIconXPM];
// }
//
//
// /**
//  * createBXBitmap forwarding
//  */
// - (unsigned)createBXBitmap:(const unsigned char *)bmap xdim:(unsigned) x ydim:(unsigned) y {
//   // return ([BXToolbar createBXBitmap:bmap xdim:x ydim:y]);
// }
//
// /**
//  * headerbarBXBitmap forwarding
//  */
// - (unsigned)headerbarBXBitmap:(unsigned) bmap_id alignment:(unsigned) align func:(void (*)()) f {
//   // return ([BXToolbar headerbarBXBitmap:bmap_id alignment:align func:f]);
// }
//
// /**
//  * create new headerbar
//  * multiple calls allowed
//  */
// - (void)headerbarCreate {
//   // [BXToolbar headerbarCreate:[self contentView]];
// }
//
// /**
//  * update headerbar
//  */
// - (void)headerbarUpdate {
//   // [BXToolbar headerbarUpdate:self.BXVGA];
// }
//
// /**
//  * change image in headerbar
//  */
// - (void)headerbarSwitchBXBitmap:(unsigned) btn_id data_id:(unsigned) bmap_id {
//   // [BXToolbar headerbarBXBitmap:btn_id data_id:bmap_id];
// }
//
// - (unsigned)getHeaderbarHeight {
//   // return (BXToolbar.height);
// }
//
// /**
//  * render VGA display
//  */
// - (void)renderVGA {
//   [self.BXVGA render];
// }
//
// /**
//  * change one VGA palette entry
//  */
// - (BOOL)changeVGApalette:(unsigned)index red:(char) r green:(char) g blue:(char) b {
//   return [self.BXVGA setPaletteRGB:index red:r green:g blue:b];
// }
//
// /**
//  * clear the VGA screen
//  */
// - (void)clearVGAscreen {
//   [self.BXVGA clearScreen];
// }
//
// /**
//  * init charmap data
//  */
// - (void)charmapVGA:(unsigned char *) dataA charmap:(unsigned char *) dataB width:(unsigned char)w height:(unsigned char) h {
//   [self.BXVGA initFonts:dataA second:dataB width:w height:h];
// }
//
// /**
//  * update charmap data at
//  */
// - (void)charmapVGAat:(unsigned) pos isFont2:(BOOL)font2 map:(unsigned char *) data {
//   [self.BXVGA updateFontAt:pos isFont2:font2 map:data];
// }
//
// /**
//  * paint char on VGA display
//  */
// - (void)paintcharVGA:(unsigned short int) charpos isCrsr:(BOOL) crsr font2:(BOOL) f2 bgcolor:(unsigned char) bg fgcolor:(unsigned char) fg position:(NSRect) rect {
//   [self.BXVGA paintChar:charpos isCrsr:crsr font2:f2 bgcolor:bg fgcolor:fg position:rect];
// }
//
// /**
//  * getter hasEvent
//  */
// - (BOOL)hasEvent {
//   return !BXEventQueue.isEmpty;
// }
//
// /**
//  * return the Event
//  * if none exist return 0
//  */
// - (UInt64)getEvent {
//   return [BXEventQueue dequeue];
// }
//
// /**
//  * clip bitmap region into VGA display
//  */
// - (void)clipRegionVGA:(unsigned char *)src position:(NSRect) rect {
//   [self.BXVGA clipRegion:src position:rect];
// }
//
// /**
//  * getVGAMemory Ptr
//  */
// - (const unsigned char *) getVGAMemory {
//   return self.BXVGA.VGAdisplayRAM;
// }
//
// /**
//  * clip region from local Memory
//  */
// - (void)clipRegionVGAPosition:(NSRect) rect {
//   [self.BXVGA clipRegionPosition:rect];
// }
//
//
//
// @end

// // C++ Wrapper for BXGuiCocoaNSWindow : NSWindow
//
// struct BXGuiCocoaWindowImpl {
//   BXGuiCocoaNSWindow * BXWindow;
// };

// // Class BXGuiCocoaWindow
//
// /**
//  * BXGuiCocoaWindow CTor
//  */
// BXGuiCocoaWindow::BXGuiCocoaWindow(unsigned x, unsigned y, unsigned headerbar_y) : BXCocoaWindow(new BXGuiCocoaWindowImpl) {
//   BXCocoaWindow->BXWindow = [[[BXGuiCocoaNSWindow alloc] init:headerbar_y VGAsize:NSMakeSize(x, y)] autorelease];
// }
//
// /**
//  * BXGuiCocoaWindow DTor
//  */
// BXGuiCocoaWindow::~BXGuiCocoaWindow() {
//   if (BXCocoaWindow) {
//     [BXCocoaWindow->BXWindow performClose:nil];
//   }
// }
//
// /**
//  * getScreenConfiguration
//  */
// void BXGuiCocoaWindow::getScreenConfiguration(unsigned int * width, unsigned int * height, unsigned char * bpp) {
//   [BXCocoaWindow->BXWindow getMaxScreenResolution:bpp width:width height:height];
// }
//
//
// /**
//  * showAlertMessage
//  */
// void BXGuiCocoaWindow::showAlertMessage(const char *msg, const char type) {
//   [BXCocoaWindow->BXWindow showAlertMessage:msg style:type];
// }
//
// /**
//  * captureMouse
//  */
// void BXGuiCocoaWindow::captureMouse(bool cap, unsigned x, unsigned y) {
//   [BXCocoaWindow->BXWindow captureMouseXY:NSMakePoint(x, y)];
//   [BXCocoaWindow->BXWindow captureMouse:cap];
// }
//
// /**
//  * captureMouse
//  */
// void BXGuiCocoaWindow::captureMouse(unsigned x, unsigned y) {
//   [BXCocoaWindow->BXWindow captureMouseXY:NSMakePoint(x, y)];
// }
//
// /**
//  * hasMouseCapture
//  */
// bool BXGuiCocoaWindow::hasMouseCapture(void) {
//   return (BXCocoaWindow->BXWindow.MouseCaptureActive);
// }
//
//
//
//
// void * BXGuiCocoaWindow::createIconXPM(void) {
//   return (void *)[BXCocoaWindow->BXWindow createIconXPM];
// }
// /**
//  * create_bitmap
//  */
// unsigned BXGuiCocoaWindow::create_bitmap(const unsigned char *bmap, unsigned xdim, unsigned ydim) {
//   return ([BXCocoaWindow->BXWindow createBXBitmap:bmap xdim:xdim ydim:ydim]);
// }
//
// /**
//  * headerbar_bitmap
//  */
// unsigned BXGuiCocoaWindow::headerbar_bitmap(unsigned bmap_id, unsigned alignment, void (*f)(void)) {
//   return ([BXCocoaWindow->BXWindow headerbarBXBitmap:bmap_id alignment:alignment func:f]);
// }
//
// /**
//  * show_headerbar
//  */
// void BXGuiCocoaWindow::show_headerbar(void) {
//   [BXCocoaWindow->BXWindow headerbarCreate];
// }
//
// /**
//  * dimension_update
//  */
// void BXGuiCocoaWindow::dimension_update(unsigned x, unsigned y, unsigned fwidth, unsigned fheight, unsigned bpp) {
//
//   NSRect windowFrame;
//   NSRect newWindowFrame;
//
//   // Change VGA display
//   [BXCocoaWindow->BXWindow.BXVGA changeBPP:bpp width:x height:y font_width:fwidth font_height:fheight];
//
//   // prepare window
//   windowFrame = [BXCocoaWindow->BXWindow contentRectForFrameRect:[BXCocoaWindow->BXWindow frame]];
//   newWindowFrame = [BXCocoaWindow->BXWindow frameRectForContentRect:NSMakeRect( NSMinX( windowFrame ), NSMinY( windowFrame ), x, y + BXCocoaWindow->BXWindow.getHeaderbarHeight)];
//
//   [BXCocoaWindow->BXWindow setContentSize:NSMakeSize(x, y + BXCocoaWindow->BXWindow.getHeaderbarHeight)];
//
//   [BXCocoaWindow->BXWindow headerbarUpdate];
//
//   //[BXCocoaWindow->BXWindow setFrame:newWindowFrame display:YES animate:[BXCocoaWindow->BXWindow isVisible]];
//
// }
//
// /**
//  * render
//  */
// void BXGuiCocoaWindow::render(void) {
//   [BXCocoaWindow->BXWindow renderVGA];
// }
//
// /**
//  * palette_change
//  */
// bool BXGuiCocoaWindow::palette_change(unsigned char index, unsigned char red, unsigned char green, unsigned char blue) {
//   return ([BXCocoaWindow->BXWindow changeVGApalette:index red:red green:green blue:blue]);
// }
//
// /**
//  * clear_screen
//  */
// void BXGuiCocoaWindow::clear_screen(void) {
//   [BXCocoaWindow->BXWindow clearVGAscreen];
// }
//
// /**
//  * replace_bitmap
//  */
// void BXGuiCocoaWindow::replace_bitmap(unsigned hbar_id, unsigned bmap_id) {
//   [BXCocoaWindow->BXWindow headerbarSwitchBXBitmap:hbar_id data_id:bmap_id];
// }
//
// /**
//  * setup_charmap
//  */
// void BXGuiCocoaWindow::setup_charmap(unsigned char *charmapA, unsigned char *charmapB, unsigned char w, unsigned char h) {
//   [BXCocoaWindow->BXWindow charmapVGA:charmapA charmap:charmapB width:w height:h];
// }
//
// /**
//  * set_font
//  */
// void BXGuiCocoaWindow::set_font(bool font2, unsigned pos, unsigned char *charmap) {
//   [BXCocoaWindow->BXWindow charmapVGAat:pos isFont2:font2 map:charmap];
// }
//
//
// /**
//  * draw_char
//  */
// void BXGuiCocoaWindow::draw_char(bool crsr, bool font2, unsigned char fgcolor, unsigned char bgcolor, unsigned short int charpos, unsigned short int x, unsigned short int y, unsigned char w, unsigned char h) {
//   [BXCocoaWindow->BXWindow paintcharVGA:charpos isCrsr:crsr font2:font2 bgcolor:bgcolor fgcolor:fgcolor position:NSMakeRect(x, y, w, h)];
// }
//
// /**
//  * hasEvent
//  */
// bool BXGuiCocoaWindow::hasEvent(void) {
//   return (BXCocoaWindow->BXWindow.hasEvent);
// }
//
// /**
//  * setEventMouseABS
//  */
// void BXGuiCocoaWindow::setEventMouseABS(bool abs) {
//   BXCocoaWindow->BXWindow.MouseCaptureAbsolute = abs;
// }
//
// /**
//  * getEvent
//  */
// unsigned long BXGuiCocoaWindow::getEvent(void) {
//   return ([BXCocoaWindow->BXWindow getEvent]);
// }
//
// /**
//  * graphics_tile_update
//  */
// void BXGuiCocoaWindow::graphics_tile_update(unsigned char *tile, unsigned x, unsigned y, unsigned w, unsigned h) {
//   [BXCocoaWindow->BXWindow clipRegionVGA:tile position:NSMakeRect(x, y, w, h)];
// }
//
// /**
//  * getVGAdisplayPtr
//  */
// const unsigned char * BXGuiCocoaWindow::getVGAdisplayPtr(void) {
//   return ([BXCocoaWindow->BXWindow getVGAMemory]);
// }
//
// /**
//  * graphics_tile_update_in_place
//  */
// void BXGuiCocoaWindow::graphics_tile_update_in_place(unsigned x, unsigned y, unsigned w, unsigned h) {
//   [BXCocoaWindow->BXWindow clipRegionVGAPosition:NSMakeRect(x, y, w, h)];
// }





// EOF
