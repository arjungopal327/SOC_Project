//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//decider_block.v:
//This module decides the winner of tron legacy multi-player game. 
//
//Created By:		Manoj Prakash Vishwanathpur, Shrikrishna Pookala, Arjun Gopal and Aravind Kumaraswamy 
//Last Modified:	10-June-2015(Manoj)
//
// Description:
// ------------
//  This module decides the winner based on the location and Orientation inputs from two individual 
//Picoblaze. This module makes use of 2 true dual port RAM's for dynamically changing the map of the game, 
//which is a key feature of the game. The first RAM is used to simultaneously write/read data from/to 
//two write/read ports. The second RAM is used to provide data to the video controller. One port is dedicated   
//write port and second port is a dedicated read port. Single RAM cannot be used since we need 2 writes and 
//1 read in a single clock cycle. The module also decides what to display on screen, I.e. different screens of
//the game- Start screen, winner declarations etc. 
//
// It also provides a feedback to picoblaze if a result is declared through gameover signal.
// gameover signal has encoded data which is defined as follows:
//                  DRAW        = 8'b00000111;  last bit signifies halt bit
//                  RED_WINS    = 8'b00000011;  First bit indicates player 1 wins
//                  BLUE_WINS   = 8'b00000101;  Second bit indicates player 2 wins
//  This feedback signal makes sure picoblaze and the exterior hardware are in sync making it a closed loop 
//design.
//  pixel_data is the video pixel data sent to VGA modules. The 2 bit output has colour information 
//which can be decoded by the colorizer module.
//
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module decider(
input[7:0] LocX1, LocY1, LocX2, LocY2,      //Location inputs from PicoBlaze
input clk, clk25mhz, reset, game_init,      
input [9:0] pixel_row, pixel_column,        //Input from DTG module- raster scan information
output reg[7:0] pixel_data,                 //Output to VGA modules
output reg[7:0] gameover                    //Feedback to the PicoBlaze
);

parameter BLACK = 2'b00;                    
parameter RED = 2'b01;
parameter BLUE = 2'b10;
parameter DARKBLUE = 2'b11;
parameter DRAW = 8'b00000111;
parameter RED_WINS = 8'b00000101;
parameter BLUE_WINS = 8'b00000011;

//Local registers to pipeline location data
reg [7:0] LocX1_reg,LocY1_reg,LocX2_reg,LocY2_reg;
reg [7:0] LocX1_reg_1,LocY1_reg_1,LocX2_reg_1,LocY2_reg_1;
reg [7:0] LocX1_reg_2,LocY1_reg_2,LocX2_reg_2,LocY2_reg_2;
reg [1:0] enable_ram2 = 2'd0;
//Internal Registers
reg block_enable;
reg[1:0] tron1_data, tron2_data;
//Nets connected to RAM and ROM
reg wea,web,wea_1;
reg[13:0] addra,addrb,addra_1,addrb_1, addr_p1, addr_p2, addr_tie, addr_init;
wire[1:0] douta,doutb, doutb_1, douta_p1, douta_p2 ,douta_tie, douta_init;
reg[1:0] dina,dinb,dina_1;

//Initializing True Dual Port RAM's 
blk_mem_gen_0 RAM_1(
    .clka(clk),
    .wea(wea),
    .addra(addra),
    .dina(dina),
    .douta(douta),
    .clkb(clk),
    .web(web),
    .addrb(addrb),
    .dinb(dinb),
    .doutb(doutb)
);

blk_mem_gen_0 RAM_2(
    .clka(clk),
    .wea(wea_1),
    .addra(addra_1),
    .dina(dina_1),
    .douta(),
    .clkb(clk25mhz),
    .web(0),
    .addrb(addrb_1),
    .dinb(0),
    .doutb(doutb_1)
);
//Initializing single port block ROM's for game screens
player1wins p1(
    .clka(clk),
    .addra(addr_p1),
    .douta(douta_p1)
);

player2wins p2(
    .clka(clk),
    .addra(addr_p2),
    .douta(douta_p2)
);

tie T(
    .clka(clk),
    .addra(addr_tie),
    .douta(douta_tie)
);

game_init G(
    .clka(clk),
    .addra(addr_init),
    .douta(douta_init)
);


//Decider logic begins

