/*
 * Copyright (c) 2025 Dylan Toussaint
 * SPDX-License-Identifier: Apache-2.0
 */

 `default_nettype none

 /*
 Module cordic_stage
 Performs a single cordic rotation.
 */

module cordic_stage (
    input  wire signed [26:0] x_in,
    input  wire signed [26:0] y_in,
    input  wire signed [26:0] z_in,
    input  wire signed [26:0] atan,
    input  wire        [4:0]  stage,
    output wire signed [26:0] x_out,
    output wire signed [26:0] y_out,
    output wire signed [26:0] z_out
);
		
    wire signed [26:0] x_shift, y_shift;
    
    assign x_shift = x_in >>> stage;
    assign y_shift = y_in >>> stage;

    assign x_out = z_in[26] ? (x_in + y_shift) : (x_in - y_shift);
    assign y_out = z_in[26] ? (y_in - x_shift) : (y_in + x_shift);
    assign z_out = z_in + (z_in[26] ? atan : -atan);

endmodule