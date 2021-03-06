//============================================================================
//  BBCMicro port to MiSTer
//  Copyright (C) 2018-2019 Sorgelig
//  Copyright (C) 2022 Iain Sharp
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [47:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef USE_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);


// Uncomment line below to reduce memory requirements by eliminating Co-processor CPU memory and sideways RAM
// This option is required when building the ICEDebugger on the DE10 Nano. Otherwise, leave undefined.
// `define use_small_memory

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_DTR} = '1;
assign {SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
// assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;
 
assign LED_USER  = ioctl_download | (vsd_sel & sd_act);
assign LED_DISK  = {1'b1,~vsd_sel & sd_act};
assign LED_POWER = 0;
assign BUTTONS   = 0;
assign VGA_SCALER= 0;
assign HDMI_FREEZE = 0;

 assign SDRAM_DQ[15:0] = 'Z;
// assign SDRAM_DQ[0] = HSync;
// assign SDRAM_DQ[1] = VSync;
// assign SDRAM_DQ[2] = HBlank;
// assign SDRAM_DQ[3] = VBlank;
// assign SDRAM_DQ[4] = ce_pix;
// assign SDRAM_DQ[5] = CLK_VIDEO;
// assign SDRAM_DQ[6] = red_vid;


wire [1:0] ar = status[14:13];
video_freak video_freak
(
	.*,
	.VGA_DE_IN(VGA_DE),
	.VGA_DE(),
	.ARX((!ar) ? 12'd4 : (ar - 1'd1)),
	.ARY((!ar) ? 12'd3 : 12'd0),
	.CROP_SIZE(0),
	.CROP_OFF(0),
	.SCALE(status[16:15])
);

// Configuration bits:
// See https://github.com/MiSTer-devel/Main_MiSTer/wiki/Core-configuration-string
// 02-03   - Scandouble settings
// 04 ( 4) - BBC B or Master
// 05-06   - Co processor
// 07-09   - Default video mode
// A (10) - Mouse as Joystick
// B (11) - Swap joysticks
// C (12) - Autostart
// D-E   - Aspect ratio
// F-G   - Image scaling
// H      - Reserved - MMFS or Floppy
// P-R (25-27) - MMFS V1 or V2
// S (28)- M7 Video opt
// T (29)- Master shadow video mode on boot
// U (30)- Master default FS
//
// Mask index : 
// 0 - MMFS Active
// 1 - DFS active
// 2 - Master selected
// 3 - Master selected and both MMFS and DFS active

`include "build_id.v" 
parameter AUTO_START_OPT = 12;
parameter FILE_SYS_OPT_L = 25;
parameter FILE_SYS_OPT_H = 27;
parameter M7_VIDEO_OPT = 28;
parameter M128_SHADOW_OPT = 29;
parameter M128_FS_OPT = 30;

parameter CONF_STR = {
	"BBCMicro;;",
	"-;",
	"OPR,Filesystem,MMFSv1,MMFSv2,DFS,MMFSv1&DFS,MMFSv2&DFS;",
	"h0S0,VHDIMGMMB;", // Allow .VHD or .MMB files to be loaded (MMFSv1) or .IMG (MMFS v2)
	"h1S1,SSDDSD;",
	"h1S2,SSDDSD;",
	"OC,Autostart,No,Yes;",
	"-;",
	"O4,Model,B(MOS6502),Master(R65SC12);",
	"O56,Co-Processor,None,MOS65C02;",
	"O79,Default video mode,0,1,2,3,4,5,6,7;",
	"h2OT,Default video mem.,Shadow,Main;",
	"h3OU,Default Filesystem,MMFS,DFS;",
	"-;",
	"ODE,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O23,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"OFG,Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer;",
	"OS,M7 Analogue Video,576p,576i;",
	"-;",
	"OA,Mouse as Joystick,Yes,No;",
	"OB,Swap Joysticks,No,Yes;",
	"-;",
	"R0,Reset;",
	"JA,Fire;",
	"V,v",`BUILD_DATE
};

