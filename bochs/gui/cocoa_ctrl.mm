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

#include <Cocoa/Cocoa.h>
#include "config.h"
#include "siminterface.h"
#include "param_names.h"

#if BX_DEBUGGER && BX_NEW_DEBUGGER_GUI
#include "bx_debug/debug.h"
#include "new_dbg.h"
#include "cocoa_bochs.h"

extern bx_dbg_gui_c * bx_dbg_new;
extern debugger_ctrl_config_t debugger_ctrl_options;

#endif /* BX_DEBUGGER && !BX_DEBUGGER_GUI && BX_NEW_DEBUGGER_GUI */

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
    self.format = @"";
  }
  
  return self;
  
}

/**
 * isPartialStringValid
 */
- (BOOL)isPartialStringValid:(NSString * _Nonnull)partialString newEditingString:(NSString * _Nullable * _Nullable)newString errorDescription:(NSString * _Nullable * _Nullable)error {
  
  NSScanner * scanner;
  unsigned value;
  
  if([partialString length] == 0) {
    return YES;
  }
  
  scanner = [NSScanner scannerWithString:partialString];
  if(!([scanner scanHexInt:&value] && [scanner isAtEnd])) {
    NSBeep();
    return NO;
  }
  *newString = partialString;
  
  return YES;
  
}

/**
 * getObjectValue
 */
- (BOOL)getObjectValue:(id _Nullable * _Nullable)obj forString:(NSString * _Nonnull)string errorDescription:(NSString * _Nullable * _Nullable)error {

  unsigned value;
  NSScanner * scanner;
  
  value = 0;
  scanner = [NSScanner scannerWithString:string];
  [scanner scanHexInt:&value];
  *obj = [NSNumber numberWithInt:value];
  
  return YES;

}

/**
 * stringForObjectValue
 */
- (NSString * _Nullable)stringForObjectValue:(id _Nullable) obj {
  
  NSString * result;
  
  if (![obj isKindOfClass:[NSNumber class]]) {
    return nil;
  }
  
  result = [NSString stringWithFormat:@"%lX", [obj longValue]];
  
  return result;
  
}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSTextField
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSTextField

/**
 * textFieldWithString
 */
+ (instancetype _Nonnull)textFieldWithString:(NSString * _Nonnull)stringValue TypeNotif:(BOOL) tnotif {
  
  BXNSTextField * result;
  
  result = [super textFieldWithString:stringValue];
  result.type_notification = tnotif;
  
  return result;
  
}

/**
 * textDidChange
 */
- (void)textDidChange:(NSNotification * _Nonnull)notification {

  if ((self.action != nil) && (self.target != nil) && self.type_notification) {
    [self sendAction:self.action to:self.target];
  }
  
}

/**
 * hexnumberValue
 */
- (unsigned)hexnumberValue {

  unsigned value;
  NSScanner * scanner;

  value = 0;
  scanner = [NSScanner scannerWithString:self.stringValue];
  [scanner scanHexInt:&value];

  return value;

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
      self.text = [BXNSTextField textFieldWithString:str_val TypeNotif:!(noMaxVal || noMinVal)];
    } else {
      self.text = [BXNSTextField labelWithString:str_val];
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
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect Value:(unsigned long)val {
  
  self = [super initWithFrame:frameRect];
  if (self) {
    
    self.param = nil;
    self.date = nil;
    self.text = [BXNSTextField textFieldWithString:[NSString stringWithFormat:@"%ld", val] TypeNotif:NO];
    self.text.autoresizingMask = NSViewHeightSizable;
    [self.text setFormatter:[[BXNSNumberFormatter alloc] init]];
    self.slider = nil;
    
    [self addView:self.text inGravity:NSStackViewGravityLeading];
    
  }
  
  return self;
  
}

/**
 * sliderChanged
 */
- (void)sliderChanged:(id _Nonnull)sender {

  NSString * str_fmt;
  BOOL noMinVal;
  BOOL noMaxVal;

  if (self.param->get_base() == BASE_HEX) {
    str_fmt = @"%X";
  } else {
    str_fmt = @"%d";
  }
  noMaxVal = self.param->get_max() == 0xffffffff;
  noMinVal = self.param->get_min() == 0xffffffff;
  
  if (!noMinVal) {
    if (self.slider.intValue < self.param->get_min()) {
      self.slider.intValue = self.param->get_min();
    }
  }
  if (!noMaxVal) {
    if (self.slider.intValue > self.param->get_max()) {
      self.slider.intValue = self.param->get_max();
    }
  }

  self.param->set(self.slider.intValue);
  self.text.stringValue = [NSString stringWithFormat:str_fmt, self.slider.intValue];

}

/**
 * valueChanged
 */
- (void)valueChanged:(id _Nonnull)sender {

  NSInteger val;
  BOOL noMinVal;
  BOOL noMaxVal;
  NSString * str_fmt;
    
  if (self.param->get_base() == BASE_HEX) {
    str_fmt = @"%X";
    val = [self.text hexnumberValue];
  } else {
    str_fmt = @"%d";
    val = [self.text.stringValue intValue];
  }
    if (val == self.param->get64()) {
      return;
    }

  noMaxVal = self.param->get_max() == 0xffffffff;
  noMinVal = self.param->get_min() == 0xffffffff;
  
  if (!noMinVal) {
    if (val < self.param->get_min()) {
      val = self.param->get_min();
    }
  }
  if (!noMaxVal) {
    if (val > self.param->get_max()) {
      val = self.param->get_max();
    }
  }
  self.text.stringValue = [NSString stringWithFormat:str_fmt, val];
  self.param->set((UInt64)val);
  
  if (self.slider != nil) {
    self.slider.intValue = val;
    [self.slider setNeedsDisplay:YES];
  }

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
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect Param:(bx_param_string_c * _Nonnull) param {
  
  NSAssert(param->get_type() == BXT_PARAM_STRING, @"Invalid param type! expected : BXT_PARAM_STRING");
  
  self = [super initWithFrame:frameRect];
  if (self) {
    
    
    self.text = [BXNSTextField textFieldWithString:[NSString stringWithUTF8String:param->getptr()] TypeNotif:YES];
    self.text.autoresizingMask = NSViewWidthSizable;

    [self addArrangedSubview:self.text];

    self.button = nil;
    if ((param->get_options() & bx_param_string_c::IS_FILENAME) == bx_param_string_c::IS_FILENAME) {
      if ((param->get_options() & bx_param_string_c::SAVE_FILE_DIALOG) == bx_param_string_c::SAVE_FILE_DIALOG) {
        self.button = [NSButton buttonWithTitle:@"..." target:self action:@selector(buttonSPressed:)];
      } else if ((param->get_options() & bx_param_string_c::SELECT_FOLDER_DLG) == bx_param_string_c::SELECT_FOLDER_DLG) {
        self.button = [NSButton buttonWithTitle:@"..." target:self action:@selector(buttonDPressed:)];
      } else {
        self.button = [NSButton buttonWithTitle:@"..." target:self action:@selector(buttonOPressed:)];
      }
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
 * initWithBrowser
 */
- (instancetype _Nonnull)initWithBrowser:(NSBrowser * _Nullable) browser Param:(bx_param_string_c * _Nonnull) param {

  NSAssert(param->get_type() == BXT_PARAM_STRING, @"Invalid param type! expected : BXT_PARAM_STRING");

  self = [super initWithFrame:NSMakeRect(10,10,(unsigned)[browser frameOfInsideOfColumn:browser.lastVisibleColumn].size.width - 20,50)];
  if (self) {

    self.text = [BXNSTextField textFieldWithString:[NSString stringWithUTF8String:param->getptr()]];
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
    panel.title = [NSString stringWithUTF8String:self.param->get_description()];
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
    panel.title = [NSString stringWithUTF8String:self.param->get_description()];
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
    panel.title = [NSString stringWithUTF8String:self.param->get_description()];
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
      self.path = [NSString stringWithUTF8String:param_name];
    } else {
      self.path = [NSString stringWithFormat:@"%@.%@", path, [NSString stringWithUTF8String:param_name]];
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
      self.path = [NSString stringWithUTF8String:param_name];
    } else {
      self.path = [NSString stringWithFormat:@"%@.%@", path, [NSString stringWithUTF8String:param_name]];
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
      self.path = [NSString stringWithUTF8String:param_name];
    } else {
      self.path = [NSString stringWithFormat:@"%@.%@", path, [NSString stringWithUTF8String:param_name]];
    }
    self.dev_no = 0;
    self.sub_control = ctrl;

  }

  return self;

}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSToolbar
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSToolbar

/**
 * init
 */
- (instancetype _Nonnull)init {
  
  self = [super initWithIdentifier:@"bx_toolbar"];
  if (self) {
    
    self.displayMode = NSToolbarDisplayModeLabelOnly;
    self.ips_item = nil;
    
    [self setDelegate:self];
    
  }
  
  return self;
  
}

/**
 * toolbarAllowedItemIdentifiers
 */
- (NSArray<NSToolbarItemIdentifier> * _Nonnull)toolbarAllowedItemIdentifiers:(NSToolbar * _Nonnull)toolbar {
  
  return @[ @"ips_item" ];
    
}

/**
 * toolbarDefaultItemIdentifiers
 */
- (NSArray<NSToolbarItemIdentifier> * _Nonnull)toolbarDefaultItemIdentifiers:(NSToolbar * _Nonnull)toolbar {
  
  return @[ @"ips_item" ];
  
}

/**
 * toolbar
 */
- (NSToolbarItem * _Nullable)toolbar:(NSToolbar * _Nonnull)toolbar itemForItemIdentifier:(NSToolbarItemIdentifier _Nonnull)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
  
  if([toolbar.identifier isEqualToString:@"bx_toolbar"]) {
    
    if([itemIdentifier isEqualToString:@"ips_item"]) {
      
      if (self.ips_item == nil) {
        self.ips_item = [[NSToolbarItem alloc] initWithItemIdentifier:@"ips_item"];
        [self updateIPS:0];
      }
      
      return self.ips_item;
      
    }
    
  }
  
  return nil;
  
}

/**
 * updateIPS
 */
- (void)updateIPS:(unsigned) val {
  
  self.ips_item.label = [NSString stringWithFormat:@"IPS : %010d", val];
  
}

@end


#if BX_DEBUGGER && BX_NEW_DEBUGGER_GUI
////////////////////////////////////////////////////////////////////////////////
// BXNSVerticalSplitView
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSVerticalSplitView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {

    self.arrangesAllSubviews = YES;
    self.dividerStyle = NSSplitViewDividerStylePaneSplitter;

  }

  return self;

}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSHorizontalSplitView
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSHorizontalSplitView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {

    self.vertical = YES;
    self.arrangesAllSubviews = YES;
    self.dividerStyle = NSSplitViewDividerStylePaneSplitter;

  }

  return self;

}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSTabView
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSTabView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {

    self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

  }

  return self;

}

