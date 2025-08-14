/*
 * Copyright (c) 2025 Dylan Toussaint
 * SPDX-License-Identifier: Apache-2.0
 */

 `default_nettype none

 /*
 Module fp_to_fixed
 Converts 32 bit floating point numbers to 4.23 fixed point format.
 */
 module fp_to_fixed (
    input         clk,
    input         rst_n,

    input [31:0]  fp_in,
    output [31:0] fixed_out
 );


 endmodule