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

// cocoa.cc -- bochs GUI file for MacOS X with Cocoa API
// written by Christoph Gembalski <christoph@gembalski.de>

// Define BX_PLUGGABLE in files that can be compiled into plugins.  For
// platforms that require a special tag on exported symbols, BX_PLUGGABLE
// is used to know when we are exporting symbols and when we are importing.
#define BX_PLUGGABLE

// BOCHS INCLUDES
#include "bochs.h"
#include "gui.h"
#include "plugin.h"
#include "param_names.h"

#if BX_WITH_COCOA
#include "icon_bochs.h"
#include "font/vga.bitmap.h"

#include "cocoa_device.h"

#define BX_GUI_STARTUP_X 640
#define BX_GUI_STARTUP_Y 64

BXGuiCocoaDevice * device;

class bx_cocoa_gui_c : public bx_gui_c {
public:
  bx_cocoa_gui_c (void) {}
  DECLARE_GUI_VIRTUAL_METHODS()
  DECLARE_GUI_NEW_VIRTUAL_METHODS()
  // new text update API
  virtual void set_font(bool lg);
  virtual void draw_char(Bit8u ch, Bit8u fc, Bit8u bc, Bit16u xc, Bit16u yc,
                         Bit8u fw, Bit8u fh, Bit8u fx, Bit8u fy,
                         bool gfxcharw9, Bit8u cs, Bit8u ce, bool curs, bool font2);
  // // optional gui methods (stubs or default code in gui.cc)
  // virtual void statusbar_setitem_specific(int element, bool active, bool w);
  // virtual void set_tooltip(unsigned hbar_id, const char *tip);
  // set_display_mode() changes the mode between the configuration interface
  // and the simulation.  This is primarily intended for display libraries
  // which have a full-screen mode such as SDL or term.  The display mode is
  // set to DISP_MODE_CONFIG before displaying any configuration menus,
  // for panics that requires user input, when entering the debugger, etc.  It
  // is set to DISP_MODE_SIM when the Bochs simulation resumes.  The
  // enum is defined in gui/siminterface.h.
  // virtual void set_display_mode (disp_mode_t newmode);
  // #if BX_USE_IDLE_HACK
  //   // this is called from the CPU model when the HLT instruction is executed.
  //   virtual void sim_is_idle(void);
  // #endif
  //   virtual void show_ips(Bit32u ips_count);
  //   virtual void beep_on(float frequency);
  //   virtual void beep_off();
  //   virtual void get_capabilities(Bit16u *xres, Bit16u *yres, Bit16u *bpp);
  //   virtual void set_mouse_mode_absxy(bool mode);
  // #if BX_USE_GUI_CONSOLE
  //   virtual void set_console_edit_mode(bool mode);
  // #endif
};

// declare one instance of the gui object and call macro to insert the
// plugin code
static bx_cocoa_gui_c *theGui = NULL;
IMPLEMENT_GUI_PLUGIN_CODE(cocoa)

#define LOG_THIS theGui->

// This file defines stubs for the GUI interface, which is a
// place to start if you want to port bochs to a platform, for
// which there is no support for your native GUI, or if you want to compile
// bochs without any native GUI support (no output window or
// keyboard input will be possible).
// Look in 'x.cc', 'carbon.cc', and 'win32.cc' for specific
// implementations of this interface.  -Kevin


// Logging to console support

extern "C" void bx_cocoa_gui_c_log_info(const char *data) {
  BX_INFO(("%s", data));
}

extern "C" void bx_cocoa_gui_c_log_debug(const char *data) {
  BX_DEBUG(("%s", data));
}

extern "C" void bx_cocoa_gui_c_log_error(const char *data) {
  BX_ERROR(("%s", data));
}

extern "C" void bx_cocoa_gui_c_log_panic(const char *data) {
  BX_PANIC(("%s", data));
}

extern "C" void bx_cocoa_gui_c_log_fatal(const char *data) {
  BX_FATAL(("%s", data));
}

// flip bits

extern "C" unsigned char flip_byte(unsigned char b) {
   b = (b & 0xF0) >> 4 | (b & 0x0F) << 4;
   b = (b & 0xCC) >> 2 | (b & 0x33) << 2;
   b = (b & 0xAA) >> 1 | (b & 0x55) << 1;
   return b;
}


