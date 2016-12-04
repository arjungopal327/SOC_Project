////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//tron_legacy_top.v: Top Level Module
//
// This file contains the top level module for the tron legacy multiplayer game, which uses a picoblaze microcontroller 
// on a Nexys4 FPGA board using Xilinx Artix-7 with keyboard interface
//
//Created By:		Manoj Prakash Vishwanathpur, Shrikrishna Pookala, Arjun Gopal and Aravind Kumaraswamy 
//Last Modified:	10-June-2015(Manoj)
//
//  Description:
//  ------------
// Top level module for the ECE 540 Project 4(tron legacy multi player)
// on the Nexys4 FPGA Board (Xilinx XC7A100T-CSG324)
// 
// References:
// (1)Design documents provided by Roy Kravitz.
// 
// External port names match pin names in the n4DDRfpga_withvideo.xdc constraints file
// un-commenting USB hub in constraints file is required for keyboard interface to work
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


module tron_legacy_top (
input 				clk,                 	    // 100MHz clock from on-board oscillator
	input				btnL, btnR,				// pushbutton inputs - left (db_btns[4])and right (db_btns[2])
	input				btnU, btnD,				// pushbutton inputs - up (db_btns[3]) and down (db_btns[1])
	input				btnC,					// pushbutton inputs - center button -> db_btns[5]
	input				btnCpuReset,			// red pushbutton input -> db_btns[0]
	input	[15:0]		sw,						// switch inputs
	input               PS2_CLK,                
	input               PS2_DATA,               // Keyboard data
	
	output	[15:0]		led,  					// LED outputs	
	
	output 	[6:0]		seg,					// Seven segment display cathode pins
	output              dp,
	output	[7:0]		an,						// Seven segment display anode pins	
	output  [3:0]       vga_red,vga_blue,vga_green, //VGA output ports 
    output              vga_vsync, vga_hsync,
	output	[7:0]		JA						// JA Header
); 

    // internal variables
	wire 	[15:0]		db_sw;					// debounced switches
	wire 	[5:0]		db_btns;				// debounced buttons
	wire				sysclk;					// 100MHz clock from on-board oscillator	
	wire				sysreset;				// system reset signal - asserted high to force reset
	
    // display digits
	wire 	[15:0]		chase_segs;				// chase segments from Rojobot (debug)
	wire    [7:0]       segs_int;               // sevensegment module the segments and the decimal point
    wire    [15:0]      char;                   //Keyboard signal
	
    //interface to picoblaze 1
    wire [11:0] address_1;
    wire [17:0] instruction_1;
    wire bram_enable_1;
    wire [7:0] port_id_1;
    wire [7:0] out_port_1;
    wire [7:0] in_port_1;
    wire write_strobe_1;
    wire k_write_strobe_1;
    wire read_strobe_1;
    wire interrupt_1;
    wire interrupt_ack_1;
    wire kcpsm6_sleep_1;
    wire kcpsm6_reset_1;
    wire rdl_1;
    
    //Interface to Picoblaze 2
    wire [11:0] address_2;
    wire [17:0] instruction_2;
    wire bram_enable_2;
    wire [7:0] port_id_2;
    wire [7:0] out_port_2;
    wire [7:0] in_port_2;
    wire write_strobe_2;
    wire k_write_strobe_2;
    wire read_strobe_2;
    wire interrupt_2;
    wire interrupt_ack_2;
    wire kcpsm6_sleep_2;
    wire kcpsm6_reset_2;
    wire rdl_2;
    wire               sys_interrupt;        //system interrupt to update frequently
    wire clk50mhz;                           //keyboard clock
    wire clk25mhz;                           //clock for DTG/VGA modules
    wire clk75mhz;
    wire locked;
    wire [1:0] pixel_data;                  
    wire [9:0] pixel_row, pixel_column;
    wire video_on;
    //interface with seven segment
    wire  [4:0]   dig7, dig6,
                  dig5, dig4,
                  dig3, dig2, 
				  dig1, dig0;
    wire  [7:0]	decpts;
    wire [7:0] LocX1, LocY1, LocX2, LocY2, Orientation1, Orientation2, gameover;
    wire [15:0] keyboard_input;
    wire reset;
    wire 	[63:0]		digits_out;

    //for dedicated reset button     
    assign kcpsm6_reset_1 = sysreset | rdl_1;
	assign kcpsm6_reset_2 = sysreset | rdl_2;
	
    // global assigns
	assign	sysclk = clk;
	assign 	sysreset = ~db_btns[0]; // btnCpuReset is asserted low
	
    //assign kcpsm6_reset = rdl | sysreset;
	assign dp = segs_int[7];
	assign seg = segs_int[6:0];
	assign	JA = {sysclk, sysreset, 6'b000000};
	assign kcpsm6_sleep = 1'b0;
    
    //Instantiating Picoblaze for Player 1
    kcpsm6 #(
	.interrupt_vector	(12'h3FF),
	.scratch_pad_memory_size(64),
	.hwbuild		(8'h00)
    )TRON_1 (
	.address 		(address_1),
	.instruction 	(instruction_1),
	.bram_enable 	(bram_enable_1),
	.port_id 		(port_id_1),
	.write_strobe 	(write_strobe_1),
	.k_write_strobe (k_write_strobe_1),
	.out_port 		(out_port_1),
	.read_strobe 	(read_strobe_1),
	.in_port 		(in_port_1),
	.interrupt 		(interrupt_1),
	.interrupt_ack 	(interrupt_ack_1),
	.reset 			(sysreset),
	.sleep			(kcpsm6_sleep_1),
	.clk 			(sysclk)
    ); 
    
    tronCycle_player1_ver2#( 
    .C_JTAG_LOADER_ENABLE  (1),                        
    .C_FAMILY ("7S"),                        
    .C_RAM_SIZE_KWORDS  (2)
)    tronCycle_player1(
    .address(address_1),
    .instruction(instruction_1), 
    .enable(bram_enable_1), 
    .rdl(rdl_1), 
    .clk(sysclk)
);    
    
    //Instantiating Picoblaze for Player 2
    kcpsm6 #(
	.interrupt_vector	(12'h3FF),
	.scratch_pad_memory_size(64),
	.hwbuild		(8'h00)
    )TRON_2 (
	.address 		(address_2),
	.instruction 	(instruction_2),
	.bram_enable 	(bram_enable_2),
	.port_id 		(port_id_2),
	.write_strobe 	(write_strobe_2),
	.k_write_strobe (k_write_strobe_2),
	.out_port 		(out_port_2),
	.read_strobe 	(read_strobe_2),
	.in_port 		(in_port_2),
	.interrupt 		(interrupt_2),
	.interrupt_ack 	(interrupt_ack_2),
	.reset 			(sysreset),
	.sleep			(kcpsm6_sleep_2),
	.clk 			(sysclk)
    ); 
    
    tronCycle_player2_ver2#( 
    .C_JTAG_LOADER_ENABLE  (1),                        
    .C_FAMILY ("7S"),                        
    .C_RAM_SIZE_KWORDS  (2)
)    tronCycle_player2(
    .address(address_2),
    .instruction(instruction_2), 
    .enable(bram_enable_2), 
    .rdl(rdl_2), 
    .clk(sysclk)
);    

    // instantiating interface module    
    nexys4_tron_if
    #(
       .RESET_POLARITY_LOW(0)
    )INTERFACE
    (
        .write_strobe_1(write_strobe_1),
        .read_strobe_1(read_strobe_1),
        .k_write_strobe_1(k_write_strobe_1),
        .interrupt_ack_1(interrupt_ack_1),
        .port_id_1(port_id_1),            //Addrin
        .out_port_1(out_port_1),           //datain
        .in_port_1(in_port_1),            //dataout
        .interrupt_1(interrupt_1),
    
    //Interface to Picoblaze 2
    
        .write_strobe_2(write_strobe_2),
        .read_strobe_2(read_strobe_2),
        .k_write_strobe_2(k_write_strobe_2),
        .interrupt_ack_2(interrupt_ack_2),
        .port_id_2(port_id_2),            //Addrin
        .out_port_2(out_port_2),           //datain
        .in_port_2(in_port_2),            //dataout
        .interrupt_2(interrupt_2),
        .gameover(gameover),
        .sys_interrupt(sys_interrupt),        //system interrupt to update frequently

    //interface with seven segment
        .dig7(dig7), 
        .dig6(dig6),
		.dig5(dig5), 
        .dig4(dig4),
		.dig3(dig3), 
        .dig2(dig2), 
		.dig1(dig1),
        .dig0(dig0),
        .decpts(decpts),
        .LED(led[11:8]),
    //interface with tron
        .LocX1(LocX1), 
        .LocY1(LocY1), 
        .LocX2(LocX2), 
        .LocY2(LocY2), 
        .Orientation1(Orientation1), 
        .Orientation2(Orientation2),
    //interface with debounce
        .db_btns(db_btns),
        .db_sw(db_sw),
        .clk(sysclk),
        .reset(sysreset),
	 //interface to keyboard
	    .keyboard_input(keyboard_input)
    );
    //instantiate interrupt generator module 
    generate_int
    #(
		.RESET_POLARITY_LOW(0)
    )RS
    (
    .clk(sysclk),
	.reset(sysreset),
    .sys_interrupt(sys_interrupt)
    );
    
    //Instantiating dtg
    dtg DT(
        .clock(clk25mhz),//25MHZ clock for VGA
        .rst(sysreset),
        .horiz_sync(vga_hsync),
        .vert_sync(vga_vsync),
        .video_on(video_on),
        .pixel_row(pixel_row), 
        .pixel_column(pixel_column)
        );   
    //Instantiating colorizer module     
    colorizer CZ(
        .video_on(video_on),
        .pixel_data(pixel_data),
        .red(vga_red),
        .green(vga_green),
        .blue(vga_blue),
        .clk(clk25mhz),
        .reset(sysreset)
        );
    
	
    clock_wizard CLK_25
    (
   // Clock in ports
  .clk_in1(clk),
  // Clock out ports  
  .clk_out1(clk25mhz),
  .clk_out2(clk75mhz),
  .clk_out3(clk50mhz),
  // Status and control signals               
  .reset(sysreset), 
  .locked(locked)            
  );    
    debounce
	#(
		.RESET_POLARITY_LOW(0),
		.SIMULATE()
	)  	DB
	(
		.clk(sysclk),	
		.pbtn_in({btnC,btnL,btnU,btnR,btnD,btnCpuReset}),
		.switch_in(sw),
		.pbtn_db(db_btns),
		.swtch_db(db_sw)
	);	
		
	// instantiate the 7-segment, 8-digit display
	
    sevensegment
	#(
		.RESET_POLARITY_LOW(0),
		.SIMULATE()
	) SSB
	(
		// inputs for control signals
		.d0(gameover[5:0]),
		.d1(dig1),
 		.d2(dig2),
		.d3(dig3),
		.d4(dig4),
		.d5(dig5),
		.d6(dig6),
		.d7(dig7),
		.dp(decpts),
		
		// outputs to seven segment display
		.seg(segs_int),			
		.an(an),
		
		// clock and reset signals (100 MHz clock, active high reset)
		.clk(sysclk),
		.reset(sysreset),
		
		// ouput for simulation only
		.digits_out(digits_out)
	);
	//instantiating decider block
decider DECIDER_BLOCK
	(
		.LocX1(LocX1),
		.LocY1(LocY1),
		.LocX2(LocX2),
		.LocY2(LocY2),
		.clk(sysclk),
        .clk25mhz(clk25mhz),
		.reset(sysreset),
        .pixel_row({2'b00,pixel_row[9:2]}),
        .pixel_column({2'b00,pixel_column[9:2]}),
        .pixel_data(pixel_data),
        .gameover(gameover),
		);
	//Instantiating keyboard module
keyboard key
 (
  .clk(clk50mhz),
  .ps2_clk(PS2_CLK),
  .ps2_data(PS2_DATA),
  .char(keyboard_input) 
 );
endmodule