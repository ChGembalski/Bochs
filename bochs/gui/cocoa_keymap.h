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

#ifndef BX_GUI_COCOA_KEYMAP_H

#define BX_GUI_COCOA_KEYMAP_H

// scancode table if no keymap
Bit32s scancode_tbl[] = {
  // 00 ... 0F
  BX_KEY_A,
  BX_KEY_S,
  BX_KEY_D,
  BX_KEY_F,
  BX_KEY_H,
  BX_KEY_G,
  BX_KEY_Z,
  BX_KEY_X,
  BX_KEY_C,
  BX_KEY_V,
  BX_KEY_UNHANDLED, // kVK_ISO_Section
  BX_KEY_B,
  BX_KEY_Q,
  BX_KEY_W,
  BX_KEY_E,
  BX_KEY_R,
  // 10 ... 1F
  BX_KEY_Y,
  BX_KEY_T,
  BX_KEY_1,
  BX_KEY_2,
  BX_KEY_3,
  BX_KEY_4,
  BX_KEY_6,
  BX_KEY_5,
  BX_KEY_EQUALS,
  BX_KEY_9,
  BX_KEY_7,
  BX_KEY_MINUS,
  BX_KEY_8,
  BX_KEY_0,
  BX_KEY_RIGHT_BRACKET,
  BX_KEY_O,
  // 20 ... 2F
  BX_KEY_U,
  BX_KEY_LEFT_BRACKET,
  BX_KEY_I,
  BX_KEY_P,
    BX_KEY_ENTER,
  BX_KEY_L,
  BX_KEY_J,
  BX_KEY_SINGLE_QUOTE,
  BX_KEY_K,
  BX_KEY_SEMICOLON,
  BX_KEY_BACKSLASH,
  BX_KEY_COMMA,
  BX_KEY_SLASH,
  BX_KEY_N,
  BX_KEY_M,
  BX_KEY_PERIOD,
  // 30 ... 3F
    BX_KEY_TAB,
    BX_KEY_SPACE,
  BX_KEY_GRAVE,
    BX_KEY_BACKSPACE,
  BX_KEY_UNHANDLED,
    BX_KEY_ESC,
  BX_KEY_UNHANDLED, // kVK_RightCommand
  BX_KEY_UNHANDLED, // kVK_Command
    BX_KEY_SHIFT_L, // kVK_Shift
    BX_KEY_CAPS_LOCK, // kVK_CapsLock
    BX_KEY_ALT_L, // kVK_Option
    BX_KEY_CTRL_L,  // kVK_Control
    BX_KEY_SHIFT_R, // kVK_RightShift
    BX_KEY_ALT_R, // kVK_RightOption
    BX_KEY_CTRL_R,  // kVK_RightControl
  BX_KEY_UNHANDLED, // kVK_Function
  // 40 ... 4F
  BX_KEY_UNHANDLED, // F17
  BX_KEY_PERIOD, // kVK_ANSI_KeypadDecimal
  BX_KEY_UNHANDLED,
  BX_KEY_KP_MULTIPLY,
  BX_KEY_UNHANDLED,
  BX_KEY_KP_ADD,
  BX_KEY_UNHANDLED,
  BX_KEY_MENU, // kVK_ANSI_KeypadClear
  BX_KEY_UNHANDLED,// kVK_VolumeUp
  BX_KEY_UNHANDLED,// kVK_VolumeDown
  BX_KEY_UNHANDLED,// kVK_Mute
  BX_KEY_KP_DIVIDE,
  BX_KEY_KP_ENTER,
  BX_KEY_UNHANDLED,
  BX_KEY_KP_SUBTRACT,
  BX_KEY_UNHANDLED,// F18
  // 50 ... 5F
  BX_KEY_UNHANDLED,// F19
  BX_KEY_EQUALS,
  BX_KEY_0,
  BX_KEY_1,
  BX_KEY_2,
  BX_KEY_3,
  BX_KEY_4,
  BX_KEY_5,
  BX_KEY_6,
  BX_KEY_7,
  BX_KEY_UNHANDLED,// F20
  BX_KEY_8,
  BX_KEY_9,
  BX_KEY_UNHANDLED, // kVK_JIS_Yen
  BX_KEY_UNHANDLED, // kVK_JIS_Underscore
  BX_KEY_UNHANDLED, // kVK_JIS_KeypadComma
  // 60 ... 6F
    BX_KEY_F5,
    BX_KEY_F6,
    BX_KEY_F7,
    BX_KEY_F3,
    BX_KEY_F8,
    BX_KEY_F9,
  BX_KEY_UNHANDLED, // kVK_JIS_Eisu
    BX_KEY_F11,
  BX_KEY_UNHANDLED, // kVK_JIS_Kana
  BX_KEY_UNHANDLED,//F13
  BX_KEY_UNHANDLED,// F16
  BX_KEY_UNHANDLED,// F14
  BX_KEY_UNHANDLED,
    BX_KEY_F10,
  BX_KEY_UNHANDLED,
    BX_KEY_F12,
  // 70 ... 7F
  BX_KEY_UNHANDLED,
  BX_KEY_UNHANDLED,// F15
  BX_KEY_UNHANDLED,// kVK_Help
    BX_KEY_HOME,
    BX_KEY_PAGE_UP,
    BX_KEY_DELETE,
    BX_KEY_F4,
    BX_KEY_END,
    BX_KEY_F2,
    BX_KEY_PAGE_DOWN,
    BX_KEY_F1,
    BX_KEY_LEFT,
    BX_KEY_RIGHT,
    BX_KEY_DOWN,
    BX_KEY_UP,
  BX_KEY_UNHANDLED,
  // 80 ... 8F

};

