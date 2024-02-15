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
//#include "cpu/decoder/instr.h"

  extern void new_dbg_handler_custom(bool init);
  extern bx_dbg_gui_c * bx_dbg_new;
  extern bx_list_c * root_param;

  static bxevent_handler old_callback = NULL;
  static void * old_callback_arg = NULL;



  const char * dbg_param_names[] = {
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

    "SSE.xmm00_0", "SSE.xmm00_1", "SSE.xmm01_0", "SSE.xmm01_1",
    "SSE.xmm02_0", "SSE.xmm02_1", "SSE.xmm03_0", "SSE.xmm03_1",
    "SSE.xmm04_0", "SSE.xmm04_1", "SSE.xmm05_0", "SSE.xmm05_1",
    "SSE.xmm06_0", "SSE.xmm06_1", "SSE.xmm07_0", "SSE.xmm07_1",
#if BX_SUPPORT_X86_64
    "SSE.xmm08_0", "SSE.xmm08_1", "SSE.xmm09_0", "SSE.xmm09_1",
    "SSE.xmm10_0", "SSE.xmm10_1", "SSE.xmm11_0", "SSE.xmm11_1",
    "SSE.xmm12_0", "SSE.xmm12_1", "SSE.xmm13_0", "SSE.xmm13_1",
    "SSE.xmm14_0", "SSE.xmm14_1", "SSE.xmm15_0", "SSE.xmm15_1",
#endif /* BX_SUPPORT_X86_64 */

#endif /* BX_CPU_LEVEL >= 6 */

    "DR0", "DR1", "DR2", "DR3", "DR6", "DR7",

    NULL

  };

  const char * dbg_reg_names_16[] = {
    "AX", "BX", "CX", "DX", "SI", "DI", "BP", "SP", "IP",
  };

  const char * dbg_reg_names_32[] = {
    "EAX", "EBX", "ECX", "EDX", "ESI", "EDI", "EBP", "ESP", "EIP",
  };

  const char * dbg_reg_names[] = {
    "RAX", "RBX", "RCX", "RDX", "RSI", "RDI", "RBP", "RSP", "RIP",
    "R8", "R9", "R10", "R11", "R12", "R13", "R14", "R15",

    "EFLAGS",
    "CS", "DS", "ES", "FS", "GS",

    "GDTR", "", "IDTR", "",
    "LDTR", "TR",

    "CR0", "CR2", "CR3",
#if BX_CPU_LEVEL >= 5
    "CR4",
#endif /* BX_CPU_LEVEL >= 5 */

#if BX_CPU_LEVEL >= 6
    "EFER",
#endif /* BX_CPU_LEVEL >= 6 */

#if BX_SUPPORT_FPU
    "ST0", "ST0", "ST1", "ST1",
    "ST2", "ST2", "ST3", "ST3",
    "ST4", "ST4", "ST5", "ST5",
    "ST6", "ST6", "ST7", "ST7",
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

    "XMM0", "XMM0", "XMM1", "XMM1",
    "XMM2", "XMM2", "XMM3", "XMM3",
    "XMM4", "XMM4", "XMM5", "XMM5",
    "XMM6", "XMM6", "XMM7", "XMM7",
#if BX_SUPPORT_X86_64
    "XMM8",  "XMM8",  "XMM9",  "XMM9",
    "XMM10", "XMM10", "XMM11", "XMM11",
    "XMM12", "XMM12", "XMM13", "XMM13",
    "XMM14", "XMM14", "XMM15", "XMM15",
#endif /* BX_SUPPORT_X86_64 */

#endif /* BX_CPU_LEVEL >= 6 */

    "DR0", "DR1", "DR2", "DR3", "DR6", "DR7",

    NULL

  };

  const char * dbg_gdt_type_names[] = {
    "",
    "Available 16bit TSS",
    "LDT",
    "Busy 16bit TSS",
    "16bit Call Gate",
    "Task Gate",
    "16bit Interrupt Gate",
    "16bit Trap Gate",
    "Reserved",
    "Available 32bit TSS",
    "Reserved",
    "Busy 32bit TSS",
    "32bit Call Gate",
    "Reserved",
    "32bit Interrupt Gate",
    "32bit Trap Gate"
  };

  const char * dbg_gdt_data_type_names[] = {
    "16-bit code",
    "64-bit code",
    "32-bit code",
    "16-bit data",
    "64-bit data",
    "32-bit data",
    "Illegal",
    "Unused"
  };

  const char * dbg_idt_type_names[] = {
    "",
    "Task Gate",
    "Interrupt Gate",
    "Trap Gate"
  };

  const char * dbg_eflags_names[] = {
    "cf", "", "pf", "", "af", "", "zf", "tf",
    "if", "df", "of", "iopl", "iopl", "nt", "", "rf",
    "vm", "ac", "vif", "vip", "id", "", "", "",
    "", "", "", "", "", "", "", ""
  };

  // depends on BxCpuMode
  const char * dbg_cpu_mode_names[] = {
    "Real Mode",
    "V8086 Mode",
    "Protected Mode",
    "Compatibility Mode",
    "Long Mode"
  };




  // internal callback handler
  BxEvent *new_dbg_notify_callback(void *unused, BxEvent *event)
  {
    switch (event->type)
    {
      case BX_SYNC_EVT_GET_DBG_COMMAND: {
        // simulator -> CI, wait for response.
        printf("new_dbg_notify_callback BX_SYNC_EVT_GET_DBG_COMMAND\n");
        // continue if we have a filled buffer
        while ((event->retcode = bx_dbg_new->sync_evt_get_debug_command(event->u.debugcmd.command, 512)) == -1) {
          // no valid buffer .. nap ...
#ifdef WIN32
          Sleep(10);
#elif BX_HAVE_USLEEP
          usleep(10000);
#else
          sleep(1);
#endif
        }
        return event;
      }
      case BX_ASYNC_EVT_DBG_MSG: {
        // simulator -> CI
        printf("new_dbg_notify_callback BX_ASYNC_EVT_DBG_MSG [%s]\n", event->u.logmsg.msg);
        return event;
      }
      default: {
        return (*old_callback)(old_callback_arg, event);
      }
    }
  }

  // internal setup
  void InitDebugDialog() {
    printf("-->InitDebugDialog\n");
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

  // setup chain
  this->cmd_chain = (struct bx_dbg_cmd_chain_t *)malloc(sizeof(struct bx_dbg_cmd_chain_t));
  this->cmd_chain->pred = this->cmd_chain;
  this->cmd_chain->succ = NULL;
  this->cmd_chain->cmd = NULL;
  atomic_flag_test_and_set(&this->cmd_chain_lock);
  
  // setup asm buffer
  this->asm_buffer = (unsigned char *)malloc(ASM_BUFFER_SIZE * sizeof(unsigned char));
  this->asm_text_buffer = (unsigned char *)malloc(ASM_TEXT_BUFFER_SIZE * sizeof(unsigned char));
  
  this->init_register_refs();
  
}

