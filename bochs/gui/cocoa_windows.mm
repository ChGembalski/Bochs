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
#include "cocoa_ctrl.h"
#include "cocoa_menu.h"
#include "config.h"
#include "siminterface.h"
#include "param_names.h"

#if BX_DEBUGGER && BX_DEBUGGER_GUI
#include "bx_debug/debug.h"
#include "enh_dbg.h"
#endif /* BX_DEBUGGER && BX_DEBUGGER_GUI */


edit_opts_t root_options[] = {
  { @"General options",                     "general" },
  { @"Optional plugin control",             BXPN_PLUGIN_CTRL },
  { @"Logfile options",                     "log" },
  { @"Log options for all devices",         "general.logfn" },
  { @"Log options for individual devices",  "general.logdevice" },
  { @"CPU options",                         "cpu" },
  { @"CPUID options",                       "cpuid" },
  { @"Memory options",                      "memory" },
  { @"Clock & CMOS options",                "clock_cmos" },
  { @"PCI options",                         "pci" },
  { @"Bochs Display & Interface options",   "display" },
  { @"Keyboard & Mouse options",            "keyboard_mouse" },
  { @"Boot options",                        "boot_params" },
  { @"Disk options",                        BXPN_MENU_DISK },
  { @"Serial / Parallel / USB options",     "ports" },
  { @"Network card options",                "network" },
  { @"Sound card options",                  "sound" },
  { @"Other options",                       "misc" },
#if BX_PLUGINS
  { @"User-defined options",                "user" },
#endif /* BX_PLUGINS */
  { nil,                                    NULL }
};



////////////////////////////////////////////////////////////////////////////////
// BXNSPropertyCollection
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSPropertyCollection

/**
 * init
 */
- (instancetype _Nonnull)init {

  self = [super init];
  if (self) {
    self.map = [[NSMutableDictionary alloc] init];
  }

  return self;

}

/**
 * setProperty
 */
- (void)setProperty:(NSString * _Nonnull) name value:(NSInteger) val {

  [self.map setObject:[NSNumber numberWithInteger:val] forKey:name];

}

/**
 * getProperty
 */
- (NSInteger)getProperty:(NSString * _Nonnull) name {

  NSNumber * value;

  value = [self.map objectForKey:name];
  if (value == nil) {
    return BX_PROPERTY_UNDEFINED;
  }
  [self. map removeObjectForKey:name];

  return value.integerValue;

}

/**
 * peekProperty
 */
- (NSInteger)peekProperty:(NSString * _Nonnull) name {

  NSNumber * value;

  value = [self.map objectForKey:name];
  if (value == nil) {
    return BX_PROPERTY_UNDEFINED;
  }

  return value.integerValue;

}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSLogEntry
////////////////////////////////////////////////////////////////////////////////
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


////////////////////////////////////////////////////////////////////////////////
// BXNSEventQueue
////////////////////////////////////////////////////////////////////////////////
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


////////////////////////////////////////////////////////////////////////////////
// BXNSWindowController
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSWindowController

BXNSMenuBar * menubar;

gui_window_t window_list[] = {
  {BX_GUI_WINDOW_CONFIGURATION, NULL, @"Window.Configuration"},
  {BX_GUI_WINDOW_VGA_DISPLAY,   NULL, @"Window.VGA Display"},
  {BX_GUI_WINDOW_LOGGING,       NULL, @"Window.Logger"},
#if BX_DEBUGGER && BX_NEW_DEBUGGER_GUI
  {BX_GUI_WINDOW_DEBUGGER,      NULL, @"Window.Debugger"},
#endif /** BX_DEBUGGER && BX_NEW_DEBUGGER_GUI */
  {BX_GUI_WINDOW_UNDEFINED,     NULL, nil}
};

/**
 * init
 */
