module mem_wb_reg(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        flush_w,
    input  wire        stall_w,
    
    input  wire [31:0] read_data_m,
    input  wire [31:0] alu_result_m,
    input  wire [31:0] pc_plus_4_m,
    input  wire [4:0]  rd_m,
    input  wire        reg_write_m,
    input  wire [1:0]  result_src_m,
    input  wire valid_m,
    input  wire crypto_en_m,
    output reg  crypto_en_w,
    output reg  valid_w,
    output reg  [31:0] read_data_w,
    output reg  [31:0] alu_result_w,
    output reg  [31:0] pc_plus_4_w,
    output reg  [4:0]  rd_w,
    output reg reg_write_w,
    output reg  [1:0]  result_src_w
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_data_w <= 32'b0;
            alu_result_w <= 32'b0;
            pc_plus_4_w <= 32'b0;
            rd_w <= 5'b0;
            reg_write_w <= 1'b0;
            result_src_w <= 2'b00;
            valid_w <= 1'b0;
            crypto_en_w <= 1'b0;
        end
        else if (flush_w) begin
            read_data_w <= 32'b0;
            alu_result_w <= 32'b0;
            pc_plus_4_w <= 32'b0;
            rd_w <= 5'b0;
            reg_write_w <= 1'b0;
            result_src_w <= 2'b00;
            valid_w <= 1'b0;
            crypto_en_w <= 1'b0;
        end
        else if (stall_w) begin//为了后续扩展除数与异常消查，这不一定要
           
        end
        else begin//为了后续扩展除数与异常消查，这不一定要
            read_data_w <= read_data_m;
            alu_result_w <= alu_result_m;
            pc_plus_4_w <= pc_plus_4_m;
            rd_w <= rd_m;
            reg_write_w <= reg_write_m;
            result_src_w <= result_src_m;
            valid_w <= valid_m;
            crypto_en_w <= crypto_en_m;
        end
    end

endmodule
