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

// BOCHS NEW DEBUGGER Ver 1.0
// written by Christoph Gembalski <christoph@gembalski.de>

#include "config.h"

#if BX_DEBUGGER && !BX_DEBUGGER_GUI && BX_NEW_DEBUGGER_GUI

  #include "new_dbg.h"
  #include "bochs.h"
  #include "siminterface.h"

  extern void new_dbg_handler_custom(bool init);
  extern bx_dbg_gui_c * bx_dbg_new;
  extern bx_list_c * root_param;

  static bxevent_handler old_callback = NULL;
  static void * old_callback_arg = NULL;



  const char * dbg_regnames[] = {
#if BX_SUPPORT_X86_64 == 0
    "EAX", "EBX", "ECX", "EDX", "ESI", "EDI", "EBP", "ESP", "EIP",
#else
    "RAX", "RBX", "RCX", "RDX", "RSI", "RDI", "RBP", "RSP", "RIP",
    "R8", "R9", "R10", "R11", "R12", "R13", "R14", "R15",
#endif
    "EFLAGS",
    "CS.selector", "DS.selector", "ES.selector", "FS.selector", "GS.selector",

    "GDTR.base", "GDTR.limit", "IDTR.base", "IDTR.limit",
    "LDTR.base", "TR.base",

    "CR0", "CR2", "CR3",
#if BX_CPU_LEVEL >= 5
    "CR4",
#endif /* BX_CPU_LEVEL >= 5 */

#if BX_CPU_LEVEL >= 6
    "MSR.EFER",
#endif /* BX_CPU_LEVEL >= 6 */

#if BX_SUPPORT_FPU
    "FPU.st0.fraction", "FPU.st0.exp", "FPU.st1.fraction", "FPU.st1.exp",
    "FPU.st2.fraction", "FPU.st2.exp", "FPU.st3.fraction", "FPU.st3.exp",
    "FPU.st4.fraction", "FPU.st4.exp", "FPU.st5.fraction", "FPU.st5.exp",
    "FPU.st6.fraction", "FPU.st6.exp", "FPU.st7.fraction", "FPU.st7.exp",
#endif /* BX_SUPPORT_FPU */

#if BX_CPU_TEST_REGISTER
#if BX_CPU_LEVEL >= 3 && BX_CPU_LEVEL <= 6
    "TR3", "TR4", "TR5",
#if BX_CPU_LEVEL >= 4
    "TR6", "TR7",
#endif /* BX_CPU_LEVEL >= 4 */
#endif /* BX_CPU_LEVEL >= 3 && BX_CPU_LEVEL <= 6 */
#endif /* BX_CPU_TEST_REGISTER */

#if BX_CPU_LEVEL >= 6

    "SSE.xmm00_0", "SSE.xmm01_0", "SSE.xmm02_0", "SSE.xmm03_0", "SSE.xmm04_0",
    "SSE.xmm05_0", "SSE.xmm06_0", "SSE.xmm07_0",
#if BX_SUPPORT_X86_64
    "SSE.xmm08_0", "SSE.xmm09_0", "SSE.xmm10_0", "SSE.xmm11_0", "SSE.xmm12_0",
    "SSE.xmm13_0", "SSE.xmm14_0", "SSE.xmm15_0",
#endif /* BX_SUPPORT_X86_64 */

    "SSE.xmm00_1", "SSE.xmm01_1", "SSE.xmm02_1", "SSE.xmm03_1", "SSE.xmm04_1",
    "SSE.xmm05_1", "SSE.xmm06_1", "SSE.xmm07_1",
#if BX_SUPPORT_X86_64
    "SSE.xmm08_1", "SSE.xmm09_1", "SSE.xmm10_1", "SSE.xmm11_1", "SSE.xmm12_1",
    "SSE.xmm13_1", "SSE.xmm14_1", "SSE.xmm15_1",
#endif /* BX_SUPPORT_X86_64 */

#endif /* BX_CPU_LEVEL >= 6 */

    "DR0", "DR1", "DR2", "DR3", "DR6", "DR7",

    NULL

  };










  // internal callback handler
  BxEvent *new_dbg_notify_callback(void *unused, BxEvent *event)
  {
    switch (event->type)
    {
      default: {
        return (*old_callback)(old_callback_arg, event);
      }
    }
  }

  // internal setup
  void InitDebugDialog() {
    new_dbg_handler_custom(true);

    // setup new callback
    SIM->get_notify_callback(&old_callback, &old_callback_arg);
    assert (old_callback != NULL);
    SIM->set_notify_callback(new_dbg_notify_callback, NULL);

    // init internal
    bx_dbg_new->init_internal();

  }

  // internal cleanup
  void CloseDebugDialog() {

    // TODO : write debugger configuration

    new_dbg_handler_custom(false);

    // restore old callback
    SIM->set_notify_callback(old_callback, old_callback_arg);


  }