// ::SPECIFIC_INIT()
//
// Called from gui.cc, once upon program startup, to allow for the
// specific GUI code (X11, Win32, ...) to be initialized.
//
// argc, argv: these arguments can be used to initialize the GUI with
//     specific options (X11 options, Win32 options,...)
//
// headerbar_y:  A headerbar (toolbar) is display on the top of the
//     VGA window, showing floppy status, and other information.  It
//     always assumes the width of the current VGA mode width, but
//     it's height is defined by this parameter.

void bx_cocoa_gui_c::specific_init(int argc, char **argv, unsigned headerbar_y)
{
  put("COCOA");
  UNUSED(argc);
  UNUSED(argv);
  UNUSED(headerbar_y);

  UNUSED(bochs_icon_bits);  // global variable of bochs icon

  BX_INFO(("bx_cocoa_gui_c::specific_init() headerbar_y=%d", headerbar_y));

  // use BOCHS_WINDOW_NAME as DLG Name

  // init device
  device = new BXGuiCocoaDevice(BX_GUI_STARTUP_X, BX_GUI_STARTUP_Y, headerbar_y);

  // init startup
  device->dimension_update(640, 480, 8, 16, 8);

  BX_INFO(("bx_cocoa_gui_c::specific_init() running some events now ..."));

  for (int i=0; i<100; i++) {
    device->handle_events();
  }

  BX_INFO(("bx_cocoa_gui_c::specific_init() done running some events now ..."));

  // device->setup_charmap((unsigned char *)&vga_charmap[0], (unsigned char *)&vga_charmap[1]);
  device->setup_charmap((unsigned char *)bx_vgafont, (unsigned char *)bx_vgafont);

  if (SIM->get_param_bool(BXPN_PRIVATE_COLORMAP)->get()) {
    BX_INFO(("private_colormap option ignored."));
  }

  // new_gfx_api = 1;
  new_text_api = 1;

}


// ::TEXT_UPDATE()
//
// Called in a VGA text mode, to update the screen with
// new content.
//
// old_text: array of character/attributes making up the contents
//           of the screen from the last call.  See below
// new_text: array of character/attributes making up the current
//           contents, which should now be displayed.  See below
//
// format of old_text & new_text: each is tm_info->line_offset*text_rows
//     bytes long. Each character consists of 2 bytes.  The first by is
//     the character value, the second is the attribute byte.
//
// cursor_x: new x location of cursor
// cursor_y: new y location of cursor
// tm_info:  this structure contains information for additional
//           features in text mode (cursor shape, line offset,...)

void bx_cocoa_gui_c::text_update(Bit8u *old_text, Bit8u *new_text,
                      unsigned long cursor_x, unsigned long cursor_y,
                      bx_vga_tminfo_t *tm_info)
{
  UNUSED(old_text);
  UNUSED(new_text);
  UNUSED(cursor_x);
  UNUSED(cursor_y);
  UNUSED(tm_info);

  // present for compatibility

}


// ::GRAPHICS_TILE_UPDATE()
//
// Called to request that a tile of graphics be drawn to the
// screen, since info in this region has changed.
//
// tile: array of 8bit values representing a block of pixels with
//       dimension equal to the 'x_tilesize' & 'y_tilesize' members.
//       Each value specifies an index into the
//       array of colors you allocated for ::palette_change()
// x0: x origin of tile
// y0: y origin of tile
//
// note: origin of tile and of window based on (0,0) being in the upper
//       left of the window.

void bx_cocoa_gui_c::graphics_tile_update(Bit8u *tile, unsigned x0, unsigned y0)
{
  UNUSED(tile);
  UNUSED(x0);
  UNUSED(y0);
  BX_INFO(("bx_cocoa_gui_c::graphics_tile_update x0=%d y0=%d", x0, y0));
}


// ::HANDLE_EVENTS()
//
// Called periodically (every 1 virtual millisecond) so the
// the gui code can poll for keyboard, mouse, and other
// relevant events.

void bx_cocoa_gui_c::handle_events(void)
{
    device->handle_events();
}


// ::FLUSH()
//
// Called periodically, requesting that the gui code flush all pending
// screen update requests.

void bx_cocoa_gui_c::flush(void)
{
    device->render();
    device->handle_events();
}


// ::CLEAR_SCREEN()
//
// Called to request that the VGA region is cleared.  Don't
// clear the area that defines the headerbar.

void bx_cocoa_gui_c::clear_screen(void)
{
  device->clear_screen();
}


// ::PALETTE_CHANGE()
//
// Allocate a color in the native GUI, for this color, and put
// it in the colormap location 'index'.
// returns: 0=no screen update needed (color map change has direct effect)
//          1=screen updated needed (redraw using current colormap)