always@(posedge clk) begin
    //Pipe lining registers
	LocX1_reg <= LocX1;
	LocY1_reg <= LocY1;
	LocX2_reg <= LocX2;
	LocY2_reg <= LocY2;
	LocX1_reg_1 <= LocX1_reg;
	LocY1_reg_1 <= LocY1_reg;
	LocX2_reg_1 <= LocX2_reg;
	LocY2_reg_1 <= LocY2_reg;
	LocX1_reg_2 <= LocX1_reg_1;
	LocY1_reg_2 <= LocY1_reg_1;
	LocX2_reg_2 <= LocX2_reg_1;
	LocY2_reg_2 <= LocY2_reg_1;
	
    if(reset) begin
        gameover <= 8'd0;       //reset gameover signal
       	block_enable <= 1'b0;   
		wea <= 1'b0;            //Assert write enable signals of RAM to zero
		web <= 1'b0;
    end
   	else begin
    //Send address to RAM's to fetch the data
	addra <= {LocY1[6:0],LocX1[6:0]};
	addrb <= {LocY2[6:0],LocX2[6:0]};
        //Check if locations have changed from previous clock cycle	
        if (({LocY1_reg_2,LocX1_reg_2} != {LocY1_reg_1,LocX1_reg_1}) && ({LocY2_reg_2,LocX2_reg_2} != {LocY2_reg_1,LocX2_reg_1})) begin
			block_enable <= 1'b1;   //If data is changed, enable condition check of the data
			tron1_data <= douta;    //store the data in local registers
			tron2_data <= doutb;
		end
		
		//if block enable = 1, time to consider writing new data into RAM
		if (block_enable == 1'b1) begin
				if((LocX1 == LocX2) && (LocY1 == LocY2)) begin    //Check for Head-on collision 
					gameover <= DRAW;                             //Set gameover signal to DRAW- sent to picoblaze
				end
				else begin
					if((tron1_data != BLACK) && (tron2_data != BLACK)) begin //Check if both players have crashed at the same time
						gameover <= DRAW;
					end
				
                    else if(tron1_data != BLACK) begin            //Check if Player 1 has crashed   
                        gameover <= BLUE_WINS;
					end
					
                    else if(tron2_data != BLACK) begin            //Check if player 2 has crashed
                        gameover <= RED_WINS;
					end
                    else begin                                    //If none of the players have crashed proceed the game
                        wea <= 1'b1;                              //Enable write signals of RAM 1(2 ports) and RAM 2(port 1)
                        web <= 1'b1;
                        wea_1<= 1'b1;
                        gameover <= 8'd0;                           
                        block_enable <= 1'b0;                     //Reset block enable signal to enable condition check for next iteration
                    end
                end
		end
		if(wea == 1'b1 && web == 1'b1) begin                      //As soon as write enables are set, Write data in the present location
					dina <= RED;                                  //which creates a light path when the player moves forward
					dinb <= BLUE;
					wea <= 1'b0;                                  //Clear write enable signals
					web <= 1'b0;
        end
	end
end

//Block to simultaneously write into RAM2 port 1:
always@(posedge clk)begin
    if(wea_1 == 1'b1) begin
        if(enable_ram2 == 2'd0)begin
            dina_1 <= RED;
            enable_ram2 <= enable_ram2 + 2'd1;
        end
        else begin
            dina_1 <= BLUE;
            enable_ram2 <= 2'd0;
        end
    end   
end                   

//Give address to RAM2 port 1 alternatively from player 1 and Player 2 based on enable_ram2 signal
always@(*) begin
    if(enable_ram2 == 0)
        addra_1 <= {LocY1[6:0],LocX1[6:0]}; //Select player 1 location
    else
        addra_1 <= {LocY2[6:0],LocX2[6:0]}; //Select player 2 location
end

//Block to choose what to display on screen
always @ (posedge clk) begin
	   //If the game has not started yet, display start screen
       if((game_init == 1'b0) && (LocX1 == 8'h03)) begin
            addr_init <= {pixel_row[6:0] ,pixel_column[6:0]};
            pixel_data <= douta_init;
       end
       //If second player wins display result
       else if(gameover == BLUE_WINS) begin
            addr_p2 <= {pixel_row[6:0] ,pixel_column[6:0]};
            pixel_data <= douta_p2;
       end
       //If first player wins display result
       else if(gameover == RED_WINS)begin
            addr_p1 <= {pixel_row[6:0] ,pixel_column[6:0]};
            pixel_data <= douta_p1;
       end
       //If the game is a tie
       else if(gameover == DRAW)begin
            addr_tie <= {pixel_row[6:0] ,pixel_column[6:0]};
            pixel_data <= douta_tie;
       end
       //If there is no result proceed the game by displaying RAM contents
       else begin
       addrb_1 <= {pixel_row[6:0] ,pixel_column[6:0]};
       pixel_data <= doutb_1;
       end
end

endmodule
              