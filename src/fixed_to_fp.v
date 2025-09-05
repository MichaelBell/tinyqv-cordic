/*
 * Copyright (c) 2025 Dylan Toussaint, Justin Fok
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

/*
 Module fixed_to_fp
 Translates Q=2 F=16 fixed point to IEEE floating point format.
 */
module fixed_to_fp(
    input  wire signed [17:0] fp_in,
    output reg         [31:0]        fp_out  
);

  wire        sign;
  wire [17:0] abs_val;
  assign sign    = fp_in[17];           
  assign abs_val = sign ? -fp_in : fp_in;  

  reg  [17:0] tmp;
  reg  [4:0]  count;  
  integer     msb;            
  integer     exp;            
  reg  [31:0] norm;
  reg  [17:0] imm;

  always @* begin

   fp_out = 32'd0;
   tmp    = 18'd0;
   count  = 5'd0;
   msb    = 32'd0;
   exp    = 32'd0;
   norm   = 32'd0;
   
    if (abs_val == 0) begin
      fp_out = {sign, 31'b0}; 
    end else begin
      tmp   = abs_val;
      count = 0;

      if (tmp[17:9] == 9'b0) begin
         count = count + 9;
         tmp = tmp << 9;
      end

      if (tmp[17:13] == 5'b0) begin
         count = count + 5;
         tmp = tmp << 5;
      end

      if (tmp[17:15] == 3'b0) begin
         count = count + 3;
         tmp = tmp << 3;
      end

      if (tmp[17:16] == 2'b0) begin
         count = count + 2;
         tmp = tmp << 2;
      end

      if (tmp[17] == 1'b0) begin
         count = count + 1;
      end

      msb = 17 - count;
      exp = (msb - 16) + 127;
      

      if (msb > 16) begin
         imm = abs_val >> (msb - 16);
         norm = {imm[15:0], 7'b0};
      end
      else begin
         imm = abs_val << (16 - msb);
         norm = {imm[15:0], 7'b0};
      end

      fp_out = { sign, exp[7:0], norm[22:0] };
    end
  end

endmodule