bool bx_cocoa_gui_c::palette_change(Bit8u index, Bit8u red, Bit8u green, Bit8u blue)
{
  return(device->palette_change(index, red, green, blue));
}


// ::DIMENSION_UPDATE()
//
// Called when the VGA mode changes it's X,Y dimensions.
// Resize the window to this size, but you need to add on
// the height of the headerbar to the Y value.
//
// x: new VGA x size
// y: new VGA y size (add headerbar_y parameter from ::specific_init().
// fheight: new VGA character height in text mode
// fwidth : new VGA character width in text mode
// bpp : bits per pixel in graphics mode

void bx_cocoa_gui_c::dimension_update(unsigned x, unsigned y, unsigned fheight, unsigned fwidth, unsigned bpp)
{
  // guest_textmode = (fheight > 0);
  // guest_xres = x;
  // guest_yres = y;
  // guest_bpp = bpp;
  UNUSED(fwidth);

  BX_INFO(("bx_cocoa_gui_c::dimension_update x=%d y=%d fheight=%d fwidth=%d bpp=%d", x, y, fheight, fwidth, bpp));
  device->dimension_update(x, y, fheight, fwidth, bpp);

  host_xres = x;
  host_yres = y;
  host_bpp = bpp;

}


// ::CREATE_BITMAP()
//
// Create a monochrome bitmap of size 'xdim' by 'ydim', which will
// be drawn in the headerbar.  Return an integer ID to the bitmap,
// with which the bitmap can be referenced later.
//
// bmap: packed 8 pixels-per-byte bitmap.  The pixel order is:
//       bit0 is the left most pixel, bit7 is the right most pixel.
// xdim: x dimension of bitmap
// ydim: y dimension of bitmap

unsigned bx_cocoa_gui_c::create_bitmap(const unsigned char *bmap, unsigned xdim, unsigned ydim)
{
  return(device->create_bitmap(bmap, xdim, ydim));
}


// ::HEADERBAR_BITMAP()
//
// Called to install a bitmap in the bochs headerbar (toolbar).
//
// bmap_id: will correspond to an ID returned from
//     ::create_bitmap().  'alignment' is either BX_GRAVITY_LEFT
//     or BX_GRAVITY_RIGHT, meaning install the bitmap in the next
//     available leftmost or rightmost space.
// alignment: is either BX_GRAVITY_LEFT or BX_GRAVITY_RIGHT,
//     meaning install the bitmap in the next
//     available leftmost or rightmost space.
// f: a 'C' function pointer to callback when the mouse is clicked in
//     the boundaries of this bitmap.

unsigned bx_cocoa_gui_c::headerbar_bitmap(unsigned bmap_id, unsigned alignment, void (*f)(void))
{
  return(device->headerbar_bitmap(bmap_id, alignment, f));
}


// ::REPLACE_BITMAP()
//
// Replace the bitmap installed in the headerbar ID slot 'hbar_id',
// with the one specified by 'bmap_id'.  'bmap_id' will have
// been generated by ::create_bitmap().  The old and new bitmap
// must be of the same size.  This allows the bitmap the user
// sees to change, when some action occurs.  For example when
// the user presses on the floppy icon, it then displays
// the ejected status.
//
// hbar_id: headerbar slot ID
// bmap_id: bitmap ID

void bx_cocoa_gui_c::replace_bitmap(unsigned hbar_id, unsigned bmap_id)
{
  device->replace_bitmap(hbar_id, bmap_id);
}


// ::SHOW_HEADERBAR()
//
// Show (redraw) the current headerbar, which is composed of
// currently installed bitmaps.

void bx_cocoa_gui_c::show_headerbar(void)
{
  device->show_headerbar();
}


// ::GET_CLIPBOARD_TEXT()
//
// Called to get text from the GUI clipboard. Returns 1 if successful.

int bx_cocoa_gui_c::get_clipboard_text(Bit8u **bytes, Bit32s *nbytes)
{
  UNUSED(bytes);
  UNUSED(nbytes);
  BX_INFO(("bx_cocoa_gui_c::get_clipboard_text"));
  return 0;
}


// ::SET_CLIPBOARD_TEXT()
//
// Called to copy the text screen contents to the GUI clipboard.
// Returns 1 if successful.

int bx_cocoa_gui_c::set_clipboard_text(char *text_snapshot, Bit32u len)
{
  UNUSED(text_snapshot);
  UNUSED(len);
  BX_INFO(("bx_cocoa_gui_c::set_clipboard_text"));
  return 0;
}