- (instancetype _Nonnull)init:(UInt8) headerbar_y VGAxRes:(UInt16) vga_xres VGAyRes:(UInt16) vga_yres {

  self = [super init];
  if(self) {

    self.simulation_state = SIM_INIT;

    // Menue Bar
    menubar = [[BXNSMenuBar alloc] init:self];

    self.bx_p_col = [[BXNSPropertyCollection alloc] init];
    self.bx_log_queue = [[BXNSLogQueue alloc] init];
    self.event_condition = [[NSCondition alloc] init];
    self.event_condition.name = @"event_condition";
    self.event_lock = NO;

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

#if BX_DEBUGGER && BX_NEW_DEBUGGER_GUI
    window_list[3].window = [[BXNSDebuggerWindow alloc] init:self];
    [((NSWindow *)window_list[3].window) center];
    [window_list[3].window setIsVisible:NO];
#endif /* BX_DEBUGGER && BX_NEW_DEBUGGER_GUI */

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
 * showModalInfoDialog
 */
+ (void)showModalInfoDialog:(UInt8) level Title:(NSString * _Nonnull) title Message:(NSString * _Nonnull) msg {

  NSAlert * alert;
  NSAlertStyle aStyle;

  switch (level) {
    case BX_ALERT_MSG_STYLE_INFO: {
      aStyle = NSAlertStyleInformational;
      break;
    }
    case BX_ALERT_MSG_STYLE_CRIT: {
      aStyle = NSAlertStyleCritical;
      break;
    }
    default: {
      aStyle = NSAlertStyleWarning;
    }
  }

  alert = [[NSAlert alloc] init];
  alert.alertStyle = aStyle;
  alert.informativeText = title;
  alert.messageText = msg;
  alert.icon = nil;

  [alert runModal];

}

/**
 * showModalQuestionDialog
 */
+ (int)showModalQuestionDialog:(UInt8) level Title:(NSString * _Nonnull) title Message:(NSString * _Nonnull) msg {

  NSAlert * alert;
  NSAlertStyle aStyle;
  NSModalResponse aResponse;

  switch (level) {
    case BX_ALERT_MSG_STYLE_INFO: {
      aStyle = NSAlertStyleInformational;
      break;
    }
    case BX_ALERT_MSG_STYLE_CRIT: {
      aStyle = NSAlertStyleCritical;
      break;
    }
    default: {
      aStyle = NSAlertStyleWarning;
    }
  }

  alert = [[NSAlert alloc] init];
  alert.alertStyle = aStyle;
  alert.informativeText = title;
  alert.messageText = msg;
  alert.icon = nil;

  // add Buttons
  [alert addButtonWithTitle:@"Continue"];
  [alert addButtonWithTitle:@"Always Continue"];
  [alert addButtonWithTitle:@"Exit Bochs"];
  [alert addButtonWithTitle:@"Dump Core"];
#if BX_DEBUGGER && BX_NEW_DEBUGGER_GUI
  [alert addButtonWithTitle:@"Debug"];
#endif /* BX_DEBUGGER && BX_NEW_DEBUGGER_GUI */

  aResponse = [alert runModal];

  switch (aResponse) {
    case NSAlertFirstButtonReturn: return BX_LOG_ASK_CHOICE_CONTINUE;
    case NSAlertSecondButtonReturn: return BX_LOG_ASK_CHOICE_CONTINUE_ALWAYS;
    case NSAlertThirdButtonReturn: return BX_LOG_ASK_CHOICE_DIE;
    case NSAlertThirdButtonReturn + 1: return BX_LOG_ASK_CHOICE_DUMP_CORE;
#if BX_DEBUGGER && BX_NEW_DEBUGGER_GUI
    case NSAlertThirdButtonReturn + 2: return BX_LOG_ASK_CHOICE_ENTER_DEBUG;
#endif /* BX_DEBUGGER && BX_NEW_DEBUGGER_GUI */
    default : return BX_LOG_ASK_CHOICE_DIE;
  }

}

/**
 * showModalParamRequestDialog
 */
+ (int)showModalParamRequestDialog:(void * _Nonnull) param {

  BXNSParamRequestWindow * request;
  NSModalResponse response;

  request = [[BXNSParamRequestWindow alloc] init:param];

  response = [NSApp runModalForWindow:request];
  if (response == NSModalResponseOK) {
    return 1;
  }

  return 0;

}

/**
 * showModalAboutDialog
 */
+ (int)showModalAboutDialog {
  
  BXNSAboutWindow * about;
  NSModalResponse response;
  
  about = [[BXNSAboutWindow alloc] init];
  
  response = [NSApp runModalForWindow:about];
  if (response == NSModalResponseOK) {
    return 1;
  }

  return 0;
  
}



/**
 * onBochsThreadExit
 */
- (void)onBochsThreadExit {
  
  self.simulation_state = SIM_TERMINATE;
  [[[self getWindow:BX_GUI_WINDOW_LOGGING] refreshTimer] invalidate];
  
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
    [curWindow makeMainWindow];
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

  property = [BXNSMenuBar getMenuItemTypePath:p];
  if (property == nil) {
    return BX_PROPERTY_UNDEFINED;
  }

  return [self.bx_p_col getProperty:property];

}

/**
 * waitPropertySet
 */
- (void)waitPropertySet:(NSMutableArray<NSNumber *> * _Nonnull) property_list {

  NSMutableArray<NSString *> * property_names;

  property_names = [[NSMutableArray alloc] init];

  // convert to string
  for (NSNumber * num_property in property_list) {
    NSString * property;
    property_t p;

    p = (property_t) num_property.intValue;
    property = [BXNSMenuBar getMenuItemTypePath:p];
    if (property != nil) {
      [property_names addObject:property];
    }
  }

  // if empty resolve faild ... can't wait
  if (property_names.count == 0) {
    return;
  }

  // now check if one is set
  for (NSString * property in property_names) {
    if ([self.bx_p_col peekProperty:property] != BX_PROPERTY_UNDEFINED) {
      return;
    }
  }

  // none is set wait ...
  [self.event_condition lock];
event_loop:
  self.event_lock = YES;
  while (self.event_lock) {
    [self.event_condition wait];
  }

  // now check if one is set
  for (NSString * property in property_names) {
    if ([self.bx_p_col peekProperty:property] != BX_PROPERTY_UNDEFINED) {
      [self.event_condition unlock];
      return;
    }
  }
  goto event_loop;

}

/**
 * setProperty
 */
- (void)setProperty:(property_t) p Value:(int) val {
  
  NSString * property;

  property = [BXNSMenuBar getMenuItemTypePath:p];
  if (property == nil) {
    return;
  }

  return [self.bx_p_col setProperty:property value:val];
  
}

/**
 * getClipboardText
 */
- (int)getClipboardText:(unsigned char * _Nullable * _Nonnull) bytes Size:(int * _Nonnull) nbytes {
  
  NSPasteboard * cb;
  NSString * cb_data;
  
  cb = [NSPasteboard generalPasteboard];
  cb_data = [cb stringForType:NSPasteboardTypeString];
  if (cb_data == nil) {
    *bytes = NULL;
    *nbytes = 0;
    return 0;
  }
  
  *nbytes = [cb_data lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
  *bytes = new unsigned char[(*nbytes + 1) * sizeof(unsigned char)];
  memset(*bytes, 0, *nbytes + 1);
  memcpy(*bytes, cb_data.UTF8String, *nbytes * sizeof(unsigned char));
  return 1;
  
}

/**
 * setClipboardText
 */
- (int)setClipboardText:(char * _Nullable)text Size:(int) len {
  
  NSPasteboard * cb;
  NSString * cb_data;
  
  if (len == 0 | text == NULL) {
    return 1;
  }
  cb = [NSPasteboard generalPasteboard];
  [cb clearContents];
  cb_data = [NSString stringWithUTF8String:text];
  [cb setString:cb_data forType:NSPasteboardTypeString];
  
  return 1;
  
}

/**
 * onMenuEvent
 */
- (void)onMenuEvent:(id _Nonnull) sender {

  NSString * senderPath;
  BXNSGenericWindow * curWindow;
  gui_window_type_t curWindowType;
  int i;

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

  // special handling About
  if ([BXNSMenuBar getMenuItemProperty:senderPath] == BX_PROPERTY_BOCHS_ABOUT) {
    [BXNSWindowController showModalAboutDialog];
    return;
  }
  
  NSLog(@"Hit that menu %@", senderPath);
  // [self.bx_p_col setProperty:senderPath value:1];

  // propagate to windows first

  i=0;
  while (window_list[i].name != BX_GUI_WINDOW_UNDEFINED) {
    if ([((BXNSGenericWindow *)window_list[i].window) onMenuEvent:senderPath]) {
      NSLog(@"event consumed by window %@", window_list[i].window);
      return;
    }
    i++;
  }

  // no window need this property so set and signal
  [self.event_condition lock];
  [self.bx_p_col setProperty:senderPath value:1];
  self.event_lock = NO;
  [self.event_condition signal];
  [self.event_condition unlock];

}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSGenericWindow
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSGenericWindow

/**
 * initWithBXController
 */
- (instancetype _Nonnull)initWithBXController:(BXNSWindowController * _Nonnull) controller contentRect:(NSRect) rect styleMask:(NSWindowStyleMask) style backing:(NSBackingStoreType) backingStoreType defer:(BOOL) flag Custom:(UInt32) cust_val {

  self = [super initWithContentRect:rect styleMask:style backing:backingStoreType defer:flag];
  if (self) {

    self.bx_controller = controller;
    self.cust_val = cust_val;

  }

  return self;

}

/**
 * windowShouldClose
 */
- (BOOL)windowShouldClose:(NSWindow * _Nonnull)sender {
  [self.bx_controller showWindow:(gui_window_type_t)self.cust_val doShow:false];
  return NO;
}

/**
 * onMenuEvent
 */
- (BOOL)onMenuEvent:(NSString * _Nonnull) path {
  // to process Menu events by Window override
  // return TRUE to stop sending to other windows
  return FALSE;
}

/**
 * setEnabled
 */
- (void)setEnabled:(BOOL)enabled {

  // maybe need some new idea here

}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSBrowser
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSBrowser

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {

    self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.hasHorizontalScroller = YES;
    self.columnResizingType = NSBrowserAutoColumnResizing;
    self.pathSeparator = @".";
    self.allowsMultipleSelection = NO;
    self.maxVisibleColumns = 3;
    self.takesTitleFromPreviousColumn = YES;
    [self setCellClass:[BXNSBrowserCell class]];

    self.delegate = self;
    self.fix_root = nil;
    self.SIMavailable = NO;

  }

  return self;

}

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect Root:(void * _Nonnull) fix_root {

  self = [super initWithFrame:frameRect];
  if (self) {

    self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.hasHorizontalScroller = YES;
    self.columnResizingType = NSBrowserAutoColumnResizing;
    self.pathSeparator = @".";
    self.allowsMultipleSelection = NO;
    self.maxVisibleColumns = 3;
    self.takesTitleFromPreviousColumn = YES;
    [self setCellClass:[BXNSBrowserCell class]];

    self.delegate = self;
    self.fix_root = fix_root;
    self.SIMavailable = YES;

  }

  return self;

}

/**
 * browser numberOfChildrenOfItem
 */
- (NSInteger)browser:(NSBrowser * _Nonnull)browser numberOfChildrenOfItem:(id _Nullable)item {

  bx_param_c * param;

  if (item == nil) {
    NSInteger count;

    if (!self.SIMavailable) {
      return 0;
    }
      
    if (self.fix_root != nil) {
      return 1;
    }

    count = 0;
    while (root_options[count].param != NULL) {
      count++;
    }
    return count;
  }

  // may be device log
  if (strcmp([item path].UTF8String, "general.logdevice") == 0) {
    return SIM->get_n_log_modules();
  }
  // may be device log device
  if ([[item path] hasPrefix:@"general.logdevice."]) {
    return 4;
  }

  param = SIM->get_param([item path].UTF8String, NULL);

  if (param == NULL) {
    return 0;
  }
  if (param->get_type() == BXT_LIST) {
    return ((bx_list_c *) param)->get_size();
  }

  return 0;

}

/**
 * browser child
 */
- (id _Nonnull)browser:(NSBrowser * _Nonnull)browser child:(NSInteger)index ofItem:(id _Nullable)item {

  BXNSBrowserCell * cell;
  bx_param_c * param;
  BOOL leaf;

  if (item == nil) {
    // may be internal item
    if (self.fix_root != nil) {
      const char * label;
      char paramPath[512] = {0};

      param = (bx_param_c *)self.fix_root;
      param->get_param_path(paramPath, 512);
      label = ((bx_list_c *)param)->get_title();

      return [[BXNSBrowserCell alloc] initTextCell:label==NULL?@"-missing root label-":[NSString stringWithUTF8String:label]
        isLeaf:NO PredPath:@"" SimParamName:paramPath
      ];
    }
    // may be device log
    if (strcmp(root_options[index].param, "general.logdevice") == 0) {
      leaf = NO;
    } else {
      param = SIM->get_param(root_options[index].param, NULL);
      leaf =  param == NULL;
    }
    cell = [[BXNSBrowserCell alloc] initTextCell:root_options[index].title isLeaf:leaf PredPath:@"" SimParamName:root_options[index].param];
  } else {
    bx_param_c * child;

    param = SIM->get_param([item path].UTF8String, NULL);
    if (param == NULL) {
      // may be device log device
      if ([[item path] hasPrefix:@"general.logdevice."]) {
        const char * log_lvl[] = { "debug", "info", "error", "panic" };
        BXNSDeviceLogSelector * choice;

        choice = [[BXNSDeviceLogSelector alloc] initWithBrowser:browser DeviceNo:[item dev_no] Param:index];

        return [[BXNSBrowserCell alloc] initTextCell:[NSString stringWithUTF8String:log_lvl[index]].uppercaseString
          isLeaf:YES PredPath:[item path] SimParamName:log_lvl[index]
          Control:choice
        ];
      }
      // here we may have general.logdevice
      NSString * dev_name;
      NSString * acces_name;

      // create a nice name
      dev_name = [[[[NSString stringWithUTF8String:SIM->get_prefix(index)]
      stringByReplacingOccurrencesOfString:@"[" withString:@" "]
      stringByReplacingOccurrencesOfString:@"]" withString:@" "]
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
      leaf = NO;
      acces_name = dev_name;

      if (dev_name.length == 0) {
        dev_name = @"not available";
        acces_name = [NSString stringWithFormat:@"not_available_%d", (unsigned)index];
        leaf = YES;
      }

      return [[BXNSBrowserCell alloc] initTextCell:dev_name isLeaf:leaf PredPath:[item path] SimParamName:acces_name.UTF8String DeviceNo:index];
    }

    child = ((bx_list_c *)param)->get((int)index);

    if ([[item path] hasPrefix:@"general.logfn"]) {
      // special case global logging
      BXNSGlobalLogSelector * choice;
      unsigned level;
      NSString * s1;

      s1 = [NSString stringWithUTF8String:child->get_name()];
      for (level=0; level<SIM->get_max_log_level(); level++) {
        NSString * s2;

        s2 = [NSString stringWithUTF8String:SIM->get_log_level_name(level)];
        if ([s1 caseInsensitiveCompare:s2] == NSOrderedSame) {
          break;
        }
      }

      choice = [[BXNSGlobalLogSelector alloc] initWithBrowser:browser Param:level];
      return [[BXNSBrowserCell alloc] initTextCell:[NSString stringWithUTF8String:child->get_name()]
        isLeaf:YES PredPath:[item path] SimParamName:child->get_name()
        Control:choice
      ];
    }

    switch (child->get_type()) {

      case BXT_PARAM_NUM: {
        bx_param_num_c * num_param;
        const char * label;
        BXNSNumberSelector * numeric;

        num_param = (bx_param_num_c *)child;
        label = num_param->get_label();
        if (label == NULL) {
          label = num_param->get_description();
        }
        if ((label != NULL) && (strlen(label)==0)) {
          label = NULL;
        }

        numeric = [[BXNSNumberSelector alloc] initWithBrowser:browser Param:num_param];

        cell = [[BXNSBrowserCell alloc] initTextCell:label==NULL?@"-missing num label-":[NSString stringWithUTF8String:label]
          isLeaf:YES PredPath:[item path] SimParamName:num_param->get_name()
          Control:numeric
        ];
        break;
      }
      case BXT_PARAM_BOOL: {
        bx_param_bool_c * bool_param;
        const char * label;
        BXNSYesNoSelector * yesno;

        bool_param = (bx_param_bool_c *)child;
        label = bool_param->get_label();
        // special handling plugins (only name is set)
        if ((label != NULL) && (strlen(label)==0)) {
          label = bool_param->get_name();
        }
        if (label == NULL) {
          label = bool_param->get_description();
        }
        if ((label != NULL) && (strlen(label)==0)) {
          label = NULL;
        }

        yesno = [[BXNSYesNoSelector alloc] initWithBrowser:browser Param:bool_param];
        cell = [[BXNSBrowserCell alloc] initTextCell:label==NULL?@"-missing bool label-":[NSString stringWithUTF8String:label]
          isLeaf:YES PredPath:[item path] SimParamName:bool_param->get_name()
          Control:yesno
        ];
        break;
      }
      case BXT_PARAM_ENUM: {
        bx_param_enum_c * enum_param;
        const char * label;
        BXNSChoiceSelector * choice;

        enum_param = (bx_param_enum_c *)child;
        label = enum_param->get_label();
        if (label == NULL) {
          label = enum_param->get_description();
        }
        if ((label != NULL) && (strlen(label)==0)) {
          label = NULL;
        }

        choice = [[BXNSChoiceSelector alloc] initWithBrowser:browser Param:enum_param];

        cell = [[BXNSBrowserCell alloc] initTextCell:label==NULL?@"-missing enum label-":[NSString stringWithUTF8String:label]
          isLeaf:YES PredPath:[item path] SimParamName:enum_param->get_name()
          Control:choice
        ];
        break;
      }
      case BXT_PARAM_STRING: {
        bx_param_string_c * string_param;
        const char * label;
        BXNSStringSelector * string;

        string_param = (bx_param_string_c *)child;
        label = string_param->get_label();
        if (label == NULL) {
          label = string_param->get_description();
        }
        if ((label != NULL) && (strlen(label)==0)) {
          label = NULL;
        }

        string = [[BXNSStringSelector alloc] initWithBrowser:browser Param:string_param];

        cell = [[BXNSBrowserCell alloc] initTextCell:label==NULL?@"-missing string label-":[NSString stringWithUTF8String:label]
          isLeaf:YES PredPath:[item path] SimParamName:string_param->get_name()
          Control:string
        ];
        break;
      }
      // case BXT_PARAM_BYTESTRING: {
      //   bx_param_bytestring_c * bytestring_param;
      //
      //   bytestring_param = (bx_param_bytestring_c *)child;
      //
      //   cell = [[BXNSBrowserCell alloc] initTextCell:@">>>BYTE STRING<<<" isLeaf:YES PredPath:[item path] SimParamName:param->get_name()];
      //   break;
      // }
      // case BXT_PARAM_FILEDATA: {
      //   bx_param_filename_c * filename_param;
      //
      //   filename_param = (bx_param_filename_c *)child;
      //
      //   cell = [[BXNSBrowserCell alloc] initTextCell:@">>>FILENAME<<<" isLeaf:YES PredPath:[item path] SimParamName:param->get_name()];
      //   break;
      // }
      case BXT_LIST: {
        bx_list_c * list_param;
        const char * label;
        list_param = (bx_list_c *)child;

        label = list_param->get_title();
        if (label == NULL) {
          label = list_param->get_label();
        }
        // special handling logfunctions (only name is set)
        if ((label != NULL) && (strlen(label)==0)) {
          label = list_param->get_name();
        }
        if (label == NULL) {
          label = list_param->get_name();
        }
        if ((label != NULL) && (strlen(label)==0)) {
          label = NULL;
        }

        cell = [[BXNSBrowserCell alloc]
          initTextCell:label==NULL?@"-missing list label-":[NSString stringWithUTF8String:label]
          isLeaf:NO PredPath:[item path] SimParamName:list_param->get_name()
        ];
        break;
      }
      default: {
        cell = [[BXNSBrowserCell alloc] initTextCell:@"NOT IMPLEMENTED" isLeaf:YES PredPath:[item path] SimParamName:param->get_name()];
        break;
      }

    }

  }

  return cell;

}

/**
 * browser isLeafItem
 */
- (BOOL)browser:(NSBrowser * _Nonnull)browser isLeafItem:(id _Nullable)item {

  if (item != nil) {
    return [item isLeaf];
  }

  return YES;

}

/**
 * browser objectValueForItem
 */
- (id _Nonnull)browser:(NSBrowser * _Nonnull)browser objectValueForItem:(id _Nullable)item {

  return item;

}

/**
 * browser previewViewControllerForLeafItem
 */
- (NSViewController * _Nullable)browser:(NSBrowser * _Nonnull)browser previewViewControllerForLeafItem:(id _Nullable)item {

  if (item == nil) {
    return nil;
  }
  if ([item sub_control] == nil) {
    return nil;
  }

  return [[BXNSPreviewController alloc] initWithView:[self frameOfInsideOfColumn:self.lastVisibleColumn] Control:[item sub_control]];

}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSAboutWindow
////////////////////////////////////////////////////////////////////////////////
extern unsigned char bochs_logo [128 * 128 * 4 + 1];
@implementation BXNSAboutWindow

- (instancetype _Nonnull)init {

  self = [super initWithContentRect:NSMakeRect(0, 0, 640, 480)
    styleMask: NSWindowStyleMaskTitled
      backing: NSBackingStoreBuffered
        defer: NO
  ];
  if (self) {

    NSStackView * inner;
    NSStackView * buttons;
    NSButton * OK_BUTTON;
    CFDataRef bochs_image_data;
    NSImage * bochs_image;
    NSImageView * bochs_imageview;
    CGColorSpaceRef colorspace;
    CGDataProviderRef provider;
    CGImageRef rgbImageRef;

    [self setLevel:NSPopUpMenuWindowLevel];
    [self setTitle:BOCHS_WINDOW_NAME];
    self.contentView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self.contentView setWantsLayer: YES];
    self.contentView.layer.backgroundColor = [[NSColor blackColor] CGColor];

    inner = [[NSStackView alloc] initWithFrame:NSMakeRect(0, 0, 640, 480)];
    inner.orientation = NSUserInterfaceLayoutOrientationVertical;
    [self.contentView addSubview:inner];

    // add control on top
    [inner addArrangedSubview:[NSTextField labelWithString:@""]];
    [inner addArrangedSubview:[NSTextField labelWithString:BOCHS_WINDOW_NAME]];
    [inner addArrangedSubview:[NSTextField labelWithString:@""]];
    
    bochs_image_data = CFDataCreateWithBytesNoCopy(NULL, (const UInt8 *)bochs_logo, (128 * 128 * 4), kCFAllocatorNull);
    colorspace = CGColorSpaceCreateDeviceRGB();
    provider = CGDataProviderCreateWithCFData(bochs_image_data);
    rgbImageRef = CGImageCreate(128, 128, 8, 32, 128*4, colorspace, kCGImageAlphaNoneSkipLast, provider, NULL, false, kCGRenderingIntentDefault);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorspace);
    bochs_image =  [[NSImage alloc] initWithCGImage:rgbImageRef size:NSZeroSize];
    CGImageRelease(rgbImageRef);
    CFRelease(bochs_image_data);
    bochs_imageview = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 130, 130)];
    bochs_imageview.image = bochs_image;
    [inner addArrangedSubview:bochs_imageview];
    
    [inner addArrangedSubview:[NSTextField labelWithString:@""]];
    [inner addArrangedSubview:[NSTextField labelWithString:@"Bochs was originally written by Kevin Lawton"]];
    [inner addArrangedSubview:[NSTextField labelWithString:@""]];
    [inner addArrangedSubview:[NSTextField labelWithString:@"MacOS X GUI written by Christoph Gembalski"]];
    [inner addArrangedSubview:[NSTextField labelWithString:@"MacOS X DEBUGGER GUI written by Christoph Gembalski"]];
    [inner addArrangedSubview:[NSTextField labelWithString:@""]];

    buttons = [[NSStackView alloc] initWithFrame:NSMakeRect(0, 0, 640, 50)];
    [inner addArrangedSubview:buttons];

    OK_BUTTON = [NSButton buttonWithTitle:@"OK" target:self action:@selector(onOKClick:)];

    [buttons addArrangedSubview:OK_BUTTON];

  }

  return self;

}

