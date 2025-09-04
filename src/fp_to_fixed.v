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
    parameter int Q = 2,
    parameter int F = 16
)(
    input  wire     [31:0] fp_in,
    output reg      [17:0] fp_out,
    output reg             fp_input_invalid_flag
);

    wire         sign;
    wire  [7:0]  exp;
    wire  [22:0] frac;
    wire  [23:0] mant;

    //Need to handle special cases...
    wire is_zero = (exp == 8'd0)   && (frac == 23'd0);
    wire is_sub  = (exp == 8'd0)   && (frac != 23'd0);
    wire is_inf  = (exp == 8'd255) && (frac == 23'd0);
    wire is_nan  = (exp == 8'd255) && (frac != 23'd0);

    integer      shift;

    assign sign = fp_in[31];
    assign exp  = fp_in[30:23];
    assign frac = fp_in[22:0];
    assign mant = is_sub ? {1'b0, frac} : {1'b1, frac};

    reg [17:0] mant_ext;

    always @* begin
        fp_out   = 18'd0;
        mant_ext = mant[17:0];
        shift    = 0;

        if(is_zero) begin
            fp_out                = 18'd0;
            fp_input_invalid_flag = 1'b0;
        end else if (is_nan || is_inf) begin
            fp_out                = 18'd0;
            fp_input_invalid_flag = 1'b1;
        end else begin
            fp_input_invalid_flag = 1'b0;

            shift = is_sub ? (-126 - 7) : ((exp - 127) - 7);

            if(shift >= 0) begin
                fp_out = sign ? - (mant_ext << shift) : (mant_ext << shift);
            end else begin
                fp_out = sign ? - (mant_ext >>> (-shift)) : (mant_ext >>> (-shift));
            end
        end
    end

endmodule
