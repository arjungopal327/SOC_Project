////////////////////////////////////////////////////////////////////////////////////
//Colorizer.v: module- Sends colour information for VGA display
//
//Created By:		Manoj Prakash Vishwanathpur, Shrikrishna Pookala, Arjun Gopal and Aravind Kumaraswamy 
//Last Modified:	10-June-2015(Manoj)
//
// Description:
// ------------
//  Module assigns colour to the pixels sent by Decider block
//
////////////////////////////////////////////////////////////////////////////////////

`timescale	1ns / 1ps
module colorizer(
input video_on,
input [1:0] pixel_data,
output reg [3:0] red,green,blue,
input clk,reset
);

always @(posedge clk) begin
    if(reset) begin             //if reset display black
        red <= 4'b0000;
        green<= 4'b0000;
        blue <= 4'b0000;
    end
    else begin
        if(video_on == 1'b0) begin  //check for video on signal
            red <= 4'b0000;
            green<= 4'b0000;
            blue <= 4'b0000;
        end
        
        else begin
                case(pixel_data)   //display colours from pixel data
                            2'b00:  begin           //Black Background
                                    red <= 4'b0000;
                                    green<= 4'b0000;
                                    blue <= 4'b0000;
                                    end
                             2'b01: begin           //Blue line
                                    red <= 4'b0000;
                                    green<= 4'b0000;
                                    blue <= 4'b1111;
                                    end
                            2'b10:  begin           //red line
                                    red <= 4'b1111;
                                    green<= 4'b0000;
                                    blue <= 4'b0000;
                                    end
                            2'b11:  begin           //default white
                                    red <= 4'b1111;
                                    green<= 4'b1111;
                                    blue <= 4'b1111;
                                    end
                                
                 endcase
        end
        
                
      end          
    end
    

endmodule

                
                