- (void)onOKClick:(id _Nonnull)sender {
  [self setIsVisible:NO];
  [NSApp stopModalWithCode:NSModalResponseOK];
}

- (BOOL) getWorksWhenModal {
  return YES;
}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSParamRequestWindow
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSParamRequestWindow

- (instancetype _Nonnull)init:(void * _Nonnull) param {

  self = [super initWithContentRect:NSMakeRect(0, 0, 640, 480)
    styleMask: NSWindowStyleMaskTitled |
               NSWindowStyleMaskClosable |
               NSWindowStyleMaskMiniaturizable |
               NSWindowStyleMaskResizable
      backing: NSBackingStoreBuffered
        defer: NO
  ];
  if (self) {

    NSStackView * inner;
    NSStackView * buttons;
    NSButton * OK_BUTTON;
    NSButton * CANCEL_BUTTON;
    BXNSBrowser * browser;
    bx_param_c * cparam;
    

    [self setLevel:NSPopUpMenuWindowLevel];
    [self setTitle:BOCHS_WINDOW_CONFIG_NAME];
    self.contentView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

    inner = [[NSStackView alloc] initWithFrame:NSMakeRect(0, 0, 640, 480)];
    inner.orientation = NSUserInterfaceLayoutOrientationVertical;
    [self.contentView addSubview:inner];

    // add control on top
    cparam = (bx_param_c *)param;
    if (cparam->get_type() == BXT_PARAM_STRING) {
      bx_param_string_c * string_param;
      
      string_param = (bx_param_string_c *)cparam;
      [inner addArrangedSubview:[NSTextField labelWithString:[NSString stringWithUTF8String:string_param->get_label()]]];
      [inner addArrangedSubview:[[BXNSStringSelector alloc] initWithFrame:NSMakeRect(0, 0, 640, 400) Param:string_param]];
    } else {
      browser = [[BXNSBrowser alloc] initWithFrame:NSMakeRect(0, 0, 640, 400) Root:param];
      [inner addArrangedSubview:browser];
    }

    buttons = [[NSStackView alloc] initWithFrame:NSMakeRect(0, 0, 640, 50)];
    [inner addArrangedSubview:buttons];

    OK_BUTTON = [NSButton buttonWithTitle:@"OK" target:self action:@selector(onOKClick:)];
    CANCEL_BUTTON = [NSButton buttonWithTitle:@"Cancel" target:self action:@selector(onCancelClick:)];

    [buttons addArrangedSubview:OK_BUTTON];
    [buttons addArrangedSubview:CANCEL_BUTTON];

  }

  return self;

}

