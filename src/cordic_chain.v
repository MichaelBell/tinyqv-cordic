/*
 * Copyright (c) 2025 Dylan Toussaint
 * SPDX-License-Identifier: Apache-2.0
 */

 `default_nettype none

 /*
 Module cordic_chain
 Links two cordic rotations for two rotations per cycle.
 */
module cordic_chain (
    input  wire  signed [17:0]            x_in,
    input  wire  signed [17:0]            y_in,
    input  wire  signed [17:0]            z_in,
    input  wire  signed [17:0]            atan0,
    input  wire  signed [17:0]            atan1,
    input  wire         [3:0]             stages,
    output wire  signed [17:0]            x_out,
    output wire  signed [17:0]            y_out,
    output wire  signed [17:0]            z_out
);

    wire signed [17:0] atan [0:1];
    assign atan[0] = atan0;
    assign atan[1] = atan1;


    wire signed [17:0] x_stage [0:2];
    wire signed [17:0] y_stage [0:2];
    wire signed [17:0] z_stage [0:2];

    reg         [3:0]  shift [0:3];

    always @* begin
        case (stages)
            4'd0:  begin shift[0] = 4'd0;  shift[1] = 4'd1;  end
            4'd2:  begin shift[0] = 4'd2;  shift[1] = 4'd3;  end
            4'd4:  begin shift[0] = 4'd4;  shift[1] = 4'd5;  end
            4'd6:  begin shift[0] = 4'd6;  shift[1] = 4'd7;  end
            4'd8:  begin shift[0] = 4'd8;  shift[1] = 4'd9;  end
            4'd10: begin shift[0] = 4'd10; shift[1] = 4'd11; end
            4'd12: begin shift[0] = 4'd12; shift[1] = 4'd13; end
            4'd14: begin shift[0] = 4'd14; shift[1] = 4'd15; end
            default: begin shift[0] = 4'd0; shift[1] = 4'd1; end
        endcase
    end

    cordic_stage stage_inst_1 (
        .x_in (x_in),
        .y_in (y_in),
        .z_in (z_in),
        .atan (atan[0]),
        .stage(shift[0]),
        .x_out(x_stage[0]),
        .y_out(y_stage[0]),
        .z_out(z_stage[0])
    );

    cordic_stage stage_inst_2 (
        .x_in (x_stage[0]),
        .y_in (y_stage[0]),
        .z_in (z_stage[0]),
        .atan (atan[1]),
        .stage(shift[1]),
        .x_out(x_stage[1]),
        .y_out(y_stage[1]),
        .z_out(z_stage[1])
    );

    assign x_out = x_stage[1];
    assign y_out = y_stage[1];
    assign z_out = z_stage[1];

endmodule