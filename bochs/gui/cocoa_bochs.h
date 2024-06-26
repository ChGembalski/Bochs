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

#ifndef BX_GUI_COCOA_BOCHS_H

  #define BX_GUI_COCOA_BOCHS_H

  #define MACOS_NSEventModifierFlagKeyUp      0x8000000000000000
  #define MACOS_NSEventModifierFlagMouse      0x4000000000000000
  #define MACOS_NSEventModifierFlagFocus      0x2000000000000000
  #define MACOS_NSEventModifierFlagSpecial    0x1000000000000000
  #define MACOS_NSEventModifierMaskDepend     0x0000FFFF00000000

  struct BXNSApplicationImpl;

  typedef void (* ButtonHandler) (void);

  typedef enum {
    BX_GUI_WINDOW_UNDEFINED,
    BX_GUI_WINDOW_CONFIGURATION,
    BX_GUI_WINDOW_VGA_DISPLAY,
    BX_GUI_WINDOW_LOGGING,
#if BX_DEBUGGER && BX_NEW_DEBUGGER_GUI
    BX_GUI_WINDOW_DEBUGGER,
    BX_GUI_WINDOW_DEBUGGER_CONFIG
#endif /* BX_DEBUGGER && BX_NEW_DEBUGGER_GUI */
  } gui_window_type_t;

  typedef enum {
    BX_PROPERTY_UNDEFINED = -1,
    BX_PROPERTY_START_SIM,
    BX_PROPERTY_CONT_SIM,
    BX_PROPERTY_STEP_SIM,
    BX_PROPERTY_STEP_N_SIM,
    BX_PROPERTY_BREAK_SIM,
    BX_PROPERTY_QUIT_SIM,
    BX_PROPERTY_RESET_SIM,
    BX_PROPERTY_CONFIG_LOAD,
    BX_PROPERTY_CONFIG_SAVE,
    BX_PROPERTY_CONFIG_RESET,
    BX_PROPERTY_BOCHS_ABOUT,
#if BX_DEBUGGER && BX_NEW_DEBUGGER_GUI
    BX_PROPERTY_WINDOW_DEBUGGER,
#endif /* BX_DEBUGGER && BX_NEW_DEBUGGER_GUI */
  } property_t;

  typedef struct {
    unsigned        headerbar_y;
    unsigned short  xres;
    unsigned short  yres;
  } vga_settings_t;

  typedef enum {
    SIM_INIT,
    SIM_STOP,
    SIM_PAUSE,
    SIM_RUN,
    SIM_TERMINATE
  } simulation_state_t;

#if BX_DEBUGGER && BX_NEW_DEBUGGER_GUI

  typedef enum {
    DBG_V_REGISTER,
    DBG_V_STACK,
    DBG_V_INSTRUCTION,
    DBG_V_GDT,
    DBG_V_IDT,
    DBG_V_PAGING,
    DBG_V_BREAKPOINT,
    DBG_V_MEMORY,
    DBG_V_NONE
  } debugger_views_t;

  typedef enum {
    DBG_LOC_LEFT,
    DBG_LOC_RIGHT
  } debugger_view_location_t;
  
  typedef struct {
    debugger_views_t          view;
    debugger_view_location_t  location;
  } debugger_view_config_t;

  typedef struct {
    bool                      show_general_purpose_regs;
    bool                      show_segment_regs;
    bool                      show_control_regs;
    bool                      show_fpu_regs;
    bool                      show_test_regs;
    bool                      show_sse_regs;
    bool                      show_debug_regs;
    
    bool                      use_gas_syntax;
    
    unsigned char             selected_cpu;
    unsigned long             global_step_count;
    
    unsigned char             stack_bytes;
    unsigned long             cpu_step_count;
    bool                      addr_displ_seg_ofs;
    
    unsigned char             mem_displ_size;
    unsigned long             mem_displ_addr;
  } debugger_ctrl_config_t;

  typedef struct {
    unsigned int              reg_id;
  } debugger_register_mapping_t;

#endif /* BX_DEBUGGER && BX_NEW_DEBUGGER_GUI */

  class BXGuiCocoaApplication {

  private:
    BXNSApplicationImpl * BXCocoaApplication;

  public:
    BXGuiCocoaApplication();
    ~BXGuiCocoaApplication();

    void onBochsThreadExit();

    void showWindow(gui_window_type_t window, bool bShow);
    void activateWindow(gui_window_type_t window);
    void activateMenu(property_t type, bool bActivate);
    int getProperty(property_t property, bool bWait);
    void waitPropertySet(unsigned cnt, unsigned property, ...);
    void setProperty(property_t property, int value);

    void setSimulationState(simulation_state_t new_state);
    void showModalInfo(unsigned char level, const char * prefix, const char * msg);
    void showModalQuestion(unsigned char level, const char * prefix, const char * msg, int * result);
    void showModalParamRequest(void * vparam, int * result);

    void postLogMessage(unsigned char level, unsigned char mode, const char * prefix, const char * msg);

    void getScreenConfiguration(unsigned int * width, unsigned int * height, unsigned char * bpp);
    void dimension_update(unsigned x, unsigned y, unsigned fwidth, unsigned fheight, unsigned bpp);
    void clear_screen(void);


    unsigned create_bitmap(const unsigned char *bmap, unsigned xdim, unsigned ydim);
    unsigned headerbar_bitmap(unsigned bmap_id, unsigned alignment, ButtonHandler handler);
    void replace_bitmap(unsigned hbar_id, unsigned bmap_id);
    void show_headerbar(void);

    void setup_charmap(unsigned char * charmapA, unsigned char * charmapB, unsigned char w, unsigned char h);
    void set_font(bool font2, unsigned pos, unsigned char * charmap);
    void draw_char(bool crsr, bool font2, unsigned char fgcolor, unsigned char bgcolor, unsigned short int charpos, unsigned short int x, unsigned short int y, unsigned char w, unsigned char h);
    bool palette_change(unsigned char index, unsigned char red, unsigned char green, unsigned char blue);

    void graphics_tile_update(unsigned char * tile, unsigned x, unsigned y, unsigned w, unsigned h);
    const unsigned char * getVGAdisplayPtr(void);
    void graphics_tile_update_in_place(unsigned x, unsigned y, unsigned w, unsigned h);

    void render(void);

    void captureMouse(bool cap, unsigned x, unsigned y);
    bool hasMouseCapture(void);
    bool hasEvent(void);
    unsigned long getEvent(void);
    
    int get_clipboard_text(unsigned char ** bytes, int * nbytes);
    int set_clipboard_text(char * text_snapshot, int len);
    void beep(void);
    void show_ips(unsigned ips_count);
    void toggle_fullscreen(bool enable);
    
    void set_tooltip(unsigned hbar_id, const char * tip);
    
    // Debugger
#if BX_DEBUGGER && BX_NEW_DEBUGGER_GUI

    void createDebuggerUI(void);
    void updateDebugger(int cpu);

    void dbg_addOutputText(char * txt);

#endif /* BX_DEBUGGER && BX_NEW_DEBUGGER_GUI */

  };

  extern BXGuiCocoaApplication * bxcocoagui;
  extern int main_argc;
  extern char ** main_argv;

#endif /* BX_GUI_COCOA_BOCHS_H */