/**
 * onOKClick
 */
- (void)onOKClick:(id _Nonnull)sender {
  [self setIsVisible:NO];
  [NSApp stopModalWithCode:NSModalResponseOK];
}

/**
 * onCancelClick
 */
- (void)onCancelClick:(id _Nonnull)sender {
  [self setIsVisible:NO];
  [NSApp stopModalWithCode:NSModalResponseCancel];
}

/**
 * getWorksWhenModal
 */
- (BOOL) getWorksWhenModal {
  return YES;
}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSConfigurationWindow
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSConfigurationWindow

/**
 * init
 */
- (instancetype _Nonnull)init:(BXNSWindowController * _Nonnull) controller; {

  self = [super initWithBXController:controller
       contentRect: NSMakeRect(0, 0, 1024, 768)
         styleMask: NSWindowStyleMaskTitled |
                    NSWindowStyleMaskClosable |
                    NSWindowStyleMaskMiniaturizable |
                    NSWindowStyleMaskResizable
           backing: NSBackingStoreBuffered
             defer: NO
            Custom: BX_GUI_WINDOW_CONFIGURATION
  ];

  if (self) {

    [self setTitle:BOCHS_WINDOW_CONFIG_NAME];
    self.contentView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

    self.config = [[BXNSBrowser alloc] initWithFrame:NSMakeRect(0, 0, 1024, 768)];

    [self.contentView addSubview:self.config];

    [NSApp setDelegate:self];
    [NSApp setDelegate:[self contentView]];

  }

  return self;
}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSSimulationWindow
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSSimulationWindow

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
            Custom: BX_GUI_WINDOW_VGA_DISPLAY
  ];

  if (self) {

    [self setTitle:BOCHS_WINDOW_NAME];

    [self setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
    self.contentView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    self.BXEventQueue = [[BXNSEventQueue alloc] init];

    self.MouseCaptureAbsolute = NO;
    self.MouseCaptureActive = NO;

    // Setup VGA display
    self.BXVGA = [[BXVGAdisplay alloc] init:8 width:vga_xres height:vga_yres font_width:0 font_height:0 view:[self contentView]];
    
    // setup Toolbar bochs
    self.BXToolbar = [[BXNSHeaderBar alloc] init:headerbar_y width:vga_xres yofs:vga_yres];

#if BX_SHOW_IPS
    // setup Toolbar ips
    self.toolbar = [[BXNSToolbar alloc] init];
    self.toolbarStyle = NSWindowToolbarStyleUnified;
#endif /* BX_SHOW_IPS */
    
    [self setAcceptsMouseMovedEvents:YES];
    [self setDelegate:self];
    self.contentAspectRatio = NSMakeSize(1.0,1.0);
    self.inFullscreen = NO;
    
  }

  return self;

}

/**
 * getter hasEvent
 */
- (BOOL)hasEvent {
  
  return !self.BXEventQueue.isEmpty;
  
}

/**
 * return the Event
 * if none exists return 0
 */
- (UInt64)getEvent {
  
  return [self.BXEventQueue dequeue];
  
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

  [self.BXEventQueue enqueue:((unsigned long)event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask) | event.keyCode | (((unsigned long)event.modifierFlags & ~NSEventModifierFlagDeviceIndependentFlagsMask) << 32) ];
  
}

/**
 * keyUp
 */
- (void)keyUp:(NSEvent * _Nonnull)event {

  [self.BXEventQueue enqueue:MACOS_NSEventModifierFlagKeyUp | ((unsigned long)event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask) | event.keyCode | (((unsigned long)event.modifierFlags & ~NSEventModifierFlagDeviceIndependentFlagsMask) << 32) ];

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
  
  [self.BXEventQueue enqueue:evt];

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

#if BX_SHOW_IPS
/**
 * updateIPS
 */
- (void)updateIPS:(unsigned) val {
  
  [((BXNSToolbar *)self.toolbar) updateIPS:val];
  
}
#endif /* BX_SHOW_IPS */

/**
 * toggleFullscreen
 */
- (void)toggleFullscreen:(BOOL) enable {
  
  if (enable & self.inFullscreen) {
    return;
  }
  if (!enable & !self.inFullscreen) {
    return;
  }
  [self toggleFullScreen:self];
    
}

/**
 * backupWindowState
 */
- (void)backupWindowState {
  
  self.restoreSize = self.frame;
  self.BXVGA.imgview.restoreSize = self.BXVGA.imgview.frame;
  
}

/**
 * restoreWindowState
 */
- (void)restoreWindowState {
  
  self.BXVGA.imgview.frame = self.BXVGA.imgview.restoreSize;
  [self setFrame:self.restoreSize display:YES];
  
}

/**
 * resizeByRatio
 */
- (void)resizeByRatio {
  
  CGFloat ratio;
  NSRect rect;
  
  ratio = MIN(self.screen.frame.size.width / self.BXVGA.width, self.screen.frame.size.height / self.BXVGA.height);
  rect = NSMakeRect(0, 0, ratio * self.BXVGA.width, ratio * self.BXVGA.height);
  self.BXVGA.imgview.frame = rect;
  [self setFrame:rect display:YES];
  
}

/**
 * windowWillEnterFullScreen
 */
- (void)windowWillEnterFullScreen:(NSNotification * _Nullable)notification {
  
  // hide other windows
  [self.bx_controller showWindow:BX_GUI_WINDOW_CONFIGURATION doShow:NO];
  [self.bx_controller showWindow:BX_GUI_WINDOW_LOGGING doShow:NO];
#if BX_DEBUGGER && BX_NEW_DEBUGGER_GUI
  [self.bx_controller showWindow:BX_GUI_WINDOW_DEBUGGER doShow:NO];
#endif /* BX_DEBUGGER && BX_NEW_DEBUGGER_GUI */
  
#if BX_SHOW_IPS
  [self toggleToolbarShown:self];
#endif /* BX_SHOW_IPS */

  [self backupWindowState];
  [self resizeByRatio];
  
  [self.BXToolbar.button_view setHidden:YES];
  // kVK_F19 -> 0x50
  [self.BXEventQueue enqueue:(MACOS_NSEventModifierFlagSpecial | 0x50 | (1l << 32))];
  
  self.inFullscreen = YES;
  
}

/**
 * windowWillExitFullScreen
 */
- (void)windowWillExitFullScreen:(NSNotification * _Nullable)notification {
  
  NSPoint wnd_location;
  
  [self.BXToolbar.button_view setHidden:NO];

  [self restoreWindowState];
  wnd_location = NSMakePoint(self.restoreSize.origin.x, self.restoreSize.origin.y);
  
#if BX_SHOW_IPS
  dispatch_async(dispatch_get_main_queue(), ^(void){
    [self toggleToolbarShown:self];
    [self setFrameOrigin:wnd_location];
  });
#endif /* BX_SHOW_IPS */

  // kVK_F19 -> 0x50
  [self.BXEventQueue enqueue:(MACOS_NSEventModifierFlagSpecial | 0x50 )];
  
  self.inFullscreen = NO;
  
}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSLoggingWindow
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSLoggingWindow

/**
 * init
 */
- (instancetype _Nonnull)init:(BXNSWindowController * _Nonnull) controller LogQueue:(BXNSLogQueue * _Nonnull) queue {

  self = [super initWithBXController:controller
       contentRect: NSMakeRect(0, 0, 440, 400)
         styleMask: NSWindowStyleMaskTitled |
                    NSWindowStyleMaskClosable |
                    NSWindowStyleMaskMiniaturizable |
                    NSWindowStyleMaskResizable
           backing: NSBackingStoreBuffered
             defer: NO
            Custom: BX_GUI_WINDOW_LOGGING
  ];
  if (self) {

    NSBox * optionsBox;
    NSButton * panicOption;
    NSButton * errorOption;
    NSButton * infoOption;
    NSButton * debugOption;
    NSButton * scrollOption;
    NSBox * messagesBox;
    NSScrollView * messagesScrollView;
    
    self.queue = queue;

    [self setTitle:BOCHS_WINDOW_LOGGER_NAME];

    self.loglevelMask = 0b10001111;

    self.contentView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

    optionsBox = [[NSBox alloc] init];
    [optionsBox setFrameFromContentFrame:NSMakeRect(20,350,400,20)];
    optionsBox.title = @"Logging Level";
    optionsBox.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;

    panicOption = [NSButton checkboxWithTitle:@"Panic" target:self action:@selector(onCheckboxClick:)];
    panicOption.frame = NSMakeRect(0, 0, 80, 20);
    panicOption.state = NSControlStateValueOn;
    [optionsBox addSubview:panicOption];
    errorOption = [NSButton checkboxWithTitle:@"Error" target:self action:@selector(onCheckboxClick:)];
    errorOption.frame = NSMakeRect(80, 0, 80, 20);
    errorOption.state = NSControlStateValueOn;
    [optionsBox addSubview:errorOption];
    infoOption = [NSButton checkboxWithTitle:@"Info" target:self action:@selector(onCheckboxClick:)];
    infoOption.frame = NSMakeRect(160, 0, 80, 20);
    infoOption.state = NSControlStateValueOn;
    [optionsBox addSubview:infoOption];
    debugOption = [NSButton checkboxWithTitle:@"Debug" target:self action:@selector(onCheckboxClick:)];
    debugOption.frame = NSMakeRect(240, 0, 80, 20);
    debugOption.state = NSControlStateValueOn;
    [optionsBox addSubview:debugOption];
    scrollOption = [NSButton checkboxWithTitle:@"Scroll" target:self action:@selector(onCheckboxClick:)];
    scrollOption.frame = NSMakeRect(320, 0, 80, 20);
    scrollOption.state = NSControlStateValueOn;
    [optionsBox addSubview:scrollOption];

    messagesBox = [[NSBox alloc] init];
    [messagesBox setFrameFromContentFrame:NSMakeRect(20,20,400,290)];
    messagesBox.title = @"Logging Messages";
    messagesBox.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin | NSViewHeightSizable;

    messagesScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(10, 10, 380, 270)];
    messagesScrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [messagesScrollView setBorderType:NSNoBorder];
    [messagesScrollView setHasVerticalScroller:YES];

    self.messagesText = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 380, 270)];
    self.messagesText.autoresizingMask = NSViewWidthSizable;
    [self.messagesText setMinSize:NSMakeSize(0, 270)];
    [self.messagesText setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [self.messagesText setVerticallyResizable:YES];
    [self.messagesText setHorizontallyResizable:NO];
    [self.messagesText setTextColor:NSColor.textColor];
    [[self.messagesText textContainer] setContainerSize:NSMakeSize(380, FLT_MAX)];
    [[self.messagesText textContainer] setWidthTracksTextView:YES];
    [[self.messagesText textContainer] setHeightTracksTextView:NO];
    [self.messagesText setEditable:NO];

    self.attributesText = @{
      NSForegroundColorAttributeName:NSColor.textColor,
      NSFontAttributeName:[NSFont monospacedSystemFontOfSize:12 weight:NSFontWeightRegular]
    };

    [messagesScrollView setDocumentView:self.messagesText];
    [messagesBox addSubview:messagesScrollView];

    [self.contentView addSubview:optionsBox];
    [self.contentView addSubview:messagesBox];

    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(refreshFromQueue) userInfo:nil repeats:YES];

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
    UInt8 mask;

    entry = [self.queue dequeue];

    mask = 1 << entry.level;
    
    if ((self.loglevelMask & mask) != 0) {
      fmsg = [NSString stringWithFormat:@"%@ (%d)[%@] %@", entry.timecode, entry.level, entry.module, entry.msg];
      msg = [[NSAttributedString alloc] initWithString:fmsg attributes:self.attributesText];
      [[self.messagesText textStorage] appendAttributedString:msg];
    }
    
  }

  if ((self.loglevelMask & 0b10000000) != 0) {
    [self.messagesText scrollRangeToVisible:NSMakeRange([[self.messagesText string] length], 0)];
  }
  
}

