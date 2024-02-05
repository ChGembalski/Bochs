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

#include "cocoa_ctrl.h"


////////////////////////////////////////////////////////////////////////////////
// BXNSPreView
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSPreView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:NSMakeRect(0, 0, (unsigned)frameRect.size.width, (unsigned)frameRect.size.height)];
  if (self) {

    self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

  }

  return self;

}

/**
 * isFlipped
 */
- (BOOL) isFlipped {

  return YES;

}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSPreviewController
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSPreviewController

/**
 * initWithView
 */
- (instancetype _Nonnull)initWithView:(NSRect) rect Control:(id _Nonnull) object {

  self = [super init];
  if (self) {

    self.view = [[BXNSPreView alloc] initWithFrame:rect];
    [self.view addSubview:object];

  }

  return self;

}

/**
 * loadView
 */
- (void)loadView {

}

/**
 * loadViewIfNeeded
 */
- (void)loadViewIfNeeded {

}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSYesNoSelector
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSYesNoSelector

/**
 * initWithBrowser
 */
- (instancetype _Nonnull)initWithBrowser:(NSBrowser * _Nonnull) browser Param:(bx_param_bool_c * _Nonnull) param {

  NSAssert(param->get_type() == BXT_PARAM_BOOL, @"Invalid param type! expected : BXT_PARAM_BOOL");

  self = [super initWithFrame:NSMakeRect(((unsigned)[browser frameOfInsideOfColumn:browser.lastVisibleColumn].size.width - 100) / 2,0,100,50)];
  if (self) {

    NSTextField * yesF;
    NSTextField * noF;

    yesF = [NSTextField labelWithString:@"YES"];
    noF = [NSTextField labelWithString:@"NO"];
    self.yesno = [[NSSwitch alloc] init];

    [self addArrangedSubview:noF];
    [self addArrangedSubview:self.yesno];
    [self addArrangedSubview:yesF];

    self.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin;
    self.param = param;
    self.yesno.state = (self.param->get() > 0) ? NSControlStateValueOn : NSControlStateValueOff;
    [self.yesno setAction:@selector(valueChanged:)];
    [self.yesno setTarget:self];

  }

  return self;

}

/**
 * valueChanged
 */
- (void)valueChanged:(id _Nonnull)sender {

  if ((self.param->get() > 0) && (self.yesno.state == NSControlStateValueOff)) {
    self.param->set(0);
  }
  if ((self.param->get() == 0) && (self.yesno.state == NSControlStateValueOn)) {
    self.param->set(1);
  }

}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSChoiceSelector
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSChoiceSelector

/**
 * initWithBrowser
 */
- (instancetype _Nonnull)initWithBrowser:(NSBrowser * _Nonnull) browser Param:(bx_param_enum_c * _Nonnull) param {

  NSAssert(param->get_type() == BXT_PARAM_ENUM, @"Invalid param type! expected : BXT_PARAM_ENUM");

  self = [super initWithFrame:NSMakeRect(0,0,[browser frameOfInsideOfColumn:browser.lastVisibleColumn].size.width,50) pullsDown:NO];
  if (self) {

    unsigned i;
    const char * choice;

    self.autoresizingMask = NSViewWidthSizable;

    i=0;
    while ((choice = param->get_choice(i)) != NULL) {
      [self addItemWithTitle:[NSString stringWithUTF8String:choice]];
      i++;
      // stop on BX_QUICK_START - max value wrong
      if (param->get_min() == BX_QUICK_START) {
        if (strcmp("start_mode", param->get_name()) == 0) {
          if (i==4) break;
        }
      }
    }
    self.param = param;
    self.objectValue = [NSNumber numberWithInt:param->get() - param->get_min()];
    [self setAction:@selector(valueChanged:)];
    [self setTarget:self];

  }

  return self;

}

/**
 * valueChanged
 */
- (void)valueChanged:(id _Nonnull)sender {

  NSInteger curSel;

  curSel = [sender indexOfSelectedItem];
  if (curSel + self.param->get_min() != self.param->get()) {
    self.param->set(curSel + self.param->get_min());
  }

}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSGlobalLogSelector
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSGlobalLogSelector

/**
 * initWithBrowser
 */
