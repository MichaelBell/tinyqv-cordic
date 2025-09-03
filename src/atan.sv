module atan(
    input  logic [4:0] stage,      
    output logic [26:0] atan_out0,
    output logic [26:0] atan_out1
);

  always_comb begin
    case(stage)
      5'd0: begin
        atan_out0 = 27'h6487ED;
        atan_out1 = 27'h3B58CE;
      end
      5'd2: begin
        atan_out0 = 27'h1F5B76;
        atan_out1 = 27'h0FEADD;
      end
      5'd4: begin
        atan_out0 = 27'h07FD57;
        atan_out1 = 27'h03FFAB;
      end
      5'd6: begin
        atan_out0 = 27'h01FFF5;
        atan_out1 = 27'h00FFFF;
      end
      5'd8: begin
        atan_out0 = 27'h008000;
        atan_out1 = 27'h004000;
      end
      5'd10: begin
        atan_out0 = 27'h002000;
        atan_out1 = 27'h001000;
      end
      5'd12: begin
        atan_out0 = 27'h000800;
        atan_out1 = 27'h000400;
      end
      5'd14: begin
        atan_out0 = 27'h000200;
        atan_out1 = 27'h000100;
      end
      5'd16: begin
        atan_out0 = 27'h000080;
        atan_out1 = 27'h000040;
      end
      5'd18: begin
        atan_out0 = 27'h000020;
        atan_out1 = 27'h00000;
      end
      default: begin
        atan_out0 = 27'h0;
        atan_out1 = 27'h0;
      end
    endcase
  end

endmodule