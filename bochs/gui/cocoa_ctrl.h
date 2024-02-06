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

  #include <Cocoa/Cocoa.h>
  #include "config.h"
  #include "siminterface.h"
  #include "param_names.h"


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

    @property (nonatomic, readwrite) bx_param_num_c * _Nonnull param;
    @property (nonatomic, readwrite, strong) NSSlider * _Nullable slider;
    @property (nonatomic, readwrite, strong) BXNSTextField * _Nullable text;
    @property (nonatomic, readwrite, strong) NSDatePicker * _Nullable date;

    - (instancetype _Nonnull)initWithBrowser:(NSBrowser * _Nonnull) browser Param:(bx_param_num_c * _Nonnull) param;

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
  //
  ////////////////////////////////////////////////////////////////////////////////



#endif /* BX_GUI_COCOA_CTRL_H */
