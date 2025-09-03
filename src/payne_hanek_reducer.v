/*
 * Copyright (c) 2025 Dylan Toussaint
 * SPDX-License-Identifier: Apache-2.0
 */
module payne_hanek_reducer(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        in_valid,
    output reg        out_valid,

    input  wire [31:0] data_in,
    output reg [4:0]  q_out,
    output reg [63:0] f_out
);

    wire        sgn;
    wire [7:0]  exp;
    wire [22:0] mant;
    wire [31:0] sigf;
    wire [9:0]  k;
    wire [4:0]  shift;
    wire [4:0]  idx;

    assign sgn   = data_in[31];
    assign exp   = data_in[30:23];
    assign mant  = data_in[22:0];
    assign sigf  = {8'd0, 1'b1, mant};
    assign k     = {1'b0, exp} - 8'd127 - 8'd23;
    assign shift = k[4:0];
    assign idx   = k[9:5];
 
    reg [31:0] INV2PI32 [0:7];
    initial begin
        INV2PI32[0]=32'h28be60db; INV2PI32[1]=32'h9391054a;
        INV2PI32[2]=32'h7f09d5f4; INV2PI32[3]=32'h7d4d3770;
        INV2PI32[4]=32'h36d8a566; INV2PI32[5]=32'h4f10e410;
        INV2PI32[6]=32'h7f9458ea; INV2PI32[7]=32'hf7aef158;
    end

    reg [31:0] a1, a2, a3;
    always @* begin
        if(shift == 0) begin
            a1 = INV2PI32[idx+0];
            a2 = INV2PI32[idx+1];
            a3 = INV2PI32[idx+2];
        end else begin
            a1 = (INV2PI32[idx+0] << shift) | (INV2PI32[idx+1] >> (32 - shift));
            a2 = (INV2PI32[idx+1] << shift) | (INV2PI32[idx+2] >> (32 - shift));
            a3 = (INV2PI32[idx+2] << shift) | (INV2PI32[idx+3] >> (32 - shift));
        end
    end

    reg [64:0] p1, p2, p3;
    reg        v1, v2, v3, s_r;
    always @(posedge clk) begin
        if (!rst_n) begin v1 <= 0; v2 <= 0; v3 <= 0; end
        else begin
            v1  <= in_valid;
            s_r <= sgn;
            p1 <= $unsigned(sigf) * $unsigned(a1);
            v2 <= v1;
            p2 <= $unsigned(sigf) * $unsigned(a2);
            v3 <= v2;
            p3 <= $unsigned(sigf) * $unsigned(a3);
        end
    end

    wire [63:0] w1 = {p1[31:0], 32'd0};
    wire [63:0] w2 = p2;
    wire [63:0] w3 = p3 >> 32;
    wire [63:0] wu = w1 + w2 + w3;
    wire [63:0] ws = s_r ? -$signed(wu) : $signed(wu);

    wire signed [3:0] qtmp = ($signed({ws[63],ws[63:61]}) + 4'sd1) >>> 1;
    always @(posedge clk) begin
        if (!rst_n) begin out_valid<=0; q_out<=0; f_out<=0; end
        else begin
            out_valid <= v3;
            q_out     <= qtmp;
            f_out     <= ws <<< 2;
        end
  end
endmodule