wire mmfsv1;
wire mmfsv2;
wire mmfs;
wire dfs;
wire model_master;
assign mmfsv1 = (status[FILE_SYS_OPT_H:FILE_SYS_OPT_L] === 0) || (status[FILE_SYS_OPT_H:FILE_SYS_OPT_L] === 3);
assign mmfsv2 = (status[FILE_SYS_OPT_H:FILE_SYS_OPT_L] === 1) || (status[FILE_SYS_OPT_H:FILE_SYS_OPT_L] === 4);
assign mmfs = mmfsv1 || mmfsv2;
assign dfs = status[FILE_SYS_OPT_H:FILE_SYS_OPT_L] >= 2;
assign model_master = status[4];


/////////////////  CLOCKS  ////////////////////////

wire clk_sys; // IES: 96MHz (32 * 3), (24 * 4)
wire clk_48 = clk_sys & ce_48;
wire clk_32 = clk_sys & ce_32;
wire clk_24 = clk_sys & ce_24;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys)
);

(* direct_enable=1 *) reg ce_32;
(* direct_enable=1 *) reg ce_48;
(* direct_enable=1 *) reg ce_24;
always @(negedge clk_sys) begin
	reg [1:0] div32;
	reg [0:0] div48;
	reg [1:0] div24;
	
	div48 <= div48 + 1'd1;
	ce_48 <= !div48;
	
	div24 <= div24 + 1'd1;
	ce_24 <= !div24;
	
	div32 <= div32 + 1'd1;
	if(div32 == 2) div32 <= 0;
	ce_32 <= !div32;
	
	
end


/////////////////  HPS  ///////////////////////////
// IES: Hard Processor System

wire [31:0] status;
wire  [1:0] buttons;

wire [15:0] joy1, joy2;
wire  [7:0] joy1_x,joy1_y,joy2_x,joy2_y;

wire [10:0] ps2_key;
wire [24:0] ps2_mouse;

wire        ioctl_download;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire [7:0]  ioctl_dout;
wire        forced_scandoubler;
wire [21:0] gamma_bus;

wire [31:0] sd_lba[3];
wire [2:0]  sd_rd;
wire [2:0]  sd_wr;
wire [2:0]  sd_ack;
wire [12:0] sd_buff_addr;
wire [7:0]  sd_buff_dout;
wire [7:0]  sd_buff_din[3];
wire        sd_buff_wr;
wire [2:0]  img_mounted;
wire        img_readonly;
wire [63:0] img_size;
wire        sd_ack_conf;

wire [64:0] RTC;

hps_io #(.CONF_STR(CONF_STR),.VDNUM(3),.BLKSZ(2)) hps_io // IES Updated from c244


(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	//.conf_str(CONF_STR),

	.buttons(buttons),
	.status(status),
	.status_menumask({(model_master && dfs && mmfs), model_master, dfs , mmfs}),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),

	.RTC(RTC),

	.ps2_key(ps2_key),
	.ps2_mouse(ps2_mouse),

	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),

	.sd_lba(sd_lba),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr),
	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),

	.joystick_0(joy1),
	.joystick_1(joy2),
	.joystick_l_analog_0({joy1_y,joy1_x}),
	.joystick_l_analog_1({joy2_y,joy2_x})
);

/////////////////  RESET  /////////////////////////

wire reset = RESET | status[0] | buttons[1] | (status[AUTO_START_OPT] & img_mounted);

////////////////  MEMORY  /////////////////////////

reg m128 = 0;
always @(posedge clk_sys) if(reset_req) m128 <= model_master;

wire        mem_we_n;
wire [18:0] mem_addr;
wire  [7:0] mem_din;

reg  [17:0] rom_addr;
reg  [7:0] rom_dout;
reg  [7:0] rom_data;