/*
 *  Summary:
 *    Virtual keycodes
 *
 *  Discussion:
 *    These constants are the virtual keycodes defined originally in
 *    Inside Mac Volume V, pg. V-191. They identify physical keys on a
 *    keyboard. Those constants with "ANSI" in the name are labeled
 *    according to the key position on an ANSI-standard US keyboard.
 *    For example, kVK_ANSI_A indicates the virtual keycode for the key
 *    with the letter 'A' in the US keyboard layout. Other keyboard
 *    layouts may have the 'A' key label on a different physical key;
 *    in this case, pressing 'A' will generate a different virtual
 *    keycode.
 */
enum {
  kVK_ANSI_A                    = 0x00,
  kVK_ANSI_S                    = 0x01,
  kVK_ANSI_D                    = 0x02,
  kVK_ANSI_F                    = 0x03,
  kVK_ANSI_H                    = 0x04,
  kVK_ANSI_G                    = 0x05,
  kVK_ANSI_Z                    = 0x06,
  kVK_ANSI_X                    = 0x07,
  kVK_ANSI_C                    = 0x08,
  kVK_ANSI_V                    = 0x09,
  kVK_ANSI_B                    = 0x0B,
  kVK_ANSI_Q                    = 0x0C,
  kVK_ANSI_W                    = 0x0D,
  kVK_ANSI_E                    = 0x0E,
  kVK_ANSI_R                    = 0x0F,
  kVK_ANSI_Y                    = 0x10,
  kVK_ANSI_T                    = 0x11,
  kVK_ANSI_1                    = 0x12,
  kVK_ANSI_2                    = 0x13,
  kVK_ANSI_3                    = 0x14,
  kVK_ANSI_4                    = 0x15,
  kVK_ANSI_6                    = 0x16,
  kVK_ANSI_5                    = 0x17,
  kVK_ANSI_Equal                = 0x18,
  kVK_ANSI_9                    = 0x19,
  kVK_ANSI_7                    = 0x1A,
  kVK_ANSI_Minus                = 0x1B,
  kVK_ANSI_8                    = 0x1C,
  kVK_ANSI_0                    = 0x1D,
  kVK_ANSI_RightBracket         = 0x1E,
  kVK_ANSI_O                    = 0x1F,
  kVK_ANSI_U                    = 0x20,
  kVK_ANSI_LeftBracket          = 0x21,
  kVK_ANSI_I                    = 0x22,
  kVK_ANSI_P                    = 0x23,
  kVK_ANSI_L                    = 0x25,
  kVK_ANSI_J                    = 0x26,
  kVK_ANSI_Quote                = 0x27,
  kVK_ANSI_K                    = 0x28,
  kVK_ANSI_Semicolon            = 0x29,
  kVK_ANSI_Backslash            = 0x2A,
  kVK_ANSI_Comma                = 0x2B,
  kVK_ANSI_Slash                = 0x2C,
  kVK_ANSI_N                    = 0x2D,
  kVK_ANSI_M                    = 0x2E,
  kVK_ANSI_Period               = 0x2F,
  kVK_ANSI_Grave                = 0x32,
  kVK_ANSI_KeypadDecimal        = 0x41,
  kVK_ANSI_KeypadMultiply       = 0x43,
  kVK_ANSI_KeypadPlus           = 0x45,
  kVK_ANSI_KeypadClear          = 0x47,
  kVK_ANSI_KeypadDivide         = 0x4B,
  kVK_ANSI_KeypadEnter          = 0x4C,
  kVK_ANSI_KeypadMinus          = 0x4E,
  kVK_ANSI_KeypadEquals         = 0x51,
  kVK_ANSI_Keypad0              = 0x52,
  kVK_ANSI_Keypad1              = 0x53,
  kVK_ANSI_Keypad2              = 0x54,
  kVK_ANSI_Keypad3              = 0x55,
  kVK_ANSI_Keypad4              = 0x56,
  kVK_ANSI_Keypad5              = 0x57,
  kVK_ANSI_Keypad6              = 0x58,
  kVK_ANSI_Keypad7              = 0x59,
  kVK_ANSI_Keypad8              = 0x5B,
  kVK_ANSI_Keypad9              = 0x5C
};

