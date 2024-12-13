/* Modules for displaying on the HEX - Don't change */
module fivedigit_decimal_twos_diplay(
input [15:0]input_value,
output [6:0]neg_sign_2_hex,
output [6:0]d_4_sign_2_hex,
output [6:0]d_3_sign_2_hex,
output [6:0]d_2_sign_2_hex,
output [6:0]d_1_sign_2_hex,
output [6:0]d_0_sign_2_hex);

reg [3:0] result_one_digit;
reg [3:0] result_ten_digit;
reg [3:0] result_hun_digit;
reg [3:0] result_tho_digit;
reg [3:0] result_ten_tho_digit;
reg result_is_negative;

reg [15:0]twos_comp;

/* convert the binary value into 3 signals */
always @(*)
begin
	 twos_comp = (~input_value) + 1'b1;
	 
	 if (input_value[15] == 1'b1) // Is negative
	 begin
	 	result_is_negative = 1;
		result_ten_tho_digit = twos_comp / 10000 % 10000;
		result_tho_digit = twos_comp / 1000 % 1000;
		result_hun_digit = twos_comp / 100 % 100;
		result_ten_digit = twos_comp / 10 % 10;
		result_one_digit = twos_comp % 10;
	 end
	 else
	 begin
		result_is_negative = 0;
		result_ten_tho_digit = input_value / 10000 % 10000;
		result_tho_digit = input_value / 1000 % 1000;
		result_hun_digit = input_value / 100 % 100;
		result_ten_digit = input_value / 10 % 10;
		result_one_digit = input_value % 10;
	 end
end

/* instantiate the modules for each of the seven seg decoders including the negative one */
seven_segment sb5(result_ten_tho_digit, d_4_sign_2_hex);
seven_segment sb3(result_tho_digit, d_3_sign_2_hex);
seven_segment sb2(result_hun_digit, d_2_sign_2_hex);
seven_segment sb1(result_ten_digit, d_1_sign_2_hex);
seven_segment sb0(result_one_digit, d_0_sign_2_hex);
seven_segment_negative neg(result_is_negative, neg_sign_2_hex);

endmodule

module seven_segment_negative(i,o);

input i;
output reg [6:0]o; // a, b, c, d, e, f, g

always @(*)
begin
	 if (i == 1'b1)
	 begin
		o = 7'b0111111;
	 end
	 else
	 begin
		o = 7'b1111111;
	 end
end

endmodule

module seven_segment(
	input wire[3:0]i,
	output reg[6:0]o
);

// HEX out - rewire DE1
//  ---0---
// |       |
// 5       1
// |       |
//  ---6---
// |       |
// 4       2
// |       |
//  ---3---

always @(*)
begin
	case (i)	    // 6543210
		4'h0: o = 7'b1000000;
		4'h1: o = 7'b1111001;
		4'h2: o = 7'b0100100;
		4'h3: o = 7'b0110000;
		4'h4: o = 7'b0011001;
		4'h5: o = 7'b0010010;
		4'h6: o = 7'b0000010;
		4'h7: o = 7'b1111000;
		4'h8: o = 7'b0000000;
		4'h9: o = 7'b0010000;
		4'ha: o = 7'b0001000;
		4'hb: o = 7'b0000011;
		4'hc: o = 7'b1000110;
		4'hd: o = 7'b0100001;
		4'he: o = 7'b0000110;
		4'hf: o = 7'b0001110;
	endcase
end

endmodule