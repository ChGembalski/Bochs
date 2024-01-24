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
#include "cocoa_menu.h"


menu_opts_t menu_options[] = {
  {NULL,                    "Bochs",          YES,  nil,  nil},
  {"Bochs",                 "Configuration",  YES,  nil,  nil},
  {"Bochs.Configuration",   "Load",           NO,   nil,  nil},
  {"Bochs.Configuration",   "Save",           NO,   nil,  nil},
  {"Bochs.Configuration",   "Reset",          NO,   nil,  nil},
  {"Bochs",                 "About",          NO,   nil,  nil},
  {"Bochs",                 "-",              NO,   nil,  nil},
  {"Bochs",                 "Quit",           NO,   @"q", @selector(terminate:)},
  {NULL,                    "Simulation",     YES,  nil,  nil},
  {"Simulation",            "Start",          NO,   nil,  nil},
  {"Simulation",            "Stop",           NO,   nil,  nil},
  {"Simulation",            "-",              NO,   nil,  nil},
  {"Simulation",            "Clipboard",      YES,  nil,  nil},
  {"Simulation.Clipboard",  "Copy",           NO,   nil,  nil},
  {"Simulation.Clipboard",  "Paste",          NO,   nil,  nil},
  {NULL,                    "Debugger",       YES,  nil,  nil},
  {NULL,                    "Window",         YES,  nil,  nil},
  {"Window",                "Configuration",  NO,   nil,  nil},
  {"Window",                "VGA Display",    NO,   nil,  nil},
  {"Window",                "Logger",         NO,   nil,  nil},
  {"Window",                "Debugger",       NO,   nil,  nil},
  {NULL,                    "Help",           YES,  nil,  nil},
  {NULL,                    NULL,             NO,   nil,  nil}
};




@implementation BXNSMenuBar


/**
 * init
 */
- (instancetype _Nonnull)init {

  self = [super init];
  if (self) {

    int i;

    i = 0;

    // create App menu bar
    NSApp.mainMenu = [NSMenu alloc];
    while ((menu_options[i].parent != NULL) | (menu_options[i].name != NULL)) {
      [BXNSMenuBar createMenu:&menu_options[i]];
      i++;
    }

  }
  return self;

}

/**
 * createMenu
 */
+ (void)createMenu:(menu_opts_t * _Nonnull) opt {

  NSMenu * parent;
  NSString * title;

  // find menu parent
  if (opt->parent == NULL) {
    parent = NSApp.mainMenu;
  } else {
    parent = [BXNSMenuBar findMenu:[NSString stringWithUTF8String:opt->parent] startAt:nil];
  }

  if (opt->childs) {
    NSMenuItem * newMenuItem;

    title = [NSString stringWithUTF8String:opt->name];
    newMenuItem = [NSMenuItem alloc];
    if (opt->parent != NULL) {
      newMenuItem.title = title;
    }
    [newMenuItem setSubmenu:[[NSMenu alloc] initWithTitle:title]];
    [parent addItem:newMenuItem];
  } else {
    title = [NSString stringWithUTF8String:opt->name];
    if ([title isEqualToString:@"-"]) {
      [parent addItem:[NSMenuItem separatorItem]];
    } else {
      [parent addItemWithTitle:title action:opt->action keyEquivalent:opt->key==nil?@"":opt->key];
    }
  }

}

/**
 * findMenu
 */
+ (NSMenu * _Nullable)findMenu:(NSString * _Nonnull) title startAt:(NSMenu * _Nullable) start; {

  NSMenu * findAt;

  findAt = start == nil ? NSApp.mainMenu : start;

  // maybe need divide
  if ([title containsString:@"."]) {
    NSArray<NSString *> * parts;
    NSMenu * resolved;

    parts = [title componentsSeparatedByString:@"."];
    resolved = nil;

    for (id seekTitle in parts) {
      resolved = [BXNSMenuBar findMenu:seekTitle startAt:resolved];
      if (resolved == nil) {
        break;
      }
    }
    return resolved;
  }

  for (id oldMenuItem in findAt.itemArray) {
    if ([title isEqualToString:((NSMenuItem *)oldMenuItem).submenu.title]) {
      return ((NSMenuItem *)oldMenuItem).submenu;
    }
  }

  return (NULL);

}

+ (NSMenuItem * _Nullable)findMenuItem:(NSString * _Nonnull) title startAt:(NSMenu * _Nullable) start {

  NSMenu * findAt;

  findAt = start == nil ? NSApp.mainMenu : start;

  // maybe need divide
  if ([title containsString:@"."]) {
    NSArray<NSString *> * parts;
    NSMenuItem * resolved;

    parts = [title componentsSeparatedByString:@"."];
    resolved = nil;

    for (id seekTitle in parts) {
      resolved = [BXNSMenuBar findMenuItem:seekTitle startAt:resolved.submenu];
      if (resolved == nil) {
        break;
      }
    }
    return resolved;
  }

  for (id oldMenuItem in findAt.itemArray) {
    if ([title isEqualToString:((NSMenuItem *)oldMenuItem).submenu.title]) {
      return ((NSMenuItem *)oldMenuItem);
    }
  }

  return (NULL);

}

/**
 * showMenu
 */
+ (void)showMenu:(NSString * _Nonnull) title doShow:(BOOL) show {

  NSMenuItem * menu;

  menu = [BXNSMenuBar findMenuItem:title startAt:nil];
  if (menu != nil) {
    [menu setHidden:!show];
  }

}






@end
