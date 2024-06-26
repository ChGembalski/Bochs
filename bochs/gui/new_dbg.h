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
#include <stdatomic.h>
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
virtual bool gui_command_finished(int cpu);                                    \



#define DECLARE_GUI_DEBUGGER_OPTIONAL_VIRTUAL_METHODS()                        \
  virtual bool parse_os_setting(const char * param, const char * value)        \
  virtual void write_os_setting(FILE * fd)
//virtual size_t sync_evt_get_debug_command(char * buffer, size_t buffer_size)


#define BX_JUMP_TARGET_NOT_REQ ((bx_address)(-1))


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
  SS,

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
  SSE_XMM00_1,
  SSE_XMM01_0,
  SSE_XMM01_1,
  SSE_XMM02_0,
  SSE_XMM02_1,
  SSE_XMM03_0,
  SSE_XMM03_1,
  SSE_XMM04_0,
  SSE_XMM04_1,
  SSE_XMM05_0,
  SSE_XMM05_1,
  SSE_XMM06_0,
  SSE_XMM06_1,
  SSE_XMM07_0,
  SSE_XMM07_1,
#if BX_SUPPORT_X86_64
  SSE_XMM08_0,
  SSE_XMM08_1,
  SSE_XMM09_0,
  SSE_XMM09_1,
  SSE_XMM10_0,
  SSE_XMM10_1,
  SSE_XMM11_0,
  SSE_XMM11_1,
  SSE_XMM12_0,
  SSE_XMM12_1,
  SSE_XMM13_0,
  SSE_XMM13_1,
  SSE_XMM14_0,
  SSE_XMM14_1,
  SSE_XMM15_0,
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
  const char *      name;
  Bit64u            value;
  Bit8u             size;
} bx_cpu_reg_t;

typedef struct {
  unsigned          cpu_no;
  unsigned          cpu_mode;
  bool              cpu_mode32;
  bool              cpu_mode64;
  bool              cpu_paging;
  bx_cpu_reg_t      reg_value[CPU_REG_END];
  bx_param_num_c *  regs[CPU_REG_END];
} bx_cpu_info_t;

typedef struct {
  size_t          cpu_count;
  bx_cpu_info_t * cpu_info;
} bx_smp_info_t;

typedef enum {
  DBG_NONE,
  DBG_EXIT,
  DBG_CONTINUE,
  DBG_STEP,
  DBG_STEP_CPU,
  DBG_STEP_ALL,
  DBG_BREAK,
  DBG_VIRT_BREAK_POINT,
  DBG_VIRT_BREAK_POINT_COND,
  DBG_LIN_BREAK_POINT,
  DBG_LIN_BREAK_POINT_COND,
  DBG_PHY_BREAK_POINT,
  DBG_PHY_BREAK_POINT_COND,
  DBG_CPU_BREAK_POINT,
  DBG_INT_BREAK_POINT,
  DBG_CALL_BREAK_POINT,
  DBG_RET_BREAK_POINT,
  DBG_MEM_WARCH_READ,
  DBG_MEM_WATCH_WRITE
} bx_cmd_t;

typedef struct {
  Bit16s                  cpu;
  Bit64u                  count;
} bx_dbg_ctrl_t;

typedef struct {
  bx_address              ofs;
  Bit32u                  seg;
} bx_dbg_address_t;

typedef struct {
  union {
    bx_address            lin;
    bx_dbg_address_t      seg;
  } addr;
  char *                  condition;
  bool                    enabled;
  int                     handle;
  bx_cmd_t                type;
} bx_dbg_breakpoint_t;

struct bx_dbg_breakpoint_chain_t {
  bx_dbg_breakpoint_chain_t *    pred;
  bx_dbg_breakpoint_chain_t *    succ;
  bx_dbg_breakpoint_t *          breakpoint;
};

typedef struct {
  bx_phy_address          phy;
  bool                    enabled;
  bool                    on_read;
} bx_dbg_watchpoint_t;

typedef struct {
  bool                    cpu;
  bool                    irq;
  bool                    call;
  bool                    ret;
} bx_dbg_modebreak_t;

typedef struct {
  bx_cmd_t                cmd;
  union {
    bx_dbg_ctrl_t         ctrl;
    bx_dbg_breakpoint_t   brk;
    bx_dbg_watchpoint_t   watch;
    bx_dbg_modebreak_t    mode;
  } data;
} bx_dbg_cmd_t;

struct bx_dbg_cmd_chain_t {
  bx_dbg_cmd_chain_t *    pred;
  bx_dbg_cmd_chain_t *    succ;
  bx_dbg_cmd_t *          cmd;
};

typedef struct {
  bx_address              addr_lin;
  bx_dbg_address_t        addr_seg;
  Bit8u                   len;
  unsigned char *         data;
  unsigned char *         text;
} bx_dbg_asm_entry_t;