/**
 * DTor
 */
bx_dbg_gui_c::~bx_dbg_gui_c(void) {

  struct bx_dbg_cmd_chain_t * next;
  
  next = this->cmd_chain;
  while (next != NULL) {
    struct bx_dbg_cmd_chain_t * node;
    
    node = next;
    if (next->cmd != NULL) {
      free(next->cmd);
    }
    next = next->succ;
    free(node);
  };
  
  free(this->asm_buffer);
  free(this->asm_text_buffer);
  
  if (this->smp_info.cpu_info != NULL) {
    free(this->smp_info.cpu_info);
  }
  
}

/**
 * init_internal
 */
void bx_dbg_gui_c::init_internal(void) {


  this->read_dbg_gui_config();

  
  this->init_os_depended();
  
}

/**
 * sync_evt_get_debug_command
 */
size_t bx_dbg_gui_c::sync_evt_get_debug_command(char * buffer, size_t buffer_size) {
  
  bx_dbg_cmd_t * cmd;
  
  while(1) {
    cmd = dequeue_cmd();
    
    if (cmd != NULL) {
      if (cmd->cmd == DBG_EXIT) {
        free(cmd);
        buffer[0] = 'q';
        buffer[1] = 0;
        return 1;
      }
      process_cmd(cmd);
      free(cmd);
    } else {
#ifdef WIN32
      Sleep(1);
#elif BX_HAVE_USLEEP
      usleep(1000);
#else
      sleep(1);
#endif
    }
    
  };
  
  return -1;
  
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
 * enqueue_cmd
 */
void bx_dbg_gui_c::enqueue_cmd(bx_dbg_cmd_t * cmd) {
  
  struct bx_dbg_cmd_chain_t * chain_cmd;
  
  while(atomic_flag_test_and_set(&this->cmd_chain_lock)) {
    usleep(100);
  }
  
  // root pred points to last element
  
  chain_cmd = (struct bx_dbg_cmd_chain_t *)malloc(sizeof(struct bx_dbg_cmd_chain_t));
  this->cmd_chain->pred->succ = chain_cmd;
  chain_cmd->cmd = cmd;
  chain_cmd->pred = this->cmd_chain->pred;
  chain_cmd->succ = NULL;
  this->cmd_chain->pred = chain_cmd;
  
  atomic_flag_clear(&this->cmd_chain_lock);
  
}

/**
 * dequeue_cmd
 */
bx_dbg_cmd_t * bx_dbg_gui_c::dequeue_cmd(void) {

  bx_dbg_cmd_t * cmd;
  struct bx_dbg_cmd_chain_t * next;
  
  if (this->cmd_chain->succ == NULL) {
    return (NULL);
  }
  
  while(atomic_flag_test_and_set(&this->cmd_chain_lock)) {
    usleep(100);
  }
  
  next = this->cmd_chain->succ;
  this->cmd_chain->succ = next->succ;
  if (next->succ != NULL) {
    next->succ->pred = this->cmd_chain;
  }
  cmd = next->cmd;
  free(next);
  
  atomic_flag_clear(&this->cmd_chain_lock);
  
  return (cmd);
  
}

/**
 * process_cmd
 */
void bx_dbg_gui_c::process_cmd(bx_dbg_cmd_t * cmd) {
  
  switch (cmd->cmd) {
    case DBG_CONTINUE:
    case DBG_STEP: {
      bx_dbg_step_over_command();
      break;
    }
    case DBG_STEP_CPU: {
      bx_dbg_stepN_command(cmd->data.ctrl.cpu, (Bit32u)cmd->data.ctrl.count);
      break;
    }
    case DBG_STEP_ALL: {
      bx_dbg_stepN_command(-1, (Bit32u)cmd->data.ctrl.count);
      break;
    }
    case DBG_BREAK:
    case DBG_VIRT_BREAK_POINT:
    case DBG_VIRT_BREAK_POINT_COND:
    case DBG_LIN_BREAK_POINT:
    case DBG_LIN_BREAK_POINT_COND:
    case DBG_TIME_BREAK_POINT:
    case DBG_CPU_BREAK_POINT:
    case DBG_INT_BREAK_POINT:
    case DBG_CALL_BREAK_POINT:
    case DBG_RET_BREAK_POINT:
    case DBG_MEM_WARCH_READ:
    case DBG_MEM_WATCH_WRITE:
    case DBG_NONE:
    default: {
      // ignore
    }
  }
  
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
  for (unsigned cpuNo = 0; cpuNo<BX_SMP_PROCESSORS; cpuNo++) {

    char cpuname[16];
    unsigned cpuregno;

    snprintf(cpuname, 16, "bochs.cpu%d", cpuNo);
    cpu_list = (bx_list_c *) SIM->get_param(cpuname, root_param);

    // now fill the regs ...
    cpuregno = 0;
    while (dbg_param_names[cpuregno] != NULL) {
      this->smp_info.cpu_info[cpuNo].regs[cpuregno] = SIM->get_param_num(dbg_param_names[cpuregno], cpu_list);
      // tests
      printf("[%s][%016lX]\n",
        this->smp_info.cpu_info[cpuNo].regs[cpuregno]->get_name(),
        this->smp_info.cpu_info[cpuNo].regs[cpuregno]->get64()
      );
      cpuregno++;
    }

    this->update_register(cpuNo);
    
  }
}

/**
 * update_register
 */
void bx_dbg_gui_c::update_register(unsigned cpuNo) {

  unsigned cpuregno;
  
  this->smp_info.cpu_info[cpuNo].cpu_no = cpuNo;
  this->smp_info.cpu_info[cpuNo].cpu_mode = BX_CPU(cpuNo)->get_cpu_mode();
  this->smp_info.cpu_info[cpuNo].cpu_mode32 = IS_CODE_32(BX_CPU(cpuNo)->guard_found.code_32_64);
  this->smp_info.cpu_info[cpuNo].cpu_mode64 = IS_CODE_64(BX_CPU(cpuNo)->guard_found.code_32_64);
  this->smp_info.cpu_info[cpuNo].cpu_paging = this->smp_info.cpu_info[cpuNo].regs[CR0]->get64() & 0x80000000;

  
  // setup reg_value
  cpuregno = 0;
  while (cpuregno != CPU_REG_END) {
    // set name
    if (cpuregno <= RIP) {
      if ((!this->smp_info.cpu_info[cpuNo].cpu_mode32 & !this->smp_info.cpu_info[cpuNo].cpu_mode64)) {
        this->smp_info.cpu_info[cpuNo].reg_value[cpuregno].name = dbg_reg_names_16[cpuregno];
        this->smp_info.cpu_info[cpuNo].reg_value[cpuregno].size = 16;
      } else if ((this->smp_info.cpu_info[cpuNo].cpu_mode32 & !this->smp_info.cpu_info[cpuNo].cpu_mode64)) {
        this->smp_info.cpu_info[cpuNo].reg_value[cpuregno].name = dbg_reg_names_32[cpuregno];
        this->smp_info.cpu_info[cpuNo].reg_value[cpuregno].size = 32;
      } else {
        this->smp_info.cpu_info[cpuNo].reg_value[cpuregno].name = dbg_reg_names[cpuregno];
        this->smp_info.cpu_info[cpuNo].reg_value[cpuregno].size = 64;
      }
    } else {
      this->smp_info.cpu_info[cpuNo].reg_value[cpuregno].name = dbg_reg_names[cpuregno];
      
#if BX_SUPPORT_FPU
      // fpu regs
      if (cpuregno >= FPU_ST0_F & cpuregno <= FPU_ST7_E) {
        if (((cpuregno - FPU_ST0_F) & 0x01) == 0) {
          this->smp_info.cpu_info[cpuNo].reg_value[cpuregno].size = 64;
        } else {
          this->smp_info.cpu_info[cpuNo].reg_value[cpuregno].size = 16;
        }
      } else
#endif /* BX_SUPPORT_FPU */
      // set size
      if ((!this->smp_info.cpu_info[cpuNo].cpu_mode32 & !this->smp_info.cpu_info[cpuNo].cpu_mode64)) {
        this->smp_info.cpu_info[cpuNo].reg_value[cpuregno].size = 16;
#if BX_CPU_LEVEL >= 5
        if (cpuregno >= CR0 & cpuregno <= CR4) {
#else
        if (cpuregno >= CR0 & cpuregno <= CR3) {
#endif /* BX_CPU_LEVEL >= 5 */
          this->smp_info.cpu_info[cpuNo].reg_value[cpuregno].size = 32;
        }
      } else if ((this->smp_info.cpu_info[cpuNo].cpu_mode32 & !this->smp_info.cpu_info[cpuNo].cpu_mode64)) {
        this->smp_info.cpu_info[cpuNo].reg_value[cpuregno].size = 32;
      } else {
        this->smp_info.cpu_info[cpuNo].reg_value[cpuregno].size = 64;
      }
    }
    
    // set value
    this->smp_info.cpu_info[cpuNo].reg_value[cpuregno].value = this->smp_info.cpu_info[cpuNo].regs[cpuregno]->get64();
    
    cpuregno++;
  }
  
}

/**
 * disassemble
 */
void bx_dbg_gui_c::disassemble(unsigned cpuNo, bool seg, bx_dbg_address_t addr, bool gas) {
  
  bx_address laddr;
  bool read_ok;
  Bit32u lineno;
  Bit32u data_ofs;
  unsigned char * text_ptr;
  bxInstruction_c i;
  Bit32u seg_base;
  
  dbg_cpu = cpuNo;
  
  if (seg) {
    laddr = bx_dbg_get_laddr(addr.seg, addr.ofs);
    seg_base = 0;
  } else {
    laddr = addr.ofs;
    seg_base = 0;
  }

  // clear buffers
  memset(this->asm_buffer, 0, ASM_BUFFER_SIZE);
  memset(this->asm_text_buffer, 0, ASM_TEXT_BUFFER_SIZE);
  
  // ok now fill the buffer
  read_ok = bx_dbg_read_linear(cpuNo, laddr, ASM_BUFFER_SIZE, this->asm_buffer);
  if (!read_ok) {
    return;
  }
  
  // create disasm
  data_ofs = 0;
  text_ptr = this->asm_text_buffer;
  for (lineno = 0; lineno<ASM_ENTRY_LINES; lineno++) {
    
    char buffer[64] = {0};
    size_t buffer_len;
    
    disasm(
      (const Bit8u *)&this->asm_buffer[data_ofs],
      this->smp_info.cpu_info[cpuNo].cpu_mode32,
      this->smp_info.cpu_info[cpuNo].cpu_mode64,
      buffer,
      &i, 
      seg_base,
      laddr,
      gas ? BX_DISASM_GAS : BX_DISASM_INTEL
    );
    
    buffer_len = strlen(buffer) + 1;
    memcpy(text_ptr, buffer, buffer_len);
        
    // setup asm_lines
    this->asm_lines[lineno].addr.seg = seg_base;
    this->asm_lines[lineno].addr.ofs = laddr;
    this->asm_lines[lineno].len = i.ilen();
    this->asm_lines[lineno].data = &this->asm_buffer[data_ofs];
    this->asm_lines[lineno].text = text_ptr;
    
    text_ptr += buffer_len;
    laddr += this->asm_lines[lineno].len;
    
  }
  
  
}

  


#endif
