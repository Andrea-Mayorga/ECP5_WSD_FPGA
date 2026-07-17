module top(
    input  wire CLK12,
    output wire LED0,
    output wire LED1,
    output wire LED2,
    output wire LED3,
    output wire LED4,
    output wire LED5,
    output wire LED6,
    output wire LED7,
    output wire LVDS_OUT_P,
    output wire LVDS_OUT_N
);

    // User LEDs are active-low, so drive high to keep them off.
    assign LED0 = 1'b1;
    assign LED1 = 1'b1;
    assign LED2 = 1'b1;
    assign LED3 = 1'b1;
    assign LED4 = 1'b1;
    assign LED5 = 1'b1;
    assign LED6 = 1'b1;
    assign LED7 = 1'b1;

    wire clk192;
    wire pll_lock;

    // 12 MHz input clock -> 192 MHz FPGA clock
    EHXPLLL #(
        .CLKI_DIV(1),
        .CLKFB_DIV(16),
        .CLKOP_DIV(1),
        .FEEDBK_PATH("CLKOP"),
        .CLKOP_ENABLE("ENABLED"),
        .CLKOP_CPHASE(0),
        .CLKOP_FPHASE(0)
    ) pll_inst (
        .CLKI(CLK12),
        .CLKFB(clk192),
        .CLKOP(clk192),
        .LOCK(pll_lock),
        .RST(1'b0)
    );

    // Number of 192 MHz clock cycles in exactly 1 second.
    localparam integer CYCLES_PER_SEC = 192_000_000;

    // 28-bit counter: needed because 192,000,000 requires 28 bits
    // (2^27 = 134,217,728 is not enough, 2^28 = 268,435,456 is enough).
    reg [27:0] slow_count = 28'd0;
    reg pulse = 1'b0;

    always @(posedge clk192) begin
        if (slow_count == CYCLES_PER_SEC - 1) begin
            slow_count <= 28'd0;
            pulse      <= 1'b1;   // one 192 MHz period wide, ~5.21 ns
        end else begin
            slow_count <= slow_count + 1'b1;
            pulse      <= 1'b0;
        end
    end

    // True differential LVDS output buffer
    OLVDS lvds_buf (
        .A(pulse),
        .Z(LVDS_OUT_P),
        .ZN(LVDS_OUT_N)
    );

endmodule