- (instancetype _Nonnull)initWithBrowser:(NSBrowser * _Nonnull) browser Param:(unsigned) param {

  self = [super initWithFrame:NSMakeRect(0,0,[browser frameOfInsideOfColumn:browser.lastVisibleColumn].size.width,50) pullsDown:NO];
  if (self) {

    unsigned i;
    const char * choices[] = {"ignore", "report", "warn", "ask", "fatal", NULL};

    self.autoresizingMask = NSViewWidthSizable;

    i=0;
    while (choices[i] != NULL) {
      [self addItemWithTitle:[NSString stringWithUTF8String:choices[i]]];
      i++;
    }

    self.param = param;
    self.objectValue = [NSNumber numberWithInt:SIM->get_default_log_action(param)];
    [self setAction:@selector(valueChanged:)];
    [self setTarget:self];

  }

  return self;

}

/**
 * valueChanged
 */
- (void)valueChanged:(id _Nonnull)sender {

  NSInteger curSel;

  curSel = [sender indexOfSelectedItem];
  SIM->set_default_log_action(self.param, curSel);

}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSDeviceLogSelector
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSDeviceLogSelector

/**
 * initWithBrowser
 */
- (instancetype _Nonnull)initWithBrowser:(NSBrowser * _Nonnull) browser DeviceNo:(unsigned) dev_no Param:(unsigned) param {

  self = [super initWithFrame:NSMakeRect(0,0,[browser frameOfInsideOfColumn:browser.lastVisibleColumn].size.width,50) pullsDown:NO];
  if (self) {

    unsigned i;
    const char * choices[] = {"ignore", "report", "warn", "ask", "fatal", NULL};

    self.autoresizingMask = NSViewWidthSizable;

    i=0;
    while (choices[i] != NULL) {
      [self addItemWithTitle:[NSString stringWithUTF8String:choices[i]]];
      i++;
    }

    self.dev_no = dev_no;
    self.param = param;
    self.objectValue = [NSNumber numberWithInt:SIM->get_log_action(dev_no, param)];
    [self setAction:@selector(valueChanged:)];
    [self setTarget:self];

  }

  return self;

}

/**
 * valueChanged
 */
- (void)valueChanged:(id _Nonnull)sender {

  NSInteger curSel;

  curSel = [sender indexOfSelectedItem];
  SIM->set_log_action(self.dev_no, self.param, curSel);

}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSNumberFormatter
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSNumberFormatter

/**
 * isPartialStringValid
 */
- (BOOL)isPartialStringValid:(NSString * _Nonnull)partialString newEditingString:(NSString * _Nullable * _Nullable)newString errorDescription:(NSString * _Nullable * _Nullable)error {

  NSScanner * scanner;

  if([partialString length] == 0) {
    return YES;
  }

  scanner = [NSScanner scannerWithString:partialString];
  if(!([scanner scanInt:nil] && [scanner isAtEnd])) {
    NSBeep();
    return NO;
  }

  return YES;

}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSHexNumberFormatter
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSHexNumberFormatter

/**
 * init
 */
- (instancetype _Nonnull)init {

  self = [super init];
  if (self) {

    self.numberStyle = NSNumberFormatterNoStyle;
    self.generatesDecimalNumbers = NO;
    self.format = @"%X";
  }

  return self;

}

/**
 * isPartialStringValid
 */
- (BOOL)isPartialStringValid:(NSString * _Nonnull)partialString newEditingString:(NSString * _Nullable * _Nullable)newString errorDescription:(NSString * _Nullable * _Nullable)error {

  NSScanner * scanner;

  if([partialString length] == 0) {
    return YES;
  }

  scanner = [NSScanner scannerWithString:partialString];
  if(!([scanner scanHexInt:nil] && [scanner isAtEnd])) {
    NSBeep();
    return NO;
  }

  return YES;

}

/**
 * getObjectValue
 */
- (BOOL)getObjectValue:(id _Nullable * _Nullable)obj forString:(NSString * _Nonnull)string errorDescription:(NSString * _Nullable * _Nullable)error {

  return YES;

}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSNumberSelector
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSNumberSelector

/**
 * initWithBrowser
 */
