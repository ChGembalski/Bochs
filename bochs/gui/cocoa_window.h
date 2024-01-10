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

#ifndef BX_GUI_COCOA_WINDOW_H

  #define BX_GUI_COCOA_WINDOW_H

  struct BXGuiCocoaWindowImpl;

  class BXGuiCocoaWindow {

  private:
    BXGuiCocoaWindowImpl * BXCocoaWindow;

  public:
    BXGuiCocoaWindow(unsigned x, unsigned y, unsigned headerbar_y);
    ~BXGuiCocoaWindow();

    unsigned create_bitmap(const unsigned char *bmap, unsigned xdim, unsigned ydim);
    unsigned headerbar_bitmap(unsigned bmap_id, unsigned alignment, void (*f)(void));
    void show_headerbar(void);
    void dimension_update(unsigned x, unsigned y, unsigned fheight, unsigned fwidth, unsigned bpp);
    void render(void);
    bool palette_change(unsigned char index, unsigned char red, unsigned char green, unsigned char blue);
    void clear_screen(void);

  };





#endif /* BX_GUI_COCOA_WINDOW_H */
