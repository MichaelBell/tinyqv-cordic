module fixed_to_fp(
    input  logic signed [26:0] fp_in,
    output logic [31:0]        fp_out  
);

  logic sign;
  logic [26:0] abs_val;
  assign sign    = fp_in[26];           
  assign abs_val = sign ? -fp_in : fp_in;  

  always_comb begin
    if (abs_val == 0) begin
      fp_out = 32'b0; 
    end else begin
      logic [26:0] tmp;
      logic [4:0] count;  
      int msb;            
      int exp;            
      logic [31:0] norm;  

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