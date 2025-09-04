/*
 * Copyright (c) 2025 Dylan Toussaint
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Cordic - trigonometry accelerator
module cordicDylanJustin (
    input         clk,          // Clock - the TinyQV project clock is normally set to 64MHz.
    input         rst_n,        // Reset_n - low to reset.

    input  [7:0]  ui_in,        // The input PMOD, always available.  Note that ui_in[7] is normally used for UART RX.
                                // The inputs are synchronized to the clock, note this will introduce 2 cycles of delay on the inputs.

    output [7:0]  uo_out,       // The output PMOD.  Each wire is only connected if this peripheral is selected.
                                // Note that uo_out[0] is normally used for UART TX.

    input [5:0]   address,      // Address within this peripheral's address space
    input [31:0]  data_in,      // Data in to the peripheral, bottom 8, 16 or all 32 bits are valid on write.

    // Data read and write requests from the TinyQV core.
    input [1:0]   data_write_n, // 11 = no write, 00 = 8-bits, 01 = 16-bits, 10 = 32-bits
    input [1:0]   data_read_n,  // 11 = no read,  00 = 8-bits, 01 = 16-bits, 10 = 32-bits
    
    output [31:0] data_out,     // Data out from the peripheral, bottom 8, 16 or all 32 bits are valid on read when data_ready is high.
    output        data_ready,

    output        user_interrupt  // Dedicated interrupt request for this peripheral
);

    //cordic accelerator at address 0
    wire cos;
    wire start;
    wire done;
    assign cos = ui_in[0];
    assign start = (data_write_n != 2'b11) && (address == 6'h0);
    assign data_ready = done;

    cordic_instr_top(
        .dataa(data_in),
        .datab(32'b0),
        .clk(clk),
        .clk_en(1'b1),
        .reset(!rst_n),
        .start(start),
        .cos(cos),
        .done(done),
        .result(data_out)
    );	
    
    /*
    wire [4:0]  q_out;
    wire [63:0] f_out;
    wire        out_valid;
    
    payne_hanek_reducer phr(.clk(clk),
                            .rst_n(rst_n),
                            .data_in(data_in),
                            .in_valid(1'b1),
                            .out_valid(out_valid),
                            .q_out(q_out),
                            .f_out(f_out));
    */

    
    // User interrupt is generated on rising edge of ui_in[6], and cleared by writing a 1 to the low bit of address 8.
    /*
    reg example_interrupt;
    reg last_ui_in_6;

    always @(posedge clk) begin
        if (!rst_n) begin
            example_interrupt <= 0;
        end

        if (ui_in[6] && !last_ui_in_6) begin
            example_interrupt <= 1;
        end else if (address == 6'h8 && data_write_n != 2'b11 && data_in[0]) begin
            example_interrupt <= 0;
        end

        last_ui_in_6 <= ui_in[6];
    end

    assign user_interrupt = example_interrupt;
    */

    // List all unused inputs to prevent warnings
    // data_read_n is unused as none of our behaviour depends on whether
    // registers are being read.
    wire _unused = &{data_read_n, 1'b0};

endmodule