/* keycodes for keys that are independent of keyboard layout*/
enum {
  kVK_Return                    = 0x24,
  kVK_Tab                       = 0x30,
  kVK_Space                     = 0x31,
  kVK_Delete                    = 0x33,
  kVK_Escape                    = 0x35,
  kVK_Command                   = 0x37,
  kVK_Shift                     = 0x38,
  kVK_CapsLock                  = 0x39,
  kVK_Option                    = 0x3A,
  kVK_Control                   = 0x3B,
  kVK_RightCommand              = 0x36,
  kVK_RightShift                = 0x3C,
  kVK_RightOption               = 0x3D,
  kVK_RightControl              = 0x3E,
  kVK_Function                  = 0x3F,
  kVK_F17                       = 0x40,
  kVK_VolumeUp                  = 0x48,
  kVK_VolumeDown                = 0x49,
  kVK_Mute                      = 0x4A,
  kVK_F18                       = 0x4F,
  kVK_F19                       = 0x50,
  kVK_F20                       = 0x5A,
  kVK_F5                        = 0x60,
  kVK_F6                        = 0x61,
  kVK_F7                        = 0x62,
  kVK_F3                        = 0x63,
  kVK_F8                        = 0x64,
  kVK_F9                        = 0x65,
  kVK_F11                       = 0x67,
  kVK_F13                       = 0x69,
  kVK_F16                       = 0x6A,
  kVK_F14                       = 0x6B,
  kVK_F10                       = 0x6D,
  kVK_F12                       = 0x6F,
  kVK_F15                       = 0x71,
  kVK_Help                      = 0x72,
  kVK_Home                      = 0x73,
  kVK_PageUp                    = 0x74,
  kVK_ForwardDelete             = 0x75,
  kVK_F4                        = 0x76,
  kVK_End                       = 0x77,
  kVK_F2                        = 0x78,
  kVK_PageDown                  = 0x79,
  kVK_F1                        = 0x7A,
  kVK_LeftArrow                 = 0x7B,
  kVK_RightArrow                = 0x7C,
  kVK_DownArrow                 = 0x7D,
  kVK_UpArrow                   = 0x7E
};

/* ISO keyboards only*/
enum {
  kVK_ISO_Section               = 0x0A
};

/* JIS keyboards only*/
enum {
  kVK_JIS_Yen                   = 0x5D,
  kVK_JIS_Underscore            = 0x5E,
  kVK_JIS_KeypadComma           = 0x5F,
  kVK_JIS_Eisu                  = 0x66,
  kVK_JIS_Kana                  = 0x68
};

/* Modifier */
enum {
  kMod_Command                  = 0b00000011,
  kMod_Command_Left             = 0b00000001,
  kMod_Command_Right            = 0b00000010,
  kMod_Shift                    = 0b00001100,
  kMod_Shift_Left               = 0b00000100,
  kMod_Shift_Right              = 0b00001000,
  kMod_Option                   = 0b00110000,
  kMod_Option_Left              = 0b00010000,
  kMod_Option_Right             = 0b00100000,
  kMod_Control                  = 0b11000000,
  kMod_Control_Left             = 0b01000000,
  kMod_Control_Right            = 0b10000000
};