@end





////////////////////////////////////////////////////////////////////////////////
// BXNSRegisterView
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSRegisterView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect) frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {

    NSTableColumn * nameCol;
    NSTableColumn * hexCol;
    NSTableColumn * decCol;
    
    self.cpuNo = 0;
    self.register_mapping = nil;
    self.register_count = 0;
    
    self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.hasVerticalScroller = YES;
    self.hasHorizontalScroller = YES;
    self.autohidesScrollers = YES;
    self.borderType = NSNoBorder;
    
    self.table = [[NSTableView alloc] initWithFrame:frameRect];
    self.table.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.table.usesAlternatingRowBackgroundColors = YES;
    self.table.headerView = [[NSTableHeaderView alloc] init];
    self.table.columnAutoresizingStyle = NSTableViewUniformColumnAutoresizingStyle;
    self.table.rowSizeStyle = NSTableViewRowSizeStyleCustom;
    self.table.rowHeight = 18;
    self.table.intercellSpacing = NSMakeSize(6, 6);
    
    nameCol = [[NSTableColumn alloc] initWithIdentifier:@"col.name"];
    nameCol.headerCell = [[NSTableHeaderCell alloc] init];
    nameCol.title = @"Name";
    nameCol.editable = NO;
    nameCol.width = 100;
//    nameCol.sortDescriptorPrototype = [[NSSortDescriptor alloc] initWithKey:@"col.name" ascending:YES];
    [self.table addTableColumn:nameCol];
    
    hexCol = [[NSTableColumn alloc] initWithIdentifier:@"col.hex"];
    hexCol.headerCell = [[NSTableHeaderCell alloc] init];
    hexCol.title = @"Hex Value";
    hexCol.editable = YES;
    hexCol.width = 200;
    [self.table addTableColumn:hexCol];
    
    decCol = [[NSTableColumn alloc] initWithIdentifier:@"col.dec"];
    decCol.headerCell = [[NSTableHeaderCell alloc] init];
    decCol.title = @"Dec Value";
    decCol.editable = YES;
    decCol.width = 200;
    [self.table addTableColumn:decCol];
    
    
    self.table.dataSource = (id)self;
    
    [self setDocumentView:self.table];
    
    // now prepare the register
    [self createRegisterMapping];
    
  }

  return self;

}

/**
 * dealloc
 */
- (void)dealloc {
  if (self.register_mapping != nil) {
    free(self.register_mapping);
  }
}

/**
 * createRegisterMapping
 */
