// IF stage for a synchronous instruction BSRAM.
// Two response slots absorb the instruction returned while IF/ID is frozen by
// a one-cycle load-use stall. q0 is presented to IF/ID; q1 preserves the next
// BSRAM response until q0 is consumed.
module if_stage(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall_f,
    input  wire        pcsrc_e,
    input  wire [31:0] pctarget_e,
    output wire [31:0] pc_f,
    output wire [31:0] pc_plus_4_f,
    output wire [31:0] pc_rom_f,
    output wire [31:0] pc_plus_4_rom_f,
    output wire        instr_valid_f,
    input  wire        use_predict,
    input  wire [31:0] predicted_target,
    output wire [31:0] instr_f
);
    (* syn_keep="true" *) reg [31:0] pc_f_reg;

    // Metadata for the logical ROM request that produced rom_rdata.
    reg [31:0] request_pc_reg;
    reg        request_valid_reg;

    reg [31:0] q0_instr, q0_pc;
    reg [31:0] q1_instr, q1_pc;
    reg [1:0]  response_count;
    reg        kill_next_response;
    wire [31:0] rom_rdata;

    wire consume_response = !stall_f && (response_count != 0);
    wire response_arrives = request_valid_reg;

    assign pc_f            = pc_f_reg;
    assign pc_plus_4_f     = pc_f_reg + 32'd4;
    assign pc_rom_f        = q0_pc;
    assign pc_plus_4_rom_f = q0_pc + 32'd4;
    assign instr_valid_f   = (response_count != 0);
    assign instr_f         = q0_instr;

    instr_mem u_instr_mem (
        .clk   (clk),
        .addr  (pc_f_reg),
        .rdata (rom_rdata)
    );

    wire [31:0] pc_next;
    assign pc_next = use_predict ? predicted_target :
                     (pcsrc_e ? pctarget_e : pc_plus_4_f);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_f_reg            <= 32'd0;
            request_pc_reg      <= 32'd0;
            request_valid_reg   <= 1'b0;
            q0_instr            <= 32'd0;
            q0_pc               <= 32'd0;
            q1_instr            <= 32'd0;
            q1_pc               <= 32'd0;
            response_count      <= 2'd0;
            kill_next_response  <= 1'b0;
        end else begin
            // Tag the address sampled by the BSRAM this cycle. Holding IF on
            // a stall is not a new logical request, so next-cycle duplicate
            // ROM data is marked invalid.
            request_pc_reg    <= pc_f_reg;
            request_valid_reg <= !stall_f;

            if (pcsrc_e) begin
                // Current q0 is flushed by the pipeline; the response for the
                // already-issued sequential request must be discarded next.
                response_count     <= 2'd0;
                kill_next_response <= 1'b1;
            end else if (kill_next_response) begin
                response_count     <= 2'd0;
                kill_next_response <= 1'b0;
            end else begin
                case ({consume_response, response_arrives})
                    2'b00: begin end
                    2'b01: begin
                        if (response_count == 0) begin
                            q0_instr <= rom_rdata;
                            q0_pc    <= request_pc_reg;
                            response_count <= 2'd1;
                        end else if (response_count == 1) begin
                            q1_instr <= rom_rdata;
                            q1_pc    <= request_pc_reg;
                            response_count <= 2'd2;
                        end
                        // A third outstanding response cannot occur with the
                        // one-cycle load-use stall contract; preserve q0/q1.
                    end
                    2'b10: begin
                        if (response_count == 1)
                            response_count <= 2'd0;
                        else begin
                            q0_instr <= q1_instr;
                            q0_pc    <= q1_pc;
                            response_count <= 2'd1;
                        end
                    end
                    2'b11: begin
                        // Pop q0 and enqueue the newly returned instruction.
                        if (response_count == 1) begin
                            q0_instr <= rom_rdata;
                            q0_pc    <= request_pc_reg;
                            response_count <= 2'd1;
                        end else begin
                            q0_instr <= q1_instr;
                            q0_pc    <= q1_pc;
                            q1_instr <= rom_rdata;
                            q1_pc    <= request_pc_reg;
                            response_count <= 2'd2;
                        end
                    end
                endcase
            end

            if (!stall_f)
                pc_f_reg <= pc_next;
        end
    end
endmodule
