module cordic_instr_top(
	input  logic [31:0] dataa,
	input  logic [31:0] datab,
	input  logic        clk,
	input  logic        clk_en,
	input  logic        reset,
	input  logic        start,
	input  logic	    cos,
	output logic        done,
	output logic [31:0] result
);	
	
	logic [26:0] fp_in;
	logic [26:0] fp_out;
	logic [31:0] temp_out;
	
	logic [26:0] cordic_in;
	logic [26:0] cordic_out;
	logic        cordic_done;
	logic        delay;
	

	fp_to_fixed #(
		.Q(4),
		.F(23)
	) fp_to_fixed_inst ( 
		.fp_in(dataa),
		.fp_out(fp_in)
	);

	cordic #(
		.Q(4),
		.F(23),
		.STAGES(10),
		.N(2)
	) cordic_inst (
		.clk(clk),
		.clk_en(clk_en),
		.rst(reset),
		.start(start),
		.theta(fp_in),
		.cos(cos),
		.cos_o(fp_out),
		.done(cordic_done)
	);
	
	fixed_to_fp fixed_to_fp_inst (
		.fp_in(fp_out),
		.fp_out(temp_out)
	);
	
	
	//Align expected done signal with that of cordic_inst impl.
	//Buffer output until next done signal
	always_ff @(posedge clk) begin
		if(reset) begin
			result <= 32'd0;
			done   <= 1'b0;
			delay  <= 1'b0;
		end else if (clk_en) begin
			delay <= cordic_done;
			done  <= delay;
			
			if(cordic_done) begin
				result <= temp_out;
			end
		end
	end
	


endmodule
