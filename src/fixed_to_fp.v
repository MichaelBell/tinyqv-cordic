/*
 * Copyright (c) 2025 Dylan Toussaint
 * SPDX-License-Identifier: Apache-2.0
 */

 `default_nettype none

 /*
 Module fixed_to_fp
 Translates Q=4 F=23 fixed point to IEEE floating point format.
 */
module fixed_to_fp(
    input  wire signed [26:0] fp_in,
    output reg         [31:0]        fp_out  
);

  wire        sign;
  wire [26:0] abs_val;
  assign sign    = fp_in[26];           
  assign abs_val = sign ? -fp_in : fp_in;  

  reg  [26:0] tmp;
  reg  [4:0]  count;  
  integer     msb;            
  integer     exp;            
  reg  [31:0] norm;  

  always @* begin

   fp_out = 32'd0;
   tmp    = 27'd0;
   count  = 5'd0;
   msb    = 32'd0;
   exp    = 32'd0;
   norm   = 32'd0;
   
    if (abs_val == 0) begin
      fp_out = {sign, 31'b0}; 
    end else begin
      tmp   = abs_val;
      count = 0;

      if (tmp[26:13] == 14'b0) begin
         count = count + 14;
         tmp = tmp << 14;
      end

      if (tmp[26:20] == 7'b0) begin
         count = count + 7;
         tmp = tmp << 7;
      end

      if (tmp[26:24] == 3'b0) begin
         count = count + 3;
         tmp = tmp << 3;
      end

      if (tmp[26:25] == 2'b0) begin
         count = count + 2;
         tmp = tmp << 2;
      end

      if (tmp[26] == 1'b0) begin
         count = count + 1;
      end

      msb = 26 - count;
      exp = (msb - 23) + 127;

      if (msb > 23)
         norm = abs_val >> (msb - 23);
      else
         norm = abs_val << (23 - msb);

      fp_out = { sign, exp[7:0], norm[22:0] };
    end
  end

endmodule