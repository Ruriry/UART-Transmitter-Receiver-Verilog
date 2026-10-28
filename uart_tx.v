`timescale 1ns/1ps

module uart_tx #(
    parameter CLKS_PER_BIT = 104
)(
    input wire clk,
    input wire reset,
    input wire tx_start,
    input wire [7:0] tx_data,
    output reg tx_serial,
    output reg tx_done
);

    // FSM states
    parameter IDLE  = 2'b00;
    parameter START = 2'b01;
    parameter DATA  = 2'b10;
    parameter STOP  = 2'b11;

    reg [1:0] state = IDLE;

    reg [15:0] clk_count = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] data_buffer = 0;

    always @(posedge clk or posedge reset) begin

        if (reset) begin
            state <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            tx_serial <= 1'b1;
            tx_done <= 1'b0;
            data_buffer <= 0;
        end

        else begin

            case (state)

                IDLE: begin
                    tx_serial <= 1'b1;
                    tx_done <= 1'b0;
                    clk_count <= 0;
                    bit_index <= 0;

                    if (tx_start) begin
                        data_buffer <= tx_data;
                        state <= START;
                    end
                end

                START: begin
                    tx_serial <= 1'b0;

                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end
                    else begin
                        clk_count <= 0;
                        state <= DATA;
                    end
                end

                DATA: begin
                    tx_serial <= data_buffer[bit_index];

                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end
                    else begin
                        clk_count <= 0;

                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end
                        else begin
                            bit_index <= 0;
                            state <= STOP;
                        end
                    end
                end

                STOP: begin
                    tx_serial <= 1'b1;

                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end
                    else begin
                        clk_count <= 0;
                        tx_done <= 1'b1;
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule