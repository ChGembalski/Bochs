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
#include "param_names.h"
#include "iodev.h"

#if BX_WITH_COCOA
#include "font/vga.bitmap.h"

#include "cocoa_bochs.h"


Bit32s scancode_tbl[] = {
  // 00 ... 0F
  BX_KEY_A,
  BX_KEY_S,
  BX_KEY_D,
  BX_KEY_F,
  BX_KEY_H,
  BX_KEY_G,
  BX_KEY_Y,
  BX_KEY_X,
  BX_KEY_C,
  BX_KEY_V,
  -1,
  BX_KEY_B,
  BX_KEY_Q,
  BX_KEY_W,
  BX_KEY_E,
  BX_KEY_R,
  // 10 ... 1F
  BX_KEY_Z,
  BX_KEY_T,
  BX_KEY_1,
  BX_KEY_2,
  BX_KEY_3,
  BX_KEY_4,
  BX_KEY_6,
  BX_KEY_5,
  BX_KEY_EQUALS,
  BX_KEY_9,
  BX_KEY_7,
  BX_KEY_MINUS,
  BX_KEY_8,
  BX_KEY_0,
  BX_KEY_RIGHT_BRACKET,
  BX_KEY_O,
  // 20 ... 2F
  BX_KEY_U,
  BX_KEY_LEFT_BRACKET,
  BX_KEY_I,
  BX_KEY_P,
    BX_KEY_ENTER,
  BX_KEY_L,
  BX_KEY_J,
  BX_KEY_SINGLE_QUOTE,
  BX_KEY_K,
  BX_KEY_SEMICOLON,
  BX_KEY_BACKSLASH,
  BX_KEY_COMMA,
  BX_KEY_SLASH,
  BX_KEY_N,
  BX_KEY_M,
  BX_KEY_PERIOD,
  // 30 ... 3F
    BX_KEY_TAB,
    BX_KEY_SPACE,
  BX_KEY_GRAVE,
    BX_KEY_BACKSPACE,
  -1,
    BX_KEY_ESC,
  -1,
  -1,
    BX_KEY_SHIFT_L, // shift
    BX_KEY_CAPS_LOCK,
    BX_KEY_ALT_L, // option
    BX_KEY_CTRL_L,  // control
    BX_KEY_SHIFT_R, // shift r
    BX_KEY_ALT_R, // option r
    BX_KEY_CTRL_R,  // control
  -1, // function
  // 40 ... 4F
  -1, // F17
  -1,
  -1,
  BX_KEY_KP_MULTIPLY,
  -1,
  BX_KEY_KP_ADD,
  -1,
  -1,
  -1,// volume up
  -1,// volume down
  -1,// mute
  BX_KEY_KP_DIVIDE,
  BX_KEY_KP_ENTER,
  -1,
  BX_KEY_KP_SUBTRACT,
  -1,// F18
  // 50 ... 5F
  -1,// F19
  -1,// F20
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  -1,
  // 60 ... 5F
    BX_KEY_F5,
    BX_KEY_F6,
    BX_KEY_F7,
    BX_KEY_F3,
    BX_KEY_F8,
    BX_KEY_F9,
  -1,
    BX_KEY_F11,
  -1,
  -1,//F13
  -1,// F16
  -1,// F14
  -1,
    BX_KEY_F10,
  -1,
    BX_KEY_F12,
  // 70 ... 7F
  -1,
  -1,// F15
  -1,// help
    BX_KEY_HOME,
    BX_KEY_PAGE_UP,
    BX_KEY_DELETE,
    BX_KEY_F4,
    BX_KEY_END,
    BX_KEY_F2,
    BX_KEY_PAGE_DOWN,
    BX_KEY_F1,
    BX_KEY_LEFT,
    BX_KEY_RIGHT,
    BX_KEY_DOWN,
    BX_KEY_UP,
  -1,
  // 80 ... 8F

};


#define MACOS_NSEventModifierFlagKeyUp      0x8000000000000000
#define MACOS_NSEventModifierFlagMouse      0x4000000000000000

