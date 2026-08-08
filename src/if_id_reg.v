module if_id_reg(
    input clk,
    input rst_n,
    input flush_d,
    input stall_d,
    input [31:0] pc_f,
    input [31 : 0] instr_f,
    input [31 : 0] pc_plus_4_f,
    output reg [31:0] pc_d,
    output reg  [31 : 0] instr_d,
    output reg [31 : 0] pc_plus_4_d,
    output reg valid_d
);

 always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        instr_d <= 32'b0;
        pc_d <= 32'b0;
        valid_d <= 1'b0;
    end
    else if( flush_d) begin
        instr_d <= 32'b0;
        pc_d <= 32'b0;
        valid_d <= 1'b0;
    end
    else if (stall_d) ;
    else begin
        instr_d <= instr_f;
        pc_d <= pc_f;
        pc_plus_4_d <= pc_plus_4_f;
        valid_d <= 1'b1;
    end
   end
endmodule
