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

#ifndef BX_GUI_COCOA_CTRL_H

  #define BX_GUI_COCOA_CTRL_H

  extern debugger_view_config_t debugger_view_tab_options[];

  ////////////////////////////////////////////////////////////////////////////////
  // BXNSPreView
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSPreView : NSView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

    - (BOOL) isFlipped;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSPreviewController
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSPreviewController : NSViewController

    - (instancetype _Nonnull)initWithView:(NSRect) rect Control:(id _Nonnull) object;

    - (void)loadView;
    - (void)loadViewIfNeeded;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSYesNoSelector
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSYesNoSelector : NSStackView

    @property (nonatomic, readwrite) bx_param_bool_c * _Nonnull param;
    @property (nonatomic, readwrite, strong) NSSwitch * _Nonnull yesno;

    - (instancetype _Nonnull)initWithBrowser:(NSBrowser * _Nonnull) browser Param:(bx_param_bool_c * _Nonnull) param;

    - (void)valueChanged:(id _Nonnull)sender;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSChoiceSelector
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSChoiceSelector : NSPopUpButton

    @property (nonatomic, readwrite) bx_param_enum_c * _Nonnull param;

    - (instancetype _Nonnull)initWithBrowser:(NSBrowser * _Nonnull) browser Param:(bx_param_enum_c * _Nonnull) param;

    - (void)valueChanged:(id _Nonnull)sender;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSGlobalLogSelector
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSGlobalLogSelector : NSPopUpButton

    @property (nonatomic, readwrite) unsigned param;

    - (instancetype _Nonnull)initWithBrowser:(NSBrowser * _Nonnull) browser Param:(unsigned) param;

    - (void)valueChanged:(id _Nonnull)sender;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSDeviceLogSelector
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSDeviceLogSelector : NSPopUpButton

    @property (nonatomic, readwrite) unsigned dev_no;
    @property (nonatomic, readwrite) unsigned param;

    - (instancetype _Nonnull)initWithBrowser:(NSBrowser * _Nonnull) browser DeviceNo:(unsigned) dev_no Param:(unsigned) param;

    - (void)valueChanged:(id _Nonnull)sender;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSNumberFormatter
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSNumberFormatter : NSNumberFormatter

    - (BOOL)isPartialStringValid:(NSString * _Nonnull)partialString newEditingString:(NSString * _Nullable * _Nullable)newString errorDescription:(NSString * _Nullable * _Nullable)error;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSHexNumberFormatter
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSHexNumberFormatter : NSNumberFormatter

    - (instancetype _Nonnull)init;

    - (BOOL)isPartialStringValid:(NSString * _Nonnull)partialString newEditingString:(NSString * _Nullable * _Nullable)newString errorDescription:(NSString * _Nullable * _Nullable)error;
    - (BOOL)getObjectValue:(id _Nullable * _Nullable)obj forString:(NSString * _Nonnull)string errorDescription:(NSString * _Nullable * _Nullable)error;
    - (NSString * _Nullable)stringForObjectValue:(id _Nullable) obj;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSTextField
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSTextField : NSTextField

    @property (nonatomic, readwrite) BOOL type_notification;

    + (instancetype _Nonnull)textFieldWithString:(NSString * _Nonnull)stringValue TypeNotif:(BOOL) tnotif;

    - (void)textDidChange:(NSNotification * _Nonnull)notification;
    - (unsigned)hexnumberValue;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSNumberSelector
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSNumberSelector : NSStackView

    @property (nonatomic, readwrite) bx_param_num_c * _Nullable param;
    @property (nonatomic, readwrite, strong) NSSlider * _Nullable slider;
    @property (nonatomic, readwrite, strong) BXNSTextField * _Nullable text;
    @property (nonatomic, readwrite, strong) NSDatePicker * _Nullable date;

    - (instancetype _Nonnull)initWithBrowser:(NSBrowser * _Nonnull) browser Param:(bx_param_num_c * _Nonnull) param;
    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect Value:(unsigned long)val;

    - (void)sliderChanged:(id _Nonnull)sender;
    - (void)valueChanged:(id _Nonnull)sender;
    - (void)dateChanged:(id _Nonnull)sender;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSStringSelector
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSStringSelector : NSStackView

    @property (nonatomic, readwrite) bx_param_string_c * _Nonnull param;
    @property (nonatomic, readwrite, strong) BXNSTextField * _Nonnull text;
    @property (nonatomic, readwrite, strong) NSButton * _Nullable button;

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect Param:(bx_param_string_c * _Nonnull) param;
    - (instancetype _Nonnull)initWithBrowser:(NSBrowser * _Nullable) browser Param:(bx_param_string_c * _Nonnull) param;

    - (void)valueChanged:(id _Nonnull)sender;
    - (void)buttonOPressed:(id _Nonnull)sender;
    - (void)buttonSPressed:(id _Nonnull)sender;
    - (void)buttonDPressed:(id _Nonnull)sender;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSBrowserCell
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSBrowserCell : NSBrowserCell

    @property (nonatomic, readwrite) BOOL isLeaf;
    @property (nonatomic, readwrite) NSString * _Nonnull path;
    @property (nonatomic, readwrite) const char * _Nullable param_name;
    @property (nonatomic, readwrite) unsigned dev_no;
    @property (nonatomic, readwrite, strong) id _Nullable sub_control;

    - (instancetype _Nonnull)initTextCell:(NSString * _Nonnull)string;
    - (instancetype _Nonnull)initTextCell:(NSString * _Nonnull)string isLeaf:(BOOL) leaf PredPath:(NSString * _Nonnull) path SimParamName:(const char * _Nonnull) param_name;
    - (instancetype _Nonnull)initTextCell:(NSString * _Nonnull)string isLeaf:(BOOL) leaf PredPath:(NSString * _Nonnull) path SimParamName:(const char * _Nonnull) param_name DeviceNo:(unsigned) dev_no;
    - (instancetype _Nonnull)initTextCell:(NSString * _Nonnull)string isLeaf:(BOOL) leaf PredPath:(NSString * _Nonnull) path SimParamName:(const char * _Nonnull) param_name Control:(id _Nonnull) ctrl;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSToolbar
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSToolbar : NSToolbar <NSToolbarDelegate>

    @property (nonatomic, readwrite, strong) NSToolbarItem * _Nullable ips_item;

    - (instancetype _Nonnull)init;

    - (NSArray<NSToolbarItemIdentifier> * _Nonnull)toolbarAllowedItemIdentifiers:(NSToolbar * _Nonnull)toolbar;
    - (NSArray<NSToolbarItemIdentifier> * _Nonnull)toolbarDefaultItemIdentifiers:(NSToolbar * _Nonnull)toolbar;
    - (NSToolbarItem * _Nullable)toolbar:(NSToolbar * _Nonnull)toolbar itemForItemIdentifier:(NSToolbarItemIdentifier _Nonnull)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
    - (void)updateIPS:(unsigned) val;

  @end


