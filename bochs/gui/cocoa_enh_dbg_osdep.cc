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

#include "bochs.h"
#include "bx_debug/debug.h"
#include "siminterface.h"
#include "enh_dbg.h"

#if BX_DEBUGGER && BX_DEBUGGER_GUI

#warning not implemented ...

void MoveLists() {}
void SetStatusText(int column, const char *buf) {} // should it be here ?
void MakeListsGray() {}
void DispMessage(const char *msg, const char *title) {}
void InsertListRow(char *ColumnText[], int ColumnCount, int listnum, int LineCount, int grouping) {}
void StartListUpdate(int listnum) {}
void EndListUpdate(int listnum) {}
void RedrawColumns(int listnum) {}
void Invalidate(int i) {}
void TakeInputFocus() {}
bool ShowAskDialog() {}
bool NewFont() {}
void GrayMenuItem(int flag, int CmdIndex) {}
void ShowMemData(bool initting) {}
void SetMenuCheckmark (int flag, int CmdIndex) {}
void ClearInputWindow() {}
void VSizeChange() {}
void ToggleWSchecks(int newWS, int oldWS) {}
void SetOutWinTxt() {}
void ShowFW() {}
void GetInputEntry(char *buf) {}
void SelectHistory(int UpDown) {}
// void DelWatchpoint(bx_watchpoint *wp_array, unsigned *TotEntries, int i) {}
// void SetWatchpoint(unsigned *num_watchpoints, bx_watchpoint *watchpoint) {}

void HideTree() {}
void FillPTree() {}

int GetASMTopIdx() {}
void ScrollASM(int pixels) {}

void GetLIText(int listnum, int itemnum, int column, char *buf) {}
void SetLIState(int listnum, int itemnum, bool Select) {}
int GetNextSelectedLI(int listnum, int StartPt) {}

bool OSInit() {}
void SpecialInit() {}
void CloseDialog() {}
bool ParseOSSettings(const char *param, const char *value) {}
void WriteOSSettings(FILE *fd) {}

void HitBreak() {}
// void ParseIDText(const char *x) {}










#endif /* BX_DEBUGGER && BX_DEBUGGER_GUI */
