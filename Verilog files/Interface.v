///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Interface.v:
//This module provides register interface to all the blocks
//
//Created By:		Manoj Prakash Vishwanathpur, Shrikrishna Pookala, Arjun Gopal and Aravind Kumaraswamy 
//Last Modified:	10-June-2015(Manoj)
//
// Description:
// ------------
//  This module provides interface for PicoBlaze 1 and PicoBlaze 2, External keyboard, FPGA On-board controls 
//and exchanges signals from Decider block.
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module nexys4_tron_if
#(
    parameter integer RESET_POLARITY_LOW = 1
)
(
     //Interface to PicoBlaze 1
    input               write_strobe_1,
                        read_strobe_1,
                        k_write_strobe_1,
                        interrupt_ack_1,
    input [7:0]         port_id_1,            //Addrin
                        out_port_1,           //datain
    output reg [7:0]    in_port_1,            //dataout
    output reg          interrupt_1,
    
    //Interface to Picoblaze 2
    
    input               write_strobe_2,
                        read_strobe_2,
                        k_write_strobe_2,
                        interrupt_ack_2,
    input [7:0]         port_id_2,            //Addrin
                        out_port_2,           //datain
    output reg [7:0]    in_port_2,            //dataout
    output reg          interrupt_2,
    
    input [7:0]         gameover,             //Signal from decider block
    input               sys_interrupt,        //system interrupt to update frequently

    //interface registers for On-board seven segment LED display
    output reg  [4:0]   dig7, dig6,
						dig5, dig4,
						dig3, dig2, 
						dig1, dig0,
    output reg  [7:0]	decpts,
    output reg [11:0]	LED,	             // for debug
    
    //Location and orientation signals to decider block
    output reg [7:0] LocX1, LocY1, LocX2, LocY2, Orientation1, Orientation2,
    
    //interface to debounce block 
    input [5:0]  db_btns,
    input [15:0] db_sw,
    
	//Interface with Keyboard
	input[15:0]  keyboard_input, 
    
    input clk,reset
);

 //reset asserted high
    wire reset_in = RESET_POLARITY_LOW ? ~reset : reset;
 //Registers to save data
    reg [7:0] LocX1_reg, LocY1_reg, LocX2_reg, LocY2_reg, Orientation1_reg, Orientation2_reg, gameover_reg;   
//Keyboard inputs to picoblaze
	wire [4:0] input_to_picoblaze;	
//Left and right buttons for player 2 from keyboard
    reg	kb_L2,kb_R2,kb_L1,kb_R1,start_space;		 
//Continuously assign data from keyboard 	
	assign input_to_picoblaze = {start_space,kb_R2,kb_L2,kb_L1,kb_R1}; 
    
    
    //Register Interface begins
    //read registers
    always @(posedge clk)begin
        case(port_id_1[4:0])    //Picoblaze 1 port ID
            5'b00000:   in_port_1 <= LED[7:0];
            5'b00001:   in_port_1 <= {3'b000, dig3};
            5'b00010:   in_port_1 <= {3'b000, dig2};
            5'b00011:   in_port_1 <= {3'b000, dig1};
            5'b00100:   in_port_1 <= {3'b000, dig0};
            5'b00101:   in_port_1 <= {4'b0000,decpts[3:0]};
            5'b00110:   in_port_1 <= LocX1;
            5'b00111:   in_port_1 <= LocY1;
            5'b01000:   in_port_1 <= Orientation1;
            5'b01001:   in_port_1 <= {3'b000, input_to_picoblaze};      //Data from keyboard
            5'b01010:   in_port_1 <= gameover;
            default:    in_port_1 <= 8'hxx;
        endcase
    end
    
 //write registers          
    always @(posedge clk) begin
	if(reset_in) begin
		LocX1_reg <= 8'h03;
		LocY1_reg <= 8'h03;
		Orientation1_reg <= 8'h01;
	end
	else begin
        if(write_strobe_1) begin
            case(port_id_1[4:0]) 
            5'b00000:   LED[7:0]<= out_port_1;
            5'b00001:   dig3    <= out_port_1[4:0];
            5'b00010:   dig2    <= out_port_1[4:0];
            5'b00011:   dig1    <= out_port_1[4:0];
            5'b00100:   dig0    <= out_port_1[4:0];
            5'b00101:   decpts[3:0] <= out_port_1[3:0];
            5'b00110:   LocX1_reg	<=	out_port_1;
            5'b00111:   LocY1_reg	<=	out_port_1;
            5'b01000:   Orientation1_reg <= out_port_1;
            default:    ;
            endcase
        end
	end
