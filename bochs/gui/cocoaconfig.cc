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

#if BX_USE_COCOACONFIG

static int cocoa_ci_callback(void *userdata, ci_command_t command);
static BxEvent* cocoa_notify_callback(void *unused, BxEvent *event);

PLUGIN_ENTRY_FOR_MODULE(cocoaconfig)
{
  if (mode == PLUGIN_INIT) {
    SIM->register_configuration_interface("cocoaconfig", cocoa_ci_callback, NULL);
    SIM->set_notify_callback(cocoa_notify_callback, NULL);
  } else if (mode == PLUGIN_PROBE) {
    return (int)PLUGTYPE_CI;
  }
  return 0; // Success
}











/**
 * cocoa_ci_callback
 */
static int cocoa_ci_callback(void *userdata, ci_command_t command) {

  switch (command)
  {
    case CI_START: {
      break;
    }
    case CI_RUNTIME_CONFIG: {
      break;
    }
    case CI_SHUTDOWN: {
      break;
    }
  }

  return 0;

}

/**
 * cocoa_notify_callback
 */
static BxEvent* cocoa_notify_callback(void *unused, BxEvent *event) {

  event->retcode = -1;
  switch (event->type)
  {
    case BX_SYNC_EVT_LOG_DLG: {
      return event;
    }
    case BX_SYNC_EVT_MSG_BOX: {
      return event;
    }
    case BX_SYNC_EVT_ML_MSG_BOX: {
      return event;
    }
    case BX_SYNC_EVT_ML_MSG_BOX_KILL: {
      return event;
    }
    case BX_SYNC_EVT_ASK_PARAM: {
      return event;
    }
    case BX_SYNC_EVT_TICK: {
      // called periodically by siminterface.
      event->retcode = 0;
      // fall into default case
    }
    default: {
      return event;
    }
  }

}

#endif /* BX_USE_COCOACONFIG */
