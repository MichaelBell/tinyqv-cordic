`timescale 1 ns / 100 ps

module tb();

	//Inputs to DUT are reg type
	reg clk;
	reg reset;	//asynchronous active high reset
	reg clk_en; 		//input active high enable
	reg [31:0] dataa; 
	reg cos;
	reg start;
	
	//Output from DUT is wire type
	wire [31:0] result;
	wire done;
	
	//Instantiate the DUT
	cordic_instr_top DUTcordic(
		.clk(clk),
		.reset(reset),
		.clk_en(clk_en),
		.start(start),
		.done(done),
		.cos(cos),
		.dataa(dataa),
		.datab(32'b0),
		.result(result) //cos(z) or sin(z)
	);

	// ---- If a clock is required, see below ----
	// //Create a 50MHz clock
	always
			#10 clk = ~clk;
	// -----------------------

	//Gtkwave debug
	initial begin
	    $dumpfile("TinyQV.vcd");
	    $dumpvars(0, tb);
	end

	//Initial Block
	initial
	begin
		$display($time, " << Starting Simulation >> ");
		
		// intialise/set input
		clk <= 1'b0; //clock 
		reset <= 1'b1;	//reset
		clk_en <= 1'b0; //IP disabled
		start <= 1'b0; //no start
		
		// If using a clock
		// @(posedge clk); 
		
		// Wait 10 cycles (corresponds to timescale at the top) 
		// 12 clock cycles per result (11 cycle latency) -> 240ns
		#10
		dataa <= 32'h3f000000;	//0.5
		reset <= 1'b0;	//no reset
		clk_en <= 1'b1;	//ip enabled
		start <= 1'b1;	//start
		cos <= 1'b1;	//cos selected
		#20
		start <= 1'b0;
		#220
		dataa <= 32'h3f000000;	//0.5
		start <= 1'b1;
		cos <= 1'b0;	//sin selected
		#20
		start <= 1'b0;
		#220
		clk_en = 1'b0;
		#40
		clk_en = 1'b1;
		dataa <= 32'hbe06177f;	//-0.130949
		cos <= 1'b1;	//cos selected
		start <= 1'b1;
		#20
		cos <= 1'b0;	//signal only relevant for 1st cycle
		start <= 1'b0;
		#220
		dataa <= 32'h3f7b316e;	//0.9812230
		cos <= 1'b0;	//sin selected
		start <= 1'b1;
		#20
		cos <= 1'b1;
		start <= 1'b0;
		#220
		reset = 1'b1;
		#40
		/*
		clk_en <= 1'b0;	//disable input
		#80
		clk_en <= 1'b1;	//enable input
		z_in <= 22'h380000;	//-0.5
		//input not disabled
		
		#100
		z_in <= 22'h063307;  //0.3874578
		//input not disabled
		
		#100
		z_in <= 22'h30345F; 	//-0.9872140
		#40
		clk_en <= 1'b0;	//disable input
		#60
		clk_en <= 1'b1;	//enable input
		#100
		
		reset <= 1'b1; //reset 
		#20
		reset <= 1'b0; 
		#60
		*/
		$display($time, "<< Simulation Complete >>");
		$finish(2);
	end

endmodule
