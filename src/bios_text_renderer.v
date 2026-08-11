// OS-0D security dashboard for the proven 400x240 internal scanout.
// Each 8x16 text cell is doubled by rgb_scanout to the physical 800x480 panel.
module bios_text_renderer (
    input  wire [8:0]  x,
    input  wire [7:0]  y,
    input  wire        security_halted,
    input  wire [31:0] mcycle,
    input  wire [31:0] minstret,
    input  wire [31:0] aes_retired_count,
    input  wire [31:0] shadow_ops,
    input  wire [31:0] cfi_checks,
    input  wire [31:0] cfi_violations,
    input  wire [5:0]  shadow_depth,
    output reg  [15:0] pixel_out
);
    localparam [15:0] BLACK=16'h0000, CYAN=16'h07FF, GREEN=16'h07E0, RED=16'hF800, AMBER=16'hFD20, WHITE=16'hFFFF;
    wire [5:0] col=x[8:3]; wire [3:0] row=y[7:4];
    wire [2:0] gx=x[2:0]; wire [2:0] gy=y[3:1];
    reg [7:0] ch; reg [15:0] ink; reg [7:0] glyph_bits;
    function [7:0] hexch; input [3:0] n; begin hexch=(n<10)?(8'h30+n):(8'h41+n-10); end endfunction
    function [7:0] glyph; input [7:0] c; input [2:0] r; begin
      glyph=0;
      case(c)
       "A":case(r)0:glyph=8'h18;1:glyph=8'h24;2:glyph=8'h42;3:glyph=8'h7E;4:glyph=8'h42;endcase
       "B":case(r)0:glyph=8'h7C;1:glyph=8'h42;2:glyph=8'h7C;3:glyph=8'h42;4:glyph=8'h7C;endcase
       "C":case(r)0:glyph=8'h3C;1:glyph=8'h42;2:glyph=8'h40;3:glyph=8'h42;4:glyph=8'h3C;endcase
       "D":case(r)0:glyph=8'h78;1:glyph=8'h44;2:glyph=8'h42;3:glyph=8'h44;4:glyph=8'h78;endcase
       "E":case(r)0:glyph=8'h7E;1:glyph=8'h40;2:glyph=8'h7C;3:glyph=8'h40;4:glyph=8'h7E;endcase
       "F":case(r)0:glyph=8'h7E;1:glyph=8'h40;2:glyph=8'h7C;3:glyph=8'h40;4:glyph=8'h40;endcase
       "H":case(r)0:glyph=8'h42;1:glyph=8'h42;2:glyph=8'h7E;3:glyph=8'h42;4:glyph=8'h42;endcase
       "I":case(r)0:glyph=8'h3C;1:glyph=8'h18;2:glyph=8'h18;3:glyph=8'h18;4:glyph=8'h3C;endcase
       "K":case(r)0:glyph=8'h42;1:glyph=8'h44;2:glyph=8'h78;3:glyph=8'h44;4:glyph=8'h42;endcase
       "L":case(r)0:glyph=8'h40;1:glyph=8'h40;2:glyph=8'h40;3:glyph=8'h40;4:glyph=8'h7E;endcase
       "M":case(r)0:glyph=8'h42;1:glyph=8'h66;2:glyph=8'h5A;3:glyph=8'h42;4:glyph=8'h42;endcase
       "O":case(r)0:glyph=8'h3C;1:glyph=8'h42;2:glyph=8'h42;3:glyph=8'h42;4:glyph=8'h3C;endcase
       "P":case(r)0:glyph=8'h7C;1:glyph=8'h42;2:glyph=8'h7C;3:glyph=8'h40;4:glyph=8'h40;endcase
       "R":case(r)0:glyph=8'h7C;1:glyph=8'h42;2:glyph=8'h7C;3:glyph=8'h44;4:glyph=8'h42;endcase
       "S":case(r)0:glyph=8'h3E;1:glyph=8'h40;2:glyph=8'h3C;3:glyph=8'h02;4:glyph=8'h7C;endcase
       "T":case(r)0:glyph=8'h7E;1:glyph=8'h18;2:glyph=8'h18;3:glyph=8'h18;4:glyph=8'h18;endcase
       "U":case(r)0:glyph=8'h42;1:glyph=8'h42;2:glyph=8'h42;3:glyph=8'h42;4:glyph=8'h3C;endcase
       "V":case(r)0:glyph=8'h42;1:glyph=8'h42;2:glyph=8'h42;3:glyph=8'h24;4:glyph=8'h18;endcase
       "Y":case(r)0:glyph=8'h42;1:glyph=8'h24;2:glyph=8'h18;3:glyph=8'h18;4:glyph=8'h18;endcase
       "0":case(r)0:glyph=8'h3C;1:glyph=8'h46;2:glyph=8'h4A;3:glyph=8'h62;4:glyph=8'h3C;endcase
       "1":case(r)0:glyph=8'h18;1:glyph=8'h38;2:glyph=8'h18;3:glyph=8'h18;4:glyph=8'h3C;endcase
       "2":case(r)0:glyph=8'h3C;1:glyph=8'h42;2:glyph=8'h0C;3:glyph=8'h30;4:glyph=8'h7E;endcase
       "3":case(r)0:glyph=8'h3C;1:glyph=8'h42;2:glyph=8'h1C;3:glyph=8'h42;4:glyph=8'h3C;endcase
       "4":case(r)0:glyph=8'h0C;1:glyph=8'h14;2:glyph=8'h24;3:glyph=8'h7E;4:glyph=8'h04;endcase
       "5":case(r)0:glyph=8'h7E;1:glyph=8'h40;2:glyph=8'h7C;3:glyph=8'h02;4:glyph=8'h7C;endcase
       "6":case(r)0:glyph=8'h3C;1:glyph=8'h40;2:glyph=8'h7C;3:glyph=8'h42;4:glyph=8'h3C;endcase
       "7":case(r)0:glyph=8'h7E;1:glyph=8'h06;2:glyph=8'h0C;3:glyph=8'h18;4:glyph=8'h18;endcase
       "8":case(r)0:glyph=8'h3C;1:glyph=8'h42;2:glyph=8'h3C;3:glyph=8'h42;4:glyph=8'h3C;endcase
       "9":case(r)0:glyph=8'h3C;1:glyph=8'h42;2:glyph=8'h3E;3:glyph=8'h02;4:glyph=8'h3C;endcase
       "-":if(r==2)glyph=8'h3C;
       ":":case(r)1:glyph=8'h18;3:glyph=8'h18;endcase
       "=":case(r)1:glyph=8'h3C;3:glyph=8'h3C;endcase
      endcase
    end endfunction
    always @(*) begin
      ch=" "; ink=GREEN;
      if(row==1) begin ink=CYAN; case(col) 2:ch="S";3:ch="E";4:ch="C";5:ch="U";6:ch="R";7:ch="I";8:ch="T";9:ch="Y";11:ch="O";12:ch="S";13:ch="-";14:ch="0";16:ch="L";17:ch="I";18:ch="V";19:ch="E"; endcase end
      else if(row==3) begin ink=security_halted?RED:GREEN; case(col) 2:ch="H";3:ch="A";4:ch="L";5:ch="T";6:ch="=";7:ch=security_halted?"1":"0"; endcase end
      else if(row>=5 && row<=11) begin
        case(row)
          5: begin if(col==2)ch="M";else if(col==3)ch="C";else if(col==4)ch="=";else if(col>=6&&col<=13)ch=hexch(mcycle[(13-col)*4 +:4]); end
          6: begin if(col==2)ch="M";else if(col==3)ch="I";else if(col==4)ch="=";else if(col>=6&&col<=13)ch=hexch(minstret[(13-col)*4 +:4]); end
          7: begin if(col==2)ch="A";else if(col==3)ch="R";else if(col==4)ch="=";else if(col>=6&&col<=13)ch=hexch(aes_retired_count[(13-col)*4 +:4]); end
          8: begin if(col==2)ch="S";else if(col==3)ch="O";else if(col==4)ch="=";else if(col>=6&&col<=13)ch=hexch(shadow_ops[(13-col)*4 +:4]); end
          9: begin if(col==2)ch="C";else if(col==3)ch="C";else if(col==4)ch="=";else if(col>=6&&col<=13)ch=hexch(cfi_checks[(13-col)*4 +:4]); end
          10:begin if(col==2)ch="C";else if(col==3)ch="V";else if(col==4)ch="=";else if(col>=6&&col<=13)ch=hexch(cfi_violations[(13-col)*4 +:4]); end
          11:begin if(col==2)ch="S";else if(col==3)ch="D";else if(col==4)ch="=";else if(col==6)ch="0";else if(col==7)ch="0";else if(col==8)ch=hexch(shadow_depth[5:4]);else if(col==9)ch=hexch(shadow_depth[3:0]); end
        endcase
      end
      if(row==13 && col>=2 && col<=19) begin ink=AMBER; case(col) 2:ch="U";3:ch="A";4:ch="R";5:ch="T";7:ch="C";8:ch="O";9:ch="M";10:ch="M";11:ch="A";12:ch="N";13:ch="D";15:ch="R";16:ch="E";17:ch="A";18:ch="D";19:ch="Y";endcase end
      glyph_bits=glyph(ch,gy);
      pixel_out=glyph_bits[7-gx] ? ink : BLACK;
    end
endmodule