- (instancetype _Nonnull)initWithBrowser:(NSBrowser * _Nonnull) browser Param:(bx_param_num_c * _Nonnull) param {

  NSAssert(param->get_type() == BXT_PARAM_NUM, @"Invalid param type! expected : BXT_PARAM_NUM");

  self = [super initWithFrame:NSMakeRect(
    10,
    10,
    (unsigned)[browser frameOfInsideOfColumn:browser.lastVisibleColumn].size.width - 20,
    (unsigned)[browser frameOfInsideOfColumn:browser.lastVisibleColumn].size.height -20
  )];
  if (self) {

    BOOL noMinVal;
    BOOL noMaxVal;
    BOOL withEdit;
    BOOL smallRange;
    NSString * str_fmt;
    NSString * str_val;
    NSStackView * inner;

    self.autoresizingMask = NSViewWidthSizable;
    self.param = param;
    // set orientation vertical
    self.orientation = NSUserInterfaceLayoutOrientationVertical;

    // special case date
    if ([[NSString stringWithUTF8String:param->get_name()] hasPrefix:@"time"]) {
      // place Date Control
      self.date = [[NSDatePicker alloc] init];
      self.date.datePickerMode = NSDatePickerModeSingle;
      self.date.datePickerStyle = NSDatePickerStyleClockAndCalendar;
      if (param->get64() == 1) {
        self.date.dateValue = [NSDate now];
        param->set((UInt64)self.date.dateValue.timeIntervalSince1970);
      } else {
        self.date.dateValue = [NSDate dateWithTimeIntervalSince1970:param->get64()];
      }
      [self addArrangedSubview:self.date];
      [self.date setTarget:self];
      [self.date setAction:@selector(dateChanged:)];
      return self;
    }

    self.date = nil;
    noMaxVal = param->get_max() == 0xffffffff;
    noMinVal = param->get_min() == 0xffffffff;
    withEdit = (!noMaxVal && ((param->get_max() - param->get_min()) > 15));
    smallRange = ((param->get_max() - param->get_min()) <= 15);

    // create a horizontal stack
    inner = [[NSStackView alloc] initWithFrame:NSMakeRect(0,0,(unsigned)[browser frameOfInsideOfColumn:browser.lastVisibleColumn].size.width - 20,50)];
    [self addArrangedSubview:inner];

    if (param->get_base() == BASE_HEX) {
      str_fmt = @"%X";
    } else {
      str_fmt = @"%d";
    }

    if (noMaxVal || noMinVal) {
      if (param->get_base() == BASE_HEX) {
        [inner addArrangedSubview:[NSTextField labelWithString:@"0x"]];
      }
    }
    str_val = [NSString stringWithFormat:str_fmt, param->get64()];
    if (noMaxVal || noMinVal || withEdit) { //!smallRange) {
      self.text = [NSTextField textFieldWithString:str_val];
    } else {
      self.text = [NSTextField labelWithString:str_val];
    }
    if (param->get_base() == BASE_HEX) {
      [self.text setFormatter:[[BXNSHexNumberFormatter alloc] init]];
    } else {
      [self.text setFormatter:[[BXNSNumberFormatter alloc] init]];
    }
    self.text.autoresizingMask = NSViewWidthSizable;
    [self.text setTarget:self];
    [self.text setAction:@selector(valueChanged:)];
    if (noMaxVal || noMinVal) {
      [inner addArrangedSubview:self.text];
      self.slider = nil;
    } else {
      self.slider = [[NSSlider alloc] initWithFrame:NSMakeRect(0,0,[browser frameOfInsideOfColumn:browser.lastVisibleColumn].size.width,50)];
      self.slider.autoresizingMask = NSViewWidthSizable;
      self.slider.minValue = (SInt64)param->get_min();
      self.slider.maxValue = (SInt64)param->get_max();
      if (smallRange) {
        self.slider.numberOfTickMarks = 1 + (param->get_max() - param->get_min());
        self.slider.allowsTickMarkValuesOnly = YES;
        self.slider.intValue = param->get64();
      } else {
        self.slider.intValue = param->get64();
      }
      [self.slider setTarget:self];
      [self.slider setAction:@selector(sliderChanged:)];

      [inner addArrangedSubview:[NSTextField labelWithString:[NSString stringWithFormat:str_fmt, param->get_min()]]];
      [inner addArrangedSubview:self.slider];
      [inner addArrangedSubview:[NSTextField labelWithString:[NSString stringWithFormat:str_fmt, param->get_max()]]];
      [self addArrangedSubview:self.text];

    }

  }

  return self;

}