- (void)onCheckboxClick:(id _Nonnull) sender {
  
  UInt8 mask;
  UInt8 value;
  
  value = 0;
  mask = 0;
  if ([[sender title] compare:@"Panic"] == NSOrderedSame) {
    mask = 0b00001000;
    if ([sender state] == NSControlStateValueOn) {
      value = 0b00001000;
    }
  } else if ([[sender title] compare:@"Error"] == NSOrderedSame) {
    mask = 0b00000100;
    if ([sender state] == NSControlStateValueOn) {
      value = 0b00000100;
    }
  } else if ([[sender title] compare:@"Info"] == NSOrderedSame) {
    mask = 0b00000010;
    if ([sender state] == NSControlStateValueOn) {
      value = 0b00000010;
    }
  } else if ([[sender title] compare:@"Debug"] == NSOrderedSame) {
    mask = 0b00000001;
    if ([sender state] == NSControlStateValueOn) {
      value = 0b00000001;
    }
  } else if ([[sender title] compare:@"Scroll"] == NSOrderedSame) {
    mask = 0b10000000;
    if ([sender state] == NSControlStateValueOn) {
      value = 0b10000000;
    }
  }
  self.loglevelMask = (self.loglevelMask & ~mask) | value;
  
}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSDebuggerWindow
////////////////////////////////////////////////////////////////////////////////
#if BX_DEBUGGER && BX_NEW_DEBUGGER_GUI