(* ram_init_file = "roms/rom.mif" *) reg [7:0] rom[16 * 16384];
always @(posedge clk_sys) if(!ioctl_index && ioctl_wr && reset) rom[reset ? ioctl_addr[17:0] : rom_addr[17:0]] <= ioctl_dout;
always @(posedge clk_sys) rom_dout <= rom[rom_addr[17:0]];


// Beeb ROM Images
// NOTE: Slots 0-3 and 9-15 correspond to the equivalent paged ROMS in the BBC
// Slots 4-7 are presented as RAM and these ROMS are not in the paged ROM space
// The ROM in slot 4 becomes the high ROM used for the OS
// Slot 8 is special. In the BBC B it is split ROM/RAM used for MMFS. In MASTER it is normal paged ROM

// 00 00xx empty     
// 00 01xx empty     
// 00 10xx empty     
// 00 11xx m128/dfs.rom     
// 01 00xx bbcb/os12.rom   - High ROM     
// 01 01xx empty     
// 01 10xx empty     
// 01 11xx empty     
// 10 00xx bbcb/swmmfs.rom    - Must be in slot 8 because of split RAM/ROM in that slot     
// 10 01xx empty     
// 10 10xx empty     
// 10 11xx empty     
// 11 00xx empty     
// 11 01xx empty     
// 11 10xx bbcb/rammaster6
// 11 11xx bbcb/basic2.rom       

// Master ROM Images

// 00 00xx empty     
// 00 01xx empty     
// 00 10xx empty  
// 00 11xx m128/mammfs.rom       
// 01 00xx m128/mos.rom    - High ROM      
// 01 01xx empty     
// 01 10xx empty     
// 01 11xx empty     
// 10 00xx empty     
// 10 01xx m128/dfs.rom          
// 10 10xx m128/viewsht.rom      
// 10 11xx m128/edit.rom         
// 11 00xx m128/basic4.rom       
// 11 01xx m128/adfs.rom         
// 11 10xx m128/view.rom         
// 11 11xx m128/terminal.rom      

always_comb begin
	rom_addr[13:0] = mem_addr[13:0];
	case({m128, mem_addr[17:14]})
		'b0_00_11: rom_addr[17:14] =  4; //bbcb/Acorn-DFS-2.26.rom
		'b0_01_00: rom_addr[17:14] =  0; //bbcb/os12.rom         
		'b0_10_00: rom_addr[17:14] = mmfsv1 ?  1 : 14; //bbcb/swmmfs.rom (v1) or //bbcb/swmmfs.rom (v2) - Must be in slot 8 because of split RAM/ROM in that slot
		'b0_11_10: rom_addr[17:14] =  2; //bbcb/ram_master_v6.rom 
		'b0_11_11: rom_addr[17:14] =  3; //bbcb/basic2.rom           
		'b1_00_11: rom_addr[17:14] = mmfsv1 ?  5 : 15;  //m128/mammfs.rom  (v1) //m128/mammfs.rom (v2)	
		'b1_01_00: rom_addr[17:14] =  6; //m128/mos.rom          
		'b1_10_01: rom_addr[17:14] =  7; //m128/dfs.rom          
		'b1_10_10: rom_addr[17:14] =  8; //m128/viewsht.rom      
		'b1_10_11: rom_addr[17:14] =  9; //m128/edit.rom         
		'b1_11_00: rom_addr[17:14] = 10; //m128/basic4.rom       
		'b1_11_01: rom_addr[17:14] = 11; //m128/adfs.rom         
		'b1_11_10: rom_addr[17:14] = 12; //m128/view.rom         
		'b1_11_11: rom_addr[17:14] = 13; //m128/terminal.rom      
		  default: rom_addr[17:14] =  0;
	endcase
end

always_comb begin
	case({m128, mem_addr[17:14]})
		'b0_01_00,
		'b0_11_10,
		'b0_11_11,	
		'b1_01_00,
		'b1_10_10,
		'b1_10_11,
		'b1_11_00,
		'b1_11_01,
		'b1_11_10,
		'b1_11_11: rom_data = rom_dout;
		'b0_00_11,
		'b1_10_01: rom_data = (dfs) ? rom_dout : 0; // Enable/disable DFS
		'b0_10_00,
		'b1_00_11: rom_data = (mmfs) ? rom_dout : 0; // Enable/disable MMFS
		  default: rom_data = 0;
	endcase