- (void)createRegisterMapping {
  
  unsigned int curRow;
  unsigned int reg_id;
  
  if (bx_dbg_new == NULL) {
    self.register_count = 0;
    return;
  }
  
  self.register_count = 0;
  
  if (debugger_ctrl_options.show_general_purpose_regs) {
#if BX_SUPPORT_X86_64 == 1
    self.register_count = 18;
#else
    self.register_count = 10;
#endif /* BX_SUPPORT_X86_64 == 1 */
  }
  
  if (debugger_ctrl_options.show_segment_regs) {
    self.register_count += 5;
  }
  
  if (debugger_ctrl_options.show_control_regs) {
    self.register_count += 3;
#if BX_CPU_LEVEL >= 5
    self.register_count += 1;
#endif /* BX_CPU_LEVEL >= 5 */
#if BX_CPU_LEVEL >= 6
    self.register_count += 1; // efer
#endif /* BX_CPU_LEVEL >= 6 */
  }
  
  if (debugger_ctrl_options.show_fpu_regs) {
    self.register_count += 8;
  }
  
  if (debugger_ctrl_options.show_test_regs) {
#if BX_CPU_TEST_REGISTER
#if BX_CPU_LEVEL >= 3 && BX_CPU_LEVEL <= 6
    self.register_count += 3;
#if BX_CPU_LEVEL >= 4
    self.register_count += 2;
#endif /* BX_CPU_LEVEL >= 4 */
#endif /* BX_CPU_LEVEL >= 3 && BX_CPU_LEVEL <= 6 */
#endif /* BX_CPU_TEST_REGISTER */
  }
  
  if (debugger_ctrl_options.show_sse_regs) {
#if BX_CPU_LEVEL >= 6
    self.register_count += 8;
#if BX_SUPPORT_X86_64
    self.register_count += 8; // depends on cpu mode (only if 64bit
#endif /* BX_SUPPORT_X86_64 */
#endif /* BX_CPU_LEVEL >= 6 */
  }
  
  if (debugger_ctrl_options.show_debug_regs) {
    self.register_count += 6;
  }
  
  // free if needed
  if (self.register_mapping != nil) {
    free(self.register_mapping);
  }
  // allocate
  self.register_mapping = (debugger_register_mapping_t *)malloc(self.register_count * sizeof(debugger_register_mapping_t));
  
  // create mapping
  curRow = 0;
  
  if (debugger_ctrl_options.show_general_purpose_regs) {
#if BX_SUPPORT_X86_64 == 1
    for (reg_id=RAX; reg_id<=R15; reg_id++) {
#if 0 /* without ide has parsing probs */
    }
#endif
#else
    for (reg_id=RAX; reg_id<=RIP; reg_id++) {
#endif /* BX_SUPPORT_X86_64 == 1 */
      self.register_mapping[curRow].reg_id = reg_id;
      curRow++;
    }
    self.register_mapping[curRow].reg_id = EFLAGS;
    curRow++;
  }
  
  if (debugger_ctrl_options.show_segment_regs) {
    for (reg_id=CS; reg_id<=GS; reg_id++) {
      self.register_mapping[curRow].reg_id = reg_id;
      curRow++;
    }
  }
    
  if (debugger_ctrl_options.show_control_regs) {
    for (reg_id=CR0; reg_id<=CR3; reg_id++) {
      self.register_mapping[curRow].reg_id = reg_id;
      curRow++;
    }
#if BX_CPU_LEVEL >= 5
    self.register_mapping[curRow].reg_id = CR4;
    curRow++;
#endif /* BX_CPU_LEVEL >= 5 */
#if BX_CPU_LEVEL >= 6
    self.register_mapping[curRow].reg_id = MSR_EFER;
    curRow++;
#endif /* BX_CPU_LEVEL >= 6 */
  }
    
  if (debugger_ctrl_options.show_fpu_regs) {
    for (reg_id=FPU_ST0_F; reg_id<=FPU_ST7_E; reg_id+=2) {
      self.register_mapping[curRow].reg_id = reg_id;
      curRow++;
    }
  }
    
  if (debugger_ctrl_options.show_test_regs) {
#if BX_CPU_TEST_REGISTER
#if BX_CPU_LEVEL >= 3 && BX_CPU_LEVEL <= 6
    for (reg_id=TR3; reg_id<=TR5; reg_id++) {
      self.register_mapping[curRow].reg_id = reg_id;
      curRow++;
    }
#if BX_CPU_LEVEL >= 4
    for (reg_id=TR6; reg_id<=TR7; reg_id++) {
      self.register_mapping[curRow].reg_id = reg_id;
      curRow++;
    }
#endif /* BX_CPU_LEVEL >= 4 */
#endif /* BX_CPU_LEVEL >= 3 && BX_CPU_LEVEL <= 6 */
#endif /* BX_CPU_TEST_REGISTER */
  }
    
  if (debugger_ctrl_options.show_sse_regs) {
#if BX_CPU_LEVEL >= 6
    for (reg_id=SSE_XMM00_0; reg_id<=SSE_XMM07_1; reg_id+=2) {
      self.register_mapping[curRow].reg_id = reg_id;
      curRow++;
    }
#if BX_SUPPORT_X86_64
    for (reg_id=SSE_XMM08_0; reg_id<=SSE_XMM15_1; reg_id+=2) {
      self.register_mapping[curRow].reg_id = reg_id;
      curRow++;
    }
#endif /* BX_SUPPORT_X86_64 */
#endif /* BX_CPU_LEVEL >= 6 */
  }
    
  if (debugger_ctrl_options.show_debug_regs) {
    for (reg_id=DR0; reg_id<=DR7; reg_id++) {
      self.register_mapping[curRow].reg_id = reg_id;
      curRow++;
    }
  }
    
}




/**
 * numberOfRowsInTableView
 */
- (NSInteger)numberOfRowsInTableView:(NSTableView * _Nonnull) tableView {
  
  return self.register_count;
  
}


- (id)tableView:(NSTableView * _Nonnull)tableView objectValueForTableColumn:(NSTableColumn * _Nullable) tableColumn row:(NSInteger) row {
  
  NSString * cellValue;
  unsigned int rowRef;
  
  rowRef = self.register_mapping[row].reg_id;
  
  if ([tableColumn.identifier compare:@"col.name"] == NSOrderedSame) {
    cellValue = [NSString stringWithUTF8String:bx_dbg_new->smp_info.cpu_info[self.cpuNo].reg_value[rowRef].name];
  } else {
    UInt8 size;
    BOOL isHex;
    
    size = bx_dbg_new->smp_info.cpu_info[self.cpuNo].reg_value[rowRef].size;
    isHex = ([tableColumn.identifier compare:@"col.hex"] == NSOrderedSame);
    switch (size) {
      case 8: {
        if (isHex) {
          cellValue = [NSString stringWithFormat:@"0x%02X", (UInt8) bx_dbg_new->smp_info.cpu_info[self.cpuNo].reg_value[rowRef].value];
        } else {
          cellValue = [NSString stringWithFormat:@"%d", (UInt8) bx_dbg_new->smp_info.cpu_info[self.cpuNo].reg_value[rowRef].value ];
        }
        break;
      }
      case 16: {
        if (isHex) {
          cellValue = [NSString stringWithFormat:@"0x%04X", (UInt16) bx_dbg_new->smp_info.cpu_info[self.cpuNo].reg_value[rowRef].value];
        } else {
          cellValue = [NSString stringWithFormat:@"%d", (UInt16) bx_dbg_new->smp_info.cpu_info[self.cpuNo].reg_value[rowRef].value ];
        }
        break;
      }
      case 32: {
        if (isHex) {
          cellValue = [NSString stringWithFormat:@"0x%08X", (UInt32) bx_dbg_new->smp_info.cpu_info[self.cpuNo].reg_value[rowRef].value];
        } else {
          cellValue = [NSString stringWithFormat:@"%d", (UInt32) bx_dbg_new->smp_info.cpu_info[self.cpuNo].reg_value[rowRef].value ];
        }
        break;
      }
      default: {
        if (isHex) {
          cellValue = [NSString stringWithFormat:@"0x%016llX", (UInt64) bx_dbg_new->smp_info.cpu_info[self.cpuNo].reg_value[rowRef].value];
        } else {
          cellValue = [NSString stringWithFormat:@"%lld", (UInt64) bx_dbg_new->smp_info.cpu_info[self.cpuNo].reg_value[rowRef].value ];
        }
        break;
      }
    }
    
    
  }
    
  return cellValue;
  
}


@end


////////////////////////////////////////////////////////////////////////////////
// BXNSInstructionView
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSInstructionView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {

    self.cpuNo = 0;
    
    self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    self.ctrl_view = [[NSStackView alloc] initWithFrame:NSMakeRect(10, frameRect.size.height - 30, frameRect.size.width - 20, 20)];
    self.ctrl_view.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
    [self addSubview:self.ctrl_view];
    
//    // CPU select - only 1 at the beginning
//    self.cpu_select = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 40, 20) pullsDown:NO];
//    [self.cpu_select addItemWithTitle:@"CPU 0"];
//    [self.ctrl_view addArrangedSubview:self.cpu_select];
    
    self.btn_continue = [NSButton buttonWithTitle:@"Continue (⌃c)" target:self action:nil];
    [self.ctrl_view addArrangedSubview:self.btn_continue];
    
    self.btn_break = [NSButton buttonWithTitle:@"Break (⌃x)" target:self action:nil];
    [self.ctrl_view addArrangedSubview:self.btn_break];
    
    self.btn_step_over = [NSButton buttonWithTitle:@"Step Over (⌥s)" target:self action:nil];
    [self.ctrl_view addArrangedSubview:self.btn_step_over];

    self.btn_step = [NSButton buttonWithTitle:@"Step (⌃s)" target:self action:nil];
    [self.ctrl_view addArrangedSubview:self.btn_step];
    
    self.cnt_title = [NSTextField labelWithString:@"count:"];
    [self.ctrl_view addArrangedSubview:self.cnt_title];
    
    NSView * wrapper = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 80, 20)];
//    wrapper.autoresizingMask = NSViewHeightSizable;
    self.cnt_value = [BXNSTextField textFieldWithString:@"0000000000" TypeNotif:NO];
    self.cnt_value.autoresizingMask = NSViewHeightSizable;
    self.cnt_value.preferredMaxLayoutWidth = 80;
    self.cnt_value.stringValue = [NSString stringWithFormat:@"%lu", debugger_ctrl_options.cpu_step_count];
    [self.cnt_value setFormatter:[[BXNSNumberFormatter alloc] init]];
    [wrapper addSubview:self.cnt_value];
    [self.ctrl_view addArrangedSubview:wrapper];
    
    self.adr_title = [NSTextField labelWithString:@"Type:"];
    [self.ctrl_view addArrangedSubview:self.adr_title];
    
    self.adr_select = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 40, 20) pullsDown:NO];
    [self.adr_select addItemWithTitle:@"linear"];
    [self.adr_select addItemWithTitle:@"seg:ofs"];
    self.adr_select.objectValue = [NSNumber numberWithInt:0];
    [self.adr_select setAction:@selector(adrValueChanged:)];
    [self.adr_select setTarget:self];
    
    [self.ctrl_view addArrangedSubview:self.adr_select];
    
    self.asm_scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, frameRect.size.width, frameRect.size.height - 40)];
    self.asm_scroll.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.asm_scroll.hasVerticalScroller = YES;
    self.asm_scroll.hasHorizontalScroller = YES;
    self.asm_scroll.autohidesScrollers = YES;
    self.asm_scroll.borderType = NSNoBorder;
    
    self.table = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, frameRect.size.width, frameRect.size.height - 40)];
    self.table.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.table.usesAlternatingRowBackgroundColors = YES;
    self.table.headerView = [[NSTableHeaderView alloc] init];
    self.table.columnAutoresizingStyle = NSTableViewFirstColumnOnlyAutoresizingStyle;
    self.table.rowSizeStyle = NSTableViewRowSizeStyleCustom;
    self.table.rowHeight = 18;
    self.table.intercellSpacing = NSMakeSize(6, 6);
    
    self.markerCol = [[NSTableColumn alloc] initWithIdentifier:@"col.marker"];
    self.markerCol.headerCell = [[NSTableHeaderCell alloc] init];
    self.markerCol.title = @"";
    self.markerCol.editable = NO;
    self.markerCol.width = 30;
    [self.table addTableColumn:self.markerCol];
    
    self.addrCol = [[NSTableColumn alloc] initWithIdentifier:@"col.addr"];
    self.addrCol.headerCell = [[NSTableHeaderCell alloc] init];
    self.addrCol.title = @"Address";
    self.addrCol.editable = NO;
    self.addrCol.width = 150;
    [self.table addTableColumn:self.addrCol];
    
    self.instrCol = [[NSTableColumn alloc] initWithIdentifier:@"col.instr"];
    self.instrCol.headerCell = [[NSTableHeaderCell alloc] init];
    self.instrCol.title = @"Instruction";
    self.instrCol.editable = NO;
    self.instrCol.width = 300;
    [self.table addTableColumn:self.instrCol];
    
    self.bytesCol = [[NSTableColumn alloc] initWithIdentifier:@"col.bytes"];
    self.bytesCol.headerCell = [[NSTableHeaderCell alloc] init];
    self.bytesCol.title = @"Bytes";
    self.bytesCol.editable = NO;
    self.bytesCol.width = 200;
    [self.table addTableColumn:self.bytesCol];
    
    self.table.dataSource = (id)self;
    
    [self.asm_scroll setDocumentView:self.table];
    
    [self addSubview:self.asm_scroll];
    
    self.attributeMonospace = @{
      NSForegroundColorAttributeName:NSColor.textColor,
      NSFontAttributeName:[NSFont monospacedSystemFontOfSize:14 weight:NSFontWeightRegular]
    };
    
    [self updateFromMemory];
    
  }

  return self;

}

/**
 * updateFromMemory
 */
- (void)updateFromMemory {
  
  self.cs_rip_addr_lin = bx_dbg_get_laddr((UInt32)bx_dbg_new->smp_info.cpu_info[self.cpuNo].reg_value[CS].value, bx_dbg_new->smp_info.cpu_info[self.cpuNo].reg_value[RIP].value);
  
  bx_dbg_new->disassemble(
    self.cpuNo,
    true,
    {
      bx_dbg_new->smp_info.cpu_info[self.cpuNo].reg_value[RIP].value,
      (UInt32)bx_dbg_new->smp_info.cpu_info[self.cpuNo].reg_value[CS].value
    }, 
    debugger_ctrl_options.use_gas_syntax
  );
  
}
  
  
  
  
/**
 * adrValueChanged
 */
- (void)adrValueChanged:(id _Nonnull)sender {
  
}

/**
 * numberOfRowsInTableView
 */
- (NSInteger)numberOfRowsInTableView:(NSTableView * _Nonnull) tableView {
  
  return ASM_ENTRY_LINES;
  
}

/**
 * tableView
 */
- (id)tableView:(NSTableView * _Nonnull)tableView objectValueForTableColumn:(NSTableColumn * _Nullable) tableColumn row:(NSInteger) row {
  
  if ([tableColumn.identifier compare:@"col.marker"] == NSOrderedSame) {
    
    if (self.cs_rip_addr_lin == bx_dbg_new->asm_lines[row].addr.ofs) {
      // if cs:ip == address put image ->
      return @"->";
    }
    
    return @"";
    
  } else if ([tableColumn.identifier compare:@"col.addr"] == NSOrderedSame) {
    
    if (bx_dbg_new->smp_info.cpu_info[self.cpuNo].cpu_mode64) {
      return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"0x%016lX", bx_dbg_new->asm_lines[row].addr.ofs] attributes:self.attributeMonospace];
    } else {
      return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"0x%08X", (UInt32)bx_dbg_new->asm_lines[row].addr.ofs] attributes:self.attributeMonospace];
    }
    
  } else if ([tableColumn.identifier compare:@"col.instr"] == NSOrderedSame) {

    return [[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:(const char *)bx_dbg_new->asm_lines[row].text] attributes:self.attributeMonospace];
    
  } else {
    NSString * jStr;
    
    jStr = @"";
    for (int cnt=0; cnt<bx_dbg_new->asm_lines[row].len; cnt++) {
      jStr = [NSString stringWithFormat:@"%@0x%02X ", jStr, bx_dbg_new->asm_lines[row].data[cnt]];
    }
    
    return [[NSAttributedString alloc] initWithString:jStr attributes:self.attributeMonospace];
  }
  
}
  
@end


