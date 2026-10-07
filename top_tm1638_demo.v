module top(
    input clk,

    output reg tm_cs,
    output tm_clk,
    inout tm_dio
);

   
    localparam HIGH = 1'b1;
    localparam LOW  = 1'b0;


   
    localparam [6:0]
        S_0   = 7'b0111111,
        S_1   = 7'b0000110,
        S_2   = 7'b1011011,
        S_3   = 7'b1001111,
        S_4   = 7'b1100110,
        S_5   = 7'b1101101,
        S_6   = 7'b1111101,
        S_7   = 7'b0000111,
        S_8   = 7'b1111111,
        S_9   = 7'b1101111,
        S_A   = 7'b1110111,
        S_b   = 7'b1111100,
        S_C   = 7'b0111001,
        S_d   = 7'b1011110,
        S_E   = 7'b1111001,
        S_F   = 7'b1110001,
        S_BLK = 7'b0000000;


   
    localparam [7:0]
        C_READ  = 8'b01000010,   
        C_WRITE = 8'b01000000,  
        C_DISP  = 8'b10001111,   
        C_ADDR  = 8'b11000000;   


   
    reg rst = HIGH;
    reg [5:0] instruction_step = 6'd1;
    reg [19:0] counter = 20'd0;


    
    reg [7:0] keys_raw = 8'b0;
    reg [7:0] switch_value = 8'b0;


    
    reg tm_rw;
    wire dio_in;
    wire dio_out;

    SB_IO #(
        .PIN_TYPE(6'b101001),
        .PULLUP(1'b1)
    ) tm_dio_io (
        .PACKAGE_PIN(tm_dio),
        .OUTPUT_ENABLE(tm_rw),
        .D_IN_0(dio_in),
        .D_OUT_0(dio_out)
    );


    
    reg tm_latch;
    wire busy;

    wire [7:0] tm_data;
    wire [7:0] tm_in;
    reg  [7:0] tm_out;

    assign tm_in = tm_data;
    assign tm_data = tm_rw ? tm_out : 8'hZZ;


   
    tm1638 u_tm1638 (
        .clk(clk),
        .rst(rst),
        .data_latch(tm_latch),
        .data(tm_data),
        .rw(tm_rw),
        .busy(busy),
        .sclk(tm_clk),
        .dio_in(dio_in),
        .dio_out(dio_out)
    );


    function [6:0] hex_to_seg;
        input [3:0] value;
        begin
            case (value)
                4'h0: hex_to_seg = S_0;
                4'h1: hex_to_seg = S_1;
                4'h2: hex_to_seg = S_2;
                4'h3: hex_to_seg = S_3;
                4'h4: hex_to_seg = S_4;
                4'h5: hex_to_seg = S_5;
                4'h6: hex_to_seg = S_6;
                4'h7: hex_to_seg = S_7;
                4'h8: hex_to_seg = S_8;
                4'h9: hex_to_seg = S_9;
                4'hA: hex_to_seg = S_A;
                4'hB: hex_to_seg = S_b;
                4'hC: hex_to_seg = S_C;
                4'hD: hex_to_seg = S_d;
                4'hE: hex_to_seg = S_E;
                4'hF: hex_to_seg = S_F;
                default: hex_to_seg = S_BLK;
            endcase
        end
    endfunction


    
    function [6:0] dec_to_seg;
        input [3:0] value;
        begin
            case (value)
                4'd0: dec_to_seg = S_0;
                4'd1: dec_to_seg = S_1;
                4'd2: dec_to_seg = S_2;
                4'd3: dec_to_seg = S_3;
                4'd4: dec_to_seg = S_4;
                4'd5: dec_to_seg = S_5;
                4'd6: dec_to_seg = S_6;
                4'd7: dec_to_seg = S_7;
                4'd8: dec_to_seg = S_8;
                4'd9: dec_to_seg = S_9;
                default: dec_to_seg = S_BLK;
            endcase
        end
    endfunction


    reg [3:0] dec_hundreds;
    reg [3:0] dec_tens;
    reg [3:0] dec_ones;
    reg [7:0] dec_remainder;

    always @(*) begin

        
        if (switch_value >= 8'd200) begin
            dec_hundreds = 4'd2;
            dec_remainder = switch_value - 8'd200;
        end
        else if (switch_value >= 8'd100) begin
            dec_hundreds = 4'd1;
            dec_remainder = switch_value - 8'd100;
        end
        else begin
            dec_hundreds = 4'd0;
            dec_remainder = switch_value;
        end

        
        if (dec_remainder >= 8'd90) begin
            dec_tens = 4'd9;
            dec_ones = dec_remainder - 8'd90;
        end
        else if (dec_remainder >= 8'd80) begin
            dec_tens = 4'd8;
            dec_ones = dec_remainder - 8'd80;
        end
        else if (dec_remainder >= 8'd70) begin
            dec_tens = 4'd7;
            dec_ones = dec_remainder - 8'd70;
        end
        else if (dec_remainder >= 8'd60) begin
            dec_tens = 4'd6;
            dec_ones = dec_remainder - 8'd60;
        end
        else if (dec_remainder >= 8'd50) begin
            dec_tens = 4'd5;
            dec_ones = dec_remainder - 8'd50;
        end
        else if (dec_remainder >= 8'd40) begin
            dec_tens = 4'd4;
            dec_ones = dec_remainder - 8'd40;
        end
        else if (dec_remainder >= 8'd30) begin
            dec_tens = 4'd3;
            dec_ones = dec_remainder - 8'd30;
        end
        else if (dec_remainder >= 8'd20) begin
            dec_tens = 4'd2;
            dec_ones = dec_remainder - 8'd20;
        end
        else if (dec_remainder >= 8'd10) begin
            dec_tens = 4'd1;
            dec_ones = dec_remainder - 8'd10;
        end
        else begin
            dec_tens = 4'd0;
            dec_ones = dec_remainder[3:0];
        end
    end


    
    task display_digit;
        input [6:0] segs;
        begin
            tm_latch <= HIGH;
            tm_out <= {1'b0, segs};
        end
    endtask


    
    task led_off;
        begin
            tm_latch <= HIGH;
            tm_out <= 8'b00000000;
        end
    endtask


    
    always @(posedge clk) begin

        if (rst) begin
            instruction_step <= 6'd1;
            counter <= 20'd0;

            tm_cs <= HIGH;
            tm_rw <= HIGH;
            tm_latch <= LOW;
            tm_out <= 8'b0;

            keys_raw <= 8'b0;
            switch_value <= 8'b0;

            rst <= LOW;
        end

        else begin

            if (counter[0] && ~busy) begin

                case (instruction_step)

                    
                    6'd1: begin
                        tm_cs <= LOW;
                        tm_rw <= HIGH;
                    end

                   
                    6'd2: begin
                        tm_latch <= HIGH;
                        tm_out <= C_READ;
                    end

                    
                    6'd3: begin
                        tm_latch <= HIGH;
                        tm_rw <= LOW;
                    end

                    
                    6'd4: begin
                        keys_raw[7] <= tm_in[0];
                        keys_raw[3] <= tm_in[4];
                    end

                    6'd5: begin
                        tm_latch <= HIGH;
                    end

                    6'd6: begin
                        keys_raw[6] <= tm_in[0];
                        keys_raw[2] <= tm_in[4];
                    end

                    
                    6'd7: begin
                        tm_latch <= HIGH;
                    end

                    
                    6'd8: begin
                        keys_raw[5] <= tm_in[0];
                        keys_raw[1] <= tm_in[4];
                    end

                    
                    6'd9: begin
                        tm_latch <= HIGH;
                    end

                   
                    6'd10: begin
                        keys_raw[4] <= tm_in[0];
                        keys_raw[0] <= tm_in[4];
                    end

                    
                    6'd11: begin
                        tm_cs <= HIGH;
                        switch_value <= keys_raw;
                    end


                    
                    6'd12: begin
                        tm_cs <= LOW;
                        tm_rw <= HIGH;
                    end

                    
                    6'd13: begin
                        tm_latch <= HIGH;
                        tm_out <= C_WRITE;
                    end

                    
                    6'd14: begin
                        tm_cs <= HIGH;
                    end

                  
                    6'd15: begin
                        tm_cs <= LOW;
                        tm_rw <= HIGH;
                    end

                    
                    6'd16: begin
                        tm_latch <= HIGH;
                        tm_out <= C_ADDR;
                    end


                  
                    6'd17: display_digit(S_BLK);
                    6'd18: led_off();

                    
                    6'd19: display_digit(S_BLK);
                    6'd20: led_off();

                   
                    6'd21: display_digit(hex_to_seg(switch_value[7:4]));
                    6'd22: led_off();

                    
                    6'd23: display_digit(hex_to_seg(switch_value[3:0]));
                    6'd24: led_off();

                   
                    6'd25: display_digit(S_BLK);
                    6'd26: led_off();

                   
                    6'd27: begin
                        if (dec_hundreds == 0)
                            display_digit(S_BLK);
                        else
                            display_digit(dec_to_seg(dec_hundreds));
                    end
                    6'd28: led_off();

                  
                    6'd29: begin
                        if ((dec_hundreds == 0) && (dec_tens == 0))
                            display_digit(S_BLK);
                        else
                            display_digit(dec_to_seg(dec_tens));
                    end
                    6'd30: led_off();

                    
                    6'd31: display_digit(dec_to_seg(dec_ones));
                    6'd32: led_off();


                   
                    6'd33: begin
                        tm_cs <= HIGH;
                    end

                   
                    6'd34: begin
                        tm_cs <= LOW;
                        tm_rw <= HIGH;
                    end

                 
                    6'd35: begin
                        tm_latch <= HIGH;
                        tm_out <= C_DISP;
                    end

                    
                    6'd36: begin
                        tm_cs <= HIGH;
                    end

                    default: begin
                        tm_cs <= HIGH;
                        tm_rw <= HIGH;
                    end

                endcase


                
                if (instruction_step == 6'd36)
                    instruction_step <= 6'd1;
                else
                    instruction_step <= instruction_step + 1'b1;
            end

            else if (busy) begin
                
                tm_latch <= LOW;
            end

            counter <= counter + 1'b1;
        end
    end

endmodule