@implementation BXNSVerticalSplitView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {

    self.arrangesAllSubviews = YES;
    self.dividerStyle = NSSplitViewDividerStylePaneSplitter;

  }

  return self;

}

@end


@implementation BXNSHorizontalSplitView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {

    self.vertical = YES;
    self.arrangesAllSubviews = YES;
    self.dividerStyle = NSSplitViewDividerStylePaneSplitter;

  }

  return self;

}

@end


@implementation BXNSTabView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {



  }

  return self;

}

@end


@implementation BXNSMemoryView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {



  }

  return self;

}

@end


@implementation BXNSGDTView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {



  }

  return self;

}

@end


@implementation BXNSIDTView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {



  }

  return self;

}

@end


@implementation BXNSLDTView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {



  }

  return self;

}

@end


@implementation BXNSPagingView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {



  }

  return self;

}

@end


@implementation BXNStackView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {



  }

  return self;

}

@end


@implementation BXNSInstructionView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {



  }

  return self;

}

@end


@implementation BXNSBreakpointView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {



  }

  return self;

}

@end


@implementation BXNSRegisterView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {



  }

  return self;

}

@end


@implementation BXNSOutputView

NSScrollView * outputScrollView;
NSTextView * outputText;
NSDictionary * outputAttributesText;

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {

    self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

    outputScrollView = [[NSScrollView alloc] initWithFrame:frameRect];
    outputScrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    // [outputScrollView setBorderType:NSNoBorder];
    [outputScrollView setHasVerticalScroller:YES];

    outputText = [[NSTextView alloc] initWithFrame:frameRect];
    outputText.autoresizingMask = NSViewWidthSizable;
    [outputText setMinSize:frameRect.size];
    [outputText setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [outputText setVerticallyResizable:YES];
    [outputText setHorizontallyResizable:NO];
    [outputText setTextColor:NSColor.textColor];
    [outputText setEditable:NO];
    [[outputText textContainer] setContainerSize:NSMakeSize(frameRect.size.width, FLT_MAX)];
    [[outputText textContainer] setWidthTracksTextView:YES];
    [[outputText textContainer] setHeightTracksTextView:NO];

    outputAttributesText = @{NSForegroundColorAttributeName:NSColor.textColor,
    NSFontAttributeName:[NSFont monospacedSystemFontOfSize:12 weight:NSFontWeightRegular]};

    [outputScrollView setDocumentView:outputText];
    [self addSubview:outputScrollView];

  }

  return self;

}

