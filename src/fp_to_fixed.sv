/*
 * Copyright (c) 2025 Dylan Toussaint
 * SPDX-License-Identifier: Apache-2.0
 */

 `default_nettype none

 /*
 Module fp_to_fixed
 Converts 32 bit floating point numbers to 4.23 fixed point format.
 */
module fp_to_fixed #(
    parameter int Q,
    parameter int F
)(
    input  logic [31:0] fp_in,
    output logic [Q+F-1:0] fp_out
);

    logic        sign;
    logic [7:0]  exp;
    logic [22:0] frac;
    logic [23:0] mant;

    assign sign = fp_in[31];
    assign exp  = fp_in[30:23];
    assign frac = fp_in[22:0];
    assign mant = {1'b1, frac};

    always_comb begin
        if(exp == 8'd0) begin
            fp_out = '0;
        end else begin
				int shift;
            shift = exp - 150 + F;

            if(shift >= 0) begin
                fp_out = sign ? - (mant << shift) : (mant << shift);
            end else begin
                fp_out = sign ? - (mant >>> (-shift)) : (mant >>> (-shift));
            end

        end
    end

endmodule