////////////////////////////////////////////////////////////////////////////////
// BXNSGDTView
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSGDTView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {



  }

  return self;

}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSIDTView
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSIDTView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {



  }

  return self;

}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNStackView
////////////////////////////////////////////////////////////////////////////////
@implementation BXNStackView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {
    
    self.cpuNo = 0;
    self.stack_buf = nil;
    
    self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.orientation = NSUserInterfaceLayoutOrientationVertical;
    
    self.header = [[NSStackView alloc] init];
    self.header.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self addArrangedSubview:self.header];
    
    self.size_label = [NSTextField labelWithString:@"Bytes"];
    [self.header addArrangedSubview:self.size_label];
    
    self.size_stack = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 40, 20) pullsDown:NO];
    [self.size_stack addItemWithTitle:@"2"];
    [self.size_stack addItemWithTitle:@"4"];
    [self.size_stack addItemWithTitle:@"8"];
    self.size_stack.objectValue = [NSNumber numberWithInt:0];
    [self.size_stack setAction:@selector(valueChanged:)];
    [self.size_stack setTarget:self];
    [self.header addArrangedSubview:self.size_stack];

    self.stack_scroll = [[NSScrollView alloc] initWithFrame:frameRect];
    self.stack_scroll.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.stack_scroll.hasVerticalScroller = YES;
    self.stack_scroll.hasHorizontalScroller = YES;
    self.stack_scroll.autohidesScrollers = YES;
    self.stack_scroll.borderType = NSNoBorder;
    
    self.table = [[NSTableView alloc] initWithFrame:frameRect];
    self.table.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.table.usesAlternatingRowBackgroundColors = YES;
    self.table.headerView = nil;//[[NSTableHeaderView alloc] init];
    self.table.columnAutoresizingStyle = NSTableViewFirstColumnOnlyAutoresizingStyle;
    self.table.rowSizeStyle = NSTableViewRowSizeStyleCustom;
    self.table.rowHeight = 18;
    self.table.intercellSpacing = NSMakeSize(6, 6);
    
    self.dataCol = [[NSTableColumn alloc] initWithIdentifier:@"col.data"];
    self.dataCol.headerCell = [[NSTableHeaderCell alloc] init];
    self.dataCol.title = @"";
    self.dataCol.editable = YES;
    self.dataCol.width = 200;
    [self.table addTableColumn:self.dataCol];
    self.table.dataSource = (id)self;
   
    [self.stack_scroll setDocumentView:self.table];
    
    [self addArrangedSubview:self.stack_scroll];
    
    self.stack_buf = (unsigned char *)malloc(8 * 64 * sizeof(unsigned char));
    
    self.attributeMonospace = @{
      NSForegroundColorAttributeName:NSColor.textColor,
      NSFontAttributeName:[NSFont monospacedSystemFontOfSize:14 weight:NSFontWeightRegular]
    };
    
    [self updateFromMemory];
    
  }

  return self;

}

/**
 * dealloc
 */
- (void)dealloc {
  
  if (self.stack_buf != nil) {
    free(self.stack_buf);
  }
  
}
  
/**
 * updateFromMemory
 */
- (void)updateFromMemory {
  
  bx_address laddr;
  
  laddr = BX_CPU(self.cpuNo)->get_laddr(BX_SEG_REG_SS, (bx_address) bx_dbg_new->smp_info.cpu_info[self.cpuNo].reg_value[RSP].value);
  
  if (bx_dbg_read_linear(self.cpuNo, laddr, 8 * 64, self.stack_buf)) {
    [self.table reloadData];
  }
  
}
  
/**
 * valueChanged
 */
- (void)valueChanged:(id _Nonnull)sender {
  
  debugger_ctrl_options.stack_bytes = (unsigned char)[sender titleOfSelectedItem].intValue;
  [self.table reloadData];
  
}
  
/**
 * numberOfRowsInTableView
 */
- (NSInteger)numberOfRowsInTableView:(NSTableView * _Nonnull) tableView {
  
  return 64;
  
}
  
/**
 * tableView
 */
- (id)tableView:(NSTableView * _Nonnull)tableView objectValueForTableColumn:(NSTableColumn * _Nullable) tableColumn row:(NSInteger) row {
  
  switch (debugger_ctrl_options.stack_bytes) {
    case 2: {
      UInt16 * wRef;
      
      wRef = (UInt16 *)self.stack_buf;
      return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"0x%04X", wRef[row]] attributes:self.attributeMonospace];
    }
    case 4: {
      UInt32 * dwRef;
      
      dwRef = (UInt32 *)self.stack_buf;
      return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"0x%08X", dwRef[row]] attributes:self.attributeMonospace];
    }
    case 8: {
      UInt64 * qwRef;
      
      qwRef = (UInt64 *)self.stack_buf;
      return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"0x%016llX", qwRef[row]] attributes:self.attributeMonospace];
    }
    default: {
      return @"";
    }
  }
  
}
  
@end


////////////////////////////////////////////////////////////////////////////////
// BXNSBreakpointView
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSBreakpointView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {



  }

  return self;

}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSPagingView
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSPagingView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {



  }

  return self;

}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSMemoryView
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSMemoryView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {

  self = [super initWithFrame:frameRect];
  if (self) {

    self.cpuNo = 0;
    
    self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    self.ctrl_view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, frameRect.size.width, 30)];
    self.ctrl_view.autoresizingMask = NSViewWidthSizable | NSViewMaxYMargin;
    [self addSubview:self.ctrl_view];
    
    self.addr_label = [NSTextField labelWithString:@"Address"];
    self.addr_label.frame = NSMakeRect(10, 0, 60, 20);
    [self.ctrl_view addSubview:self.addr_label];
    
    self.addr_value = [BXNSTextField textFieldWithString:@"09090909:09090909" TypeNotif:NO];
//    self.cnt_value.autoresizingMask = NSViewHeightSizable;
    self.addr_value.preferredMaxLayoutWidth = 160;
    self.addr_value.stringValue = [NSString stringWithFormat:@"%lu", debugger_ctrl_options.mem_displ_addr];
    [self.addr_value setFormatter:[[BXNSHexNumberFormatter alloc] init]];
    self.addr_value.frame = NSMakeRect(70, 2, 160, 20);
    [self.addr_value setAction:@selector(addrValueChanged:)];
    [self.addr_value setTarget:self];
    [self.ctrl_view addSubview:self.addr_value];
    
    self.page_label = [NSTextField labelWithString:@"Page"];
    self.page_label.frame = NSMakeRect(250, 0, 40, 20);
    [self.ctrl_view addSubview:self.page_label];
    
    self.prev_button = [NSButton buttonWithTitle:@"<" target:self action:nil];
    self.prev_button.bezelStyle = NSBezelStyleSmallSquare;
    self.prev_button.frame = NSMakeRect(290, 2, 30, 20);
    [self.prev_button setAction:@selector(prevButtonClick:)];
    [self.prev_button setTarget:self];
    [self.ctrl_view addSubview:self.prev_button];
    
    self.succ_button = [NSButton buttonWithTitle:@">" target:self action:nil];
    self.succ_button.bezelStyle = NSBezelStyleSmallSquare;
    self.succ_button.frame = NSMakeRect(320, 2, 30, 20);
    [self.succ_button setAction:@selector(succButtonClick:)];
    [self.succ_button setTarget:self];
    [self.ctrl_view addSubview:self.succ_button];
    
    self.bytes_label = [NSTextField labelWithString:@"Number of Bytes"];
    self.bytes_label.frame = NSMakeRect(360, 0, 120, 20);
    [self.ctrl_view addSubview:self.bytes_label];
    
    self.bytes_select = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 40, 20) pullsDown:NO];
    [self.bytes_select addItemWithTitle:@"16"];
    [self.bytes_select addItemWithTitle:@"32"];
    [self.bytes_select addItemWithTitle:@"64"];
    [self.bytes_select addItemWithTitle:@"128"];
    [self.bytes_select addItemWithTitle:@"256"];
    [self.bytes_select addItemWithTitle:@"512"];
    [self.bytes_select addItemWithTitle:@"1024"];
    [self.bytes_select addItemWithTitle:@"2048"];
    [self.bytes_select addItemWithTitle:@"4096"];
    [self.bytes_select addItemWithTitle:@"8192"];
    [self.bytes_select addItemWithTitle:@"16384"];
    [self.bytes_select addItemWithTitle:@"32768"];
    [self.bytes_select addItemWithTitle:@"65536"];
    self.bytes_select.objectValue = [NSNumber numberWithInt:debugger_ctrl_options.mem_displ_size];
    [self.bytes_select setAction:@selector(bytesValueChanged:)];
    [self.bytes_select setTarget:self];
    self.bytes_select.frame = NSMakeRect(470, 0, 80, 20);
    [self.ctrl_view addSubview:self.bytes_select];
    
    self.bytes_scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 40, frameRect.size.width, frameRect.size.height - 40)];
    self.bytes_scroll.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.bytes_scroll.hasVerticalScroller = YES;
    self.bytes_scroll.hasHorizontalScroller = NO;
    self.bytes_scroll.autohidesScrollers = YES;
    self.bytes_scroll.borderType = NSNoBorder;
    
    self.bytes_view = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 40, frameRect.size.width, frameRect.size.height - 40)];
    self.bytes_view.frame = NSMakeRect(0, 40, frameRect.size.width, frameRect.size.height - 40);
    self.bytes_view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.bytes_view.headerView = [[NSTableHeaderView alloc] init];
    self.bytes_view.dataSource = self;
    self.bytes_view.allowsColumnReordering = NO;
    self.bytes_view.gridStyleMask = NSTableViewSolidVerticalGridLineMask;
    self.bytes_view.usesStaticContents = NO;
    self.bytes_view.usesAlternatingRowBackgroundColors = YES;