end

reg [7:0] ram_dout;

// See definition of use_small_memory for explanation
`ifdef use_small_memory
	reg [7:0] ram[5 * 16384];
	always @(posedge clk_sys) if(mem_addr[18] & mem_addr[17] & old_we & ~mem_we_n) ram[mem_addr[16:0]] <= mem_din;
	always @(posedge clk_sys) if(mem_addr[17]) ram_dout <= ram[mem_addr[16:0]]; else ram_dout <=0;
`else
	reg [7:0] ram[212992];
	always @(posedge clk_sys) if(mem_addr[18] & old_we & ~mem_we_n) ram[mem_addr[17:0]] <= mem_din;
	always @(posedge clk_sys) ram_dout <= ram[mem_addr[17:0]];
`endif


reg old_we;
always @(posedge clk_sys) old_we <= mem_we_n;

// 16k blocks of RAM (not all RAM in each block is used)
// 00 00xx  Co Processor
// 00 01xx  Co Processor
// 00 10xx  Co Processor
// 00 11xx  Co Processor
// 01 00xx  RAM Slot 4
// 01 01xx  RAM Slot 5
// 01 10xx  RAM Slot 6
// 01 11xx  RAM Slot 7
// 10 00xx  Main memory
// 10 01xx  Main memory
// 10 1000  Filing System RAM (4K, at C000-CFFF) (unused in Beeb Mode)
// 10 1001  Filing System RAM (4K, at D000-DFFF) (unused in Beeb Mode)
// 10 1010  Private RAM (4K, at 8000-8FFF)       (unused in Beeb Mode)
// 10 1011  Shadow memory (4K, at 3000-3FFF)     (unused in Beeb Mode)
// 10 11xx  Shadow memory (16K, at 4000-7FFF)    (unused in Beeb Mode)
// 11 00xx  RAM Slot 8 (B600-BFFF) For SWMMFS - BBC B Only
// 11 01xx  unused
// 11 10xx  unused
// 11 11xx  unused


///////////////////////////////////////////////////

wire reset_req = reset;

wire [7:0] joya_x = 8'hFF - {~ax[7],ax[6:0]};
wire [7:0] joya_y = 8'hFF - {~ay[7],ay[6:0]};
wire [7:0] joyb_x = 8'hFF - {~joy2_x[7],joy2_x[6:0]};
wire [7:0] joyb_y = 8'hFF - {~joy2_y[7],joy2_y[6:0]};


wire       ce_pix;

bbc_micro_core BBCMicro(
    .clksys(clk_sys),
	.clock_32(clk_32),
	.clock_48(clk_48),
	.clock_avr(clk_24),

	.hard_reset_n(~reset),
//	.reset_req(reset_req),

    .ps2_mse_clk (),
    .ps2_mse_data(),

	 .mister_key(ps2_key),
	 .mister_mouse(status[10] ? ps2_mouse : 25'd0),

	.video_sel(clk_sel),
	.video_cepix(ce_pix),
//	.video_cerate(ce_rate),
	.video_red(red_vid),
	.video_green(green_vid),
	.video_blue(blue_vid),
	.video_vblank(VBlank),
	.video_hblank(HBlank),
	.video_vsync(VSync),
	.video_hsync(HSync),
	.m7_video_opt(status[M7_VIDEO_OPT]),
	.odd_field(odd_field),

	.audio_l(AUDIO_L),
	.audio_r(AUDIO_R),

	.ext_nOE(),
	.ext_nWE(mem_we_n),
	.ext_nCS(),
	.ext_A(mem_addr),
	.ext_Dout(mem_addr[18] ? ram_dout : rom_data),
	.ext_Din(mem_din),

	.SDMISO(sdmiso),
	.SDCLK(sdclk),
	.SDMOSI(sdmosi),
	.SDSS(sdss),

	.caps_led(),
	.shift_led(),
	
	.RTC(RTC),

	.keyb_dip({4'b0000, status[AUTO_START_OPT], ~status[9:7]}),
	
	// cmos_options stores extra options that would normally be in CMOS on Master 128
	// Format:
	// b0 = Use shadow memory for default mode (1 = Yes)
	// b4-1 = ROM # for default file system: 3 for MMFS or 9 for DFS
	.cmos_options({(~dfs || (mmfs && dfs && ~status[M128_FS_OPT]))?4'd3:4'd9, ~status[M128_SHADOW_OPT]}),
	
	.ext_keyb_led1(),
	.ext_keyb_led2(),
	.ext_keyb_led3(),
	.ext_keyb_1mhz(),
	.ext_keyb_en_n(),
	.ext_keyb_pa(),
	.ext_keyb_rst_n(),
	.ext_keyb_ca2(),
	.ext_keyb_pa7(),
	
	.ps2config(),

	.joystick1_x(    status[11] ? {joyb_x,joyb_x[7:4]} : {joya_x,joya_x[7:4]}),
	.joystick1_y(    status[11] ? {joyb_y,joyb_y[7:4]} : {joya_y,joya_y[7:4]}),
	.joystick1_fire( status[11] ? ~joy2[4] : ~af),

	.joystick2_x(   ~status[11] ? {joya_x,joya_x[7:4]} : {joyb_x,joyb_x[7:4]}),
	.joystick2_y(   ~status[11] ? {joya_y,joya_y[7:4]} : {joyb_y,joyb_y[7:4]}),
	.joystick2_fire(~status[11] ? ~joy2[4] : ~af),
	
	.avr_reset(reset),
	.avr_RxD(UART_RXD),
	.avr_TxD(UART_TXD),

	.cpu_addr(), // IES: Debugging
	.m128_mode(m128),
	.copro_mode(|status[6:5]),
	
	.img_mounted    ( img_mounted[2:1] ),
	.img_size       ( img_size       ),
	.sd_lba         ( fd_sd_lba      ),
	.sd_rd          ( sd_rd[2:1]       ),
	.sd_wr          ( sd_wr[2:1]       ),
	.sd_ack         ( sd_ack[2:1]      ),
	.sd_buff_addr   ( sd_buff_addr[8:0]   ),
	.sd_dout        ( sd_buff_dout   ),
	.sd_din         ( fd_sd_buff_din ),
	.sd_dout_strobe ( sd_buff_wr ),
	
	.p_spi_ssel(),
	.p_spi_sck(),
	.p_spi_mosi(),
	.p_spi_miso(),
	.p_irq_b(),
	.p_nmi_b(),
	.p_rst_b(),
	.ext_tube_r_nw(),
	.ext_tube_nrst(),
	.ext_tube_ntube(),
	.ext_tube_phi2(),
	.ext_tube_a(),
	.ext_tube_di(),
	.ext_tube_do(),
	.test()
);


wire [31:0] fd_sd_lba;
wire [7:0] fd_sd_buff_din;


always @(posedge clk_48)
begin
	// ajs hack for now
	sd_buff_din[1] <= fd_sd_buff_din;
	sd_lba[1]      <=  fd_sd_lba;
	sd_buff_din[2] <= fd_sd_buff_din;
	sd_lba[2]      <=fd_sd_lba;

end

wire [7:0] audio_sn;

assign AUDIO_MIX = 0;
assign AUDIO_S = 1;


wire [1:0] scale = status[3:2];

wire HSync, VSync, HBlank, VBlank, clk_sel, odd_field;
wire [3:0] red_vid,green_vid,blue_vid;

assign CLK_VIDEO = clk_sys;
video_mixer #(640, 1, 1) mixer
(
	// .ce_pix(clock_48 & ce_pix),
	 .ce_pix(ce_pix),
	.freeze_sync(),
	
	.*,

	.hq2x(scale == 1),
	.scandoubler(scale || forced_scandoubler),

	.R(red_vid),
	.G(green_vid),
	.B(blue_vid)
);
// Testing shows that best results for the HDMI output are:
// Mode 0 - 6: Always set VGA_F1 to 0 even when interlaced - therefore and with ~clk_sel
// Mode 7: When using progressive output then set VGA_F1 to 0, when using interlace output set VGA_F1 based on the interlace field
assign VGA_F1 = (~clk_sel) & status[M7_VIDEO_OPT] & ~ odd_field;
assign VGA_SL = scale ? scale - 1'd1 : 2'd0;

//////////////////   SD   ///////////////////

wire sdclk;
wire sdmosi;
wire sdmiso = vsd_sel ? vsdmiso : SD_MISO;
wire sdss;

reg vsd_sel = 0;
always @(posedge clk_sys) if(img_mounted[0]) vsd_sel <= |img_size;

wire vsdmiso;
sd_card #(.WIDE(0)) sd_card // IES Updated from c244
(
	.*,
	
	.img_mounted(img_mounted[0]),
	.sd_buff_addr(sd_buff_addr[8:0]),
	.sd_rd(sd_rd[0]),
	.sd_wr(sd_wr[0]),
	.sd_ack(sd_ack[0]),
	
	.sd_lba(sd_lba[0]),
	.sd_buff_din(sd_buff_din[0]),
	
	.clk_spi(clk_sys),
	.sdhc(1),
	.sck(sdclk),
	.ss(sdss | ~vsd_sel),
	.mosi(sdmosi),
	.miso(vsdmiso)
);

assign SD_CS   = sdss   |  vsd_sel;
assign SD_SCK  = sdclk  & ~vsd_sel;
assign SD_MOSI = sdmosi & ~vsd_sel;

reg sd_act;

always @(posedge clk_sys) begin
	reg old_mosi, old_miso;
	integer timeout = 0;

	old_mosi <= sdmosi;
	old_miso <= sdmiso;

	sd_act <= 0;
	if(timeout < 2000000) begin
		timeout <= timeout + 1;
		sd_act <= 1;
	end

	if((old_mosi ^ sdmosi) || (old_miso ^ sdmiso)) timeout <= 0;
end


//////////////////   ANALOG AXIS   ///////////////////
reg        emu = 0;
wire [7:0] ax = emu ? mx[7:0] : joy1_x;
wire [7:0] ay = emu ? my[7:0] : joy1_y;
wire [7:0] af = emu ? |ps2_mouse[1:0] : joy1[4];

reg  signed [8:0] mx = 0;
wire signed [8:0] mdx = {ps2_mouse[4],ps2_mouse[4],ps2_mouse[15:9]};
wire signed [8:0] mdx2 = (mdx > 10) ? 9'd10 : (mdx < -10) ? -8'd10 : mdx;
wire signed [8:0] nmx = mx + mdx2;

reg  signed [8:0] my = 0;
wire signed [8:0] mdy = {ps2_mouse[5],ps2_mouse[5],ps2_mouse[23:17]};
wire signed [8:0] mdy2 = (mdy > 10) ? 9'd10 : (mdy < -10) ? -9'd10 : mdy;
wire signed [8:0] nmy = my - mdy2;

always @(posedge clk_sys) begin
	reg old_stb = 0;
	
	old_stb <= ps2_mouse[24];
	if(old_stb != ps2_mouse[24]) begin
		emu <= 1;
		mx <= (nmx < -128) ? -9'd128 : (nmx > 127) ? 9'd127 : nmx;
		my <= (nmy < -128) ? -9'd128 : (nmy > 127) ? 9'd127 : nmy;
	end

	if(joy1 || reset_req || status[10]) begin
		emu <= 0;
		mx <= 0;
		my <= 0;
	end
end

endmodule
