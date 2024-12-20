module project (
	//////////// CLOCK //////////
	input 		          		CLOCK_50,

	//////////// SEG7 //////////
	output		     [6:0]		HEX0,
	output		     [6:0]		HEX1,
	output		     [6:0]		HEX2,
	output		     [6:0]		HEX3,

	//////////// KEY //////////
	input 		     [8:0]		KEY,

	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// SW //////////
	input 		     [9:0]		SW	 
);

wire clk;
wire rst;

assign clk  			 = CLOCK_50;
assign rst  			 = KEY[8];
assign LEDR           = round;


//Choose the between the 4 options
assign card3_selector = KEY[3];
assign card2_selector = KEY[2];
assign card1_selector = KEY[1];
assign raise 			 = KEY[0];

reg [23:0] h_count;
reg [23:0] v_count;



reg [5:0] S;
reg [5:0] NS;

// FSM states
parameter   START             = 5'b00000,
				SHUFFLE           = 5'b00001,
				WAIT_SHUFFLE      = 5'b00010,
				GIVE_CARDS        = 5'b00011,
				WAIT_GIVE_CARDS   = 5'b00100,
					
				ROUND_1      		= 5'b00101,
				ROUND_2      		= 5'b00110,
				ROUND_3      		= 5'b00111,
				
				PLAYER_1          = 5'b01000,
				PLAYER_1_RAISE    = 5'b01001,
				PLAYER_1_CARD     = 5'b01010,
				PLAYER_1_WON_ROUND= 5'b01011,
				PLAYER_1_WON_GAME = 5'b01100,
				
				PLAYER_2          = 5'b01101,
				PLAYER_2_RAISE    = 5'b01110,
				PLAYER_2_CARD     = 5'b01111,
				PLAYER_2_WON_ROUND= 5'b10000,
				PLAYER_2_WON_GAME = 5'b10001,
				
				COMPARE_CARDS     = 5'b10010,
				WAIT_COMPARE_CARDS= 5'b10011,

				CHECK_SCORE       = 5'b10100,

				DONE              = 5'b10101;
				
//Assigning cards
// Assigning cards
reg [0:31] deck; // 32 cards

initial begin
    // Clubs (LSB = 11)
    deck[0] = 6'b00011; // Ace of Clubs
    deck[1] = 6'b00111; // 2 of Clubs
    deck[2] = 6'b01011; // 3 of Clubs
    deck[3] = 6'b01111; // 4 of Clubs
    deck[4] = 6'b10011; // 5 of Clubs
    deck[5] = 6'b10111; // 6 of Clubs
    deck[6] = 6'b11011; // 7 of Clubs
    deck[7] = 6'b11111; // 8 of Clubs

    // Hearts (LSB = 10)
    deck[8] = 6'b00010; // Ace of Hearts
    deck[9] = 6'b00110; // 2 of Hearts
    deck[10] = 6'b01010; // 3 of Hearts
    deck[11] = 6'b01110; // 4 of Hearts
    deck[12] = 6'b10010; // 5 of Hearts
    deck[13] = 6'b10110; // 6 of Hearts
    deck[14] = 6'b11010; // 7 of Hearts
    deck[15] = 6'b11110; // 8 of Hearts

    // Spades (LSB = 01)
    deck[16] = 6'b00001; // Ace of Spades
    deck[17] = 6'b00101; // 2 of Spades
    deck[18] = 6'b01001; // 3 of Spades
    deck[19] = 6'b01101; // 4 of Spades
    deck[20] = 6'b10001; // 5 of Spades
    deck[21] = 6'b10101; // 6 of Spades
    deck[22] = 6'b11001; // 7 of Spades
    deck[23] = 6'b11101; // 8 of Spades

    // Diamonds (LSB = 00)
    deck[24] = 6'b00000; // Ace of Diamonds
    deck[25] = 6'b00100; // 2 of Diamonds
    deck[26] = 6'b01000; // 3 of Diamonds
    deck[27] = 6'b01100; // 4 of Diamonds
    deck[28] = 6'b10000; // 5 of Diamonds
    deck[29] = 6'b10100; // 6 of Diamonds
    deck[30] = 6'b11000; // 7 of Diamonds
    deck[31] = 6'b11100; // 8 of Diamonds
end

//End of assigning cards
reg [15:0]value_2_hex; // value for the hexes

reg [23:0] rgb;

reg shuffle_done;  // Signal indicating shuffle completion

reg cards_dealt;   // Signal indicating cards have been dealt
	 
reg round_result;  // Signal indicating result of the round (can be extended)

reg [1:0]round; //The points come form a best of three rounds
reg [1:0]round_winner; //If 1 player1 won = 1 player2 won = 2
//3'b000 = 1 point , 
//3'b001 = 3 points, 
//3'b010 = 6 points, 
//3'b011 = 9 points,
//3'b100 = 12 points 
reg [2:0]round_weight;
	
// Players cards (3 options)
reg [2:0]player1_cards;
reg [2:0]player2_cards;

