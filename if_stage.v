module if_stage(
    input clk,
    input rst_n,
    input stall_f,      
    input pcsrc_e,       
    input [31:0] pctarget_e,    
    output wire [31:0] pc_f,
    output wire [31:0] pc_plus_4_f,
    input  wire  use_predict,      
    input  wire [31:0] predicted_target,  
    output wire [31:0] instr_f
);
    
    (* syn_keep="true" *) reg [31:0] pc_f_reg;
    assign pc_f = pc_f_reg;

    icache u_icache (
    .clk   (clk),
    .rst_n (rst_n),
    .addr  (pc_f),
    .inst  (instr_f)
);

    assign pc_plus_4_f = pc_f_reg + 4;
    wire [31:0] pc_next;
    assign pc_next = use_predict ? predicted_target : (pcsrc_e ? pctarget_e : pc_plus_4_f);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) pc_f_reg <= 0;
        else if (!stall_f) pc_f_reg <= pc_next;
    end
endmodule
