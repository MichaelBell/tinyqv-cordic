module cordic_chain #(
    parameter int  Q      = 4,
    parameter int  F      = 36,
    parameter int  N      = 4,
    parameter int  STAGES = 10
)(
    input  logic signed [Q+F-1:0]            x_in,
    input  logic signed [Q+F-1:0]            y_in,
    input  logic signed [Q+F-1:0]            z_in,
    input  logic signed [Q+F-1:0]            atan [0:N-1],
    input  logic        [$clog2(N*STAGES)-1:0] stages,
    output logic signed [Q+F-1:0]            x_out,
    output logic signed [Q+F-1:0]            y_out,
    output logic signed [Q+F-1:0]            z_out
);

    typedef logic signed [Q+F-1:0] fixed_t;

    fixed_t x_stage [0:N];
    fixed_t y_stage [0:N];
    fixed_t z_stage [0:N];
    logic [$clog2(N*STAGES)-1:0]    shift   [0:3];

    always_comb begin
        case(stages)
            5'd0: begin
                shift[0] = 0;
                shift[1] = 1;
            end
            5'd2: begin
                shift[0] = 2;
                shift[1] = 3;
            end
            5'd4: begin
                shift[0] = 4;
                shift[1] = 5;
            end
            5'd6: begin
                shift[0] = 6;
                shift[1] = 7;
            end
            5'd8: begin
                shift[0] = 8;
                shift[1] = 9;
            end
            5'd10:begin
                shift[0] = 10;
                shift[1] = 11;
            end
            5'd12:begin
                shift[0] = 12;
                shift[1] = 13;
            end
            5'd14: begin
                shift[0] = 14;
                shift[1] = 15;
            end
            5'd16:begin
                shift[0] = 16;
                shift[1] = 17;
            end
            5'd18: begin
                shift[0] = 18;
                shift[1] = 19;
            end
        endcase
    end

    cordic_stage #(
        .Q(Q),
        .F(F),
        .STAGES(STAGES),
        .N(N)
    ) stage_inst_1 (
        .x_in(x_in),
        .y_in(y_in),
        .z_in(z_in),
        .atan(atan[0]),
        .stage(shift[0]),
        .x_out(x_stage[0]),
        .y_out(y_stage[0]),
        .z_out(z_stage[0])
    );

    cordic_stage #(
        .Q(Q),
        .F(F),
        .STAGES(STAGES),
        .N(N)
    ) stage_inst_2 (
        .x_in(x_stage[0]),
        .y_in(y_stage[0]),
        .z_in(z_stage[0]),
        .atan(atan[1]),
        .stage(shift[1]),
        .x_out(x_stage[1]),
        .y_out(y_stage[1]),
        .z_out(z_stage[1])
    );

    assign x_out = x_stage[1];
    assign y_out = y_stage[1];
    assign z_out = z_stage[1];

endmodule   