reg [1:0] player_turn; // Indicates which player's turn it is (1 or 2)

// If player already played equals to one
reg player1_played;
reg player2_played;

reg player1_card1_played, player1_card2_played, player1_card3_played;
reg player2_card1_played, player2_card2_played, player2_card3_played;

reg player1_card_choice;
reg player2_card_choice;

//If player make 12 points he wins
reg [4:0] player1_score;
reg [4:0] player2_score;

//If 0 RISE else CHOOSE CARDS
reg player1_choice;
reg player2_choice;

reg done;     // Indicates the game is done

// See various items out to the hex display - these are your numbers converted to decimals
fivedigit_decimal_twos_diplay display(
value_2_hex,
HEX5,
HEX4,
HEX3,
HEX2,
HEX1,
HEX0);

// State transition logic
always @ (posedge clk or negedge rst) 
begin
	if (!rst)
		S <= START;  // Use START as the initial state
   else
      S <= NS;
end

// Next state logic
always @ (*) 
begin
	NS = START;
	case(S)
		START: NS = SHUFFLE;  // Move to SHUFFLE state

      SHUFFLE: NS = WAIT_SHUFFLE;

      WAIT_SHUFFLE: 
		begin
			if (shuffle_done)
				NS = GIVE_CARDS;  // Shuffle completed
			else
				NS = WAIT_SHUFFLE;  // Stay in the same state
      end

      GIVE_CARDS: NS = WAIT_GIVE_CARDS;  // Wait for cards to be dealt

      WAIT_GIVE_CARDS: 
		begin
			if (cards_dealt)
				NS = ROUND_1;
			else
				NS = WAIT_GIVE_CARDS;
      end

      ROUND_1: NS = PLAYER_1;
		
		ROUND_2:
		begin
			if (round_winner == 2'b01)
				NS = PLAYER_1;
			else
				NS = PLAYER_2;
      end
		
		ROUND_3:
		begin
			if (round_winner == 2'b10)
				NS = PLAYER_1;
			else
				NS = PLAYER_2;
      end

		//You can choose between Raising the value or Picking a card
      PLAYER_1: 
		begin
			if (player1_choice)
				NS = PLAYER_1_RAISE;

			else 
				NS = PLAYER_1_CARD;
      end
		
		PLAYER_1_RAISE: NS = PLAYER_1_CARD;
		
		PLAYER_1_CARD:
		begin
			if (player2_played)
				NS = COMPARE_CARDS;
			else 
				NS = PLAYER_2;  // Transition to Player 2
      end

		PLAYER_2: 
		begin
			if (player2_choice)
				NS = PLAYER_2_RAISE;

			else 
				NS = PLAYER_2_CARD;
      end
		
		PLAYER_2_RAISE: NS = PLAYER_2_CARD;
		
      PLAYER_2_CARD:
		begin
			if (player1_played)
				NS = COMPARE_CARDS;
			else 
				NS = PLAYER_1;  // Transition to Player 2
      end

		COMPARE_CARDS: NS = WAIT_COMPARE_CARDS;
		
		WAIT_COMPARE_CARDS: NS = ROUND_1;
		
		PLAYER_1_WON_ROUND: NS = CHECK_SCORE;
		
		PLAYER_2_WON_ROUND: NS = CHECK_SCORE;
		
		CHECK_SCORE:
		begin
		if (player1_score < 12 && player2_score < 12)
			if(round == 2'b10)
				NS = SHUFFLE;
			else if(round == 2'b00) //This was round 1
				NS = ROUND_2;
			else if(round == 2'b01) //This was round 2
				NS = ROUND_3;
		else if (player1_score == 12)
			NS = PLAYER_1_WON_GAME;
		else if (player2_score == 12)
			NS = PLAYER_2_WON_GAME;
		end
		
		PLAYER_1_WON_GAME: NS = DONE;
		
		PLAYER_2_WON_GAME: NS = DONE;
		
      DONE: NS = DONE;  // Stay in DONE state

      default: NS = START;  // Default to START state		
	endcase
end

// Output logic
always @ (posedge clk or negedge rst) 
begin
	if(!rst) 
	begin
		// Reset all outputs to their default values
      player_turn <= 2'b00;
      done <= 1'b0;
      round <= 2'b00;
		value_2_hex <= 16'd0;
      round_winner <= 1'b0;
      player1_played <= 1'b0;
      player2_played <= 1'b0;
      player1_score <= 5'b0;
      player2_score <= 5'b0;
      player1_choice <= 1'b0;
      player2_choice <= 1'b0;
		
		rgb <= 24'h0000ff;  // Reset to black
	end
	
	else if ((h_count < 640) && (v_count < 480)) begin

        rgb <= 24'h000000;  // Default background color (black)
	end


        // Draw lanes

        //else if (h_count < 212) begin

            //rgb <= 24'hffffff; // First lane (white)

       // end else if (h_count < 217) begin

            //rgb <= 24'h000000; // Left border of the first lane (black)

        //end else if (h_count < 424) begin

            //rgb <= 24'hffffff; // Second lane (white)

        //end else if (h_count < 428) begin

            //rgb <= 24'h000000; // Left border of the second lane (black)

        //end else if (h_count < 636) begin

            //rgb <= 24'hffffff; // Third lane (white)

        //end
		  
	else 
	begin
		case(S)
			START:
			begin
				// Initialize values for the game start
		            player_turn <= 2'b00;
		            done <= 1'b0;
		            round <= 2'b00;
						value_2_hex <= 16'd0;
		            round_winner <= 1'b0;
		            player1_played <= 1'b0;
		            player2_played <= 1'b0;
		            player1_score <= 5'b0;
		            player2_score <= 5'b0;			
			end
			
			SHUFFLE:
			begin
				//No round started yet
				round <= 2'b00;
				
				// Reset player states during shuffling
		            player1_played <= 1'b0;
		            player2_played <= 1'b0;
				
				// Sudo Randomizer for the cards
				
				
			end
			
			WAIT_SHUFFLE:
			begin
				shuffle_done <= 1'b1;
			end
			
			GIVE_CARDS:
			begin
				shuffle_done <= 1'b0;

			end
			
			WAIT_GIVE_CARDS:
			begin
				cards_dealt <= 1'b1;
				
			end
					
			ROUND_1:
			begin
				cards_dealt <= 1'b0;
				
				player_turn <= 2'b01; //player 1 plays
				
				// Prepare for the new round
		            player1_played <= 1'b0;
		            player2_played <= 1'b0;
				round <= 2'b01;
			end
			
			ROUND_2:
			begin
				if (round_winner == 2'b01) player_turn <= 2'b01; 		//player 1 plays
				else if (round_winner == 2'b10) player_turn <= 2'b10; //player 2 plays
				
				// Prepare for the new round
		            player1_played <= 1'b0;
		            player2_played <= 1'b0;
				round <= 2'b10;
			end
			
			ROUND_3:
			begin
				if (round_winner == 2'b01) player_turn <= 2'b01; 		//player 1 plays
				else if (round_winner == 2'b10) player_turn <= 2'b10; //player 2 plays
				
				// Prepare for the new round
		            player1_played <= 1'b0;
		            player2_played <= 1'b0;
				round <= 2'b11;
			end
			
				
			PLAYER_1:
			begin
				
			end
			
			PLAYER_1_RAISE:
			begin
				if (raise)
				begin
					if (round_weight < 3'b100)
						round_weight <= round_weight + 3'b001;
				end
			end
			
			PLAYER_1_CARD:
			begin
				if (player1_card1_played == 1'b0) begin
					if (card1_selector) 
					begin
						player1_card1_played <= 1'b1;
						
					end
				end
				if (player1_card2_played == 1'b0) begin
					if (card2_selector) 
					begin
						player1_card2_played <= 1'b1;
					end
				end
				if (player1_card3_played == 1'b0) begin
					if (card3_selector) 
					begin
						player1_card3_played <= 1'b1;
					end
				end
				
				player1_played <= 1'b1;
			end
			
			PLAYER_1_WON_ROUND:
			begin
				
				player1_score <= player1_score + round_weight;
				value_2_hex <= value_2_hex + round_weight << 14;
			end
			
			PLAYER_1_WON_GAME:
			begin
			
			end
			
				
			PLAYER_2:
			begin
			
			end
			
			PLAYER_2_RAISE:
			begin
				if (raise)
				begin
					if (round_weight < 3'b100)
						round_weight <= round_weight + 3'b001;
				end
			end
			
			PLAYER_2_CARD:
			begin
				if (player2_card1_played == 1'b0) begin
					if (card1_selector) player2_card1_played <= 1'b1;
				end
				if (player2_card2_played == 1'b0) begin
					if (card2_selector) player2_card2_played <= 1'b1;
				end
				if (player2_card3_played == 1'b0) begin
					if (card3_selector) player2_card3_played <= 1'b1;
				end
				
				player2_played <= 1'b1;
			end
			
			PLAYER_2_WON_ROUND:
			begin
			
				player2_score <= player2_score + round_weight;
				value_2_hex <= value_2_hex + round_weight;
			end
			
			PLAYER_2_WON_GAME:
			begin
			
			end
				
			COMPARE_CARDS:
			begin
				// Compare cards and determine the winner of the round
				if (player1_card_choice > player2_card_choice) 
				begin
					round_winner <= 1'b1;
					player1_score <= player1_score + 1;
				end
				else 
				begin
					round_winner <= 1'b0;
					player2_score <= player2_score + 1;
				end
        		end
			WAIT_COMPARE_CARDS:
			begin
			
			end

			CHECK_SCORE:
			begin
			
			end

			DONE:
			begin
				// End the game
            			done <= 1'b1;
			end
			
			default:
			begin
				// Default case for safety
		            player_turn <= 2'b00;
		            done <= 1'b0;
			end
		endcase
	end
end
endmodule
