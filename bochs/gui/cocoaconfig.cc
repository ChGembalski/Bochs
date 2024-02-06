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

#define CI_PATH_LENGTH 512

static int cocoa_ci_callback(void *userdata, ci_command_t command);
static BxEvent* cocoa_notify_callback(void *unused, BxEvent *event);

PLUGIN_ENTRY_FOR_MODULE(cocoaconfig)
{
  if (mode == PLUGIN_INIT) {
    SIM->register_configuration_interface("cocoaconfig", cocoa_ci_callback, NULL);
    SIM->set_log_viewer(true);
    
    // SIM->register_runtime_config_handler()
  } else if (mode == PLUGIN_FINI) {
    // not safe to delete here
//    delete bxcocoagui;
  } else if (mode == PLUGIN_PROBE) {
    return (int)PLUGTYPE_CI;
  }
  return 0; // Success
}

/**
 * need to init gui support on startup
 * called in bx main to supply gui feedback features
 */
void preinit_cocoa_notify_callback(void) {
    // create BXGuiCocoaApplication ref
    bxcocoagui = new BXGuiCocoaApplication();
    // this callback is captured by cocoa.cc
    SIM->set_notify_callback(cocoa_notify_callback, NULL);
}







/**
 * cocoa_ci_callback
 */
static int cocoa_ci_callback(void *userdata, ci_command_t command) {

  switch (command)
  {
    case CI_START: {
      if (SIM->get_param_enum(BXPN_BOCHS_START)->get() == BX_QUICK_START) {
        bxcocoagui->setSimulationState(SIM_STOP);
        bxcocoagui->showWindow(BX_GUI_WINDOW_LOGGING, false);
        bxcocoagui->activateMenu(BX_PROPERTY_START_SIM, false);
        bxcocoagui->activateMenu(BX_PROPERTY_CONFIG_LOAD, false);
        bxcocoagui->activateMenu(BX_PROPERTY_CONFIG_SAVE, false);
        bxcocoagui->activateMenu(BX_PROPERTY_CONFIG_RESET, false);
        bxcocoagui->showWindow(BX_GUI_WINDOW_CONFIGURATION, false);
        bxcocoagui->setSimulationState(SIM_RUN);
        SIM->begin_simulation(main_argc, main_argv);
        // we don't expect it to return, but if it does, quit
        SIM->quit_sim(1);
      } else {
        bxcocoagui->setSimulationState(SIM_STOP);
        bxcocoagui->showWindow(BX_GUI_WINDOW_LOGGING, true);
        bxcocoagui->showWindow(BX_GUI_WINDOW_CONFIGURATION, true);
        bxcocoagui->activateWindow(BX_GUI_WINDOW_CONFIGURATION);
ci_start_wait:
        bxcocoagui->waitPropertySet(5,
          BX_PROPERTY_START_SIM,
          BX_PROPERTY_QUIT_SIM,
          BX_PROPERTY_CONFIG_LOAD,
          BX_PROPERTY_CONFIG_SAVE,
          BX_PROPERTY_CONFIG_RESET
        );

        if (bxcocoagui->getProperty(BX_PROPERTY_START_SIM, false) == 1) {
          bxcocoagui->activateMenu(BX_PROPERTY_START_SIM, false);
          bxcocoagui->activateMenu(BX_PROPERTY_CONFIG_LOAD, false);
          bxcocoagui->activateMenu(BX_PROPERTY_CONFIG_SAVE, false);
          bxcocoagui->activateMenu(BX_PROPERTY_CONFIG_RESET, false);
          bxcocoagui->showWindow(BX_GUI_WINDOW_CONFIGURATION, false);
          bxcocoagui->setSimulationState(SIM_RUN);
          SIM->begin_simulation(main_argc, main_argv);
          // we don't expect it to return, but if it does, quit
          SIM->quit_sim(1);
        }
        if (bxcocoagui->getProperty(BX_PROPERTY_QUIT_SIM, false) == 1) {
          SIM->quit_sim(1);
        }
        if (bxcocoagui->getProperty(BX_PROPERTY_CONFIG_LOAD, false) == 1) {
          char cfg_fname[CI_PATH_LENGTH] = {0};
          if (SIM->ask_filename(cfg_fname, CI_PATH_LENGTH, "#config#file#", "", bx_param_bytestring_c::IS_FILENAME)) {
            SIM->reset_all_param();
            if (SIM->read_rc(cfg_fname) >= 0) {
              SIM->get_param_enum(BXPN_BOCHS_START)->set(BX_RUN_START);
            }
          }
        }
        if (bxcocoagui->getProperty(BX_PROPERTY_CONFIG_SAVE, false) == 1) {
          char cfg_fname[CI_PATH_LENGTH] = {0};
          if (SIM->ask_filename(cfg_fname, CI_PATH_LENGTH, "#config#file#", "", bx_param_bytestring_c::SAVE_FILE_DIALOG)) {
            if (SIM->write_rc(cfg_fname, 1) >= 0) {
              SIM->get_param_enum(BXPN_BOCHS_START)->set(BX_RUN_START);
            }
          }
        }
        if (bxcocoagui->getProperty(BX_PROPERTY_CONFIG_RESET, false) == 1) {
           SIM->reset_all_param();
           SIM->get_param_enum(BXPN_BOCHS_START)->set(BX_EDIT_START);
        }

        goto ci_start_wait;
      }
      break;
    }
    case CI_RUNTIME_CONFIG: {
      // WARNING !!! this is called from the BX_GUI_WINDOW_VGA_DISPLAY
      // now on a separate thread
      // so we have to stop the simulation
      // hide the sim window -> bring up the config
      // set state to pause -> and then ? how to get it back running again?
      if (!bx_gui->has_gui_console()) {
//         // TODO : get Simulation State
//         bxcocoagui->setSimulationState(SIM_PAUSE);
//         bxcocoagui->showWindow(BX_GUI_WINDOW_CONFIGURATION, true);
//         bxcocoagui->activateWindow(BX_GUI_WINDOW_CONFIGURATION);
//         // need to wait for one of BX_PROPERTY_START_SIM | BX_PROPERTY_EXIT_SIM | BX_PROPERTY_CONT_SIM
// loopOn:
//         bxcocoagui->getPropertySet(true, 3, BX_PROPERTY_START_SIM, BX_PROPERTY_EXIT_SIM, BX_PROPERTY_CONT_SIM);
//         // check the properties
//         if (bxcocoagui->getProperty(BX_PROPERTY_START_SIM, false) == 1) {
//           printf("BX_PROPERTY_START_SIM");
//         } else if (bxcocoagui->getProperty(BX_PROPERTY_CONT_SIM, false) == 1) {
//           printf("BX_PROPERTY_CONT_SIM");
//         } else if (bxcocoagui->getProperty(BX_PROPERTY_EXIT_SIM, false) == 1) {
//           printf("BX_PROPERTY_EXIT_SIM");
//         } else {
//           printf("NON VALID");
//           sleep(1);
//           goto loopOn;
        // }



//         if (bxcocoagui->getProperty(BX_PROPERTY_EXIT_SIM, false) == 1) {
//           bxcocoagui->activateMenu(BX_PROPERTY_EXIT_SIM, false);
//           bxcocoagui->activateMenu(BX_PROPERTY_START_SIM, true);
//           bxcocoagui->showWindow(BX_GUI_WINDOW_CONFIGURATION, false);
//           bx_user_quit = 1;
// #if !BX_DEBUGGER
//           bx_atexit();
//           SIM->quit_sim(1);
// #else
//           bx_dbg_exit(1);
// #endif
//           return -1;
//         } else {
//           printf("NO CONSOLE GUI!!!!!!!!");
//         }
      }
      break;
    }
    case CI_SHUTDOWN: {
      printf("someone hit us to terminate");
      bxcocoagui->setSimulationState(SIM_TERMINATE);
      // cleanup here?
      // send a cleanup call to bxcocoagui ?????
      //delete bxcocoagui;
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
      // simulator -> CI
      bxcocoagui->postLogMessage(event->u.logmsg.level, event->u.logmsg.mode, event->u.logmsg.prefix, event->u.logmsg.msg);
      event->retcode = 0;// is ignored
      return event;
    }
    case BX_SYNC_EVT_LOG_DLG: {
      // simulator -> CI, wait for response.
      bxcocoagui->showModalQuestion(event->u.logmsg.level, event->u.logmsg.prefix, event->u.logmsg.msg, &event->retcode);
      return event;
    }
    case BX_SYNC_EVT_MSG_BOX: {
      printf("BX_SYNC_EVT_MSG_BOX\n");
      return event;
    }
    case BX_SYNC_EVT_ML_MSG_BOX: {
      printf("BX_SYNC_EVT_ML_MSG_BOX\n");
      return event;
    }
    case BX_SYNC_EVT_ML_MSG_BOX_KILL: {
      printf("BX_SYNC_EVT_ML_MSG_BOX_KILL\n");
      return event;
    }
    case BX_SYNC_EVT_ASK_PARAM: {
      printf("BX_SYNC_EVT_ASK_PARAM\n");
      if (event->u.param.param->get_type() == BXT_LIST) {
        bx_list_c * list_param;

        list_param = (bx_list_c *)event->u.param.param;
        printf("##list [%p] [%s] [%s] [%s] [%s] [%0X] [%d]\n",
        list_param,
        list_param->get_name(), list_param->get_label(), list_param->get_description(), list_param->get_title(),
        list_param->get_choice(), list_param->get_size());
      }
      bxcocoagui->showModalParamRequest(event->u.param.param, &event->retcode);
      return event;
    }
    case BX_SYNC_EVT_TICK: {
      // check if stop was set
      // if so return -1 to exit
      if (bxcocoagui->getProperty(BX_PROPERTY_QUIT_SIM, false) == 1) {
        event->retcode = -1;
      } else {
        // called periodically by siminterface.
        event->retcode = 0;
      }
      // fall into default case
    }
    default: {
      return event;
    }
  }

}

#endif /* BX_USE_COCOACONFIG */