typedef struct {
  const char *name;
  Bit32u value;
} keyTableEntry;

#define DEF_MAC_KEY(key) { #key, key },

keyTableEntry keytable[] = {

  DEF_MAC_KEY(kVK_ANSI_A)
  DEF_MAC_KEY(kVK_ANSI_S)
  DEF_MAC_KEY(kVK_ANSI_D)
  DEF_MAC_KEY(kVK_ANSI_F)
  DEF_MAC_KEY(kVK_ANSI_H)
  DEF_MAC_KEY(kVK_ANSI_G)
  DEF_MAC_KEY(kVK_ANSI_Z)
  DEF_MAC_KEY(kVK_ANSI_X)
  DEF_MAC_KEY(kVK_ANSI_C)
  DEF_MAC_KEY(kVK_ANSI_V)
  DEF_MAC_KEY(kVK_ANSI_B)
  DEF_MAC_KEY(kVK_ANSI_Q)
  DEF_MAC_KEY(kVK_ANSI_W)
  DEF_MAC_KEY(kVK_ANSI_E)
  DEF_MAC_KEY(kVK_ANSI_R)
  DEF_MAC_KEY(kVK_ANSI_Y)
  DEF_MAC_KEY(kVK_ANSI_T)
  DEF_MAC_KEY(kVK_ANSI_1)
  DEF_MAC_KEY(kVK_ANSI_2)
  DEF_MAC_KEY(kVK_ANSI_3)
  DEF_MAC_KEY(kVK_ANSI_4)
  DEF_MAC_KEY(kVK_ANSI_6)
  DEF_MAC_KEY(kVK_ANSI_5)
  DEF_MAC_KEY(kVK_ANSI_Equal)
  DEF_MAC_KEY(kVK_ANSI_9)
  DEF_MAC_KEY(kVK_ANSI_7)
  DEF_MAC_KEY(kVK_ANSI_Minus)
  DEF_MAC_KEY(kVK_ANSI_8)
  DEF_MAC_KEY(kVK_ANSI_0)
  DEF_MAC_KEY(kVK_ANSI_RightBracket)
  DEF_MAC_KEY(kVK_ANSI_O)
  DEF_MAC_KEY(kVK_ANSI_U)
  DEF_MAC_KEY(kVK_ANSI_LeftBracket)
  DEF_MAC_KEY(kVK_ANSI_I)
  DEF_MAC_KEY(kVK_ANSI_P)
  DEF_MAC_KEY(kVK_ANSI_L)
  DEF_MAC_KEY(kVK_ANSI_J)
  DEF_MAC_KEY(kVK_ANSI_Quote)
  DEF_MAC_KEY(kVK_ANSI_K)
  DEF_MAC_KEY(kVK_ANSI_Semicolon)
  DEF_MAC_KEY(kVK_ANSI_Backslash)
  DEF_MAC_KEY(kVK_ANSI_Comma)
  DEF_MAC_KEY(kVK_ANSI_Slash)
  DEF_MAC_KEY(kVK_ANSI_N)
  DEF_MAC_KEY(kVK_ANSI_M)
  DEF_MAC_KEY(kVK_ANSI_Period)
  DEF_MAC_KEY(kVK_ANSI_Grave)
  DEF_MAC_KEY(kVK_ANSI_KeypadDecimal)
  DEF_MAC_KEY(kVK_ANSI_KeypadMultiply)
  DEF_MAC_KEY(kVK_ANSI_KeypadPlus)
  DEF_MAC_KEY(kVK_ANSI_KeypadClear)
  DEF_MAC_KEY(kVK_ANSI_KeypadDivide)
  DEF_MAC_KEY(kVK_ANSI_KeypadEnter)
  DEF_MAC_KEY(kVK_ANSI_KeypadMinus)
  DEF_MAC_KEY(kVK_ANSI_KeypadEquals)
  DEF_MAC_KEY(kVK_ANSI_Keypad0)
  DEF_MAC_KEY(kVK_ANSI_Keypad1)
  DEF_MAC_KEY(kVK_ANSI_Keypad2)
  DEF_MAC_KEY(kVK_ANSI_Keypad3)
  DEF_MAC_KEY(kVK_ANSI_Keypad4)
  DEF_MAC_KEY(kVK_ANSI_Keypad5)
  DEF_MAC_KEY(kVK_ANSI_Keypad6)
  DEF_MAC_KEY(kVK_ANSI_Keypad7)
  DEF_MAC_KEY(kVK_ANSI_Keypad8)
  DEF_MAC_KEY(kVK_ANSI_Keypad9)

  // ISO keyboards only
  DEF_MAC_KEY(kVK_ISO_Section)

  // JIS keyboards only
  DEF_MAC_KEY(kVK_JIS_Yen)
  DEF_MAC_KEY(kVK_JIS_Underscore)
  DEF_MAC_KEY(kVK_JIS_KeypadComma)
  DEF_MAC_KEY(kVK_JIS_Eisu)
  DEF_MAC_KEY(kVK_JIS_Kana)

  // keycodes for keys that are independent of keyboard layout
  DEF_MAC_KEY(kVK_Return)
  DEF_MAC_KEY(kVK_Tab)
  DEF_MAC_KEY(kVK_Space)
  DEF_MAC_KEY(kVK_Delete)
  DEF_MAC_KEY(kVK_Escape)
  DEF_MAC_KEY(kVK_Command)
  DEF_MAC_KEY(kVK_Shift)
  DEF_MAC_KEY(kVK_CapsLock)
  DEF_MAC_KEY(kVK_Option)
  DEF_MAC_KEY(kVK_Control)
  DEF_MAC_KEY(kVK_RightCommand)
  DEF_MAC_KEY(kVK_RightShift)
  DEF_MAC_KEY(kVK_RightOption)
  DEF_MAC_KEY(kVK_RightControl)
  DEF_MAC_KEY(kVK_Function)
  DEF_MAC_KEY(kVK_F17)
  DEF_MAC_KEY(kVK_VolumeUp)
  DEF_MAC_KEY(kVK_VolumeDown)
  DEF_MAC_KEY(kVK_Mute)
  DEF_MAC_KEY(kVK_F18)
  DEF_MAC_KEY(kVK_F19)
  DEF_MAC_KEY(kVK_F20)
  DEF_MAC_KEY(kVK_F5)
  DEF_MAC_KEY(kVK_F6)
  DEF_MAC_KEY(kVK_F7)
  DEF_MAC_KEY(kVK_F3)
  DEF_MAC_KEY(kVK_F8)
  DEF_MAC_KEY(kVK_F9)
  DEF_MAC_KEY(kVK_F11)
  DEF_MAC_KEY(kVK_F13)
  DEF_MAC_KEY(kVK_F16)
  DEF_MAC_KEY(kVK_F14)
  DEF_MAC_KEY(kVK_F10)
  DEF_MAC_KEY(kVK_F12)
  DEF_MAC_KEY(kVK_F15)
  DEF_MAC_KEY(kVK_Help)
  DEF_MAC_KEY(kVK_Home)
  DEF_MAC_KEY(kVK_PageUp)
  DEF_MAC_KEY(kVK_ForwardDelete)
  DEF_MAC_KEY(kVK_F4)
  DEF_MAC_KEY(kVK_End)
  DEF_MAC_KEY(kVK_F2)
  DEF_MAC_KEY(kVK_PageDown)
  DEF_MAC_KEY(kVK_F1)
  DEF_MAC_KEY(kVK_LeftArrow)
  DEF_MAC_KEY(kVK_RightArrow)
  DEF_MAC_KEY(kVK_DownArrow)
  DEF_MAC_KEY(kVK_UpArrow)

  // Modifier
  DEF_MAC_KEY(kMod_Command)
  DEF_MAC_KEY(kMod_Command_Left)
  DEF_MAC_KEY(kMod_Command_Right)
  DEF_MAC_KEY(kMod_Shift)
  DEF_MAC_KEY(kMod_Shift_Left)
  DEF_MAC_KEY(kMod_Shift_Right)
  DEF_MAC_KEY(kMod_Option)
  DEF_MAC_KEY(kMod_Option_Left)
  DEF_MAC_KEY(kMod_Option_Right)
  DEF_MAC_KEY(kMod_Control)
  DEF_MAC_KEY(kMod_Control_Left)
  DEF_MAC_KEY(kMod_Control_Right)
              
  { NULL, 0 }
};

#endif /* BX_GUI_COCOA_KEYMAP_H */
