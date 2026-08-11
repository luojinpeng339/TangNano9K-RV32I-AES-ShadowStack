// ================================================================
// Fichier          : branch_predictor_top.v
// Projet           : Prédicteur de branchements pour cœur RISC-V
// Description      : Module top-level intégrant le BHT (Table d'Historique)
//                    et le BTB (Tampon de Cible) pour la prédiction.
// Auteur           : jinpeng luo
// Date             : Juillet 2026
// Architecture générale :
//   - BHT  : 64 compteurs saturés 2 bits, indexés par PC[11:6].
//            États : 00 (Fort non-pris), 01 (Faiblement non-pris) [INIT],
//                    10 (Faiblement pris), 11 (Fort pris).
//            Prédiction : bit de poids fort (1 = Pris, 0 = Non-pris).
//   - BTB  : 32 entrées (mapping direct). Stocke les adresses cibles
//            pour les branchements déjà rencontrés.
//   - Top  : Connecte les deux modules. En cas de miss BTB, la
//            prédiction est forcée à "Non-pris" (sécurité).
// ================================================================

module BHT_2bit #(
    parameter ENTRIES = 64,// 64项
    parameter INDEX_HIGH = 11,
    parameter INDEX_LOW  = 6
)(
    input clk,
    input rst_n,
    // ---------- IF阶段：预测读端口 ----------
    input  wire [31:0] pc_i,  // 当前取指的PC
    output wire pred_taken_o, // 1=预测跳, 0=预测不跳
    // ---------- EX阶段：更新写端口 ----------
    input wire [31:0] update_pc_i,  // 执行阶段的分支PC
    input wire update_taken_i // 1=实际跳了, 0=实际没跳
);

    // ------------------------------------------（初始化为 Weakly Not Taken = 2'b01）------------------------------------------
    reg [1:0] bht_table [0:ENTRIES-1];

    integer i;

    // ------------------------------------------
    // 2. 索引计算（PC[11:6]）
    // ------------------------------------------

    wire [5:0] read_idx  = pc_i[INDEX_HIGH:INDEX_LOW];
    wire [5:0] write_idx = update_pc_i[INDEX_HIGH:INDEX_LOW];

    // ------------------------------------------
    // 3. 读操作（组合逻辑，无延迟输出预测结果）
    // ------------------------------------------

    wire [1:0] current_state = bht_table[read_idx];
    assign pred_taken_o = current_state[1];

    // ------------------------------------------
    // 4. 写操作（EX阶段反馈，时序更新）
    // ------------------------------------------

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位时，把 64 个表项全部初始化为 01（弱不跳）
            for (i = 0; i < ENTRIES; i = i + 1) begin
                bht_table[i] <= 2'b01;
            end
        end else begin
            case (bht_table[write_idx])
                // --- 强不跳 00 ---
                2'b00: bht_table[write_idx] <= update_taken_i ? 2'b01 : 2'b00;
                // --- 弱不跳 01 ---
                2'b01: bht_table[write_idx] <= update_taken_i ? 2'b10 : 2'b00;
                // --- 弱跳10 ---
                2'b10: bht_table[write_idx] <= update_taken_i ? 2'b11 : 2'b01;
                // --- 强跳11 ---
                2'b11: bht_table[write_idx] <= update_taken_i ? 2'b11 : 2'b10;
                default: bht_table[write_idx] <= 2'b01;
            endcase
        end
    end
endmodule

module BTB #( 
    parameter ENTRIES = 32,
    parameter INDEX_HIGH = 11, 
    parameter INDEX_LOW  = 7
    )(
    input clk, rst_n,
    // IF阶段
    input  wire [31:0] pc_i,
    output reg btb_hit_o,// 1=命中，0=未命中
    output reg  [31:0] btb_target_o,// 缓存的目标地址

    // EX阶段反馈
    input  wire [31:0] update_pc_i,
    input  wire        update_valid_i, // 只有真实跳转了才更新
    input  wire [31:0] update_target_i // 底部加法器算出的真实目标
);
    reg [31:0] btb [0:ENTRIES-1];
    reg        valid[0:ENTRIES-1];
    integer    j;
    wire [4:0] read_idx  = pc_i[11:7];
    wire [4:0] write_idx = update_pc_i[11:7];

    // 读
    always @(*) begin
        btb_hit_o = valid[read_idx];
        btb_target_o = btb[read_idx];
    end

    // 写
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (j = 0; j < ENTRIES; j = j + 1) begin
                valid[j] <= 1'b0;
            end
        end
        else if (update_valid_i) begin
            valid[write_idx] <= 1'b1;
            btb[write_idx]   <= update_target_i;
        end
    end
endmodule

module branch_predictor_top(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] pc_i,
    output wire        pred_taken_o,
    output wire        btb_hit_o,
    output wire [31:0] btb_target_o,
    input  wire [31:0] update_pc_i,
    input  wire        update_taken_i,
    input  wire [31:0] update_target_i
);
    // 在内部实例化 BHT
    BHT_2bit u_bht (
        .clk(clk), .rst_n(rst_n),
        .pc_i(pc_i),
        .pred_taken_o(pred_taken_o),
        .update_pc_i(update_pc_i),
        .update_taken_i(update_taken_i)
    );
    // 在内部实例化 BTB
    BTB u_btb (
        .clk(clk), .rst_n(rst_n),
        .pc_i(pc_i),
        .btb_hit_o(btb_hit_o),
        .btb_target_o(btb_target_o),
        .update_pc_i(update_pc_i),
        .update_valid_i(update_taken_i),
        .update_target_i(update_target_i)
    );
endmodule

