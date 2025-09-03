
module cordic #(
    parameter int Q      = 4,
    parameter int F      = 36,
    parameter int STAGES = 8,
    parameter int N      = 4
)(
    input  logic                  clk,
    input  logic                  clk_en,
    input  logic                  rst,
    input  logic                  start,
    input  logic signed [Q+F-1:0] theta,
    input  logic		  cos,
    output logic signed [Q+F-1:0] cos_o,
    output logic                  done
);

localparam int TOTAL_STAGES = N * STAGES;
typedef logic signed [Q+F-1:0] fixed_t;


typedef enum logic [1:0] {
    IDLE,
    BUSY,
    DONE
} state_t;

state_t state;

localparam fixed_t CORDIC_K = 27'h004dba77;
localparam fixed_t PI       = 27'h1921FB5;
localparam fixed_t PI_2     = PI >>> 1;


fixed_t x_in, y_in, z_in;
fixed_t x_out, y_out, z_out;
logic signed [Q+F-1:0] atan [0:N-1];
logic [$clog2(STAGES+1)-1:0] count;
logic [$clog2(TOTAL_STAGES)-1:0] stage;

fixed_t theta_red;
logic   flip;
logic   work;

reg cos_state;

cordic_chain #(
    .Q(Q),
    .F(F),
    .N(N),
    .STAGES(STAGES)
) cordic_chain_inst(
    .x_in(x_in),
    .y_in(y_in),
    .z_in(z_in),
    .atan(atan),
    .stages(stage),
    .x_out(x_out),
    .y_out(y_out),
    .z_out(z_out)
);

atan atan_inst(
    .stage(stage),
    .atan_out0(atan[0]),
    .atan_out1(atan[1])
);


//Range Correction
always_comb begin
    theta_red = theta;
    flip      = 0;
    if(theta > PI_2) begin
        theta_red = PI - theta;
        flip      = cos_state ? 1 : 0;
    end else if (theta < -PI_2) begin
        theta_red = -PI - theta;
        flip      = cos_state ? 1 : 0;
    end
end

assign stage = (N*count);

//Reset and Start Signals
//Stage Counter for final operation
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        //Reset signal, set state to IDLE and signals to 0
        x_in  <= 0;
        y_in  <= 0;
        z_in  <= 0;
        count <= 0;
        done  <= 0;
        state <= IDLE;
    end else if (clk_en) begin
        case(state)
            IDLE: begin
                done <=0;
                if(start) begin
                    x_in  <= CORDIC_K;
                    y_in  <= 0;
                    z_in  <= theta_red;
                    count <= 0;
                    state <= BUSY;
                end
            end
            BUSY: begin
                x_in <= x_out;
                y_in <= y_out;
                z_in <= z_out;
                if(count == STAGES-1) begin
                    state <= DONE;
                    done <= 1;
                    cos_o <= flip ? (cos_state ? -x_out : -y_out) : (cos_state ? x_out : y_out);
                end else begin
                    count <= count + 1;
                end
            end
            DONE: begin
                done <= 0;
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
