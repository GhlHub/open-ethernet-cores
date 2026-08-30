// SPDX-License-Identifier: GPL-3.0-or-later
`timescale 1ns/1ps

// Combinational IBM 8b/10b codec used by the open SGMII PCS.
// Symbols use the SelectIO-facing convention: symbol[0] is transmitted first.
module open_eth_8b10b_encoder (
    input  wire [7:0] data,
    input  wire       is_control,
    input  wire       disparity_in, // 0 = RD-, 1 = RD+
    output reg  [9:0] symbol,
    output reg        disparity_out,
    output reg        code_error
);

wire [4:0] x = data[4:0];
wire [2:0] y = data[7:5];
reg [5:0] code6_neg;
reg [5:0] code6_pos;
reg [5:0] code6;
reg [3:0] code4;
reg disparity_mid;
reg use_alt7;
reg [9:0] standard_symbol;

function automatic [2:0] ones6;
    input [5:0] value;
    begin
        ones6 = value[0] + value[1] + value[2] +
            value[3] + value[4] + value[5];
    end
endfunction

function automatic [2:0] ones4;
    input [3:0] value;
    begin
        ones4 = value[0] + value[1] + value[2] + value[3];
    end
endfunction

always @* begin
    case (x)
        5'd0:  begin code6_neg = 6'b100111; code6_pos = 6'b011000; end
        5'd1:  begin code6_neg = 6'b011101; code6_pos = 6'b100010; end
        5'd2:  begin code6_neg = 6'b101101; code6_pos = 6'b010010; end
        5'd3:  begin code6_neg = 6'b110001; code6_pos = 6'b110001; end
        5'd4:  begin code6_neg = 6'b110101; code6_pos = 6'b001010; end
        5'd5:  begin code6_neg = 6'b101001; code6_pos = 6'b101001; end
        5'd6:  begin code6_neg = 6'b011001; code6_pos = 6'b011001; end
        5'd7:  begin code6_neg = 6'b111000; code6_pos = 6'b000111; end
        5'd8:  begin code6_neg = 6'b111001; code6_pos = 6'b000110; end
        5'd9:  begin code6_neg = 6'b100101; code6_pos = 6'b100101; end
        5'd10: begin code6_neg = 6'b010101; code6_pos = 6'b010101; end
        5'd11: begin code6_neg = 6'b110100; code6_pos = 6'b110100; end
        5'd12: begin code6_neg = 6'b001101; code6_pos = 6'b001101; end
        5'd13: begin code6_neg = 6'b101100; code6_pos = 6'b101100; end
        5'd14: begin code6_neg = 6'b011100; code6_pos = 6'b011100; end
        5'd15: begin code6_neg = 6'b010111; code6_pos = 6'b101000; end
        5'd16: begin code6_neg = 6'b011011; code6_pos = 6'b100100; end
        5'd17: begin code6_neg = 6'b100011; code6_pos = 6'b100011; end
        5'd18: begin code6_neg = 6'b010011; code6_pos = 6'b010011; end
        5'd19: begin code6_neg = 6'b110010; code6_pos = 6'b110010; end
        5'd20: begin code6_neg = 6'b001011; code6_pos = 6'b001011; end
        5'd21: begin code6_neg = 6'b101010; code6_pos = 6'b101010; end
        5'd22: begin code6_neg = 6'b011010; code6_pos = 6'b011010; end
        5'd23: begin code6_neg = 6'b111010; code6_pos = 6'b000101; end
        5'd24: begin code6_neg = 6'b110011; code6_pos = 6'b001100; end
        5'd25: begin code6_neg = 6'b100110; code6_pos = 6'b100110; end
        5'd26: begin code6_neg = 6'b010110; code6_pos = 6'b010110; end
        5'd27: begin code6_neg = 6'b110110; code6_pos = 6'b001001; end
        5'd28: begin code6_neg = 6'b001110; code6_pos = 6'b001110; end
        5'd29: begin code6_neg = 6'b101110; code6_pos = 6'b010001; end
        5'd30: begin code6_neg = 6'b011110; code6_pos = 6'b100001; end
        default: begin code6_neg = 6'b101011; code6_pos = 6'b010100; end
    endcase
end

always @* begin
    code_error = is_control && !(x == 5'd28 ||
        (y == 3'd7 && (x == 5'd23 || x == 5'd27 ||
                       x == 5'd29 || x == 5'd30)));

    if (is_control && x == 5'd28)
        code6 = disparity_in ? 6'b110000 : 6'b001111;
    else
        code6 = disparity_in ? code6_pos : code6_neg;

    if (ones6(code6) > 3)
        disparity_mid = 1'b1;
    else if (ones6(code6) < 3)
        disparity_mid = 1'b0;
    else
        disparity_mid = disparity_in;

    use_alt7 = !is_control && y == 3'd7 &&
        ((!disparity_mid && (x == 5'd17 || x == 5'd18 || x == 5'd20)) ||
         ( disparity_mid && (x == 5'd11 || x == 5'd13 || x == 5'd14)));

    if (is_control && x == 5'd28) begin
        case (y)
            3'd0: code4 = disparity_mid ? 4'b0100 : 4'b1011;
            3'd1: code4 = disparity_mid ? 4'b1001 : 4'b0110;
            3'd2: code4 = disparity_mid ? 4'b0101 : 4'b1010;
            3'd3: code4 = disparity_mid ? 4'b0011 : 4'b1100;
            3'd4: code4 = disparity_mid ? 4'b0010 : 4'b1101;
            3'd5: code4 = disparity_mid ? 4'b1010 : 4'b0101;
            3'd6: code4 = disparity_mid ? 4'b0110 : 4'b1001;
            default: code4 = disparity_mid ? 4'b1000 : 4'b0111;
        endcase
    end else if (is_control && y == 3'd7 &&
                 (x == 5'd23 || x == 5'd27 || x == 5'd29 || x == 5'd30)) begin
        code4 = disparity_mid ? 4'b1000 : 4'b0111;
    end else if (use_alt7) begin
        code4 = disparity_mid ? 4'b1000 : 4'b0111;
    end else begin
        case (y)
            3'd0: code4 = disparity_mid ? 4'b0100 : 4'b1011;
            3'd1: code4 = 4'b1001;
            3'd2: code4 = 4'b0101;
            3'd3: code4 = disparity_mid ? 4'b0011 : 4'b1100;
            3'd4: code4 = disparity_mid ? 4'b0010 : 4'b1101;
            3'd5: code4 = 4'b1010;
            3'd6: code4 = 4'b0110;
            default: code4 = disparity_mid ? 4'b0001 : 4'b1110;
        endcase
    end

    if (ones4(code4) > 2)
        disparity_out = 1'b1;
    else if (ones4(code4) < 2)
        disparity_out = 1'b0;
    else
        disparity_out = disparity_mid;

    standard_symbol = {code6, code4};
    // Convert abcdei_fghj with a transmitted first into symbol[0]-first form.
    symbol = {standard_symbol[0], standard_symbol[1], standard_symbol[2],
              standard_symbol[3], standard_symbol[4], standard_symbol[5],
              standard_symbol[6], standard_symbol[7], standard_symbol[8],
              standard_symbol[9]};
end
endmodule

module open_eth_8b10b_decoder (
    input  wire [9:0] symbol,
    input  wire       disparity_in,
    output reg  [7:0] data,
    output reg        is_control,
    output reg        disparity_out,
    output reg        disparity_error,
    output reg        code_error
);

wire [9:0] standard_symbol = {
    symbol[0], symbol[1], symbol[2], symbol[3], symbol[4],
    symbol[5], symbol[6], symbol[7], symbol[8], symbol[9]};
wire [5:0] code6 = standard_symbol[9:4];
wire [3:0] code4 = standard_symbol[3:0];
reg [4:0] decoded_x;
reg [2:0] decoded_y;
reg valid6;
reg valid4;
reg k28;
reg alt7;

wire [9:0] encoded_neg;
wire [9:0] encoded_pos;
wire disparity_neg_out;
wire disparity_pos_out;
wire encoder_neg_error;
wire encoder_pos_error;
open_eth_8b10b_encoder check_neg (
    .data({decoded_y, decoded_x}), .is_control(is_control),
    .disparity_in(1'b0), .symbol(encoded_neg),
    .disparity_out(disparity_neg_out), .code_error(encoder_neg_error));
open_eth_8b10b_encoder check_pos (
    .data({decoded_y, decoded_x}), .is_control(is_control),
    .disparity_in(1'b1), .symbol(encoded_pos),
    .disparity_out(disparity_pos_out), .code_error(encoder_pos_error));
wire match_neg = valid6 && valid4 && !encoder_neg_error && symbol == encoded_neg;
wire match_pos = valid6 && valid4 && !encoder_pos_error && symbol == encoded_pos;

always @* begin
    decoded_x = 5'd0;
    valid6 = 1'b1;
    k28 = 1'b0;
    case (code6)
        6'b100111, 6'b011000: decoded_x = 5'd0;
        6'b011101, 6'b100010: decoded_x = 5'd1;
        6'b101101, 6'b010010: decoded_x = 5'd2;
        6'b110001: decoded_x = 5'd3;
        6'b110101, 6'b001010: decoded_x = 5'd4;
        6'b101001: decoded_x = 5'd5;
        6'b011001: decoded_x = 5'd6;
        6'b111000, 6'b000111: decoded_x = 5'd7;
        6'b111001, 6'b000110: decoded_x = 5'd8;
        6'b100101: decoded_x = 5'd9;
        6'b010101: decoded_x = 5'd10;
        6'b110100: decoded_x = 5'd11;
        6'b001101: decoded_x = 5'd12;
        6'b101100: decoded_x = 5'd13;
        6'b011100: decoded_x = 5'd14;
        6'b010111, 6'b101000: decoded_x = 5'd15;
        6'b011011, 6'b100100: decoded_x = 5'd16;
        6'b100011: decoded_x = 5'd17;
        6'b010011: decoded_x = 5'd18;
        6'b110010: decoded_x = 5'd19;
        6'b001011: decoded_x = 5'd20;
        6'b101010: decoded_x = 5'd21;
        6'b011010: decoded_x = 5'd22;
        6'b111010, 6'b000101: decoded_x = 5'd23;
        6'b110011, 6'b001100: decoded_x = 5'd24;
        6'b100110: decoded_x = 5'd25;
        6'b010110: decoded_x = 5'd26;
        6'b110110, 6'b001001: decoded_x = 5'd27;
        6'b001110: decoded_x = 5'd28;
        6'b101110, 6'b010001: decoded_x = 5'd29;
        6'b011110, 6'b100001: decoded_x = 5'd30;
        6'b101011, 6'b010100: decoded_x = 5'd31;
        6'b001111, 6'b110000: begin decoded_x = 5'd28; k28 = 1'b1; end
        default: valid6 = 1'b0;
    endcase
end

always @* begin
    decoded_y = 3'd0;
    valid4 = 1'b1;
    alt7 = 1'b0;
    if (k28) begin
        if (code6 == 6'b001111) begin
            case (code4)
                4'b0100: decoded_y = 3'd0;
                4'b1001: decoded_y = 3'd1;
                4'b0101: decoded_y = 3'd2;
                4'b0011: decoded_y = 3'd3;
                4'b0010: decoded_y = 3'd4;
                4'b1010: decoded_y = 3'd5;
                4'b0110: decoded_y = 3'd6;
                4'b1000: decoded_y = 3'd7;
                default: valid4 = 1'b0;
            endcase
        end else begin
            case (code4)
                4'b1011: decoded_y = 3'd0;
                4'b0110: decoded_y = 3'd1;
                4'b1010: decoded_y = 3'd2;
                4'b1100: decoded_y = 3'd3;
                4'b1101: decoded_y = 3'd4;
                4'b0101: decoded_y = 3'd5;
                4'b1001: decoded_y = 3'd6;
                4'b0111: decoded_y = 3'd7;
                default: valid4 = 1'b0;
            endcase
        end
    end else begin
        case (code4)
            4'b1011, 4'b0100: decoded_y = 3'd0;
            4'b1001: decoded_y = 3'd1;
            4'b0101: decoded_y = 3'd2;
            4'b1100, 4'b0011: decoded_y = 3'd3;
            4'b1101, 4'b0010: decoded_y = 3'd4;
            4'b1010: decoded_y = 3'd5;
            4'b0110: decoded_y = 3'd6;
            4'b1110, 4'b0001: decoded_y = 3'd7;
            4'b0111, 4'b1000: begin decoded_y = 3'd7; alt7 = 1'b1; end
            default: valid4 = 1'b0;
        endcase
    end
end

always @* begin
    is_control = k28 || (alt7 &&
        (decoded_x == 5'd23 || decoded_x == 5'd27 ||
         decoded_x == 5'd29 || decoded_x == 5'd30));
    data = {decoded_y, decoded_x};
    code_error = !(match_neg || match_pos);
    disparity_error = !code_error &&
        (disparity_in ? !match_pos : !match_neg);
    if (disparity_in && match_pos)
        disparity_out = disparity_pos_out;
    else if (!disparity_in && match_neg)
        disparity_out = disparity_neg_out;
    else if (match_neg)
        disparity_out = disparity_neg_out;
    else if (match_pos)
        disparity_out = disparity_pos_out;
    else
        disparity_out = disparity_in;
end
endmodule