/**
 * sliderChanged
 */
- (void)sliderChanged:(id _Nonnull)sender {

  NSString * str_fmt;

  if (self.param->get_base() == BASE_HEX) {
    str_fmt = @"%X";
  } else {
    str_fmt = @"%d";
  }

  self.param->set(self.slider.intValue);
  self.text.stringValue = [NSString stringWithFormat:str_fmt, self.slider.intValue];

}

/**
 * valueChanged
 */
- (void)valueChanged:(id _Nonnull)sender {

  NSInteger val;

  val = [self.text.stringValue intValue];
  if (self.slider != nil) {
    self.slider.intValue = val;
    [self.slider setNeedsDisplay:YES];
  }

  self.param->set((UInt64)val);

}

/**
 * dateChanged
 */
- (void)dateChanged:(id _Nonnull)sender {

  self.param->set((UInt64)self.date.dateValue.timeIntervalSince1970);

}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSStringSelector
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSStringSelector

/**
 * initWithBrowser
 */
- (instancetype _Nonnull)initWithBrowser:(NSBrowser * _Nonnull) browser Param:(bx_param_string_c * _Nonnull) param {

  NSAssert(param->get_type() == BXT_PARAM_STRING, @"Invalid param type! expected : BXT_PARAM_STRING");

  self = [super initWithFrame:NSMakeRect(10,10,(unsigned)[browser frameOfInsideOfColumn:browser.lastVisibleColumn].size.width - 20,50)];
  if (self) {

    self.text = [NSTextField textFieldWithString:[NSString stringWithUTF8String:param->getptr()]];
    self.text.autoresizingMask = NSViewWidthSizable;

    [self addArrangedSubview:self.text];

    self.button = nil;
    if (param->get_options() == param->IS_FILENAME) {
      self.button = [NSButton buttonWithTitle:@"..." target:self action:@selector(buttonOPressed:)];
      [self addArrangedSubview:self.button];
    } else if (param->get_options() == param->SAVE_FILE_DIALOG) {
      self.button = [NSButton buttonWithTitle:@"..." target:self action:@selector(buttonSPressed:)];
      [self addArrangedSubview:self.button];
    } else if (param->get_options() == param->SELECT_FOLDER_DLG) {
      self.button = [NSButton buttonWithTitle:@"..." target:self action:@selector(buttonDPressed:)];
      [self addArrangedSubview:self.button];
    }

    self.autoresizingMask = NSViewWidthSizable;
    self.param = param;

    [self.text setAction:@selector(valueChanged:)];
    [self.text setTarget:self];

  }

  return self;

}

/**
 * valueChanged
 */
- (void)valueChanged:(id _Nonnull)sender {

  if (strcmp(self.text.stringValue.UTF8String, self.param->getptr()) != 0) {
    self.param->set(self.text.stringValue.UTF8String);
  }

}

/**
 * buttonPressed
 */
- (void)buttonOPressed:(id _Nonnull)sender {

  NSOpenPanel * panel;

  panel = [NSOpenPanel openPanel];
  panel.canChooseFiles = YES;
  panel.canChooseDirectories = NO;
  panel.resolvesAliases = YES;
  panel.allowsMultipleSelection = NO;
  panel.accessoryViewDisclosed = YES;
  panel.canDownloadUbiquitousContents = NO;
  panel.directoryURL = [NSURL URLWithString:self.text.stringValue];
  if (self.param->get_description() != NULL) {
    panel.title = [[NSString alloc] initWithUTF8String:self.param->get_description()];
  }

  if ([panel runModal] == NSModalResponseOK) {
    NSArray * urls;
    NSURL * url;

    urls = [panel URLs];
    if ([urls count] != 0) {
      url = [urls objectAtIndex:0];
      self.text.stringValue = url.path;
      [self valueChanged:self];
    }
  }

}

/**
 * buttonPressed
 */