//    self.bytes_view.style = NSTableViewStyleFullWidth;
    self.bytes_view.enabled = YES;
    self.bytes_view.rowSizeStyle = NSTableViewRowSizeStyleCustom;
    self.bytes_view.rowHeight = 18;
    self.bytes_view.intercellSpacing = NSMakeSize(6, 6);
    // gridStyleMask
    
    [self.bytes_scroll setDocumentView:self.bytes_view];
    
    self.addrCol = [[NSTableColumn alloc] initWithIdentifier:@"col.addr"];
    self.addrCol.headerCell = [[NSTableHeaderCell alloc] init];
    self.addrCol.title = @"Address";
    self.addrCol.editable = NO;
    self.addrCol.resizingMask = NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask;
    [self.bytes_view addTableColumn:self.addrCol];

    self.byteCol_0 = [[NSTableColumn alloc] initWithIdentifier:@"col.byte.0"];
    self.byteCol_0.headerCell = [[NSTableHeaderCell alloc] init];
    self.byteCol_0.title = @"00";
    self.byteCol_0.width = 25;
    self.byteCol_0.editable = NO;
    self.byteCol_0.resizingMask = NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask;
    [self.bytes_view addTableColumn:self.byteCol_0];

    self.byteCol_1 = [[NSTableColumn alloc] initWithIdentifier:@"col.byte.1"];
    self.byteCol_1.headerCell = [[NSTableHeaderCell alloc] init];
    self.byteCol_1.title = @"01";
    self.byteCol_1.width = 25;
    self.byteCol_1.editable = NO;
    self.byteCol_1.resizingMask = NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask;
    [self.bytes_view addTableColumn:self.byteCol_1];

    self.byteCol_2 = [[NSTableColumn alloc] initWithIdentifier:@"col.byte.2"];
    self.byteCol_2.headerCell = [[NSTableHeaderCell alloc] init];
    self.byteCol_2.title = @"02";
    self.byteCol_2.width = 25;
    self.byteCol_2.editable = NO;
    self.byteCol_2.resizingMask = NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask;
    [self.bytes_view addTableColumn:self.byteCol_2];

    self.byteCol_3 = [[NSTableColumn alloc] initWithIdentifier:@"col.byte.3"];
    self.byteCol_3.headerCell = [[NSTableHeaderCell alloc] init];
    self.byteCol_3.title = @"03";
    self.byteCol_3.width = 25;
    self.byteCol_3.editable = NO;
    self.byteCol_3.resizingMask = NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask;
    [self.bytes_view addTableColumn:self.byteCol_3];

    self.byteCol_4 = [[NSTableColumn alloc] initWithIdentifier:@"col.byte.4"];
    self.byteCol_4.headerCell = [[NSTableHeaderCell alloc] init];
    self.byteCol_4.title = @"04";
    self.byteCol_4.width = 25;
    self.byteCol_4.editable = NO;
    self.byteCol_4.resizingMask = NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask;
    [self.bytes_view addTableColumn:self.byteCol_4];

    self.byteCol_5 = [[NSTableColumn alloc] initWithIdentifier:@"col.byte.5"];
    self.byteCol_5.headerCell = [[NSTableHeaderCell alloc] init];
    self.byteCol_5.title = @"05";
    self.byteCol_5.width = 25;
    self.byteCol_5.editable = NO;
    self.byteCol_5.resizingMask = NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask;
    [self.bytes_view addTableColumn:self.byteCol_5];

    self.byteCol_6 = [[NSTableColumn alloc] initWithIdentifier:@"col.byte.6"];
    self.byteCol_6.headerCell = [[NSTableHeaderCell alloc] init];
    self.byteCol_6.title = @"06";
    self.byteCol_6.width = 25;
    self.byteCol_6.editable = NO;
    self.byteCol_6.resizingMask = NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask;
    [self.bytes_view addTableColumn:self.byteCol_6];

    self.byteCol_7 = [[NSTableColumn alloc] initWithIdentifier:@"col.byte.7"];
    self.byteCol_7.headerCell = [[NSTableHeaderCell alloc] init];
    self.byteCol_7.title = @"07";
    self.byteCol_7.width = 25;
    self.byteCol_7.editable = NO;
    self.byteCol_7.resizingMask = NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask;
    [self.bytes_view addTableColumn:self.byteCol_7];
    
    self.byteCol_8 = [[NSTableColumn alloc] initWithIdentifier:@"col.byte.8"];
    self.byteCol_8.headerCell = [[NSTableHeaderCell alloc] init];
    self.byteCol_8.title = @"08";
    self.byteCol_8.width = 25;
    self.byteCol_8.editable = NO;
    self.byteCol_8.resizingMask = NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask;
    [self.bytes_view addTableColumn:self.byteCol_8];

    self.byteCol_9 = [[NSTableColumn alloc] initWithIdentifier:@"col.byte.9"];
    self.byteCol_9.headerCell = [[NSTableHeaderCell alloc] init];
    self.byteCol_9.title = @"09";
    self.byteCol_9.width = 25;
    self.byteCol_9.editable = NO;
    self.byteCol_9.resizingMask = NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask;
    [self.bytes_view addTableColumn:self.byteCol_9];

    self.byteCol_A = [[NSTableColumn alloc] initWithIdentifier:@"col.byte.A"];
    self.byteCol_A.headerCell = [[NSTableHeaderCell alloc] init];
    self.byteCol_A.title = @"0A";
    self.byteCol_A.width = 25;
    self.byteCol_A.editable = NO;
    self.byteCol_A.resizingMask = NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask;
    [self.bytes_view addTableColumn:self.byteCol_A];

    self.byteCol_B = [[NSTableColumn alloc] initWithIdentifier:@"col.byte.B"];
    self.byteCol_B.headerCell = [[NSTableHeaderCell alloc] init];
    self.byteCol_B.title = @"0B";
    self.byteCol_B.width = 25;
    self.byteCol_B.editable = NO;
    self.byteCol_B.resizingMask = NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask;
    [self.bytes_view addTableColumn:self.byteCol_B];

    self.byteCol_C = [[NSTableColumn alloc] initWithIdentifier:@"col.byte.C"];
    self.byteCol_C.headerCell = [[NSTableHeaderCell alloc] init];
    self.byteCol_C.title = @"0C";
    self.byteCol_C.width = 25;
    self.byteCol_C.editable = NO;
    self.byteCol_C.resizingMask = NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask;
    [self.bytes_view addTableColumn:self.byteCol_C];

    self.byteCol_D = [[NSTableColumn alloc] initWithIdentifier:@"col.byte.D"];
    self.byteCol_D.headerCell = [[NSTableHeaderCell alloc] init];
    self.byteCol_D.title = @"0D";
    self.byteCol_D.width = 25;
    self.byteCol_D.editable = NO;
    self.byteCol_D.resizingMask = NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask;
    [self.bytes_view addTableColumn:self.byteCol_D];

    self.byteCol_E = [[NSTableColumn alloc] initWithIdentifier:@"col.byte.E"];
    self.byteCol_E.headerCell = [[NSTableHeaderCell alloc] init];
    self.byteCol_E.title = @"0E";
    self.byteCol_E.width = 25;
    self.byteCol_E.editable = NO;
    self.byteCol_E.resizingMask = NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask;
    [self.bytes_view addTableColumn:self.byteCol_E];

    self.byteCol_F = [[NSTableColumn alloc] initWithIdentifier:@"col.byte.F"];
    self.byteCol_F.headerCell = [[NSTableHeaderCell alloc] init];
    self.byteCol_F.title = @"0F";
    self.byteCol_F.width = 25;
    self.byteCol_F.editable = NO;
    self.byteCol_F.resizingMask = NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask;
    [self.bytes_view addTableColumn:self.byteCol_F];

