// tb_nes2lcd.sv - nes2lcd の動作確認用テストベンチ (Icarus Verilog)
//   iverilog -g2012 -o sim tb_nes2lcd.sv nes2lcd.sv && vvp sim
// 疑似 PPU (clk/4 で 1 ピクセル、341x262) が絵柄を出し、LCD モデルが WR 立ち上がりで
// バイトを取り込む。初期化コマンド列、全面クリアのバイト数、各フレームの全ピクセル値、
// WR のパルス幅とフレーム転送時間を検査する。
`timescale 1ns / 1ps
module tb;
localparam real TCLK = 1.0e9 / 21_491_200.0;   // 46.53 ns
logic clk = 0, resetn = 0;
always #(TCLK/2) clk = ~clk;

// ---- 疑似 PPU ----
logic [1:0] div = 0;
logic [8:0] cycle = 0, scanline = 0;
logic [7:0] frame = 0;
logic [5:0] color;
function automatic logic [5:0] pattern(input [7:0] f, input [8:0] x, input [8:0] y);
    pattern = 6'((x >> 3) + (y >> 3) + f);
endfunction
assign color = pattern(frame, cycle, scanline);
always_ff @(posedge clk) if (resetn) begin
    div <= div + 1;
    if (div == 3) begin
        if (cycle == 340) begin
            cycle <= 0;
            if (scanline == 260)      scanline <= 9'd511;   // pre-render
            else if (scanline == 511) begin scanline <= 0; frame <= frame + 1; end
            else                      scanline <= scanline + 1;
        end else cycle <= cycle + 1;
    end
end

// ---- DUT ----
logic lcd_rst_n, lcd_cs_n, lcd_rs, lcd_wr_n, lcd_rd_n, init_done, frame_start;
logic [7:0] lcd_d;
nes2lcd #(.MS_DIV(10)) dut (.*);

function automatic logic [15:0] pal565(input logic [5:0] idx);
    case (idx)
        6'd0 : pal565 = 16'h52AA;  // #545454
        6'd1 : pal565 = 16'h00EE;  // #001E74
        6'd2 : pal565 = 16'h0892;  // #081090
        6'd3 : pal565 = 16'h3011;  // #300088
        6'd4 : pal565 = 16'h400C;  // #440064
        6'd5 : pal565 = 16'h5806;  // #5C0030
        6'd6 : pal565 = 16'h5020;  // #540400
        6'd7 : pal565 = 16'h38C0;  // #3C1800
        6'd8 : pal565 = 16'h2140;  // #202A00
        6'd9 : pal565 = 16'h09C0;  // #083A00
        6'd10: pal565 = 16'h0200;  // #004000
        6'd11: pal565 = 16'h01E0;  // #003C00
        6'd12: pal565 = 16'h0187;  // #00323C
        6'd13: pal565 = 16'h0000;  // #000000
        6'd14: pal565 = 16'h0000;  // #000000
        6'd15: pal565 = 16'h0000;  // #000000
        6'd16: pal565 = 16'h9CB3;  // #989698
        6'd17: pal565 = 16'h0A78;  // #084CC4
        6'd18: pal565 = 16'h319D;  // #3032EC
        6'd19: pal565 = 16'h58FC;  // #5C1EE4
        6'd20: pal565 = 16'h88B6;  // #8814B0
        6'd21: pal565 = 16'hA0AC;  // #A01464
        6'd22: pal565 = 16'h9904;  // #982220
        6'd23: pal565 = 16'h79E0;  // #783C00
        6'd24: pal565 = 16'h52C0;  // #545A00
        6'd25: pal565 = 16'h2B80;  // #287200
        6'd26: pal565 = 16'h0BE0;  // #087C00
        6'd27: pal565 = 16'h03A5;  // #007628
        6'd28: pal565 = 16'h032F;  // #006678
        6'd29: pal565 = 16'h0000;  // #000000
        6'd30: pal565 = 16'h0000;  // #000000
        6'd31: pal565 = 16'h0000;  // #000000
        6'd32: pal565 = 16'hEF7D;  // #ECEEEC
        6'd33: pal565 = 16'h4CDD;  // #4C9AEC
        6'd34: pal565 = 16'h7BFD;  // #787CEC
        6'd35: pal565 = 16'hB31D;  // #B062EC
        6'd36: pal565 = 16'hE2BD;  // #E454EC
        6'd37: pal565 = 16'hEAD6;  // #EC58B4
        6'd38: pal565 = 16'hEB4C;  // #EC6A64
        6'd39: pal565 = 16'hD444;  // #D48820
        6'd40: pal565 = 16'hA540;  // #A0AA00
        6'd41: pal565 = 16'h7620;  // #74C400
        6'd42: pal565 = 16'h4E84;  // #4CD020
        6'd43: pal565 = 16'h3E6D;  // #38CC6C
        6'd44: pal565 = 16'h3DB9;  // #38B4CC
        6'd45: pal565 = 16'h39E7;  // #3C3C3C
        6'd46: pal565 = 16'h0000;  // #000000
        6'd47: pal565 = 16'h0000;  // #000000
        6'd48: pal565 = 16'hEF7D;  // #ECEEEC
        6'd49: pal565 = 16'hAE7D;  // #A8CCEC
        6'd50: pal565 = 16'hBDFD;  // #BCBCEC
        6'd51: pal565 = 16'hD59D;  // #D4B2EC
        6'd52: pal565 = 16'hED7D;  // #ECAEEC
        6'd53: pal565 = 16'hED7A;  // #ECAED4
        6'd54: pal565 = 16'hEDB6;  // #ECB4B0
        6'd55: pal565 = 16'hE632;  // #E4C490
        6'd56: pal565 = 16'hCE8F;  // #CCD278
        6'd57: pal565 = 16'hB6EF;  // #B4DE78
        6'd58: pal565 = 16'hAF12;  // #A8E290
        6'd59: pal565 = 16'h9F16;  // #98E2B4
        6'd60: pal565 = 16'hA6BC;  // #A0D6E4
        6'd61: pal565 = 16'hA514;  // #A0A2A0
        6'd62: pal565 = 16'h0000;  // #000000
        6'd63: pal565 = 16'h0000;  // #000000
        default: pal565 = 16'h0000;
    endcase
endfunction

// ---- LCD モデル ----
byte    cmds[$];
int     n_data_after_cmd = 0;
logic [7:0] last_cmd = 0;
int     errors = 0, frames_ok = 0, clear_bytes = 0;
logic [15:0] px; logic hi_phase = 0; int pidx = 0;
logic [7:0] frame_at_read;
realtime t_fall, t_rise, t_prev_fall = 0, t_ramwr = 0;
real min_low = 1e9, min_high = 1e9, min_period = 1e9, max_frame_ms = 0;

always @(negedge lcd_wr_n) begin
    t_fall = $realtime;
    if (t_prev_fall > 0 && t_fall - t_prev_fall < min_period) min_period = t_fall - t_prev_fall;
    if (t_prev_fall > 0 && t_fall - t_rise < min_high) min_high = t_fall - t_rise;
    t_prev_fall = t_fall;
end

always @(posedge lcd_wr_n) if (lcd_rst_n === 1'b1) begin   // リセット中の X->1 は無視
    t_rise = $realtime;
    if (t_rise - t_fall < min_low) min_low = t_rise - t_fall;
    if (lcd_cs_n !== 1'b0) begin $display("ERR: WR while CS high"); errors++; end
    if (lcd_rs == 0) begin
        if (last_cmd == 8'h2C && init_done && pidx != 0 && pidx != 61440) begin
            $display("ERR: RAMWR interrupted at pixel %0d", pidx); errors++;
        end
        last_cmd = lcd_d; cmds.push_back(lcd_d);
        n_data_after_cmd = 0; hi_phase = 0; pidx = 0;
        if (lcd_d == 8'h2C) begin t_ramwr = $realtime; frame_at_read = frame; end
    end else begin
        n_data_after_cmd++;
        if (last_cmd == 8'h2C && !init_done) clear_bytes++;
        else if (last_cmd == 8'h2C) begin
            if (!hi_phase) begin px[15:8] = lcd_d; hi_phase = 1; end
            else begin
                px[7:0] = lcd_d; hi_phase = 0;
                // 読み出し開始は VBlank。直前に描き終えたフレームの絵柄と一致するはず
                // 電源投入直後のフレーム 0 は PPU がまだ全画素を書いていないので検査しない
                if (frame_at_read >= 1 && px !== pal565(pattern(frame_at_read, pidx % 256, pidx / 256))) begin
                    if (errors < 10) $display("ERR: pixel %0d got %h exp %h", pidx, px,
                        pal565(pattern(frame_at_read, pidx % 256, pidx / 256)));
                    errors++;
                end
                pidx++;
                if (pidx == 61440) begin
                    frames_ok++;
                    if (($realtime - t_ramwr)/1e6 > max_frame_ms) max_frame_ms = ($realtime - t_ramwr)/1e6;
                end
            end
        end
    end
end

initial begin
    #(TCLK*20) resetn = 1;
    wait (frames_ok == 4);
    #1000;
    $write("commands (init)  :");
    for (int i = 0; i < 13; i++) $write(" %02h", cmds[i]);
    $display("");
    $display("clear bytes      : %0d (expect 153600)", clear_bytes);
    $display("frames checked   : %0d", frames_ok);
    $display("WR low  min      : %.1f ns (ILI9341 tWRL >= 15)", min_low);
    $display("WR high min      : %.1f ns (ILI9341 tWRH >= 15)", min_high);
    $display("WR period min    : %.1f ns (ILI9341 tWC  >= 66)", min_period);
    $display("frame transfer   : %.2f ms (< 16.64)", max_frame_ms);
    $display("errors           : %0d", errors);
    $finish;
end
initial begin #(80_000_000); $display("TIMEOUT frames_ok=%0d", frames_ok); $finish; end
endmodule
