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

#ifndef BX_GUI_COCOA_MENU_H

  #define BX_GUI_COCOA_MENU_H

  typedef struct {
    const char * _Nullable parent;
    const char * _Nullable name;
    bool                   childs;
    NSString   * _Nullable key;
    NSUInteger             key_modifier;
    bool                   enabled;
    property_t             type;
  } menu_opts_t;


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSMenuBar
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSMenuBar : NSObject

  - (instancetype _Nonnull)init:(id _Nonnull) target;

  + (void)createMenu:(menu_opts_t * _Nonnull) opt menuTarget:(id _Nonnull) target;
  + (NSMenu * _Nullable)findMenu:(NSString * _Nonnull) title startAt:(NSMenu * _Nullable) start;
  + (NSMenuItem * _Nullable)findMenuItem:(NSString * _Nonnull) title startAt:(NSMenu * _Nullable) start;
  + (void)showMenu:(NSString * _Nonnull) title doShow:(BOOL) show;
  + (NSString * _Nonnull)getMenuItemPath:(NSMenuItem * _Nonnull) menuitem;
  + (NSString * _Nullable)getMenuItemTypePath:(property_t) type;
  + (property_t) getMenuItemProperty:(NSString * _Nonnull) path;

  @end


#endif /* BX_GUI_COCOA_MENU_H */
