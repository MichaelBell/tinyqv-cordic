/*
 * Copyright (c) 2025 Dylan Toussaint, Justin Fok
 * SPDX-License-Identifier: Apache-2.0
 */

 /* MODULE cordic
    Performs full cordic rotations for an input angle within -PI to PI in fixed point format.
 */

module cordic (
    input  wire                  clk,
    input  wire                  clk_en,
    input  wire                  rst,
    input  wire                  start,
    input  wire signed [18:0]    theta,
    input  wire                  cos,
    output reg  signed [18:0]    cos_o,
    output reg                   done
);

    localparam [3:0] STAGES       = 12;

    reg busy;

    localparam signed   [18:0] CORDIC_K = 19'h09B75; 
    localparam unsigned [18:0] PI       = 19'h3243F; 
    localparam signed   [18:0] PI_2     = PI >> 1;

    reg  signed [18:0] x_in, y_in, z_in;
    wire signed [18:0] x_out, y_out, z_out;
    wire signed [18:0] atan;
    reg  [3:0]         count;
    wire [3:0]         stage; 

    reg  signed [18:0] theta_red;
    reg                flip;
    reg  signed [18:0] sel;

    reg cos_state;

    cordic_stage stage_inst_1 (
        .x_in (x_in),
        .y_in (y_in),
        .z_in (z_in),
        .atan (atan),
        .stage(stage),
        .x_out(x_out),
        .y_out(y_out),
        .z_out(z_out)
    );

    atan atan_inst(
        .stage    (stage),
        .atan_out (atan)
    );
    
    //Range Correction
    always @* begin
        theta_red = theta;
        flip      = 1'b0;
        if (theta > PI_2) begin
            theta_red = PI - theta;
            flip      = cos_state ? 1'b1 : 1'b0;
        end else if (theta < -PI_2) begin
            theta_red = -PI - theta;
            flip      = cos_state ? 1'b1 : 1'b0;
        end
    end

    assign stage = (count);

    //Reset and Start Signals
    //Stage Counter for final operation
    wire signed [18:0] sel_val   = (cos_state ? x_out : y_out);
    wire signed [18:0] final_val = flip ? -sel_val : sel_val;
    
    always @(posedge clk) begin
        if (rst) begin
            busy  <= 1'b0;
            count <= 4'd0;
            done  <= 1'b0;
        end else if (clk_en) begin
            done <= 1'b0;

            if (!busy) begin
            if (start) begin
                busy      <= 1'b1;
                count     <= 4'd0;
                cos_state <= cos;
                x_in      <= CORDIC_K;
                y_in      <= 19'sd0;
                z_in      <= theta_red;
            end
            end else begin
                // BUSY
                x_in  <= x_out;
                y_in  <= y_out;
                z_in  <= z_out;

                if (count == (STAGES-1)) begin
                    busy  <= 1'b0;
                    done  <= 1'b1;
                    cos_o <= final_val;
                end else begin
                    count <= count + 4'd1;
                end
            end
        end
    end

endmodule
