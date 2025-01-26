/////////////////////////////////////////////////////////////////////////
// $Id$
/////////////////////////////////////////////////////////////////////////
//
//   Copyright (c) 2025 Stanislav Shwartsman
//          Written by Stanislav Shwartsman [sshwarts at sourceforge net]
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
//  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA B 02110-1301 USA
//
/////////////////////////////////////////////////////////////////////////

#include "bochs.h"
#include "cpu.h"
#include "athlon.h"

#define LOG_THIS cpu->

#if BX_CPU_LEVEL >= 6

athlon_t::athlon_t(BX_CPU_C *cpu): bx_cpuid_t(cpu)
{
  enable_cpu_extension(BX_ISA_X87);
  enable_cpu_extension(BX_ISA_486);
  enable_cpu_extension(BX_ISA_PENTIUM);
  enable_cpu_extension(BX_ISA_MMX);
  enable_cpu_extension(BX_ISA_SYSENTER_SYSEXIT);
  enable_cpu_extension(BX_ISA_SYSCALL_SYSRET_LEGACY);
#if BX_SUPPORT_3DNOW
  enable_cpu_extension(BX_ISA_3DNOW);
  enable_cpu_extension(BX_ISA_3DNOW_EXT);
#endif
  enable_cpu_extension(BX_ISA_DEBUG_EXTENSIONS);
  enable_cpu_extension(BX_ISA_VME);
  enable_cpu_extension(BX_ISA_PSE);
  enable_cpu_extension(BX_ISA_P6);
  enable_cpu_extension(BX_ISA_PAE);
  enable_cpu_extension(BX_ISA_PGE);
  enable_cpu_extension(BX_ISA_MTRR);
  enable_cpu_extension(BX_ISA_PAT);
}

void athlon_t::get_cpuid_leaf(Bit32u function, Bit32u subfunction, cpuid_function_t *leaf) const
{
  static const char* brand_string = "AMD Athlon(tm) Processor\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0";

  switch(function) {
  case 0x80000000:
    get_ext_cpuid_leaf_0(leaf);
    return;
  case 0x80000001:
    get_ext_cpuid_leaf_1(leaf);
    return;
  case 0x80000002:
  case 0x80000003:
  case 0x80000004:
    get_ext_cpuid_brand_string_leaf(brand_string, function, leaf);
    return;
  case 0x80000005:
    get_ext_cpuid_leaf_5(leaf);
    return;
  case 0x80000006:
    get_ext_cpuid_leaf_6(leaf);
    return;
  case 0x00000000:
    get_std_cpuid_leaf_0(leaf);
    return;
  case 0x00000001:
    get_std_cpuid_leaf_1(leaf);
    return;
  default:
    get_reserved_leaf(leaf);
    return;
  }
}

// leaf 0x00000000 //
void athlon_t::get_std_cpuid_leaf_0(cpuid_function_t *leaf) const
{
  get_leaf_0(0x1, "AuthenticAMD", leaf);
}

// leaf 0x00000001 //
void athlon_t::get_std_cpuid_leaf_1(cpuid_function_t *leaf) const
{
  // EAX:       CPU Version Information
  //   [3:0]   Stepping ID
  //   [7:4]   Model: starts at 1
  //   [11:8]  Family: 4=486, 5=Pentium, 6=PPro, ...
  //   [13:12] Type: 0=OEM, 1=overdrive, 2=dual cpu, 3=reserved
  //   [19:16] Extended Model
  //   [27:20] Extended Family
  leaf->eax = 0x00000622;

  leaf->ebx = 0;
  leaf->ecx = 0;

  // EDX: Standard Feature Flags
  // * [0:0]   FPU on chip
  // * [1:1]   VME: Virtual-8086 Mode enhancements
  // * [2:2]   DE: Debug Extensions (I/O breakpoints)
  // * [3:3]   PSE: Page Size Extensions
  // * [4:4]   TSC: Time Stamp Counter
  // * [5:5]   MSR: RDMSR and WRMSR support
  // * [6:6]   PAE: Physical Address Extensions
  // * [7:7]   MCE: Machine Check Exception
  // * [8:8]   CXS: CMPXCHG8B instruction
  //   [9:9]   APIC: APIC on Chip
  //   [10:10] Reserved
  // * [11:11] SYSENTER/SYSEXIT support
  // * [12:12] MTRR: Memory Type Range Reg
  // * [13:13] PGE/PTE Global Bit
  // * [14:14] MCA: Machine Check Architecture
  // * [15:15] CMOV: Cond Mov/Cmp Instructions
  // * [16:16] PAT: Page Attribute Table
  // * [17:17] PSE-36: Physical Address Extensions
  //   [18:18] PSN: Processor Serial Number
  //   [19:19] CLFLUSH: CLFLUSH Instruction support
  //   [20:20] Reserved
  //   [21:21] DS: Debug Store
  //   [22:22] ACPI: Thermal Monitor and Software Controlled Clock Facilities
  // * [23:23] MMX Technology
  // * [24:24] FXSR: FXSAVE/FXRSTOR (also indicates CR4.OSFXSR is available)
  //   [25:25] SSE: SSE Extensions
  //   [26:26] SSE2: SSE2 Extensions
  //   [27:27] Self Snoop
  //   [28:28] Hyper Threading Technology
  //   [29:29] TM: Thermal Monitor
  //   [30:30] Reserved
  //   [31:31] PBE: Pending Break Enable
  leaf->edx = get_std_cpuid_leaf_1_edx();
}

