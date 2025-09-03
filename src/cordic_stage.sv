module cordic_stage #(
    parameter int Q      = 4,
    parameter int F      = 36,
    parameter int STAGES = 5,
    parameter int N      = 4
)(
    input  logic signed [Q+F-1:0]            x_in,
    input  logic signed [Q+F-1:0]            y_in,
    input  logic signed [Q+F-1:0]            z_in,
    input  logic signed [Q+F-1:0]            atan,
    input  logic        [$clog2(STAGES*N)-1:0] stage,
    output logic signed [Q+F-1:0]            x_out,
    output logic signed [Q+F-1:0]            y_out,
    output logic signed [Q+F-1:0]            z_out
);
		
    logic signed [Q+F-1:0] x_shift, y_shift;
    
    assign x_shift = x_in >>> stage;
    assign y_shift = y_in >>> stage;

    assign x_out = z_in[Q+F-1] ? (x_in + y_shift) : (x_in - y_shift);
    assign y_out = z_in[Q+F-1] ? (y_in - x_shift) : (y_in + x_shift);
    assign z_out = z_in + (z_in[Q+F-1] ? atan : -atan);

endmodule