// 800x480 RGB-panel scanout.  The timing geometry and pin-output discipline
// mirror the proven Runtime Emerald GPU path: launch RGB, DE, HSYNC and VSYNC
// together on clk's rising edge so the entire bundle is stable through the
// panel's following sampling edge.
module rgb_scanout (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] pixel_in,
    output wire [8:0]  internal_x,
    output wire [7:0]  internal_y,
    output wire        rgb_pclk,
    output wire        rgb_hsync,
    output wire        rgb_vsync,
    output wire        rgb_de,
    output wire [4:0]  rgb_r,
    output wire [5:0]  rgb_g,
    output wire [4:0]  rgb_b
);
    localparam [9:0] H_ACTIVE = 10'd800;
    localparam [9:0] H_FRONT  = 10'd20;
    localparam [9:0] H_SYNC   = 10'd40;
    localparam [9:0] H_TOTAL  = 10'd900;
    localparam [9:0] V_ACTIVE = 10'd480;
    localparam [9:0] V_FRONT  = 10'd8;
    localparam [9:0] V_SYNC   = 10'd4;
    localparam [9:0] V_TOTAL  = 10'd500;

    reg [9:0] h_count;
    reg [9:0] v_count;
    reg       de_q, hsync_q, vsync_q;
    reg [4:0] r_q, b_q;
    reg [5:0] g_q;

    wire active = (h_count < H_ACTIVE) && (v_count < V_ACTIVE);
    wire hsync_now = ((h_count >= H_ACTIVE + H_FRONT) &&
                      (h_count < H_ACTIVE + H_FRONT + H_SYNC)) ? 1'b0 : 1'b1;
    wire vsync_now = ((v_count >= V_ACTIVE + V_FRONT) &&
                      (v_count < V_ACTIVE + V_FRONT + V_SYNC)) ? 1'b0 : 1'b1;

    // Renderer sees the current physical sample address.  It has a whole
    // clock period to form pixel_in before the next rising-edge pin launch.
    assign internal_x = h_count[9:1];
    assign internal_y = v_count[8:1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
            de_q <= 1'b0;
            hsync_q <= 1'b1;
            vsync_q <= 1'b1;
            r_q <= 5'd0;
            g_q <= 6'd0;
            b_q <= 5'd0;
        end else begin
            // One coherent registered pin bundle: no combinational renderer
            // transition can race the LCD sampling edge.
            de_q    <= active;
            hsync_q <= hsync_now;
            vsync_q <= vsync_now;
            r_q     <= active ? pixel_in[15:11] : 5'd0;
            g_q     <= active ? pixel_in[10:5]  : 6'd0;
            b_q     <= active ? pixel_in[4:0]   : 5'd0;

            if (h_count == H_TOTAL - 10'd1) begin
                h_count <= 10'd0;
                if (v_count == V_TOTAL - 10'd1)
                    v_count <= 10'd0;
                else
                    v_count <= v_count + 10'd1;
            end else begin
                h_count <= h_count + 10'd1;
            end
        end
    end

    assign rgb_pclk  = clk;
    assign rgb_de    = de_q;
    assign rgb_hsync = hsync_q;
    assign rgb_vsync = vsync_q;
    assign rgb_r     = r_q;
    assign rgb_g     = g_q;
    assign rgb_b     = b_q;
endmodule