// leaf 0x80000000 //
void athlon_t::get_ext_cpuid_leaf_0(cpuid_function_t *leaf) const
{
  // EAX: highest extended function understood by CPUID
  // EBX: reserved
  // EDX: reserved
  // ECX: reserved
  get_leaf_0(0x80000006, NULL, leaf);
}

// leaf 0x80000001 //
void athlon_t::get_ext_cpuid_leaf_1(cpuid_function_t *leaf) const
{
  // EAX:       CPU Version Information (same as 0x00000001.EAX)
  leaf->eax = 0x00000722;

  leaf->ebx = 0;
  leaf->ecx = 0;

  // EDX:
  // Many of the bits in EDX are the same as FN 0x00000001 [*] for AMD
  // * [0:0]   FPU on chip
  // * [1:1]   VME: Virtual-8086 Mode enhancements
  // * [2:2]   DE: Debug Extensions (I/O breakpoints)
  // * [3:3]   PSE: Page Size Extensions
  // * [4:4]   TSC: Time Stamp Counter
  // * [5:5]   MSR: RDMSR and WRMSR support
  // * [6:6]   PAE: Physical Address Extensions
  // * [7:7]   MCE: Machine Check Exception
  // * [8:8]   CXS: CMPXCHG8B instruction
  //   [9:9]   APIC: APIC on Chip
  //   [10:10] Reserved
  // * [11:11] SYSCALL/SYSRET support
  // * [12:12] MTRR: Memory Type Range Reg
  // * [13:13] PGE/PTE Global Bit
  // * [14:14] MCA: Machine Check Architecture
  // * [15:15] CMOV: Cond Mov/Cmp Instructions
  // * [16:16] PAT: Page Attribute Table
  // * [17:17] PSE-36: Physical Address Extensions
  //   [18:18] Reserved
  //   [19:19] Reserved
  //   [20:20] No-Execute page protection
  //   [21:21] Reserved
  // * [22:22] AMD MMX Extensions
  // * [23:23] MMX Technology
  // * [24:24] FXSR: FXSAVE/FXRSTOR (also indicates CR4.OSFXSR is available)
  //   [25:25] Fast FXSAVE/FXRSTOR mode support
  //   [26:26] 1G paging support
  //   [27:27] Support RDTSCP Instruction
  //   [28:28] Reserved
  //   [29:29] Long Mode
  // * [30:30] AMD 3DNow! Extensions
  // * [31:31] AMD 3DNow! Instructions
  leaf->edx = get_ext_cpuid_leaf_1_edx_amd();
}

// leaf 0x80000005 - L1 Cache and TLB Identifiers //
void athlon_t::get_ext_cpuid_leaf_5(cpuid_function_t *leaf) const
{
  leaf->eax = 0x0408ff08;
  leaf->ebx = 0xff18ff10;
  leaf->ecx = 0x40020140;
  leaf->edx = 0x40020140;
}

// leaf 0x80000006 - L2 Cache and TLB Identifiers //
void athlon_t::get_ext_cpuid_leaf_6(cpuid_function_t *leaf) const
{
  leaf->eax = 0x00000000;
  leaf->ebx = 0x41004100;
  leaf->ecx = 0x02002140;
  leaf->edx = 0x00000000;
}

void athlon_t::dump_cpuid(void) const
{
  bx_cpuid_t::dump_cpuid(0x1, 0x80000006);
}

bx_cpuid_t *create_athlon_cpuid(BX_CPU_C *cpu) { return new athlon_t(cpu); }

#endif
