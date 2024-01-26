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

#ifndef BX_GUI_COCOA_BOCHS_H

  #define BX_GUI_COCOA_BOCHS_H

  struct BXNSApplicationImpl;

  typedef enum {
    BX_GUI_WINDOW_UNDEFINED,
    BX_GUI_WINDOW_CONFIGURATION,
    BX_GUI_WINDOW_VGA_DISPLAY,
    BX_GUI_WINDOW_LOGGING,
    BX_GUI_WINDOW_DEBUGGER
  } gui_window_type_t;

  typedef enum {
    BX_PROPERTY_UNDEFINED = -1,
    BX_PROPERTY_START_SIM,
    BX_PROPERTY_EXIT_SIM,
  } property_t;

  typedef struct {
    unsigned        headerbar_y;
    unsigned short  xres;
    unsigned short  yres;
  } vga_settings_t;

  class BXGuiCocoaApplication {

  private:
    BXNSApplicationImpl * BXCocoaApplication;

  public:
    BXGuiCocoaApplication();
    ~BXGuiCocoaApplication();

    void showWindow(gui_window_type_t window, bool bShow);
    void activateWindow(gui_window_type_t window);
    int getProperty(property_t property, bool bWait);

    void postLogMessage(unsigned char level, unsigned char mode, const char * prefix, const char * msg);

    void getScreenConfiguration(unsigned int * width, unsigned int * height, unsigned char * bpp);
    void dimension_update(unsigned x, unsigned y, unsigned fwidth, unsigned fheight, unsigned bpp);


    unsigned create_bitmap(const unsigned char *bmap, unsigned xdim, unsigned ydim);
    unsigned headerbar_bitmap(unsigned bmap_id, unsigned alignment, void (*f)(void));
    void replace_bitmap(unsigned hbar_id, unsigned bmap_id);
    void show_headerbar(void);

    void setup_charmap(unsigned char *charmapA, unsigned char *charmapB, unsigned char w, unsigned char h);
    void set_font(bool font2, unsigned pos, unsigned char *charmap);
    void draw_char(bool crsr, bool font2, unsigned char fgcolor, unsigned char bgcolor, unsigned short int charpos, unsigned short int x, unsigned short int y, unsigned char w, unsigned char h);
    bool palette_change(unsigned char index, unsigned char red, unsigned char green, unsigned char blue);
    
    void render(void);



  };

  extern BXGuiCocoaApplication * bxcocoagui;
  extern int main_argc;
  extern char ** main_argv;

#endif /* BX_GUI_COCOA_BOCHS_H */
