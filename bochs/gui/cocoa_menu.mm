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
  {NULL,                    "Bochs",          YES,  nil,  0,                          YES,  BX_PROPERTY_UNDEFINED},
  {"Bochs",                 "Configuration",  YES,  nil,  0,                          YES,  BX_PROPERTY_UNDEFINED},
  {"Bochs.Configuration",   "Load",           NO,   nil,  0,                          YES,  BX_PROPERTY_UNDEFINED},
  {"Bochs.Configuration",   "Save",           NO,   nil,  0,                          NO,   BX_PROPERTY_UNDEFINED},
  {"Bochs.Configuration",   "Reset",          NO,   nil,  0,                          NO,   BX_PROPERTY_UNDEFINED},
  {"Bochs",                 "About",          NO,   nil,  0,                          YES,  BX_PROPERTY_UNDEFINED},
  {"Bochs",                 "-",              NO,   nil,  0,                          YES,  BX_PROPERTY_UNDEFINED},
  {"Bochs",                 "Quit",           NO,   @"q", NSEventModifierFlagCommand, YES,  BX_PROPERTY_UNDEFINED},
  {NULL,                    "Simulation",     YES,  nil,  0,                          YES,  BX_PROPERTY_UNDEFINED},
  {"Simulation",            "Start",          NO,   nil,  0,                          YES,  BX_PROPERTY_START_SIM},
  {"Simulation",            "Stop",           NO,   nil,  0,                          NO,   BX_PROPERTY_EXIT_SIM},
  {"Simulation",            "-",              NO,   nil,  0,                          YES,  BX_PROPERTY_UNDEFINED},
  {"Simulation",            "Clipboard",      YES,  nil,  0,                          NO,   BX_PROPERTY_UNDEFINED},
  {"Simulation.Clipboard",  "Copy",           NO,   @"c", NSEventModifierFlagCommand, NO,   BX_PROPERTY_UNDEFINED},
  {"Simulation.Clipboard",  "Paste",          NO,   @"v", NSEventModifierFlagCommand, NO,   BX_PROPERTY_UNDEFINED},
  {NULL,                    "Debugger",       YES,  nil,  0,                          YES,  BX_PROPERTY_UNDEFINED},
  {"Debugger",              "Simulation",     YES,  nil,  0,                          YES,  BX_PROPERTY_UNDEFINED},
  {"Debugger.Simulation",   "Continue",       NO,   @"c", NSEventModifierFlagControl, NO,   BX_PROPERTY_UNDEFINED},
  {"Debugger.Simulation",   "Step",           NO,   @"s", NSEventModifierFlagControl, NO,   BX_PROPERTY_UNDEFINED},
  {"Debugger.Simulation",   "Step N",         NO,   nil,  0,                          NO,   BX_PROPERTY_UNDEFINED},
  {"Debugger.Simulation",   "Break",          NO,   @"x", NSEventModifierFlagControl, NO,   BX_PROPERTY_BREAK_SIM},

  {NULL,                    "Window",         YES,  nil,  0,                          YES,  BX_PROPERTY_UNDEFINED},
  {"Window",                "Configuration",  NO,   nil,  0,                          YES,  BX_PROPERTY_UNDEFINED},
  {"Window",                "VGA Display",    NO,   nil,  0,                          YES,  BX_PROPERTY_UNDEFINED},
  {"Window",                "Logger",         NO,   nil,  0,                          YES,  BX_PROPERTY_UNDEFINED},
  {"Window",                "Debugger",       NO,   nil,  0,                          YES,  BX_PROPERTY_UNDEFINED},
  {NULL,                    "Help",           YES,  nil,  0,                          YES,  BX_PROPERTY_UNDEFINED},
  {NULL,                    NULL,             NO,   nil,  0,                          NO,   BX_PROPERTY_UNDEFINED}
};




@implementation BXNSMenuBar


/**
 * init
 */
- (instancetype _Nonnull)init:(id _Nonnull) target {

  self = [super init];
  if (self) {

    int i;

    i = 0;

    // create App menu bar
    NSApp.mainMenu = [NSMenu alloc];
    while ((menu_options[i].parent != NULL) | (menu_options[i].name != NULL)) {
      [BXNSMenuBar createMenu:&menu_options[i] menuTarget:target];
      i++;
    }

  }

  return self;

}

/**
 * createMenu
 */
+ (void)createMenu:(menu_opts_t * _Nonnull) opt menuTarget:(id _Nonnull) target {

  NSMenu * parent;
  NSString * title;
  NSMenuItem * newMenuItem;
  NSMenu * newMenu;

  // find menu parent
  if (opt->parent == NULL) {
    parent = NSApp.mainMenu;
  } else {
    parent = [BXNSMenuBar findMenu:[NSString stringWithUTF8String:opt->parent] startAt:nil];
  }

  if (opt->childs) {
    title = [NSString stringWithUTF8String:opt->name];
    newMenuItem = [NSMenuItem alloc];
    if (opt->parent != NULL) {
      newMenuItem.title = title;
    }
    newMenu = [[NSMenu alloc] initWithTitle:title];
    [newMenu setAutoenablesItems:NO];
    [newMenuItem setSubmenu:newMenu];
    [parent addItem:newMenuItem];
  } else {
    title = [NSString stringWithUTF8String:opt->name];
    if ([title isEqualToString:@"-"]) {
      [parent addItem:[NSMenuItem separatorItem]];
    } else {
      newMenuItem = [[NSMenuItem alloc] initWithTitle:title action:@selector(onMenuEvent:) keyEquivalent:opt->key==nil?@"":opt->key];
      if (opt->key_modifier != 0) {
        newMenuItem.keyEquivalentModifierMask = opt->key_modifier;
      }
      newMenuItem.target = target;
      [newMenuItem setEnabled:opt->enabled];
      [parent addItem:newMenuItem];
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
    // check NSMenu
    if ([title isEqualToString:[oldMenuItem title]]) {
      return ((NSMenuItem *)oldMenuItem);
    }
    // check NSMenuItem
    if ([title isEqualToString:[oldMenuItem submenu].title]) {
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

/**
 * getMenuItemPath
 */
+ (NSString * _Nonnull)getMenuItemPath:(NSMenuItem * _Nonnull) menuitem {

  NSMenu * curMenu;
  NSString * menuPath;

  menuPath = menuitem.title;
  curMenu = menuitem.menu;

  while ((curMenu != nil) & (curMenu.title != nil)) {
    menuPath = [[NSString alloc] initWithFormat:@"%@.%@", curMenu.title, menuPath];
    curMenu = curMenu.supermenu;
  };

  return menuPath;

}

/**
 * getMenuItemTypePath
 */
+ (NSString * _Nullable)getMenuItemTypePath:(property_t) type {

  int i;

  i = 0;

  while ((menu_options[i].parent != NULL) | (menu_options[i].name != NULL)) {
    if (type == menu_options[i].type) {
      return [[NSString alloc] initWithFormat:@"%s.%s", menu_options[i].parent, menu_options[i].name];
    }
    i++;
  }

  return nil;

}



@end
