///////////////////////////////////////////////////////////////////////////////////////////////////
//keyboard.v:
//
//Created By:		Manoj Prakash Vishwanathpur, Shrikrishna Pookala, Arjun Gopal and Aravind Kumaraswamy 
//Last Modified:	10-June-2015(Arjun)
//
//Description:
//  ------------
//Module implements the keyboard interface to the FPGA
//
/////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module keyboard(
   input clk,                  //the clock is 50Mhz clock used for keyboard control
   input ps2_clk,              //the clock used for the PS/2 interface for communication with the keyboard.
   input ps2_data,             //this is used to send the data serially from the fpga to the keyboard serially.
   output reg [15:0] char = 0  //outptus the the data of the presssed key.
   );

   reg [9:0] bits = 0;         // the lower 8-bits of the scan code or the break code.
   reg [3:0] count = 0;        // used to check if the all the bits are present for transmisssion of the signal
   reg [1:0] ps2_clk_prev2 = 2'b11; //this reg retains the previous clk value.
   reg [19:0] timeout = 0;       //reg used to keep check whether the data is coming in the given time.
   
   always @(posedge clk)
      ps2_clk_prev2 <= {ps2_clk_prev2[0], ps2_clk};   //two bit value one from the previous clokc and the other from the current ps2_clk
      
   always @(posedge clk)
   begin
      if((count == 11) || (timeout[19] == 1))
      begin
         count <= 0;                                   //if either 11-bits or the timeout becomes 19 the count is initialised to zero
         if((char[7:0] == 8'hE0) || (char[7:0] == 8'hF0)) //if the scan code has a value greater than 8bits then we the output will be the upper 8-bits
            char[15:0] <= {char[7:0], bits[7:0]};         //followed by the lower 8-bits is given to the output.
         else
            char[15:0] <= {8'b0, bits[7:0]};              //otherwise if the upper 8-bits are present only the lower bits are considered.
      end
      else
      begin
         if(ps2_clk_prev2 == 2'b10)                      // when the present value of clock is not high then we have to increment the count  
         begin
            count <= count + 1;
            bits <= {ps2_data, bits[9:1]};              //the ps2_data is fed to the lowest bit hence they get occupied in the bits reg serially.
         end
      end
   end
   
   always @(posedge clk)
      timeout <= (count != 0) ? timeout + 1 : 0;         //if count is not zero then timeout is zero else the timeout is incremented,as the count increment indicates that we can expect                                                          //  some data still more.

endmodule