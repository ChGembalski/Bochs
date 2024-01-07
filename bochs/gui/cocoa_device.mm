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
#include "cocoa_device.h"

// C++ Wrapper for NSApplication

struct BXGuiCocoaDeviceImpl {
  NSApplication * BXNSApp;
};


// Class BXGuiCocoaDevice

/**
 * BXGuiCocoaDevice CTor
 */
BXGuiCocoaDevice::BXGuiCocoaDevice() : BXCocoaDevice(new BXGuiCocoaDeviceImpl) {
  BXCocoaDevice->BXNSApp = [NSApplication sharedApplication];
  // test create window
  BXview = new BXGuiCocoaView();
  BXwindow = new BXGuiCocoaWindow(BXview);
  [BXCocoaDevice->BXNSApp setDelegate:BXwindow->getWindow()];
}

/**
 * BXGuiCocoaDevice DTor
 */
BXGuiCocoaDevice::~BXGuiCocoaDevice() {

  if (BXCocoaDevice) {
    [BXCocoaDevice->BXNSApp release];
  }

}

/**
 * run once
 * NSEvent loop processing
 */
void BXGuiCocoaDevice::run_once() {
  @autoreleasepool {

    NSEvent* ev;

    do {
      ev = [NSApp nextEventMatchingMask: NSEventMaskAny
                              untilDate: nil
                                 inMode: NSDefaultRunLoopMode
                                dequeue: YES];

      if (ev) {
        // handle events here
        [NSApp sendEvent: ev];
      }
    } while (ev);

  }
}

/**
 * run_terminate
 * hopefully cleanup
 */
void BXGuiCocoaDevice::run_terminate() {
  [BXCocoaDevice->BXNSApp terminate:nil];
}