/**
 * appendText
 */
- (void)appendText:(NSString * _Nonnull) msg {

  NSAttributedString * amsg;

  amsg = [[NSAttributedString alloc] initWithString:msg attributes:outputAttributesText];

  [[outputText textStorage] appendAttributedString:amsg];
  [outputText scrollRangeToVisible:NSMakeRange([[outputText string] length], 0)];

}

@end


@implementation BXNSDebuggerWindow

BXNSVerticalSplitView * verticalSplitView;
BXNSHorizontalSplitView * horizontalSplitViewTop;
BXNSHorizontalSplitView * horizontalSplitViewBottom;
BXNSTabView * tabViewTopLeft;
BXNSTabView * tabViewTopRight;
BXNSTabView * tabViewBottom;

BXNSMemoryView * memoryView;
BXNSGDTView * gdtView;
BXNSIDTView * idtView;
BXNSLDTView * ldtView;
BXNSPagingView * pagingView;
BXNStackView * stackView;
BXNSInstructionView * instructionView;
BXNSBreakpointView * breakpointView;
BXNSRegisterView * registerView;



/**
 * init
 */
- (instancetype _Nonnull)init:(BXNSWindowController * _Nonnull) controller {

  self = [super initWithBXController:controller
       contentRect: NSMakeRect(0, 0, 1024, 768)
         styleMask: NSWindowStyleMaskTitled |
                    NSWindowStyleMaskClosable |
                    NSWindowStyleMaskMiniaturizable |
                    NSWindowStyleMaskResizable
           backing: NSBackingStoreBuffered
             defer: NO
            Custom: BX_GUI_WINDOW_DEBUGGER
  ];

  if (self) {

    [self setTitle:BOCHS_WINDOW_DEBUGGER_NAME];

    self.contentView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

    verticalSplitView = [[BXNSVerticalSplitView alloc] initWithFrame:NSMakeRect(0, 0, 1024, 768)];
    verticalSplitView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self.contentView addSubview:verticalSplitView];

    horizontalSplitViewTop = [[BXNSHorizontalSplitView alloc] initWithFrame:NSMakeRect(0, 0, 1024, 640)];
    horizontalSplitViewBottom = [[BXNSHorizontalSplitView alloc] initWithFrame:NSMakeRect(0, 0, 1024, 128)];
    [verticalSplitView addSubview:horizontalSplitViewTop];
    [verticalSplitView addSubview:horizontalSplitViewBottom];

    tabViewTopLeft = [[BXNSTabView alloc] initWithFrame:NSMakeRect(0, 0, 512, 640)];
    tabViewTopRight = [[BXNSTabView alloc] initWithFrame:NSMakeRect(0, 0, 512, 640)];
    [horizontalSplitViewTop addSubview:tabViewTopLeft];
    [horizontalSplitViewTop addSubview:tabViewTopRight];
    tabViewBottom = [[BXNSTabView alloc] initWithFrame:NSMakeRect(0, 0, 1024, 128)];
    [horizontalSplitViewBottom addSubview:tabViewBottom];

    registerView = [[BXNSRegisterView alloc] initWithFrame:NSMakeRect(0, 0, 640, 480)];
    NSTabViewItem * registerViewItem = [[NSTabViewItem alloc] init];
    registerViewItem.label = @"Register";
    registerViewItem.view = registerView;
    [tabViewTopLeft addTabViewItem:registerViewItem];

    memoryView = [[BXNSMemoryView alloc] initWithFrame:NSMakeRect(0, 0, 640, 480)];
    NSTabViewItem * memoryViewItem = [[NSTabViewItem alloc] init];
    memoryViewItem.label = @"Memory";
    memoryViewItem.view = memoryView;
    [tabViewTopLeft addTabViewItem:memoryViewItem];



    instructionView = [[BXNSInstructionView alloc] initWithFrame:NSMakeRect(0, 0, 640, 480)];
    NSTabViewItem * instructionViewItem = [[NSTabViewItem alloc] init];
    instructionViewItem.label = @"Instruction";
    instructionViewItem.view = instructionView;
    [tabViewTopRight addTabViewItem:instructionViewItem];

    breakpointView = [[BXNSBreakpointView alloc] initWithFrame:NSMakeRect(0, 0, 640, 480)];
    NSTabViewItem * breakpointViewItem = [[NSTabViewItem alloc] init];
    breakpointViewItem.label = @"Breakpoint";
    breakpointViewItem.view = breakpointView;
    [tabViewTopRight addTabViewItem:breakpointViewItem];



    self.outputView = [[BXNSOutputView alloc] initWithFrame:NSMakeRect(0, 0, 1024, 128)];
    NSTabViewItem * outputViewItem = [[NSTabViewItem alloc] init];
    outputViewItem.label = @"Output";
    outputViewItem.view = self.outputView;
    [tabViewBottom addTabViewItem:outputViewItem];

  }

  return self;

}
// extern void ActivateMenuItem (int LW);
/**
 * onMenuEvent
 */
- (BOOL)onMenuEvent:(NSString * _Nonnull) path {

  property_t p;

  p = [BXNSMenuBar getMenuItemProperty:path];
  if (p == BX_PROPERTY_UNDEFINED) {
    return NO;
  }
NSLog(@"onMenuEvent path=%@ property=%d", path, p);
  switch (p) {
    case BX_PROPERTY_BREAK_SIM: {
      //ActivateMenuItem(CMD_CONT);
      return YES;
    }
    default:
      break;
  }

  return NO;

}




@end

#endif /* BX_DEBUGGER && BX_NEW_DEBUGGER_GUI */