#define ASM_ENTRY_LINES       256
#define ASM_BUFFER_SIZE       4096
#define ASM_TEXT_BUFFER_SIZE  (40 * ASM_ENTRY_LINES)

typedef struct {
  bx_address              addr_lin;
  bx_dbg_address_t        addr_seg;
  Bit64u                  addr_on_stack;
} bx_dbg_stack_entry_64_t;

typedef struct {
  bx_address              addr_lin;
  bx_dbg_address_t        addr_seg;
  Bit32u                  addr_on_stack;
} bx_dbg_stack_entry_32_t;

typedef struct {
  bx_address              addr_lin;
  bx_dbg_address_t        addr_seg;
  Bit16u                  addr_on_stack;
} bx_dbg_stack_entry_16_t;

typedef struct {
#if BX_SUPPORT_X86_64
  bx_dbg_stack_entry_64_t * data_64;
#endif
  bx_dbg_stack_entry_32_t * data_32;
  bx_dbg_stack_entry_16_t * data_16;
  unsigned                cnt;
} bx_dbg_stack_data_t;

#define STACK_ENTRY_LINES   128


////////////////////////////////////////////////////////////////////////////////
// bx_dbg_gui_c
////////////////////////////////////////////////////////////////////////////////
class BOCHSAPI bx_dbg_gui_c {

public:
  bx_smp_info_t smp_info;
  bx_dbg_asm_entry_t asm_lines[ASM_ENTRY_LINES];
  unsigned char * mem_buffer;
  bx_dbg_stack_data_t stack_data;

private:
  struct bx_dbg_cmd_chain_t * cmd_chain;
  volatile atomic_flag cmd_chain_lock;
  unsigned char * asm_buffer;
  unsigned char * asm_text_buffer;
  bool in_run_loop;
  struct bx_dbg_breakpoint_chain_t * breakpoint_chain;
  
public:
  bx_dbg_gui_c(void);
  virtual ~bx_dbg_gui_c(void);

  void init_internal(void);
  bool command_finished(int cpu);
  
  /// async call : fetch next debug command
  /// buffer is allocated, buffer_size size of allocated buffer
  /// fill the buffer and return no of bytes filled
  virtual size_t sync_evt_get_debug_command(char * buffer, size_t buffer_size);

  void disassemble(unsigned cpuNo, bool seg, bx_dbg_address_t addr, bool gas);
  bool must_disassemble(unsigned cpuNo, bool seg, bx_dbg_address_t addr);
  void memorydump(unsigned cpuNo, bool seg, bx_dbg_address_t addr, size_t buffer_size);
  void memoryset(unsigned cpuNo, bx_dbg_address_t addr, Bit8u val);
  void update_register(unsigned cpuNo);
  void write_register(unsigned cpuNo, unsigned regno);
  void prepare_stack_data(unsigned cpuNo);
  bool is_addr_equal(unsigned cpuNo, bool segA, bx_dbg_address_t addrA, bool segB, bx_dbg_address_t addrB);
  
  void cmd_step_n(int cpuNo, unsigned step_cnt);
  void cmd_continue(void);
  void cmd_break(void);
  void cmd_step_over(void);
  
  bool add_breakpoint_lin(bx_address addr, bool enabled, const char * condition);
  bool add_breakpoint_virt(bx_dbg_address_t addr, bool enabled, const char * condition);
  bool add_breakpoint_phy(bx_address addr, bool enabled, const char * condition);
  int get_breakpoint_lin_count(void);
  int get_breakpoint_virt_count(void);
  int get_breakpoint_phy_count(void);
  bx_dbg_breakpoint_t * get_breakpoint_lin(int no);
  bx_dbg_breakpoint_t * get_breakpoint_lin(bx_address addr);
  bx_dbg_breakpoint_t * get_breakpoint_virt(int no);
  bx_dbg_breakpoint_t * get_breakpoint_phy(int no);
  void del_breakpoint(unsigned handle);
  void del_all_breakpoints(void);
  void enable_breakpoint(unsigned handle, bool enable);
  
protected:
  virtual void init_os_depended(void) {};
  virtual bool parse_os_setting(const char * param, const char * value) { return false; };
  virtual void write_os_setting(FILE * fd) {};
  virtual bool gui_command_finished(int cpu) { return true; };
  
private:
  void read_dbg_gui_config(void);
  void write_dbg_gui_config(void);
  char * strip_whitespace(char * s);

  void enqueue_cmd(bx_dbg_cmd_t * cmd);
  bx_dbg_cmd_t * dequeue_cmd(void);
  void process_cmd(bx_dbg_cmd_t * cmd);
  
  void init_register_refs(void);
  
  bx_address get_segment(unsigned cpuNo, Bit16u sel, bx_address ofs);
  
  
  

};



#endif /* BX_DEBUGGER && !BX_DEBUGGER_GUI && BX_NEW_DEBUGGER_GUI */

#endif /* BX_NEW_DBG_DEF_H */