////////////////////////////////////////////////////////////////////////////////
// bx_dbg_gui_c
////////////////////////////////////////////////////////////////////////////////

/**
 * CTor
 */
bx_dbg_gui_c::bx_dbg_gui_c(void) {

  this->bCpuModeHasChanged = true;
  this->currentCPUNo = 0;
  this->CPUcount = BX_SMP_PROCESSORS;

  this->init_register_refs();
}

/**
 * DTor
 */
bx_dbg_gui_c::~bx_dbg_gui_c(void) {

  if (this->smp_info.cpu_info != NULL) {
    free(this->smp_info.cpu_info);
  }
}

/**
 * init_internal
 */
void bx_dbg_gui_c::init_internal(void) {


  this->read_dbg_gui_config();

}






/**
 * read_dbg_gui_config
 */
void bx_dbg_gui_c::read_dbg_gui_config(void) {

  FILE * fd;
  char line[512];
  char * ret;
  bool format_checked;

  fd = fopen("bx_new_dbg.cfg", "r");
  if (fd == NULL) return;

  format_checked = false;
  do {
    ret = fgets(line, sizeof(line)-1, fd);
    line[sizeof(line) - 1] = '\0';
    size_t len = strlen(line);
    if ((len>0) && (line[len-1] < ' ')) {
      line[len-1] = '\0';
    }
    if ((ret != NULL) && (strlen(line) > 0)) {
      if (!format_checked) {
        if (!strncmp(line, "# bx_new_dbg_cfg", 16)) {
          format_checked = true;
        } else {
          break;
        }
      } else {
        char * param;
        char * val;

        if (line[0] == '#') {
          continue;
        }
        param = strtok(line, "=");
        if (param != NULL) {
          param = strip_whitespace(param);
          val = strtok(NULL, "");
          if (val == NULL) {
            fprintf(stderr, "bx_new_dbg.ini: missing value for parameter '%s'\n", param);
            continue;
          }
          // here process the param and val


          // last option involve parse_os_setting
          if (!parse_os_setting(param, val)) {
            fprintf(stderr, "bx_new_dbg.ini: unknown option '%s'\n", line);
          }
        } else {
          continue;
        }
      }
    }
  } while (!feof(fd));
  fclose(fd);

}

/**
 * write_dbg_gui_config
 */
void bx_dbg_gui_c::write_dbg_gui_config(void) {

  FILE *fd;

  fd = fopen("bx_new_dbg.cfg", "w");
  if (fd == NULL) return;
  fprintf(fd, "# bx_new_dbg_cfg\n");

  fprintf(fd, "# bx_new_dbg_cfg\n");
  fclose(fd);

}

/**
 * strip_whitespace
 */
char * bx_dbg_gui_c::strip_whitespace(char * s) {

  char * first_valid;
  char * last_valid;
  size_t s_len;

  first_valid = s;
  s_len = strlen(s);
  last_valid = s + ((s_len > 0) ? s_len-1 : 0);

  while ((first_valid != last_valid) && (*first_valid == ' ' | *first_valid == '\t')) {
    first_valid++;
  }

  while ((last_valid != first_valid) && (*last_valid == ' ' | *last_valid == '\t')) {
    *last_valid = '\0';
    last_valid--;
  }

  return (first_valid);

}



/**
 * init_register_refs
 */
void bx_dbg_gui_c::init_register_refs(void) {

  bx_list_c * cpu_list;

  this->smp_info.cpu_count = BX_SMP_PROCESSORS;
  this->smp_info.cpu_info = (bx_cpu_info_t *)malloc( BX_SMP_PROCESSORS * sizeof(bx_cpu_info_t));
  memset(this->smp_info.cpu_info, 0, BX_SMP_PROCESSORS * sizeof(bx_cpu_info_t));
  // now fill the bx_cpu_info_t struct each cpu
  for (int cpuNo = 0; cpuNo<BX_SMP_PROCESSORS; cpuNo++) {

    char cpuname[16];
    int cpuregno;

    snprintf(cpuname, 16, "bochs.cpu%d", cpuNo);
    cpu_list = (bx_list_c *) SIM->get_param(cpuname, root_param);

    // now fill the regs ...
    cpuregno = 0;
    while (dbg_regnames[cpuregno] != NULL) {
      this->smp_info.cpu_info[cpuNo].regs[cpuregno] = SIM->get_param_num(dbg_regnames[cpuregno], cpu_list);
      cpuregno++;
    }

  }
}






#endif
