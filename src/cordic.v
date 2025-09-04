/*
 * Copyright (c) 2025 Dylan Toussaint
 * SPDX-License-Identifier: Apache-2.0
 */

module cordic (
    input  wire                  clk,
    input  wire                  clk_en,
    input  wire                  rst,
    input  wire                  start,
    input  wire signed [17:0]    theta,
    input  wire                  cos,
    output reg  signed [17:0]    cos_o,
    output reg                   done
);

    localparam integer Q            = 2;
    localparam integer F            = 16;
    localparam integer STAGES       = 6;
    localparam integer N            = 2;

    localparam integer TOTAL_STAGES = N * STAGES;

    localparam [1:0] IDLE = 2'd0, BUSY = 2'd1, DONE = 2'd2;
    reg [1:0] state;

    localparam signed [17:0] CORDIC_K = 18'h09B75; //TODO: unsure
    localparam signed [17:0] PI       = 18'h3243F; //TODO: unsure
    localparam signed [17:0] PI_2     = PI >>> 1;

    reg  signed [17:0] x_in, y_in, z_in;
    wire signed [17:0] x_out, y_out, z_out;
    wire signed [17:0] atan [0:1];
    reg  [3:0]         count;
    wire [3:0]         stage; 

    reg  signed [17:0] theta_red;
    reg                flip;
    wire               work;

    reg cos_state;

    cordic_chain cordic_chain_inst(
        .x_in   (x_in),
        .y_in   (y_in),
        .z_in   (z_in),
        .atan0  (atan[0]),
        .atan1  (atan[1]),
        .stages (stage),
        .x_out  (x_out),
        .y_out  (y_out),
        .z_out  (z_out)
    );

    atan atan_inst(
        .stage     (stage),
        .atan_out0 (atan[0]),
        .atan_out1 (atan[1])
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

    assign stage = (N*count);

    //Reset and Start Signals
    //Stage Counter for final operation
    always @(posedge clk) begin
        if (rst) begin
            //Reset signal, set state to IDLE and signals to 0
            x_in  <= 18'sd0;
            y_in  <= 18'sd0;
            z_in  <= 18'sd0;
            count <= 4'd0;
            done  <= 1'b0;
            state <= IDLE;
        end else if (clk_en) begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        x_in  <= CORDIC_K;
                        y_in  <= 18'sd0;
                        z_in  <= theta_red;
                        count <= 4'd0;
                        state <= BUSY;
                    end
                end
                BUSY: begin
                    x_in <= x_out;
                    y_in <= y_out;
                    z_in <= z_out;
                    if (count == (STAGES-1)) begin
                        state <= DONE;
                        done  <= 1'b1;
                        cos_o <= flip ? (cos_state ? -x_out : -y_out) : (cos_state ? x_out : y_out);
                    end else begin
                        count <= count + 4'd1;
                    end
                end
                DONE: begin
                    done  <= 1'b0;
                    state <= IDLE;
                end
            endcase
        end
    end
  
    //cos state register
    always @(posedge clk) begin
        if (rst) cos_state <= 1'b0;
        else if (state == IDLE) cos_state <= cos;
        else cos_state <= cos_state;
    end

endmodule