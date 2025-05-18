`include "config.svh"
`include "game_config.svh"

module lab_top
# (
    parameter  clk_mhz       = 50,
               pixel_mhz     = 25,


               w_key         = 4,
               w_sw          = 4,
               w_led         = 8,
               w_digit       = 8,
               w_gpio        = 100,

               screen_width  = 640,
               screen_height = 480,

               w_red         = 4,
               w_green       = 4,
               w_blue        = 4,

               w_x           = $clog2 ( screen_width  ),
               w_y           = $clog2 ( screen_height ),

               strobe_to_update_xy_counter_width
                   = $clog2 (clk_mhz * 1000 * 1000) - 6
)
(
    input                        clk,
    input                        slow_clk,
    input                        rst,

    // Keys, switches, LEDs
 
    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    // A dynamic seven-segment display

    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit,

    // Graphics

    input                        display_on,

    input        [w_x     - 1:0] x,
    input        [w_y     - 1:0] y,

    output logic [w_red   - 1:0] red,
    output logic [w_green - 1:0] green,
    output logic [w_blue  - 1:0] blue,

    // Microphone, sound output and UART

    input        [         23:0] mic,
    output       [         15:0] sound,

    input                        uart_rx,
    output                       uart_tx,

    // General-purpose Input/Output

    inout        [w_gpio  - 1:0] gpio
);

    //------------------------------------------------------------------------
    //    assign led        = sw;
    //    assign abcdefgh   = '0;
    //    assign digit      = '0;
    // assign red        = '0;
    // assign green      = '0;
    // assign blue       = '0;
    //    assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------

    wire [`GAME_RGB_WIDTH - 1:0] rgb;
    wire music_state;

    game_top
    # (
        .clk_mhz                           (clk_mhz                          ),
        .pixel_mhz                         (pixel_mhz                        ),
        .screen_width                      (screen_width                     ),
        .screen_height                     (screen_height                    ),
        .strobe_to_update_xy_counter_width (strobe_to_update_xy_counter_width)
    )
    i_game_top
    (
        .clk              (   clk                ),
        .rst              (   rst                ),

        .launch_key       ( | key                ),
        .left_right_keys  ( { key [1], key [0] } ),
        .up_down_keys     ( { key [2], key [3] } ),

        .up_down_keys_target  ( { sw [1], sw [0] } ),
        .target_speedup          ( { sw [3], sw [2] } ),


        .display_on       (   display_on         ),

        .x                (   x                  ),
        .y                (   y                  ),

        .rgb              (   rgb                ),
        .music_state      (   music_state        )
    );

    
    always_comb 
    begin
        if (x < w_gpio*4)
        begin
            // red = gpio[x >> 2];
            // green = gpio[x >> 2];
            // blue = gpio[x >> 2];
            red   = { w_red   { rgb [2] } };
            green = { w_green { rgb [1] } };
            blue  = { w_blue  { rgb [0] } };
        end
        else
        begin
        red   = { w_red   { rgb [2] } };
        green = { w_green { rgb [1] } };
        blue  = { w_blue  { rgb [0] } };
        end
        
    end


    logic  [2:0] octave;
    logic  [3:0] note;

    //------------------------------------------------------------------------

    tone_sel
    # (
        .clk_mhz (clk_mhz)
    )
    wave_gen
    (
        .clk       ( clk       ),
        .reset     ( rst       ),
        .octave    ( octave    ),
        .note      ( note      ),
        .y         ( sound     )
    );

    //------------------------------------------------------------------------

    logic [23:0] clk_div;

    always @ (posedge clk or posedge rst)
        if (rst)
            clk_div <= 0;
        else
            clk_div <= clk_div + 1;

    logic  [7:0] note_cnt;

    always @ (posedge clk or posedge rst)
        if (rst)
            note_cnt <= 0;
        else
            if (note_cnt == 109)
                note_cnt <= 0;
            else if (&clk_div && note != silence && ~music_state)
                note_cnt <= note_cnt + 1;
            else
                note_cnt <= 100;

    //------------------------------------------------------------------------

    localparam [3:0] C  = 4'd0,
                     Cs = 4'd1,
                     D  = 4'd2,
                     Ds = 4'd3,
                     E  = 4'd4,
                     F  = 4'd5,
                     Fs = 4'd6,
                     G  = 4'd7,
                     Gs = 4'd8,
                     A  = 4'd9,
                     As = 4'd10,
                     B  = 4'd11;

    localparam [3:0] Df = Cs, Ef = Ds, Gf = Fs, Af = Gs, Bf = As;

    localparam [3:0] silence = 4'd12;

    always_comb
        case (note_cnt)
        0:  { octave, note } = { 3'b0, G };
        1:  { octave, note } = { 3'b0, G };
        2:  { octave, note } = { 3'b1, C };
        3:  { octave, note } = { 3'b1, C };
        4:  { octave, note } = { 3'b1, C };
        5:  { octave, note } = { 3'b1, C };
        6:  { octave, note } = { 3'b0, G };
        7:  { octave, note } = { 3'b0, G };
        8:  { octave, note } = { 3'b1, A };
        9:  { octave, note } = { 3'b1, A };
        10:  { octave, note } = { 3'b1, B };
        11:  { octave, note } = { 3'b1, B };
        12:  { octave, note } = { 3'b1, B };
        13:  { octave, note } = { 3'b1, B };
        14:  { octave, note } = { 3'b0, E };
        15:  { octave, note } = { 3'b0, E };
        16:  { octave, note } = { 3'b0, E };
        17:  { octave, note } = { 3'b0, E };
        18:  { octave, note } = { 3'b1, A };
        19:  { octave, note } = { 3'b1, A };
        20:  { octave, note } = { 3'b1, A };
        21:  { octave, note } = { 3'b1, A };
        22:  { octave, note } = { 3'b0, G };
        23:  { octave, note } = { 3'b0, G };
        24:  { octave, note } = { 3'b0, F };
        25:  { octave, note } = { 3'b0, G };
        26:  { octave, note } = { 3'b0, G };
        27:  { octave, note } = { 3'b0, G };
        28:  { octave, note } = { 3'b0, G };
        29:  { octave, note } = { 3'b0, C };
        30:  { octave, note } = { 3'b0, C };
        31:  { octave, note } = { 3'b0, C };
        32:  { octave, note } = { 3'b0, C };
        33:  { octave, note } = { 3'b0, D };
        34:  { octave, note } = { 3'b0, D };
        35:  { octave, note } = { 3'b0, D };
        36:  { octave, note } = { 3'b0, D };
        37:  { octave, note } = { 3'b0, D };
        38:  { octave, note } = { 3'b0, D };
        39:  { octave, note } = { 3'b0, E };
        40:  { octave, note } = { 3'b0, E };
        41:  { octave, note } = { 3'b0, F };
        42:  { octave, note } = { 3'b0, F };
        43:  { octave, note } = { 3'b0, F };
        44:  { octave, note } = { 3'b0, F };
        45:  { octave, note } = { 3'b0, F };
        46:  { octave, note } = { 3'b0, F };
        47:  { octave, note } = { 3'b0, G };
        48:  { octave, note } = { 3'b1, A };
        49:  { octave, note } = { 3'b1, A };
        50:  { octave, note } = { 3'b1, A };
        51:  { octave, note } = { 3'b1, A };
        52:  { octave, note } = { 3'b1, B };
        53:  { octave, note } = { 3'b1, B };
        54:  { octave, note } = { 3'b1, C };
        55:  { octave, note } = { 3'b1, C };
        56:  { octave, note } = { 3'b1, D };
        57:  { octave, note } = { 3'b1, D };
        58:  { octave, note } = { 3'b1, D };
        59:  { octave, note } = { 3'b1, D };
        60:  { octave, note } = { 3'b1, D };
        61:  { octave, note } = { 3'b1, D };
        62:  { octave, note } = { 3'b1, D };
        63:  { octave, note } = { 3'b1, D };
        100:  { octave, note } = { 3'b1, A };
        101:  { octave, note } = { 3'b1, A };
        102:  { octave, note } = { 3'b0, E };
        103:  { octave, note } = { 3'b0, E };
        104:  { octave, note } = { 3'b0, A };
        105:  { octave, note } = { 3'b0, A };
        106:  { octave, note } = { 3'b0, A };
        107:  { octave, note } = { 3'b0, C };
        108:  { octave, note } = { 3'b0, C };

        default: { octave, note } = { 3'b0, silence };
        endcase


    //------------------------------------------------------------------------

    assign led  = { {(w_led - $left (octave)){1'b0}}, octave };

    assign digit = { {(w_digit - 1){1'b0}}, 1'b1};

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            abcdefgh <= 'b00000000;
        else
            case (note)
            'd0:    abcdefgh <= 'b10011100;  // C   // abcdefgh
            'd1:    abcdefgh <= 'b10011101;  // C#
            'd2:    abcdefgh <= 'b01111010;  // D   //   --a--
            'd3:    abcdefgh <= 'b01111011;  // D#  //  |     |
            'd4:    abcdefgh <= 'b10011110;  // E   //  f     b
            'd5:    abcdefgh <= 'b10001110;  // F   //  |     |
            'd6:    abcdefgh <= 'b10001111;  // F#  //   --g--
            'd7:    abcdefgh <= 'b10111100;  // G   //  |     |
            'd8:    abcdefgh <= 'b10111101;  // G#  //  e     c
            'd9:    abcdefgh <= 'b11101110;  // A   //  |     |
            'd10:   abcdefgh <= 'b11101111;  // A#  //   --d--  h
            'd11:   abcdefgh <= 'b00111110;  // B
            default: abcdefgh <= 'b00000000;
            endcase

endmodule