- (void)buttonSPressed:(id _Nonnull)sender {

  NSSavePanel * panel;

  panel = [NSSavePanel savePanel];
  panel.canCreateDirectories = YES;
  panel.canSelectHiddenExtension = YES;
  panel.showsHiddenFiles = YES;
  panel.treatsFilePackagesAsDirectories = NO;
  panel.directoryURL = [NSURL URLWithString:self.text.stringValue];
  if (self.param->get_description() != NULL) {
    panel.title = [[NSString alloc] initWithUTF8String:self.param->get_description()];
  }

  if ([panel runModal] == NSModalResponseOK) {
    NSURL * url;

    url = [panel URL];
    if (url != nil) {
      self.text.stringValue = url.path;
      [self valueChanged:self];
    }
  }

}

/**
 * buttonPressed
 */
- (void)buttonDPressed:(id _Nonnull)sender {

  NSOpenPanel * panel;

  panel = [NSOpenPanel openPanel];
  panel.canChooseFiles = NO;
  panel.canChooseDirectories = YES;
  panel.resolvesAliases = YES;
  panel.allowsMultipleSelection = NO;
  panel.accessoryViewDisclosed = YES;
  panel.canDownloadUbiquitousContents = NO;
  panel.directoryURL = [NSURL URLWithString:self.text.stringValue];
  if (self.param->get_description() != NULL) {
    panel.title = [[NSString alloc] initWithUTF8String:self.param->get_description()];
  }

  if ([panel runModal] == NSModalResponseOK) {
    NSArray * urls;
    NSURL * url;

    urls = [panel URLs];
    if ([urls count] != 0) {
      url = [urls objectAtIndex:0];
      self.text.stringValue = url.path;
      [self valueChanged:self];
    }
  }

}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSBrowserCell
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSBrowserCell

/**
 * initTextCell
 */
- (instancetype _Nonnull)initTextCell:(NSString * _Nonnull)string {

  self = [super initTextCell:string];
  if (self) {

    self.isLeaf = YES;
    self.param_name = nil;
    self.path = @"";
    self.dev_no = 0;
    self.sub_control = nil;

  }

  return self;

}

/**
 * initTextCell
 */
- (instancetype _Nonnull)initTextCell:(NSString * _Nonnull)string isLeaf:(BOOL) leaf PredPath:(NSString * _Nonnull) path SimParamName:(const char * _Nonnull) param_name {

  self = [super initTextCell:string];
  if (self) {

    self.isLeaf = leaf;
    self.param_name = param_name;
    if (path.length == 0) {
      self.path = [[NSString alloc] initWithUTF8String:param_name];
    } else {
      self.path = [NSString stringWithFormat:@"%@.%@", path, [[NSString alloc] initWithUTF8String:param_name]];
    }
    self.dev_no = 0;
    self.sub_control = nil;

  }

  return self;

}

/**
 * initTextCell
 */
- (instancetype _Nonnull)initTextCell:(NSString * _Nonnull)string isLeaf:(BOOL) leaf PredPath:(NSString * _Nonnull) path SimParamName:(const char * _Nonnull) param_name DeviceNo:(unsigned) dev_no {

  self = [super initTextCell:string];
  if (self) {

    self.isLeaf = leaf;
    self.param_name = param_name;
    if (path.length == 0) {
      self.path = [[NSString alloc] initWithUTF8String:param_name];
    } else {
      self.path = [NSString stringWithFormat:@"%@.%@", path, [[NSString alloc] initWithUTF8String:param_name]];
    }
    self.dev_no = dev_no;
    self.sub_control = nil;

  }

  return self;

}

/**
 * initTextCell
 */
- (instancetype _Nonnull)initTextCell:(NSString * _Nonnull)string isLeaf:(BOOL) leaf PredPath:(NSString * _Nonnull) path SimParamName:(const char * _Nonnull) param_name Control:(id _Nonnull) ctrl {

  self = [super initTextCell:string];
  if (self) {

    self.isLeaf = leaf;
    self.param_name = param_name;
    if (path.length == 0) {
      self.path = [[NSString alloc] initWithUTF8String:param_name];
    } else {
      self.path = [NSString stringWithFormat:@"%@.%@", path, [[NSString alloc] initWithUTF8String:param_name]];
    }
    self.dev_no = 0;
    self.sub_control = ctrl;

  }

  return self;

}

@end
