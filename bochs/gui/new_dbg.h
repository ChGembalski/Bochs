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

#ifndef BX_NEW_DBG_DEF_H
#define BX_NEW_DBG_DEF_H

#if BX_DEBUGGER && !BX_DEBUGGER_GUI && BX_NEW_DEBUGGER_GUI

#include <stdio.h>
#include "bochs.h"
#include "siminterface.h"
// #include "bx_debug/debug.h"
// #include "memory/memory-bochs.h"
// #include "pc_system.h"
#include "cpu/cpu.h"

#define IMPLEMENT_GUI_DEBUGGER(debugger_class) \
debugger_class * bx_dbg_new; \
void new_dbg_handler_custom(bool init) { \
  if (init) { \
    bx_dbg_new = new debugger_class(); \
  } else { \
    delete bx_dbg_new; \
  } \
}

#define DECLARE_GUI_DEBUGGER_VIRTUAL_METHODS()                                 \
protected:                                                                     \
  virtual void init_os_depended(void);                                         \



#define DECLARE_GUI_DEBUGGER_OPTIONAL_VIRTUAL_METHODS()                        \
  virtual bool parse_os_setting(const char * param, const char * value)        \
  virtual void write_os_setting(FILE * fd)


typedef enum {

  RAX = 0,
  RBX,
  RCX,
  RDX,
  RSI,
  RDI,
  RBP,
  RSP,
  RIP,

  EAX = RAX,  // only if someone will use them
  EBX,
  ECX,
  EDX,
  ESI,
  EDI,
  EBP,
  ESP,
  EIP,

#if BX_SUPPORT_X86_64 == 1
  R8,
  R9,
  R10,
  R11,
  R12,
  R13,
  R14,
  R15,
#endif /* BX_SUPPORT_X86_64 == 1 */

  EFLAGS,
  CS,
  DS,
  ES,
  FS,
  GS,

  GDTR_BASE,
  GDTR_LIMIT,
  IDTR_BASE,
  IDTR_LIMIT,
  LDTR,
  TR,

  CR0,
  CR2,
  CR3,
#if BX_CPU_LEVEL >= 5
  CR4,
#endif /* BX_CPU_LEVEL >= 5 */

#if BX_CPU_LEVEL >= 6
  MSR_EFER,
#endif /* BX_CPU_LEVEL >= 6 */

#if BX_SUPPORT_FPU
  FPU_ST0_F,
  FPU_ST0_E,
  FPU_ST1_F,
  FPU_ST1_E,
  FPU_ST2_F,
  FPU_ST2_E,
  FPU_ST3_F,
  FPU_ST3_E,
  FPU_ST4_F,
  FPU_ST4_E,
  FPU_ST5_F,
  FPU_ST5_E,
  FPU_ST6_F,
  FPU_ST6_E,
  FPU_ST7_F,
  FPU_ST7_E,
#endif /* BX_SUPPORT_FPU */

#if BX_CPU_TEST_REGISTER
#if BX_CPU_LEVEL >= 3 && BX_CPU_LEVEL <= 6
  TR3,
  TR4,
  TR5,
#if BX_CPU_LEVEL >= 4
  TR6,
  TR7,
#endif /* BX_CPU_LEVEL >= 4 */
#endif /* BX_CPU_LEVEL >= 3 && BX_CPU_LEVEL <= 6 */
#endif /* BX_CPU_TEST_REGISTER */

#if BX_CPU_LEVEL >= 6

  SSE_XMM00_0,
  SSE_XMM01_0,
  SSE_XMM02_0,
  SSE_XMM03_0,
  SSE_XMM04_0,
  SSE_XMM05_0,
  SSE_XMM06_0,
  SSE_XMM07_0,
#if BX_SUPPORT_X86_64
  SSE_XMM08_0,
  SSE_XMM09_0,
  SSE_XMM10_0,
  SSE_XMM11_0,
  SSE_XMM12_0,
  SSE_XMM13_0,
  SSE_XMM14_0,
  SSE_XMM15_0,
#endif /* BX_SUPPORT_X86_64 */

  SSE_XMM00_1,
  SSE_XMM01_1,
  SSE_XMM02_1,
  SSE_XMM03_1,
  SSE_XMM04_1,
  SSE_XMM05_1,
  SSE_XMM06_1,
  SSE_XMM07_1,
#if BX_SUPPORT_X86_64
  SSE_XMM08_1,
  SSE_XMM09_1,
  SSE_XMM10_1,
  SSE_XMM11_1,
  SSE_XMM12_1,
  SSE_XMM13_1,
  SSE_XMM14_1,
  SSE_XMM15_1,
#endif /* BX_SUPPORT_X86_64 */

#endif /* BX_CPU_LEVEL >= 6 */

  DR0,
  DR1,
  DR2,
  DR3,
  DR6,
  DR7,

  CPU_REG_END
} dbg_cpu_reg_t;

typedef struct {
  Bit64u            reg_value[CPU_REG_END];
  Bit64u            reg_backup[CPU_REG_END];
  bx_param_num_c *  regs[CPU_REG_END];
} bx_cpu_info_t;

typedef struct {
  size_t          cpu_count;
  bx_cpu_info_t * cpu_info;
} bx_smp_info_t;






////////////////////////////////////////////////////////////////////////////////
// bx_dbg_gui_c
////////////////////////////////////////////////////////////////////////////////
class BOCHSAPI bx_dbg_gui_c {

public:
  bx_dbg_gui_c(void);
  virtual ~bx_dbg_gui_c(void);

  void init_internal(void);

protected:
  virtual void init_os_depended(void) {};
  virtual bool parse_os_setting(const char * param, const char * value) { return false; };
  virtual void write_os_setting(FILE * fd) {};

private:
  void read_dbg_gui_config(void);
  void write_dbg_gui_config(void);
  char * strip_whitespace(char * s);

  void init_register_refs(void);

  bx_smp_info_t smp_info;



  bool bCpuModeHasChanged;  // set if cpu mode has changed
  unsigned currentCPUNo;    // active cpu
  bool showAllSMPCPUs;      // Display all SMP CPUs
  unsigned CPUcount;        // # of CPUs in a multi-CPU simulation


};



#endif /* BX_DEBUGGER && !BX_DEBUGGER_GUI && BX_NEW_DEBUGGER_GUI */

#endif /* BX_NEW_DBG_DEF_H */