//    self.byteCol = [[NSTableColumn alloc] initWithIdentifier:@"col.byte.0"];
//    self.byteCol.headerCell = [[NSTableHeaderCell alloc] init];
//    self.byteCol.title = @"Bytes";
//    self.byteCol.editable = NO;
//    self.byteCol.resizingMask = NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask;
//    [self.bytes_view addTableColumn:self.byteCol];

    self.stringCol = [[NSTableColumn alloc] initWithIdentifier:@"col.string"];
    self.stringCol.headerCell = [[NSTableHeaderCell alloc] init];
    self.stringCol.title = @"";
    self.stringCol.width = 200;
    self.stringCol.editable = NO;
    self.stringCol.resizingMask = NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask;
    [self.bytes_view addTableColumn:self.stringCol];

    [self addSubview:self.bytes_scroll];
    
    self.attributeMonospace = @{
      NSForegroundColorAttributeName:NSColor.textColor,
      NSFontAttributeName:[NSFont monospacedSystemFontOfSize:14 weight:NSFontWeightRegular]
    };
    
    [self updateFromMemory];
    
  }

  return self;

}

/**
 * updateFromMemory
 */
- (void)updateFromMemory {
  
  size_t buffer_size;
  
  buffer_size = (1 << (debugger_ctrl_options.mem_displ_size + 4));
  
  if (debugger_ctrl_options.mem_displ_addr == 0) {
    self.prev_button.enabled = NO;
  } else {
    self.prev_button.enabled = YES;
  }
  
  bx_dbg_new->memorydump(self.cpuNo, false, {debugger_ctrl_options.mem_displ_addr, 0}, buffer_size);
  
  //bx_dbg_new->mem_buffer
  [self.bytes_view reloadData];
  
}

/**
 * bytesValueChanged
 */
- (void)bytesValueChanged:(id _Nonnull)sender {
  
  debugger_ctrl_options.mem_displ_size = (unsigned char)[sender indexOfSelectedItem];
  [self updateFromMemory];
  
}

- (void)prevButtonClick:(id _Nonnull)sender {
  
  size_t buffer_size;
  
  buffer_size = (1 << (debugger_ctrl_options.mem_displ_size + 4));
  if (debugger_ctrl_options.mem_displ_addr < buffer_size) {
    debugger_ctrl_options.mem_displ_addr = 0;
  } else {
    debugger_ctrl_options.mem_displ_addr -= buffer_size;
  }
  
  if (bx_dbg_new->smp_info.cpu_info[self.cpuNo].cpu_mode64) {
    self.addr_value.stringValue = [NSString stringWithFormat:@"%016lX", debugger_ctrl_options.mem_displ_addr];
  } else {
    self.addr_value.stringValue = [NSString stringWithFormat:@"%08X", (UInt32)debugger_ctrl_options.mem_displ_addr];
  }
  
  [self updateFromMemory];
  
}

- (void)succButtonClick:(id _Nonnull)sender {
  
  size_t buffer_size;
  
  buffer_size = (1 << (debugger_ctrl_options.mem_displ_size + 4));
  debugger_ctrl_options.mem_displ_addr += buffer_size;
  
  if (bx_dbg_new->smp_info.cpu_info[self.cpuNo].cpu_mode64) {
    self.addr_value.stringValue = [NSString stringWithFormat:@"%016lX", debugger_ctrl_options.mem_displ_addr];
  } else {
    self.addr_value.stringValue = [NSString stringWithFormat:@"%08X", (UInt32)debugger_ctrl_options.mem_displ_addr];
  }
  
  [self updateFromMemory];
  
}

- (void)addrValueChanged:(id _Nonnull)sender {
  
  debugger_ctrl_options.mem_displ_addr = (UInt64)self.addr_value.hexnumberValue;
  [self updateFromMemory];
  
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  
  size_t buffer_size;
  
  buffer_size = (1 << (debugger_ctrl_options.mem_displ_size + 4));
  
  return buffer_size/16;
  
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *) tableColumn row:(NSInteger) row {
  
  if ([tableColumn.identifier compare:@"col.addr"] == NSOrderedSame) {

    if (bx_dbg_new->smp_info.cpu_info[self.cpuNo].cpu_mode64) {
      return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"0x%016lX", debugger_ctrl_options.mem_displ_addr + (row * 8)] attributes:self.attributeMonospace];
    } else {
      return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"0x%08X", (UInt32)debugger_ctrl_options.mem_displ_addr + (row * 16)] attributes:self.attributeMonospace];
    }

  } else if ([tableColumn.identifier hasPrefix:@"col.byte"]) {
    
    UInt8 bofs;
    NSString * subStr;
    
    subStr = [tableColumn.identifier substringFromIndex:9];
    bofs = subStr.UTF8String[0] - '0';
    if (bofs > 9) {
      bofs -= 7;
    }
    
    return [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%02X", (UInt8)bx_dbg_new->mem_buffer[(row * 16) + bofs]] attributes:self.attributeMonospace];
    
  } else {
    NSString * jStr;
    
    jStr = @"";
    for (int i=0; i<16; i++) {
      if (isprint(bx_dbg_new->mem_buffer[(row * 16) + i])) {
        jStr = [NSString stringWithFormat:@"%@%c", jStr, bx_dbg_new->mem_buffer[(row * 16) + i]];
      } else {
        jStr = [NSString stringWithFormat:@"%@.", jStr];
      }
    }
    return [[NSAttributedString alloc] initWithString:jStr attributes:self.attributeMonospace];
  }
  
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id) object forTableColumn:(NSTableColumn *) tableColumn row:(NSInteger) row {
  
}



@end


