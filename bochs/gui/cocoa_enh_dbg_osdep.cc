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

#include "cocoa_bochs.h"

#warning not fully implemented ...

void MoveLists() {}
void SetStatusText(int column, const char *buf) {
  printf("BX_DEBUGGER_GUI SetStatusText %d %s\n", column, buf);
} // should it be here ?
void MakeListsGray() {}
void DispMessage(const char *msg, const char *title) {
  printf("BX_DEBUGGER_GUI DispMessage %s %s\n", msg, title);
}
void InsertListRow(char *ColumnText[], int ColumnCount, int listnum, int LineCount, int grouping) {}
void StartListUpdate(int listnum) {}
void EndListUpdate(int listnum) {}
void RedrawColumns(int listnum) {}
void Invalidate(int i) {}
void TakeInputFocus() {}
bool ShowAskDialog() {
  printf("BX_DEBUGGER_GUI ShowAskDialog\n");
}
bool NewFont() {
  printf("BX_DEBUGGER_GUI NewFont\n");
  return (false);
}
void GrayMenuItem(int flag, int CmdIndex) {}
void ShowMemData(bool initting) {

}
void SetMenuCheckmark (int flag, int CmdIndex) {}
void ClearInputWindow() {}
void VSizeChange() {}
void ToggleWSchecks(int newWS, int oldWS) {}
void SetOutWinTxt() {
  bxcocoagui->dbg_addOutputText(OutWindow);
}
void ShowFW() {}
void GetInputEntry(char *buf) {}
void SelectHistory(int UpDown) {}
// void DelWatchpoint(bx_watchpoint *wp_array, unsigned *TotEntries, int i) {}
// void SetWatchpoint(unsigned *num_watchpoints, bx_watchpoint *watchpoint) {}

void HideTree() {
  printf("BX_DEBUGGER_GUI HideTree\n");
}
void FillPTree() {
  printf("BX_DEBUGGER_GUI FillPTree\n");
}

int GetASMTopIdx() {}
void ScrollASM(int pixels) {}

void GetLIText(int listnum, int itemnum, int column, char *buf) {}
void SetLIState(int listnum, int itemnum, bool Select) {}
int GetNextSelectedLI(int listnum, int StartPt) {}

bool OSInit() {
  printf("BX_DEBUGGER_GUI OSInit\n");

  // bxcocoagui initialized by cocoaconfig
  bxcocoagui->showWindow(BX_GUI_WINDOW_DEBUGGER, true);
  bxcocoagui->activateWindow(BX_GUI_WINDOW_DEBUGGER);

  return (true);
}
void SpecialInit() {
  // set all TRUE flags to checked in the Options menu, gray out unsupported features
}
void CloseDialog() {
  bxcocoagui->showWindow(BX_GUI_WINDOW_DEBUGGER, false);
  // close debug window
}
bool ParseOSSettings(const char *param, const char *value) {
  printf("BX_DEBUGGER_GUI param=%s value=%s\n", param, value);
}
void WriteOSSettings(FILE *fd) {
  printf("BX_DEBUGGER_GUI someone trying save settings\n");
}

void HitBreak() {}
// void ParseIDText(const char *x) {}



// running an action by ActivateMenuItem






#endif /* BX_DEBUGGER && BX_DEBUGGER_GUI */