#define MACOS_NSEventModifierFlagMask       0xFFFF0000
#define MACOS_NSEventModifierFlagCapsLock   1 << 16
#define MACOS_NSEventModifierFlagShift      1 << 17
#define MACOS_NSEventModifierFlagControl    1 << 18
#define MACOS_NSEventModifierFlagOption     1 << 19
#define MACOS_NSEventModifierFlagCommand    1 << 20
#define MACOS_NSEventModifierFlagNumericPad 1 << 21
#define MACOS_NSEventModifierFlagHelp       1 << 22
#define MACOS_NSEventModifierFlagFunction   1 << 23


#define LOG_THIS theGui->

class bx_cocoa_gui_c : public bx_gui_c {
private:
  bool cocoa_mouse_mode_absxy;
  bxevent_handler old_callback;
  void *old_callback_arg;
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
  #if BX_USE_IDLE_HACK
    // this is called from the CPU model when the HLT instruction is executed.
    virtual void sim_is_idle(void);
  #endif
  //   virtual void show_ips(Bit32u ips_count);
  //   virtual void beep_on(float frequency);
  //   virtual void beep_off();
  //   virtual void get_capabilities(Bit16u *xres, Bit16u *yres, Bit16u *bpp);
  virtual void set_mouse_mode_absxy(bool mode);
  // #if BX_USE_GUI_CONSOLE
  //   virtual void set_console_edit_mode(bool mode);
  // #endif
  BxEvent * notify_callback(void *unused, BxEvent *event);
};

// declare one instance of the gui object and call macro to insert the
// plugin code
static bx_cocoa_gui_c *theGui = NULL;
IMPLEMENT_GUI_PLUGIN_CODE(cocoa)

// This file defines stubs for the GUI interface, which is a
// place to start if you want to port bochs to a platform, for
// which there is no support for your native GUI, or if you want to compile
// bochs without any native GUI support (no output window or
// keyboard input will be possible).
// Look in 'x.cc', 'carbon.cc', and 'win32.cc' for specific
// implementations of this interface.  -Kevin

// Logging to console support
#if !BX_NO_LOGGING

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

#endif /* !BX_NO_LOGGING */

// flip bits

// extern "C"
unsigned char flip_byte(unsigned char b) {
   b = (b & 0xF0) >> 4 | (b & 0x0F) << 4;
   b = (b & 0xCC) >> 2 | (b & 0x33) << 2;
   b = (b & 0xAA) >> 1 | (b & 0x55) << 1;
   return b;
}


static BxEvent * cocoa_notify_callback(void *unused, BxEvent *event) {
  return (theGui->notify_callback(unused, event));
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
  Bit8u max_bpp;

#if BX_DEBUGGER && BX_NEW_DEBUGGER_GUI
  bool cocoa_with_debug_gui = 0;
#endif

  put("COCOA");
  UNUSED(argc);
  UNUSED(argv);

  BX_INFO(("bx_cocoa_gui_c::specific_init headerbar_y=%d", headerbar_y));

  BX_INFO(("bx_cocoa_gui_c::specific_init guest_textmode=%s guest_xres=%d guest_yres=%d guest_bpp=%d",
    guest_textmode?"YES":"NO", guest_xres, guest_yres, guest_bpp));

  cocoa_mouse_mode_absxy = false;
  old_callback = NULL;
  old_callback_arg = NULL;

  // bxcocoagui created by cocoaconfig !!!

  // setup screen
  bxcocoagui->getScreenConfiguration(&max_xres, &max_yres, &max_bpp);

  // setup mouse handling
  // device->setEventMouseABS(cocoa_mouse_mode_absxy);

  // init startup - use current guest settings
  bxcocoagui->dimension_update(guest_xres, guest_yres, 16, 8, guest_bpp);
  bxcocoagui->showWindow(BX_GUI_WINDOW_VGA_DISPLAY, true);
  bxcocoagui->activateWindow(BX_GUI_WINDOW_VGA_DISPLAY);
  bxcocoagui->setup_charmap((unsigned char *)bx_vgafont, (unsigned char *)bx_vgafont, 8, 16);

  // redirect notify callback
  SIM->get_notify_callback(&old_callback, &old_callback_arg);
  assert(old_callback != NULL);
  SIM->set_notify_callback(cocoa_notify_callback, NULL);

#if BX_DEBUGGER && BX_NEW_DEBUGGER_GUI
  cocoa_with_debug_gui = 1;
#else
  // SIM->message_box("ERROR", "Bochs debugger not available - ignoring 'gui_debug' option");
#endif

  // ??? Need this one here ?
  if (SIM->get_param_bool(BXPN_PRIVATE_COLORMAP)->get()) {
    BX_INFO(("private_colormap option ignored."));
  }

  new_gfx_api = 1;
  new_text_api = 1;

  dialog_caps = BX_GUI_DLG_ALL;

#if BX_DEBUGGER && BX_NEW_DEBUGGER_GUI
  // initialize debugger gui
  if (cocoa_with_debug_gui) {
    SIM->set_debug_gui(1);
    init_debug_dialog();
  }
#endif

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
  bxcocoagui->graphics_tile_update(tile, x0, y0, x_tilesize, y_tilesize);
}


// ::HANDLE_EVENTS()
//
// Called periodically (every 1 virtual millisecond) so the
// the gui code can poll for keyboard, mouse, and other
// relevant events.

void bx_cocoa_gui_c::handle_events(void)
{

    if (bxcocoagui->hasEvent()) {
      Bit64u event;
      Bit32u scancode;
      Bit32u scanflags;
      bool released;
      bool mouse;

      event = bxcocoagui->getEvent();
      mouse = (event & MACOS_NSEventModifierFlagMouse) == MACOS_NSEventModifierFlagMouse;
      if (mouse) {
        Bit16s mx;
        Bit16s my;
        Bit8u  mb;
        Bit8u  mf;

        mb = (event >> 48) & 0xFF;
        mf = (event >> 32) % 0xFF;
        mx = (event >> 16) & 0xFFFF;
        my = event & 0xFFFF;
        BX_INFO((">>> event mouse event=%lx x=%d y=%d mb=%d mf=%x x=%x y=%x mb=%x", event, mx, my, mb, mf, mx, my, mb));

        if (bxcocoagui->hasMouseCapture() & ((mf & 0x10) == 0x10) & (mb == 1)) {
          SIM->get_param_bool(BXPN_MOUSE_ENABLED)->set(false);
          return;
        }

        DEV_mouse_motion(mx, my, 0, mb, cocoa_mouse_mode_absxy);

        return;
      }
      scanflags = event & MACOS_NSEventModifierFlagMask;
      scancode = event & ~MACOS_NSEventModifierFlagMask;
      released = (event & MACOS_NSEventModifierFlagKeyUp) == 0;
      BX_DEBUG((">>> event %lx mouse %s scancode %x scanflags %x released %x", event, mouse?"YES":"NO", scancode, scanflags, released));

      if (scancode < 0x80) {
        BX_DEBUG(("scancode %x scanflags %x released %x", scancode, scanflags, released));
        scancode = scancode_tbl[scancode];
        BX_DEBUG(("resolved scancode %x scanflags %x released %x", scancode, scanflags, released));
        if (scancode != -1) {

          // resolve scanflags (seems each must be send one after one)
          if ((scanflags & MACOS_NSEventModifierFlagCapsLock) > 0) {
            bx_gui->set_modifier_keys(BX_MOD_KEY_CAPS, released);
            // BX_INFO(("BX_KEY_CAPS_LOCK %d", released));
            DEV_kbd_gen_scancode((released?0:BX_KEY_RELEASED) | BX_KEY_CAPS_LOCK);
          }
          if ((scanflags & MACOS_NSEventModifierFlagShift) > 0) {
            bx_gui->set_modifier_keys(BX_MOD_KEY_SHIFT, released);
            // BX_INFO(("BX_KEY_SHIFT_L %d", released));
            DEV_kbd_gen_scancode((released?0:BX_KEY_RELEASED) | BX_KEY_SHIFT_L);
          }
          if ((scanflags & MACOS_NSEventModifierFlagControl) > 0) {
            set_modifier_keys(BX_MOD_KEY_CTRL, released);
            // BX_INFO(("BX_KEY_CTRL_L %d", released));
            DEV_kbd_gen_scancode((released?0:BX_KEY_RELEASED) | BX_KEY_CTRL_L);
          }
          if ((scanflags & MACOS_NSEventModifierFlagOption) > 0) {
            set_modifier_keys(BX_MOD_KEY_ALT, released);
            // BX_INFO(("BX_KEY_ALT_L %d", released));
            DEV_kbd_gen_scancode((released?0:BX_KEY_RELEASED) | BX_KEY_ALT_L);
          }
          // if ((scanflags & MACOS_NSEventModifierFlagCommand) > 0) {
          //
          // }
          // if ((scanflags & MACOS_NSEventModifierFlagNumericPad) > 0) {
          //
          // }
          // if ((scanflags & MACOS_NSEventModifierFlagHelp) > 0) {
          //
          // }
          // if ((scanflags & MACOS_NSEventModifierFlagFunction) > 0) {
          //
          // }
          // Send keycode
          DEV_kbd_gen_scancode((released?0:BX_KEY_RELEASED) | scancode);

        }
      } else {
        BX_ERROR((">>> event dropped"));
      }
    }

}


// ::FLUSH()
//
// Called periodically, requesting that the gui code flush all pending
// screen update requests.

void bx_cocoa_gui_c::flush(void)
{
  bxcocoagui->render();
}


// ::CLEAR_SCREEN()
//
// Called to request that the VGA region is cleared.  Don't
// clear the area that defines the headerbar.

void bx_cocoa_gui_c::clear_screen(void)
{
  bxcocoagui->clear_screen();
}


// ::PALETTE_CHANGE()
//
// Allocate a color in the native GUI, for this color, and put
// it in the colormap location 'index'.
// returns: 0=no screen update needed (color map change has direct effect)
//          1=screen updated needed (redraw using current colormap)

bool bx_cocoa_gui_c::palette_change(Bit8u index, Bit8u red, Bit8u green, Bit8u blue)
{
  return(bxcocoagui->palette_change(index, red, green, blue));
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

  // inform client about changes?
  guest_textmode = (fheight > 0);
  guest_fwidth = fwidth;
  guest_fheight = fheight;
  guest_xres = x;
  guest_yres = y;

  BX_INFO(("bx_cocoa_gui_c::dimension_update x=%d y=%d fheight=%d fwidth=%d bpp=%d", x, y, fheight, fwidth, bpp));
  bxcocoagui->dimension_update(x, y, fwidth, fheight, bpp);

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
  return(bxcocoagui->create_bitmap(bmap, xdim, ydim));
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
  return(bxcocoagui->headerbar_bitmap(bmap_id, alignment, f));
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
  bxcocoagui->replace_bitmap(hbar_id, bmap_id);
}


// ::SHOW_HEADERBAR()
//
// Show (redraw) the current headerbar, which is composed of
// currently installed bitmaps.

void bx_cocoa_gui_c::show_headerbar(void)
{
  bxcocoagui->show_headerbar();
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
  bxcocoagui->captureMouse(val, guest_xres/2, guest_yres/2);
}


// ::EXIT()
//
// Called before bochs terminates, to allow for a graceful
// exit from the native GUI mechanism.

void bx_cocoa_gui_c::exit(void)
{
BX_INFO(("bx_cocoa_gui_c::exit"));
// #if BX_DEBUGGER && BX_NEW_DEBUGGER_GUI
//   if (SIM->has_debug_gui()) {
//     close_debug_dialog();
//   }
// #endif

  // restore notify callback
  SIM->set_notify_callback(old_callback, old_callback_arg);
  
  bxcocoagui->onBochsThreadExit();

}

// Cocoa implementation of new graphics API methods (compatibility mode in gui.cc)

bx_svga_tileinfo_t * bx_cocoa_gui_c::graphics_tile_info(bx_svga_tileinfo_t *info) {

  host_pitch = host_xres * ((host_bpp + 1) >> 3);

  info->bpp = host_bpp;
  info->pitch = host_pitch;
  switch (info->bpp) {
    case 15:
      info->red_shift = 15;
      info->green_shift = 10;
      info->blue_shift = 5;
      info->red_mask = 0x7c00;
      info->green_mask = 0x03e0;
      info->blue_mask = 0x001f;
      break;
    case 16:
      info->red_shift = 16;
      info->green_shift = 11;
      info->blue_shift = 5;
      info->red_mask = 0xf800;
      info->green_mask = 0x07e0;
      info->blue_mask = 0x001f;
      break;
    case 24:
    case 32:
      info->red_shift = 8;
      info->green_shift = 16;
      info->blue_shift = 24;
      info->red_mask = 0x0000ff;
      info->green_mask = 0x00ff00;
      info->blue_mask = 0xff0000;
      break;
  }
  info->is_indexed = (host_bpp <= 8);
#ifdef BX_LITTLE_ENDIAN
  info->is_little_endian = 1;
#else
  info->is_little_endian = 0;
#endif

  return info;

}


Bit8u * bx_cocoa_gui_c::graphics_tile_get(unsigned x, unsigned y, unsigned *w, unsigned *h) {

  if (x+x_tilesize > host_xres) {
    *w = host_xres - x;
  }
  else {
    *w = x_tilesize;
  }

  if (y+y_tilesize > host_yres) {
    *h = host_yres - y;
  }
  else {
    *h = y_tilesize;
  }

  return (Bit8u *)bxcocoagui->getVGAdisplayPtr() + y * host_pitch + x * ((host_bpp + 1) >> 3);

}


void bx_cocoa_gui_c::graphics_tile_update_in_place(unsigned x, unsigned y, unsigned w, unsigned h) {
  bxcocoagui->graphics_tile_update_in_place(x, y, w, h);
}


// Cocoa implementation of new text update API
void bx_cocoa_gui_c::set_font(bool lg) {
BX_INFO(("bx_cocoa_gui_c::set_font"));
  for (unsigned m = 0; m < 2; m++) {
    for (unsigned c = 0; c < 256; c++) {
      if (char_changed[m][c]) {
        // display knows about font size from dimension_update call
        // font pixel space 16x16
        bxcocoagui->set_font(c, m==1, m==0 ? (unsigned char *)&vga_charmap[0] : (unsigned char *)&vga_charmap[1]);
        char_changed[m][c] = 0;
      }
    }
  }

}


void bx_cocoa_gui_c::draw_char(Bit8u ch, Bit8u fc, Bit8u bc, Bit16u xc, Bit16u yc,
                       Bit8u fw, Bit8u fh, Bit8u fx, Bit8u fy,
                       bool gfxcharw9, Bit8u cs, Bit8u ce, bool curs, bool font2) {

  bxcocoagui->draw_char(curs, font2, fc, bc, ch, xc, yc, fw+fx, fh);

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

void bx_cocoa_gui_c::set_mouse_mode_absxy(bool mode) {
  // device->showAlertMessage("bx_cocoa_gui_c::set_mouse_mode_absxy", BX_ALERT_MSG_STYLE_CRIT);
  BX_INFO(("bx_cocoa_gui_c::set_mouse_mode_absxy %s", mode?"TRUE":"FALSE"));
}

#if BX_USE_IDLE_HACK
  // this is called from the CPU model when the HLT instruction is executed.
  void bx_cocoa_gui_c::sim_is_idle(void) {
    // device->handle_events();
    // sleep(5);
    // usleep(500);
  }

#endif





BxEvent * bx_cocoa_gui_c::notify_callback(void *unused, BxEvent *event) {

  // bx_param_c *param;

  switch (event->type) {
    case BX_SYNC_EVT_GET_PARAM: {
      // CI -> simulator -> CI
      printf("notify_callback BX_SYNC_EVT_GET_PARAM\n");
      break;
    }
    case BX_SYNC_EVT_ASK_PARAM: {
      // simulator -> CI -> simulator
      printf("notify_callback BX_SYNC_EVT_ASK_PARAM\n");
      break;
    }
    case BX_SYNC_EVT_TICK: {
      // simulator -> CI, wait for response.
      // printf("notify_callback BX_SYNC_EVT_TICK\n");
      break;
    }
    case BX_SYNC_EVT_LOG_DLG: {
      // simulator -> CI, wait for response.
      // mode is one of BX_LOG_DLG_ASK, BX_LOG_DLG_WARN, BX_LOG_DLG_QUIT
      printf("notify_callback BX_SYNC_EVT_LOG_DLG\n");
      break;
    }
    case BX_SYNC_EVT_GET_DBG_COMMAND: {
      // simulator -> CI, wait for response.
      printf("notify_callback BX_SYNC_EVT_GET_DBG_COMMAND\n");
      break;
    }
    case BX_SYNC_EVT_MSG_BOX: {
      // simulator -> CI, wait for response.
      // mode not used
      bxcocoagui->showModalInfo(event->u.logmsg.mode, event->u.logmsg.prefix, event->u.logmsg.msg);
      // printf("notify_callback BX_SYNC_EVT_MSG_BOX level=%d mode=%d prefix=%s msg=%s\n",
      // event->u.logmsg.level,
      // event->u.logmsg.mode,
      // event->u.logmsg.prefix,
      // event->u.logmsg.msg
      // );
      break;
    }
    case BX_SYNC_EVT_ML_MSG_BOX: {
      // simulator -> CI, do not wait for response.
      printf("notify_callback BX_SYNC_EVT_ML_MSG_BOX\n");
      break;
    }
    case BX_SYNC_EVT_ML_MSG_BOX_KILL: {
      // simulator -> CI, do not wait for response.
      printf("notify_callback BX_SYNC_EVT_ML_MSG_BOX_KILL\n");
      break;
    }

    case BX_ASYNC_EVT_KEY: {
      // vga window -> simulator
      printf("notify_callback BX_ASYNC_EVT_KEY\n");
      break;
    }
    case BX_ASYNC_EVT_MOUSE: {
      // vga window -> simulator
      printf("notify_callback BX_ASYNC_EVT_MOUSE\n");
      break;
    }
    case BX_ASYNC_EVT_SET_PARAM: {
      // CI -> simulator
      printf("notify_callback BX_ASYNC_EVT_SET_PARAM\n");
      break;
    }
    case BX_ASYNC_EVT_LOG_MSG: {
      // simulator -> CI
      // processed by cocoaconsole.cc
      break;
    }
    case BX_ASYNC_EVT_DBG_MSG: {
      // simulator -> CI
      printf("notify_callback BX_ASYNC_EVT_DBG_MSG\n");
      break;
    }
    case BX_ASYNC_EVT_VALUE_CHANGED: {
      // simulator -> CI
      printf("notify_callback BX_ASYNC_EVT_VALUE_CHANGED\n");
      break;
    }
    case BX_ASYNC_EVT_TOOLBAR: {
      // CI -> simulator
      printf("notify_callback BX_ASYNC_EVT_TOOLBAR\n");
      break;
    }
    case BX_ASYNC_EVT_STATUSBAR: {
      // simulator -> CI
      printf("notify_callback BX_ASYNC_EVT_STATUSBAR\n");
      break;
    }
    case BX_ASYNC_EVT_REFRESH: {
      // simulator -> CI
      printf("notify_callback BX_ASYNC_EVT_REFRESH\n");
      break;
    }
    case BX_ASYNC_EVT_QUIT_SIM: {
      // simulator -> CI
      printf("notify_callback BX_ASYNC_EVT_QUIT_SIM\n");
      break;
    }

    // case BX_SYNC_EVT_LOG_DLG: {
    //   device->showAlertMessage(event->u.logmsg.msg, BX_ALERT_MSG_STYLE_CRIT);
    //   return event;
    // }
    // case BX_SYNC_EVT_MSG_BOX: {
    //   device->showAlertMessage(event->u.logmsg.msg, BX_ALERT_MSG_STYLE_CRIT);
    //   return event;
    // }
    // case BX_SYNC_EVT_ML_MSG_BOX: {
    //   device->showAlertMessage(event->u.logmsg.msg, BX_ALERT_MSG_STYLE_CRIT);
    //   return event;
    // }
    // case BX_SYNC_EVT_ML_MSG_BOX_KILL: {
    //   device->showAlertMessage(event->u.logmsg.msg, BX_ALERT_MSG_STYLE_CRIT);
    //   return event;
    // }
    // case BX_SYNC_EVT_ASK_PARAM: {
    //   device->showAlertMessage(event->u.logmsg.msg, BX_ALERT_MSG_STYLE_CRIT);
    //   return event;
    // }

    // case BX_ASYNC_EVT_LOG_MSG: // maybe have a window collecting the logs ?
    // case BX_SYNC_EVT_TICK: // called periodically by siminterface.
    // case BX_ASYNC_EVT_REFRESH: // called when some bx_param_c parameters have changed.
      // fall into default case
    default:
      return (*old_callback)(old_callback_arg, event);
  }

  return (*old_callback)(old_callback_arg, event);

}






























#endif /* if BX_WITH_COCOA */