////////////////////////////////////////////////////////////////////////////////
// ???
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
// BXNSCpuTabContentView
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSCpuTabContentView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect SmpInfo:(bx_smp_info_t *) smp {
  
  self = [super initWithFrame:frameRect];
  if (self) {
    
    self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    // setup tab views
    self.tabViewLeft = [[BXNSTabView alloc] initWithFrame:NSMakeRect(0, 0, frameRect.size.width/2, frameRect.size.height)];
    self.tabViewLeft.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self addArrangedSubview:self.tabViewLeft];
    self.tabViewRight = [[BXNSTabView alloc] initWithFrame:NSMakeRect(0, 0, frameRect.size.width/2, frameRect.size.height)];
    self.tabViewRight.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self addArrangedSubview:self.tabViewRight];
    

    // insert into tab views
    for (int i=0; i<DBG_V_NONE; i++) {
      
      NSTabViewItem * item;
      
      item = nil;
      switch (debugger_view_tab_options[i].view) {
        case DBG_V_REGISTER: {
          self.registerView = [[BXNSRegisterView alloc] initWithFrame:NSMakeRect(0, 0, frameRect.size.width/2, frameRect.size.height)];
          item = [[NSTabViewItem alloc] init];
          item.label = @"Register";
          item.view = self.registerView;
          break;
        }
        case DBG_V_STACK: {
          self.stackView = [[BXNStackView alloc] initWithFrame:NSMakeRect(0, 0, frameRect.size.width/2, frameRect.size.height)];
          item = [[NSTabViewItem alloc] init];
          item.label = @"Stack";
          item.view = self.stackView;
          break;
        }
        case DBG_V_INSTRUCTION: {
          self.instructionView = [[BXNSInstructionView alloc] initWithFrame:NSMakeRect(0, 0, frameRect.size.width/2, frameRect.size.height)];
          item = [[NSTabViewItem alloc] init];
          item.label = @"Instruction";
          item.view = self.instructionView;
          break;
        }
        case DBG_V_GDT: {
          self.gdtView = [[BXNSGDTView alloc] initWithFrame:NSMakeRect(0, 0, frameRect.size.width/2, frameRect.size.height)];
          item = [[NSTabViewItem alloc] init];
          item.label = @"GDT";
          item.view = self.gdtView;
          break;
        }
        case DBG_V_IDT: {
          self.idtView = [[BXNSIDTView alloc] initWithFrame:NSMakeRect(0, 0, frameRect.size.width/2, frameRect.size.height)];
          item = [[NSTabViewItem alloc] init];
          item.label = @"IDT";
          item.view = self.idtView;
          break;
        }
        case DBG_V_PAGING: {
          self.pagingView = [[BXNSPagingView alloc] initWithFrame:NSMakeRect(0, 0, frameRect.size.width/2, frameRect.size.height)];
          item = [[NSTabViewItem alloc] init];
          item.label = @"Paging";
          item.view = self.pagingView;
          break;
        }
        case DBG_V_BREAKPOINT: {
          self.breakpointView = [[BXNSBreakpointView alloc] initWithFrame:NSMakeRect(0, 0, frameRect.size.width/2, frameRect.size.height)];
          item = [[NSTabViewItem alloc] init];
          item.label = @"Breakpoints";
          item.view = self.idtView;
          break;
        }
        case DBG_V_MEMORY: {
          self.memoryView = [[BXNSMemoryView alloc] initWithFrame:NSMakeRect(0, 0, frameRect.size.width/2, frameRect.size.height)];
          item = [[NSTabViewItem alloc] init];
          item.label = @"Memory";
          item.view = self.memoryView;
          break;
        }
        default: {
          break;
        }
      }
      
      if (item != nil) {
        if (debugger_view_tab_options[i].location == DBG_LOC_LEFT) {
          [self.tabViewLeft addTabViewItem:item];
        } else {
          [self.tabViewRight addTabViewItem:item];
        }
      }
      
    }
    
  }
  
  return self;
  
}

/**
 * moveToView
 */
- (void)moveToView:(debugger_view_location_t) dest View:(debugger_views_t) view {
  
  // TODO : ...
  
}



@end


////////////////////////////////////////////////////////////////////////////////
// BXNSDebugView
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSDebugView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {
  
  self = [super initWithFrame:frameRect];
  if (self) {
    
    self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.autoresizesSubviews = YES;
    
    self.ctrl_view = [[NSStackView alloc] initWithFrame:NSMakeRect(10, frameRect.size.height - 30, frameRect.size.width - 20, 20)];
    self.ctrl_view.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
    [self addSubview:self.ctrl_view];
    
    // CPU select - only 1 at the beginning
    self.cpu_select = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 40, 20) pullsDown:NO];
    for (UInt16 i=0; i<bx_dbg_new->smp_info.cpu_count; i++) {
      [self.cpu_select addItemWithTitle:[NSString stringWithFormat:@"CPU %d",i]];
    }
    self.cpu_select.objectValue = [NSNumber numberWithInt:debugger_ctrl_options.selected_cpu];
    [self.cpu_select setAction:@selector(cpuValueChanged:)];
    [self.cpu_select setTarget:self];
    [self.ctrl_view addArrangedSubview:self.cpu_select];
    
    self.btn_continue = [NSButton buttonWithTitle:@"Continue (⌃c)" target:self action:nil];
    [self.ctrl_view addArrangedSubview:self.btn_continue];
    
    self.btn_break = [NSButton buttonWithTitle:@"Break (⌃x)" target:self action:nil];
    [self.ctrl_view addArrangedSubview:self.btn_break];
    
    self.btn_step_over = [NSButton buttonWithTitle:@"Step Over (⌥s)" target:self action:nil];
    [self.ctrl_view addArrangedSubview:self.btn_step_over];

    self.btn_step = [NSButton buttonWithTitle:@"Step (⌃s)" target:self action:nil];
    [self.ctrl_view addArrangedSubview:self.btn_step];
    
    self.cnt_title = [NSTextField labelWithString:@"count:"];
    [self.ctrl_view addArrangedSubview:self.cnt_title];
    
    NSView * wrapper = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 80, 20)];
//    wrapper.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.cnt_value = [BXNSTextField textFieldWithString:@"0000000000" TypeNotif:NO];
    self.cnt_value.autoresizingMask = NSViewHeightSizable;
    self.cnt_value.preferredMaxLayoutWidth = 80;
    self.cnt_value.stringValue = [NSString stringWithFormat:@"%lu", debugger_ctrl_options.global_step_count];
    [self.cnt_value setFormatter:[[BXNSNumberFormatter alloc] init]];
    [wrapper addSubview:self.cnt_value];
    [self.ctrl_view addArrangedSubview:wrapper];
 
    
    self.cpu_view = [[BXNSCpuTabContentView alloc] initWithFrame:NSMakeRect(0, 0, frameRect.size.width, frameRect.size.height - 40) SmpInfo:nil];
    [self addSubview:self.cpu_view];
    
  }
  
  return self;
  
}

/**
 * cpuValueChanged
 */
- (void)cpuValueChanged:(id _Nonnull)sender {
  
  debugger_ctrl_options.selected_cpu = (unsigned char)[sender titleOfSelectedItem].intValue;
  
}
  
@end


////////////////////////////////////////////////////////////////////////////////
// BXNSOptionCtrlView
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSOptionCtrlView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {
  
  self = [super initWithFrame:frameRect];
  if (self) {
    
    self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.autoresizesSubviews = YES;
    
  }
  
  return self;
  
}

@end


////////////////////////////////////////////////////////////////////////////////
// BXNSOptionTabView
////////////////////////////////////////////////////////////////////////////////
@implementation BXNSOptionTabView

/**
 * initWithFrame
 */
- (instancetype _Nonnull)initWithFrame:(NSRect)frameRect {
  
  self = [super initWithFrame:frameRect];
  if (self) {
    
    self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.autoresizesSubviews = YES;
    
  }
  
  return self;
  
}

@end


#endif /* BX_DEBUGGER && BX_NEW_DEBUGGER_GUI */
