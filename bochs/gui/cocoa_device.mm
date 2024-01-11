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
#include "cocoa_device.h"

// C++ Wrapper for NSApplication

struct BXGuiCocoaDeviceImpl {
  NSApplication * BXNSApp;
};


// Class BXGuiCocoaDevice

/**
 * BXGuiCocoaDevice CTor
 */
BXGuiCocoaDevice::BXGuiCocoaDevice(unsigned x, unsigned y, unsigned headerbar_y) : BXCocoaDevice(new BXGuiCocoaDeviceImpl) {
  BXCocoaDevice->BXNSApp = [NSApplication sharedApplication];
  // create main window
  BXwindow = new BXGuiCocoaWindow(x, y, headerbar_y);
  BXL_DEBUG((@"NSApp Window created"));

  [BXCocoaDevice->BXNSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

  id menubar = [[NSMenu new] autorelease];
  id appMenuItem = [[NSMenuItem new] autorelease];
  [menubar addItem:appMenuItem];
  [BXCocoaDevice->BXNSApp setMainMenu:menubar];

  // Then we add the quit item to the menu. Fortunately the action is simple since terminate: is
  // already implemented in NSApplication and the NSApplication is always in the responder chain.
  id appMenu = [[NSMenu new] autorelease];
  id appName = [[NSProcessInfo processInfo] processName];
  id quitTitle = [@"Quit " stringByAppendingString:appName];
  id quitMenuItem = [[[NSMenuItem alloc] initWithTitle:quitTitle
                                                action:@selector(terminate:) keyEquivalent:@"q"] autorelease];
  [appMenu addItem:quitMenuItem];
  [appMenuItem setSubmenu:appMenu];

  // TODO : need a icon ...
}

/**
 * BXGuiCocoaDevice DTor
 */
BXGuiCocoaDevice::~BXGuiCocoaDevice() {

  if (BXwindow) {
    delete BXwindow;
  }
  if (BXCocoaDevice) {
    [BXCocoaDevice->BXNSApp release];
  }

}

/**
 * run once
 * NSEvent loop processing
 */
void BXGuiCocoaDevice::handle_events() {
  @autoreleasepool {

    NSEvent* ev;

    do {
      ev = [BXCocoaDevice->BXNSApp nextEventMatchingMask: NSEventMaskAny
                              untilDate: nil
                                 inMode: NSDefaultRunLoopMode
                                dequeue: YES];

      if (ev) {
        // handle events here
        [BXCocoaDevice->BXNSApp sendEvent: ev];
      }
      [BXCocoaDevice->BXNSApp updateWindows];
    } while (ev);

  }
}

/**
 * run_terminate
 * hopefully cleanup
 */
void BXGuiCocoaDevice::run_terminate() {
  BXL_DEBUG((@"NSApp terminate"));
  // close all windows
  if (BXwindow) {
    delete BXwindow;
    BXwindow = NULL;
  }
  [BXCocoaDevice->BXNSApp terminate:nil];
}

/**
 * create_bitmap forwarding
 */
unsigned BXGuiCocoaDevice::create_bitmap(const unsigned char *bmap, unsigned xdim, unsigned ydim) {
  return (BXwindow->create_bitmap(bmap, xdim, ydim));
}

/**
 * headerbar_bitmap forwarding
 */
unsigned BXGuiCocoaDevice::headerbar_bitmap(unsigned bmap_id, unsigned alignment, void (*f)(void)) {
  return (BXwindow->headerbar_bitmap(bmap_id, alignment, f));
}

/**
 * show_headerbar forwarding
 */
void BXGuiCocoaDevice::show_headerbar(void) {
  BXwindow->show_headerbar();
}

/**
 * dimension_update forwarding
 */
void BXGuiCocoaDevice::dimension_update(unsigned x, unsigned y, unsigned fheight, unsigned fwidth, unsigned bpp) {
  BXwindow->dimension_update(x, y, fheight, fwidth, bpp);
}

/**
 * render forwarding
 */
void BXGuiCocoaDevice::render(void) {
  BXwindow->render();
}

/**
 * palette_change forwarding
 */
bool BXGuiCocoaDevice::palette_change(unsigned char index, unsigned char red, unsigned char green, unsigned char blue) {
  return (BXwindow->palette_change(index, red, green, blue));
}

/**
 * clear_screen forwarding
 */
void BXGuiCocoaDevice::clear_screen(void) {
  BXwindow->clear_screen();
}

/**
 * replace_bitmap forwarding
 */
void BXGuiCocoaDevice::replace_bitmap(unsigned hbar_id, unsigned bmap_id) {
  BXwindow->replace_bitmap(hbar_id, bmap_id);
}

/**
 * setup_charmap forwarding
 */
void BXGuiCocoaDevice::setup_charmap(unsigned char *charmapA, unsigned char *charmapB) {
  BXwindow->setup_charmap(charmapA, charmapB);
}

/**
 * set_font
 */
void BXGuiCocoaDevice::set_font(unsigned pos, unsigned char *charmapA, unsigned char *charmapB) {
  BXwindow->set_font(pos, charmapA, charmapB);
}

/**
 * draw_char forwarding
 */
void BXGuiCocoaDevice::draw_char(bool font2, unsigned char fgcolor, unsigned char bgcolor, unsigned short int charpos, unsigned short int x, unsigned short int y, unsigned char w, unsigned char h) {
  BXwindow->draw_char(font2, fgcolor, bgcolor, charpos, x, y, w, h);
}









//
