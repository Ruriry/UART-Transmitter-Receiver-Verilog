module uart_rx #(
    parameter CLKS_PER_BIT = 104
)(
    input wire clk,
    input wire reset,
    input wire rx_serial,
    output reg [7:0] rx_data,
    output reg rx_done
);

    // Receiver FSM states
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state;
    reg [15:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] data_buffer;

    always @(posedge clk or posedge reset) begin

        if (reset) begin
            state <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            data_buffer <= 0;
            rx_data <= 0;
            rx_done <= 0;
        end

        else begin
            // Default: completion signal lasts one clock cycle
            rx_done <= 0;

            case (state)

                IDLE: begin
                    clk_count <= 0;
                    bit_index <= 0;

                    // Detect falling start bit
                    if (rx_serial == 1'b0)
                        state <= START;
                end

                START: begin
                    // Sample near the middle of the start bit
                    if (clk_count == (CLKS_PER_BIT/2)-1) begin
                        clk_count <= 0;

                        if (rx_serial == 1'b0)
                            state <= DATA;
                        else
                            state <= IDLE;
                    end
                    else
                        clk_count <= clk_count + 1;
                end

                DATA: begin
                    if (clk_count == CLKS_PER_BIT-1) begin
                        clk_count <= 0;

                        // Sample incoming bit
                        data_buffer[bit_index] <= rx_serial;

                        if (bit_index == 7) begin
                            bit_index <= 0;
                            state <= STOP;
                        end
                        else
                            bit_index <= bit_index + 1;
                    end
                    else
                        clk_count <= clk_count + 1;
                end

                STOP: begin
                    if (clk_count == CLKS_PER_BIT-1) begin
                        clk_count <= 0;

                        // Validate stop bit
                        if (rx_serial == 1'b1) begin
                            rx_data <= data_buffer;
                            rx_done <= 1'b1;
                        end

                        state <= IDLE;
                    end
                    else
                        clk_count <= clk_count + 1;
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule