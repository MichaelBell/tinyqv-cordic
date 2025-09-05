/*
 * Copyright (c) 2025 Dylan Toussaint, Justin Fok
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

    // Register map
    localparam [5:0] ADDR_THETA = 6'h00; // float32 input
    localparam [5:0] ADDR_CONTROL = 6'h01; // bit0 start, bit1 cos
    localparam [5:0] ADDR_RESULT = 6'h02; // float32 result
    localparam [5:0] ADDR_STATUS = 6'h03; // bit0 done (read-to-clear)
    
    // Registers
    reg  [31:0] theta_reg;
    reg  [1:0]  control_reg;        // bit 1:cos, bit 0:start
    reg  [31:0] result_reg;
    reg         status_reg;       // done

    // Cordic wires
    wire        cordic_done;
    wire [31:0] cordic_result;
    wire input_invalid_flag;
    
    // Drive CORDIC top
    cordic_instr_top cit(
        .dataa(theta_reg),
        .datab(32'b0),
        .clk(clk),
        .clk_en(1'b1),
        .reset(!rst_n),
        .start(control_reg[0]),
        .cos(control_reg[1]),
        .done(cordic_done),
        .result(cordic_result),
        .input_invalid_flag(input_invalid_flag)
    );
    
    reg	prev_start;
  
    // Register writes
    always @(posedge clk) begin
        if (!rst_n) begin
            theta_reg  <= 32'b0;
            control_reg    <= 2'b10;   // default cos
            result_reg <= 32'b0;
            status_reg   <= 1'b0;  // clear done status
        end else begin
            if (address == ADDR_THETA) begin
                if (data_write_n != 2'b11)              theta_reg[7:0]   <= data_in[7:0];
                if (data_write_n[1] != data_write_n[0]) theta_reg[15:8]  <= data_in[15:8];
                if (data_write_n == 2'b10)              theta_reg[31:16] <= data_in[31:16];
            end
            if (address == ADDR_CONTROL)  begin
                if (data_write_n != 2'b11) begin
        	    control_reg[1:0]	<= data_in[1:0];
                    if (data_in[0])	status_reg <= 1'b0; // clear done status on new start
                end
            end
            if (cordic_done) begin
                result_reg <= cordic_result;
                status_reg <= 1'b1; //done
                control_reg[0] <= 1'b0; //clear start on done
            end
        end
        
        prev_start <= control_reg[0];
    end
    
    wire [31:0] data_out_imm;
    
    // Register reads, unused addresses read 0
    assign data_out_imm = (address == ADDR_THETA) ? theta_reg :
                      (address == ADDR_CONTROL) ? {30'b0, control_reg} :
                      (address == ADDR_RESULT) ? result_reg :
                      (address == ADDR_STATUS) ? {31'b0, status_reg} : 
                      32'b0;
    /*
    assign data_out = (data_read_n == 2'b00) ? {24'b0, data_out_imm[7:0]} :
    		      (data_read_n == 2'b01) ? {16'b0, data_out_imm[15:0]} :
    		      (data_read_n == 2'b00) ? data_out_imm : 
    		      32'b0;
    */
    assign data_out = data_out_imm;
    assign data_ready = (address == ADDR_RESULT) ? status_reg : 1'b1;
    
    // User interrupt is generated on rising edge of invalid floating point input, and cleared by writing a 1 to the low bit of address 8.
    
    reg interrupt;
    reg prev_interrupt;

    always @(posedge clk) begin
        if (!rst_n) begin
            interrupt <= 0;
        end

        if (input_invalid_flag && !prev_interrupt) begin
            interrupt <= 1;
        end else if (address == 6'h8 && data_write_n != 2'b11 && data_in[0]) begin
            interrupt <= 0;
        end

        prev_interrupt <= input_invalid_flag;
    end

    assign user_interrupt = interrupt;

    // List all unused inputs to prevent warnings
    // data_read_n is unused as none of our behaviour depends on whether
    // registers are being read.
    wire _unused = &{data_read_n, 1'b0};
    assign uo_out         = 8'd0;
endmodule

