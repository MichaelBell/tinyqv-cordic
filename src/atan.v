/*
 * Copyright (c) 2025 Dylan Toussaint
 * SPDX-License-Identifier: Apache-2.0
 */

module atan(
    input  wire  [3:0]  stage,      
    output reg   [17:0] atan_out0,
    output reg   [17:0] atan_out1
);

  always @* begin
    case (stage)
      4'd0:  begin atan_out0 = 18'h0C910; atan_out1 = 18'h076B2; end // 0,1
      4'd2:  begin atan_out0 = 18'h03EB7; atan_out1 = 18'h01FD6; end // 2,3
      4'd4:  begin atan_out0 = 18'h00FFB; atan_out1 = 18'h007FF; end // 4,5
      4'd6:  begin atan_out0 = 18'h00400; atan_out1 = 18'h00200; end // 6,7
      4'd8:  begin atan_out0 = 18'h00100; atan_out1 = 18'h00080; end // 8,9
      4'd10: begin atan_out0 = 18'h00040; atan_out1 = 18'h00020; end // 10,11
      default: begin atan_out0 = 18'h00000; atan_out1 = 18'h00000; end
    endcase
  end

endmodule
