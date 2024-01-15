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

#ifndef BX_GUI_COCOA_DEVICE_H

  #define BX_GUI_COCOA_DEVICE_H

  #include "cocoa_window.h"

  struct BXGuiCocoaDeviceImpl;

  class BXGuiCocoaDevice {

  private:
    BXGuiCocoaDeviceImpl * BXCocoaDevice;
    BXGuiCocoaWindow * BXwindow;

  public:
    BXGuiCocoaDevice(unsigned x, unsigned y, unsigned headerbar_y);
    ~BXGuiCocoaDevice();

    void handle_events();
    void run_terminate();

    void getScreenConfiguration(unsigned int * width, unsigned int * height, unsigned char * bpp);

    void showAlertMessage(const char *msg, const char type);

    void captureMouse(bool cap, unsigned x, unsigned y);
    void captureMouse(unsigned x, unsigned y);
    bool hasMouseCapture();

    unsigned create_bitmap(const unsigned char *bmap, unsigned xdim, unsigned ydim);
    unsigned headerbar_bitmap(unsigned bmap_id, unsigned alignment, void (*f)(void));
    void show_headerbar(void);
    void dimension_update(unsigned x, unsigned y, unsigned fwidth, unsigned fheight, unsigned bpp);
    void render(void);
    bool palette_change(unsigned char index, unsigned char red, unsigned char green, unsigned char blue);
    void clear_screen(void);
    void replace_bitmap(unsigned hbar_id, unsigned bmap_id);
    void setup_charmap(unsigned char *charmapA, unsigned char *charmapB, unsigned char w, unsigned char h);
    void set_font(bool font2, unsigned pos, unsigned char *charmap);
    void draw_char(bool crsr, bool font2, unsigned char fgcolor, unsigned char bgcolor, unsigned short int charpos, unsigned short int x, unsigned short int y, unsigned char w, unsigned char h);
    bool hasEvent();
    void setEventMouseABS(bool abs);
    unsigned long getEvent();
    void graphics_tile_update(unsigned char *tile, unsigned x, unsigned y, unsigned w, unsigned h);

  };

#endif /* BX_GUI_COCOA_DEVICE_H */
