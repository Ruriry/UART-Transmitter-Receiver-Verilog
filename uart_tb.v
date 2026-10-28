`timescale 1ns/1ps

module uart_tb;

    // Clock and control signals
    reg clk = 0;
    reg reset = 0;
    reg tx_start = 0;
    reg [7:0] tx_data = 0;

    // UART connection signals
    wire tx_serial;
    wire tx_done;

    wire [7:0] rx_data;
    wire rx_done;

    // Test counters
    integer pass_count = 0;
    integer fail_count = 0;

    // Generate 1 MHz clock
    always #500 clk = ~clk;

    // UART Transmitter
    uart_tx #(
        .CLKS_PER_BIT(104)
    ) transmitter (
        .clk(clk),
        .reset(reset),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_serial(tx_serial),
        .tx_done(tx_done)
    );

    // UART Receiver
    uart_rx #(
        .CLKS_PER_BIT(104)
    ) receiver (
        .clk(clk),
        .reset(reset),
        .rx_serial(tx_serial),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    // Task to transmit and verify one byte
    task test_uart;
        input [7:0] test_data;

        begin
            // Start transmission on a falling clock edge
            @(negedge clk);
            tx_data = test_data;
            tx_start = 1'b1;

            @(negedge clk);
            tx_start = 1'b0;

            // Wait for reception, with timeout protection
            fork
                begin
                    @(posedge rx_done);

                    if (rx_data === test_data) begin
                        $display(
                            "PASS: Sent = %0d, Received = %0d",
                            test_data, rx_data
                        );

                        pass_count = pass_count + 1;
                    end
                    else begin
                        $display(
                            "FAIL: Sent = %0d, Received = %0d",
                            test_data, rx_data
                        );

                        fail_count = fail_count + 1;
                    end
                end

                begin
                    // Maximum wait: 12 UART bit periods
                    repeat (12 * 104) @(posedge clk);

                    $display(
                        "FAIL: Timeout receiving %0d",
                        test_data
                    );

                    fail_count = fail_count + 1;
                end
            join_any

            disable fork;

            // Wait until transmitter has completed
            wait (tx_done == 1'b1);

            // Allow transmitter to return to IDLE
            repeat (5) @(posedge clk);
        end
    endtask

            // Generate waveform file for visualization
initial begin
    $dumpfile("uart_waveform.vcd");
    $dumpvars(0, uart_tb);
end
              
    initial begin

        $display("====================================");
        $display("UART TRANSMITTER + RECEIVER TEST");
        $display("====================================");

        // Initialize system
        reset = 1'b1;
        #2000;
        reset = 1'b0;

        // Run ten UART loopback tests
test_uart(8'd65);
test_uart(8'd170);
test_uart(8'd255);
test_uart(8'd0);
test_uart(8'd85);

// Additional verification patterns
test_uart(8'd1);
test_uart(8'd128);
test_uart(8'd127);
test_uart(8'd15);
test_uart(8'd240);

        // Print summary
        $display("====================================");
        $display("TOTAL PASSED: %0d", pass_count);
        $display("TOTAL FAILED: %0d", fail_count);

        if (fail_count == 0 && pass_count == 10)
            $display("OVERALL RESULT: PASS");
        else
            $display("OVERALL RESULT: FAIL");

        $display("====================================");

        $finish;
    end

endmodule