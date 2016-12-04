/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//generate_int.v:
//Module to Generate interrupt signals for PicoBlaze 1 and 2
//Created By:		Manoj Prakash Vishwanathpur, Shrikrishna Pookala, Arjun Gopal and Aravind Kumaraswamy 
//Last Modified:	10-June-2015(Manoj)
//
//  Description:
//  ------------
//  This module generates 15 Hz interrupt signal for picoblaze 1 and picoblaze 2. This interrupt signal also
//controls the speed of the tron lightcycle. Hence for future enhancements we can implement more levels where we 
//can increase the frequency of the interrupt and make game faster and more challenging.
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


module generate_int
#(  parameter integer	CLK_FREQUENCY_HZ		= 100000000, //Base clock
	parameter integer	UPDATE_FREQUENCY_HZ		= 15,        //input for 15hz interrupt clock
	parameter integer	RESET_POLARITY_LOW		= 1,
	parameter integer 	CNTR_WIDTH 				= 32,
	
	parameter integer	SIMULATE				= 0,
	parameter integer	SIMULATE_FREQUENCY_CNT	= 15
)
(
    input 				clk,
	input				reset,
    output reg          sys_interrupt
);

// reset - asserted high
	wire reset_in = RESET_POLARITY_LOW ? ~reset : reset;
    reg			[CNTR_WIDTH-1:0]	clk_cnt;    //for 15 Hz
    wire		[CNTR_WIDTH-1:0]	top_cnt_15hz = SIMULATE ? SIMULATE_FREQUENCY_CNT : (((CLK_FREQUENCY_HZ) / UPDATE_FREQUENCY_HZ) - 1);
    
    
    // generate update clock enable for 15hz
    always @(posedge clk) begin
		if (reset_in) begin
			clk_cnt <= {CNTR_WIDTH{1'b0}};
		end
		else if (clk_cnt == top_cnt_15hz) begin
		    sys_interrupt <= 1'b1;
		    clk_cnt <= {CNTR_WIDTH{1'b0}};
		end
		else begin
		    clk_cnt <= clk_cnt + 1'b1;
		    sys_interrupt <= 1'b0;
		end
	end 
endmodule