end
    //read register for second player
   always @(posedge clk)begin
        case(port_id_2[4:0])
           5'b00110:   in_port_2 <= LocX2;
           5'b00111:   in_port_2 <= LocY2;
           5'b01000:   in_port_2 <= Orientation2;
           5'b01001:   in_port_2 <= {3'b000, input_to_picoblaze};           //Data from keyboard
           5'b01010:   in_port_2 <= gameover;
           5'b01101:   in_port_2 <= {3'b000, dig7};
           5'b01110:   in_port_2 <= {3'b000, dig6};
           5'b01111:   in_port_2 <= {3'b000, dig5};
           5'b10110:   in_port_2 <= {3'b000, dig4};
           5'b10001:   in_port_2 <= {4'b0000,decpts[7:4]};
           5'b10010:   in_port_2 <= {4'b0000,LED[11:8]};
            default:   in_port_2 <= 8'hxx;
        endcase
    end
 //write registers for picoblaze 2         
    always @(posedge clk) begin
	if(reset_in) begin
		LED[7:0] <=8'd0;
        LocX2_reg <= 8'h7D;
		LocY2_reg <= 8'h7D;
		Orientation2_reg <= 8'h03;
	end
	else begin
        if(write_strobe_2) begin
            case(port_id_2[4:0]) 
            5'b10011:   dig7    <= out_port_2[4:0];
            5'b10100:   dig6    <= out_port_2[4:0];
            5'b10101:   dig5    <= out_port_2[4:0];
            5'b10110:   dig4    <= out_port_2[4:0];
            5'b10111:   decpts[7:4] <= out_port_2[7:4];
			5'b10010:	LED[11:8]	<= out_port_2[3:0]; //for debug
            5'b00110:   LocX2_reg	<=	out_port_2;
            5'b00111:   LocY2_reg	<=	out_port_2;
            5'b01000:   Orientation2_reg <= out_port_2;
		default:    ;
        endcase
        end
	end
    end
   //Handling interrupt signal to the picoblaze 1
     always @(posedge clk) begin
        if(interrupt_ack_1 == 1'b1) begin
           interrupt_1 <= 1'b0;
           end
        else if(sys_interrupt == 1'b1) begin
            interrupt_1 <= 1'b1;
            end
        else
            interrupt_1 <= interrupt_1;
    end
   //Handling interrupt signal to the picoblaze 2 
    always @(posedge clk) begin
        if(interrupt_ack_2 == 1'b1) begin
           interrupt_2 <= 1'b0;
           end
        else if(sys_interrupt == 1'b1) begin
            interrupt_2 <= 1'b1;
            end
        else
            interrupt_2 <= interrupt_2;
    end
	//Register initialization and storing 
	always @(posedge clk) begin
        if(reset_in) begin
			LocX1 <= 8'h03; 
			LocX2 <= 8'hC;
			LocY1 <= 8'h03;
			LocY2 <= 8'h7C;
			Orientation1 <= 01;
			Orientation2 <= 03;
		end
		else if(sys_interrupt)begin
			LocX1 <= LocX1_reg;
			LocX2 <= LocX2_reg;
			LocY1 <= LocY1_reg;
			LocY2 <= LocY2_reg;
			Orientation1 <= Orientation1_reg;
			Orientation2 <= Orientation2_reg;
		end
        
		else begin
	//Keyboard interface  
			case(keyboard_input) 
			    16'h0029: {start_space,kb_R2,kb_L2,kb_L1,kb_R1} <= 5'b10000;    //Scan code for space key
				16'h001C: {start_space,kb_R2,kb_L2,kb_L1,kb_R1} <= 5'b00001;	//Scan code of key A
				16'h001B: {start_space,kb_R2,kb_L2,kb_L1,kb_R1} <= 5'b00010;    //Scan code of key S
				16'hF01C: {start_space,kb_R2,kb_L2,kb_L1,kb_R1} <= 5'b00000;    //break code of key S
				16'hF01B: {start_space,kb_R2,kb_L2,kb_L1,kb_R1} <= 5'b00000;	//break code of key A
                16'h004B: {start_space,kb_R2,kb_L2,kb_L1,kb_R1} <= 5'b01000;    //scan code of key L
 				16'h0042: {start_space,kb_R2,kb_L2,kb_L1,kb_R1} <= 5'b00100;    //scan code of key K
				16'hF04B: {start_space,kb_R2,kb_L2,kb_L1,kb_R1} <= 5'b00000;    //Break code of key L
				16'hF042: {start_space,kb_R2,kb_L2,kb_L1,kb_R1} <= 5'b00000;    //Break code of key K
				16'hF029: {start_space,kb_R2,kb_L2,kb_L1,kb_R1} <= 5'b00000;    //Break code of space key
				default: {start_space,kb_R2,kb_L2,kb_L1,kb_R1} <= 5'b00000;
			endcase
            
    //Refresh registers
			LocX1 <= LocX1;
			LocX2 <= LocX2;
			LocY1 <= LocY1;
			LocY2 <= LocY2;
			Orientation1 <= Orientation1;
			Orientation2 <= Orientation2;
		end
		
	end
 
 endmodule