#if BX_DEBUGGER && BX_NEW_DEBUGGER_GUI
  ////////////////////////////////////////////////////////////////////////////////
  // BXNSVerticalSplitView
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSVerticalSplitView : NSSplitView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSHorizontalSplitView
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSHorizontalSplitView : NSSplitView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSTabView
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSTabView : NSTabView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSAdressFormat
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSAdressFormat : NSObject

    + (NSAttributedString * _Nonnull)stringAddress:(bx_dbg_address_t) addr UseSegMode:(BOOL) modeSeg Mode64:(BOOL) mode64 Mode32:(BOOL) mode32 Att:(NSDictionary * _Nonnull) attribute;
    + (NSAttributedString * _Nonnull)stringHexValue64:(UInt64) val Att:(NSDictionary * _Nonnull) attribute;
    + (NSAttributedString * _Nonnull)stringHexValue32:(UInt32) val Att:(NSDictionary * _Nonnull) attribute;
    + (NSAttributedString * _Nonnull)stringHexValue16:(UInt16) val Att:(NSDictionary * _Nonnull) attribute;
    + (NSAttributedString * _Nonnull)stringHexValue8:(UInt8) val Att:(NSDictionary * _Nonnull) attribute;
    + (NSAttributedString * _Nonnull)stringDecValue64:(UInt64) val Att:(NSDictionary * _Nonnull) attribute;
    + (NSAttributedString * _Nonnull)stringDecValue32:(UInt32) val Att:(NSDictionary * _Nonnull) attribute;
    + (NSAttributedString * _Nonnull)stringDecValue16:(UInt16) val Att:(NSDictionary * _Nonnull) attribute;
    + (NSAttributedString * _Nonnull)stringDecValue8:(UInt8) val Att:(NSDictionary * _Nonnull) attribute;
    + (NSAttributedString * _Nonnull)stringWithUTF8String:(const char * _Nonnull) nullTerminatedCString Att:(NSDictionary * _Nonnull) attribute;
    + (UInt64)scanValue:(id _Nonnull) object Hex:(BOOL) hex Size:(UInt8) size;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSRegisterView
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSRegisterView : NSScrollView <NSTableViewDataSource>

    @property (nonatomic, readwrite, strong) NSTableView * _Nonnull table;
    @property (nonatomic, readwrite) unsigned cpuNo;
    @property (nonatomic, readwrite) debugger_register_mapping_t * _Nullable register_mapping;
    @property (nonatomic, readwrite) NSInteger register_count;
    @property (nonatomic, readwrite, strong) NSDictionary * _Nonnull attributeMonospace;

    - (instancetype _Nonnull)initWithFrame:(NSRect) frameRect;
    - (void)dealloc;

    - (void)createRegisterMapping;
    - (NSInteger)numberOfRowsInTableView:(NSTableView * _Nonnull) tableView;
    - (id _Nonnull)tableView:(NSTableView * _Nonnull)tableView objectValueForTableColumn:(NSTableColumn * _Nullable) tableColumn row:(NSInteger) row;
    - (void)tableView:(NSTableView * _Nonnull)tableView setObjectValue:(id _Nullable) object forTableColumn:(NSTableColumn * _Nullable) tableColumn row:(NSInteger) row;
    - (void)reload:(int) cpu;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSInstructionView
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSInstructionView : NSView <NSTableViewDataSource>

    @property (nonatomic, readwrite, strong) NSView * _Nonnull ctrl_view;
    @property (nonatomic, readwrite, strong) NSButton * _Nonnull btn_continue;
    @property (nonatomic, readwrite, strong) NSButton * _Nonnull btn_break;
    @property (nonatomic, readwrite, strong) NSButton * _Nonnull btn_step_over;
    @property (nonatomic, readwrite, strong) NSButton * _Nonnull btn_step;
    @property (nonatomic, readwrite, strong) NSTextField * _Nonnull cnt_title;
    @property (nonatomic, readwrite, strong) BXNSTextField * _Nonnull cnt_value;
    @property (nonatomic, readwrite, strong) NSTextField * _Nonnull adr_title;
    @property (nonatomic, readwrite, strong) NSPopUpButton * _Nonnull adr_select;
    @property (nonatomic, readwrite, strong) NSTextField * _Nonnull disadr_title;
    @property (nonatomic, readwrite, strong) BXNSTextField * _Nonnull disadr_value;
    @property (nonatomic, readwrite, strong) BXNSTextField * _Nonnull disadrseg_value;
    @property (nonatomic, readwrite, strong) BXNSTextField * _Nonnull disadrofs_value;
    @property (nonatomic, readwrite, strong) NSButton * _Nonnull btn_disadr;

    @property (nonatomic, readwrite, strong) NSScrollView * _Nonnull asm_scroll;
    @property (nonatomic, readwrite, strong) NSTableView * _Nonnull table;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull markerCol;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull addrCol;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull instrCol;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull bytesCol;
    @property (nonatomic, readwrite, strong) NSDictionary * _Nonnull attributeMonospace;
    @property (nonatomic, readwrite, strong) id _Nullable breakpointView;
    @property (nonatomic, readwrite) unsigned cpuNo;
    @property (nonatomic, readwrite) NSInteger lastRowNo;

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

    - (void)updateFromMemory;

    - (void)adrValueChanged:(id _Nonnull)sender;
    - (void)continueButtonClick:(id _Nonnull)sender;
    - (void)breakButtonClick:(id _Nonnull)sender;
    - (void)stepoverButtonClick:(id _Nonnull)sender;
    - (void)stepButtonClick:(id _Nonnull)sender;
    - (void)cntValueChanged:(id _Nonnull)sender;
    - (void)disadrButtonClick:(id _Nonnull)sender;
    - (void)breakpointClick:(id _Nonnull)sender;

    - (NSInteger)numberOfRowsInTableView:(NSTableView * _Nonnull) tableView;
    - (id _Nonnull)tableView:(NSTableView * _Nonnull)tableView objectValueForTableColumn:(NSTableColumn * _Nullable) tableColumn row:(NSInteger) row;

    - (void)reload:(int) cpu;
    - (NSInteger)getActiveTableRow;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSGDTView
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSGDTView : NSView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSIDTView
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSIDTView : NSView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNStackView
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNStackView : NSStackView <NSTableViewDataSource>

    @property (nonatomic, readwrite, strong) NSStackView * _Nonnull header;
    @property (nonatomic, readwrite, strong) NSTextField * _Nonnull size_label;
    @property (nonatomic, readwrite, strong) NSPopUpButton * _Nonnull size_stack;
    @property (nonatomic, readwrite, strong) NSScrollView * _Nonnull stack_scroll;
    @property (nonatomic, readwrite, strong) NSTableView * _Nonnull table;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull addrCol;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull dataCol;
    @property (nonatomic, readwrite) unsigned cpuNo;
    @property (nonatomic, readwrite, strong) NSDictionary * _Nonnull attributeMonospace;

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

    - (void)updateFromMemory;
    - (void)valueChanged:(id _Nonnull)sender;

    - (void)reload:(int) cpu;

    - (NSInteger)numberOfRowsInTableView:(NSTableView * _Nonnull) tableView;
    - (id _Nonnull)tableView:(NSTableView * _Nonnull)tableView objectValueForTableColumn:(NSTableColumn * _Nullable) tableColumn row:(NSInteger) row;
    - (void)tableView:(NSTableView * _Nonnull)tableView setObjectValue:(id _Nullable) object forTableColumn:(NSTableColumn * _Nullable) tableColumn row:(NSInteger) row;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSBreakpointView
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSBreakpointView : NSView <NSTableViewDataSource>

    @property (nonatomic, readwrite, strong) NSScrollView * _Nonnull brk_scroll;
    @property (nonatomic, readwrite, strong) NSTableView * _Nonnull table;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull typeCol;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull addrCol;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull enCol;
    @property (nonatomic, readwrite, strong) NSDictionary * _Nonnull attributeMonospace;
    @property (nonatomic, readwrite, strong) id _Nullable instructionView;
    @property (nonatomic, readwrite) unsigned cpuNo;
    @property (nonatomic, readwrite) unsigned linTitleRow;
    @property (nonatomic, readwrite) unsigned virtTitleRow;
    @property (nonatomic, readwrite) unsigned phyTitleRow;

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

    - (void)reload:(int) cpu;
    - (BOOL)isLinBreakpoint:(bx_address) linaddr Enabled:(BOOL * _Nonnull) enabled;
    - (void)toggleLinBreakpoint:(bx_address) linaddr;
    - (void)toggleLinBreakpointEnable:(id _Nonnull) sender;

    - (NSInteger)numberOfRowsInTableView:(NSTableView * _Nonnull) tableView;
    - (id _Nonnull)tableView:(NSTableView * _Nonnull)tableView objectValueForTableColumn:(NSTableColumn * _Nullable) tableColumn row:(NSInteger) row;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSPagingView
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSPagingView : NSView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSMemoryView
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSMemoryView : NSView <NSTableViewDataSource>

    @property (nonatomic, readwrite, strong) NSView * _Nonnull ctrl_view;
    @property (nonatomic, readwrite, strong) NSTextField * _Nonnull addr_label;
    @property (nonatomic, readwrite, strong) BXNSTextField * _Nonnull addr_value;
    @property (nonatomic, readwrite, strong) NSTextField * _Nonnull page_label;
    @property (nonatomic, readwrite, strong) NSButton * _Nonnull prev_button;
    @property (nonatomic, readwrite, strong) NSButton * _Nonnull succ_button;
    @property (nonatomic, readwrite, strong) NSTextField * _Nonnull bytes_label;
    @property (nonatomic, readwrite, strong) NSPopUpButton * _Nonnull bytes_select;
    @property (nonatomic, readwrite, strong) NSScrollView * _Nonnull bytes_scroll;
    @property (nonatomic, readwrite, strong) NSTableView * _Nonnull bytes_view;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull addrCol;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull byteCol_0;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull byteCol_1;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull byteCol_2;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull byteCol_3;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull byteCol_4;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull byteCol_5;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull byteCol_6;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull byteCol_7;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull byteCol_8;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull byteCol_9;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull byteCol_A;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull byteCol_B;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull byteCol_C;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull byteCol_D;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull byteCol_E;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull byteCol_F;
    @property (nonatomic, readwrite, strong) NSTableColumn * _Nonnull stringCol;
    @property (nonatomic, readwrite, strong) NSDictionary * _Nonnull attributeMonospace;
    @property (nonatomic, readwrite) unsigned cpuNo;

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

    - (void)updateFromMemory;
    - (void)bytesValueChanged:(id _Nonnull)sender;
    - (void)prevButtonClick:(id _Nonnull)sender;
    - (void)succButtonClick:(id _Nonnull)sender;
    - (void)addrValueChanged:(id _Nonnull)sender;

    - (NSInteger)numberOfRowsInTableView:(NSTableView * _Nonnull)tableView;
    - (id _Nonnull)tableView:(NSTableView * _Nonnull)tableView objectValueForTableColumn:(NSTableColumn * _Nullable) tableColumn row:(NSInteger) row;
    - (void)tableView:(NSTableView * _Nonnull)tableView setObjectValue:(id _Nullable) object forTableColumn:(NSTableColumn * _Nullable) tableColumn row:(NSInteger) row;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // ???
  ////////////////////////////////////////////////////////////////////////////////





  ////////////////////////////////////////////////////////////////////////////////
  // BXNSCpuTabContentView
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSCpuTabContentView : BXNSHorizontalSplitView

    @property (nonatomic, readwrite, strong) BXNSTabView * _Nonnull tabViewLeft;
    @property (nonatomic, readwrite, strong) BXNSTabView * _Nonnull tabViewRight;
    
    @property (nonatomic, readwrite, strong) BXNSRegisterView * _Nonnull registerView;
    @property (nonatomic, readwrite, strong) BXNSInstructionView * _Nonnull instructionView;
    @property (nonatomic, readwrite, strong) BXNSGDTView * _Nonnull gdtView;
    @property (nonatomic, readwrite, strong) BXNSIDTView * _Nonnull idtView;
    @property (nonatomic, readwrite, strong) BXNStackView * _Nonnull stackView;
    @property (nonatomic, readwrite, strong) BXNSBreakpointView * _Nonnull breakpointView;
    @property (nonatomic, readwrite, strong) BXNSPagingView * _Nonnull pagingView;
    @property (nonatomic, readwrite, strong) BXNSMemoryView * _Nonnull memoryView;

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

    - (void)reload:(int) cpu;
    - (void)moveToView:(debugger_view_location_t) dest View:(debugger_views_t) view;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSDebugView
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSDebugView : NSView 

    @property (nonatomic, readwrite, strong) NSView * _Nonnull ctrl_view;
    @property (nonatomic, readwrite, strong) NSPopUpButton * _Nonnull cpu_select;
    @property (nonatomic, readwrite, strong) NSButton * _Nonnull btn_continue;
    @property (nonatomic, readwrite, strong) NSButton * _Nonnull btn_break;
    @property (nonatomic, readwrite, strong) NSButton * _Nonnull btn_step_over;
    @property (nonatomic, readwrite, strong) NSButton * _Nonnull btn_step;
    @property (nonatomic, readwrite, strong) NSTextField * _Nonnull cnt_title;
    @property (nonatomic, readwrite, strong) BXNSTextField * _Nonnull cnt_value;
    @property (nonatomic, readwrite, strong) BXNSCpuTabContentView * _Nonnull cpu_view;

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

    - (void)cpuValueChanged:(id _Nonnull)sender;
    - (void)continueButtonClick:(id _Nonnull)sender;
    - (void)breakButtonClick:(id _Nonnull)sender;
    - (void)stepoverButtonClick:(id _Nonnull)sender;
    - (void)stepButtonClick:(id _Nonnull)sender;
    - (void)cntValueChanged:(id _Nonnull)sender;

    - (void)reload:(int) cpu;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSOptionCtrlView
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSOptionCtrlView : NSView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

  @end


  ////////////////////////////////////////////////////////////////////////////////
  // BXNSOptionTabView
  ////////////////////////////////////////////////////////////////////////////////
  @interface BXNSOptionTabView : NSView

    - (instancetype _Nonnull)initWithFrame:(NSRect)frameRect;

  @end


#endif /* BX_DEBUGGER && BX_NEW_DEBUGGER_GUI */

#endif /* BX_GUI_COCOA_CTRL_H */
