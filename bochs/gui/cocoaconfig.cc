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

#include "config.h"

#if BX_USE_COCOACONFIG

#include "bochs.h"
#include "param_names.h"
#include "iodev.h"

#include "cocoa_bochs.h"

static int cocoa_ci_callback(void *userdata, ci_command_t command);
static BxEvent* cocoa_notify_callback(void *unused, BxEvent *event);

PLUGIN_ENTRY_FOR_MODULE(cocoaconfig)
{
  if (mode == PLUGIN_INIT) {
    // create BXGuiCocoaApplication ref
    bxcocoagui = new BXGuiCocoaApplication();
    SIM->register_configuration_interface("cocoaconfig", cocoa_ci_callback, NULL);
    SIM->set_log_viewer(true);
    // this callback is captured by cocoa.cc
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
      if (SIM->get_param_enum(BXPN_BOCHS_START)->get() == BX_QUICK_START) {
        SIM->begin_simulation(main_argc, main_argv);
        // we don't expect it to return, but if it does, quit
        SIM->quit_sim(1);
      } else {
        bxcocoagui->showWindow(BX_GUI_WINDOW_CONFIGURATION, true);
        bxcocoagui->activateWindow(BX_GUI_WINDOW_CONFIGURATION);
        if (bxcocoagui->getProperty(BX_PROPERTY_START_SIM, true) == 1) {
          bxcocoagui->showWindow(BX_GUI_WINDOW_CONFIGURATION, false);
          SIM->begin_simulation(main_argc, main_argv);
        }
        SIM->quit_sim(1);
      }
      break;
    }
    case CI_RUNTIME_CONFIG: {
      if (!bx_gui->has_gui_console()) {
        bxcocoagui->showWindow(BX_GUI_WINDOW_CONFIGURATION, true);
        bxcocoagui->activateWindow(BX_GUI_WINDOW_CONFIGURATION);
        if (bxcocoagui->getProperty(BX_PROPERTY_EXIT_SIM, false) == 1) {
          bxcocoagui->showWindow(BX_GUI_WINDOW_CONFIGURATION, false);
          bx_user_quit = 1;
#if !BX_DEBUGGER
          bx_atexit();
          SIM->quit_sim(1);
#else
          bx_dbg_exit(1);
#endif
          return -1;
        }
      }
      break;
    }
    case CI_SHUTDOWN: {
      // cleanup here?
      // send a cleanup call to bxcocoagui ?????
      delete bxcocoagui;
      break;
    }
  }

  return CI_OK;

}

/**
 * cocoa_notify_callback
 */
static BxEvent* cocoa_notify_callback(void *unused, BxEvent *event) {

  event->retcode = -1;
  switch (event->type)
  {
    case BX_ASYNC_EVT_DBG_MSG:
    case BX_ASYNC_EVT_LOG_MSG: {
      bxcocoagui->postLogMessage(event->u.logmsg.level, event->u.logmsg.mode, event->u.logmsg.prefix, event->u.logmsg.msg);
      event->retcode = 0;
      return event;
    }
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