// ::MOUSE_ENABLED_CHANGED_SPECIFIC()
//
// Called whenever the mouse capture mode should be changed. It can change
// because of a gui event such as clicking on the mouse bitmap / button of
// the header / tool bar, toggle the mouse capture using the configured
// method with keyboard or mouse, or from the configuration interface.

void bx_cocoa_gui_c::mouse_enabled_changed_specific(bool val)
{
  BX_INFO(("bx_cocoa_gui_c::mouse_enabled_changed_specific Mouse capture %s", val ? "on":"off"));
}


// ::EXIT()
//
// Called before bochs terminates, to allow for a graceful
// exit from the native GUI mechanism.

void bx_cocoa_gui_c::exit(void)
{

  if (device != NULL) {
    device->run_terminate();
    delete device;
  }

}

// Cocoa implementation of new graphics API methods (compatibility mode in gui.cc)

bx_svga_tileinfo_t * bx_cocoa_gui_c::graphics_tile_info(bx_svga_tileinfo_t *info) {
  BX_INFO(("bx_cocoa_gui_c::graphics_tile_info"));

  return NULL;
}


Bit8u * bx_cocoa_gui_c::graphics_tile_get(unsigned x, unsigned y, unsigned *w, unsigned *h) {
  BX_INFO(("bx_cocoa_gui_c::graphics_tile_get x=%d y=%d w=%d h=%d", x, y, *w, *h));

  return NULL;
}


void bx_cocoa_gui_c::graphics_tile_update_in_place(unsigned x, unsigned y, unsigned w, unsigned h) {
  BX_INFO(("bx_cocoa_gui_c::graphics_tile_update_in_place x=%d y=%d w=%d h=%d", x, y, w, h));
}


// Cocoa implementation of new text update API
void bx_cocoa_gui_c::set_font(bool lg) {

  for (unsigned m = 0; m < 2; m++) {
    for (unsigned c = 0; c < 256; c++) {
      if (char_changed[m][c]) {
        // bool gfxchar = lg && ((c & 0xE0) == 0xC0);
        // if (!gfxchar) {

        // display knows about size from dimension_update call
        device->set_font(c, (unsigned char *)&vga_charmap[0], (unsigned char *)&vga_charmap[1]);
        char_changed[m][c] = 0;
      // }
      }
    }
  }

}


int maxshow=200;
void bx_cocoa_gui_c::draw_char(Bit8u ch, Bit8u fc, Bit8u bc, Bit16u xc, Bit16u yc,
                       Bit8u fw, Bit8u fh, Bit8u fx, Bit8u fy,
                       bool gfxcharw9, Bit8u cs, Bit8u ce, bool curs, bool font2) {

  unsigned short int charpos;

  charpos = ch * fh;



  device->draw_char(font2, fc, bc, charpos, xc, yc, fw, fh);

  if (maxshow <200) {
  BX_INFO(("bx_cocoa_gui_c::draw_char cd=%d fc=%d bc=%d xc=%d yc=%d fw=%d fh=%d fx=%d fy=%d gfxcharw9=%s cs=%d ce=%d curs=%s font2=%s",
    ch, fc, bc, xc, yc, fw, fh, fx, fy, gfxcharw9?"YES":"NO", cs, ce, curs?"YES":"NO", font2?"YES":"NO"));
  maxshow++;
  }
}





// Cocoa implementation of optional bx_gui_c methods (see gui.h)


// // set_display_mode() changes the mode between the configuration interface
// // and the simulation.  This is primarily intended for display libraries
// // which have a full-screen mode such as SDL or term.  The display mode is
// // set to DISP_MODE_CONFIG before displaying any configuration menus,
// // for panics that requires user input, when entering the debugger, etc.  It
// // is set to DISP_MODE_SIM when the Bochs simulation resumes.  The
// // enum is defined in gui/siminterface.h.
// void bx_cocoa_gui_c::set_display_mode(disp_mode_t newmode)
// {
//   BX_INFO(("bx_cocoa_gui_c::set_display_mode mode=%d", newmode));
//   // // if no mode change, do nothing.
//   // if (disp_mode == newmode) return;
//   // // remember the display mode for next time
//   // disp_mode = newmode;
//   // if ((newmode == DISP_MODE_SIM) && console_running()) {
//   //   console_cleanup();
//   // }
// }







#endif /* if BX_WITH_COCOA */
