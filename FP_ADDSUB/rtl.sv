
module fp_addsub_core (
    input      [31:0] a,
    input      [31:0] b,
    input             sub,
    output reg [31:0] result
);

    reg [31:0] b2, big, small;

    reg [26:0] big_ext, small_ext;
    reg [26:0] small_shifted, mant_ext;

    reg [27:0] sum;
    reg [24:0] rounded;
    reg [23:0] mant24;

    reg [7:0] exp_field;
    reg [7:0] exp_field_b;

    reg sign_result;
    reg round_inc;
    reg sticky;

    integer exp_big;
    integer exp_small;
    integer exp_work;
    integer d;
    integer i;

    always @* begin

        // Default values
        result = 32'd0;
        b2 = {b[31] ^ sub, b[30:0]};

        big = 32'd0;
        small = 32'd0;

        big_ext = 27'd0;
        small_ext = 27'd0;
        small_shifted = 27'd0;
        mant_ext = 27'd0;

        sum = 28'd0;
        rounded = 25'd0;
        mant24 = 24'd0;

        exp_field = 8'd0;
        exp_field_b = 8'd0;

        sign_result = 1'b0;
        round_inc = 1'b0;
        sticky = 1'b0;

        exp_big = 0;
        exp_small = 0;
        exp_work = 0;
        d = 0;

        // Special case: NaN
        if (((a[30:23] == 8'hFF) && (a[22:0] != 0)) ||
            ((b2[30:23] == 8'hFF) && (b2[22:0] != 0))) begin

            result = 32'h7FC00000;

        end

        // Special case: both operands infinity
        else if ((a[30:23] == 8'hFF) &&
                 (a[22:0] == 0) &&
                 (b2[30:23] == 8'hFF) &&
                 (b2[22:0] == 0)) begin

            if (a[31] != b2[31])
                result = 32'h7FC00000;
            else
                result = {a[31], 8'hFF, 23'd0};

        end

        // A is infinity
        else if ((a[30:23] == 8'hFF) &&
                 (a[22:0] == 0)) begin

            result = {a[31], 8'hFF, 23'd0};

        end

        // B is infinity
        else if ((b2[30:23] == 8'hFF) &&
                 (b2[22:0] == 0)) begin

            result = {b2[31], 8'hFF, 23'd0};

        end

        else begin

            // Compare magnitudes
            if (a[30:0] >= b2[30:0]) begin
                big = a;
                small = b2;
            end
            else begin
                big = b2;
                small = a;
            end

            sign_result = big[31];

            // Effective exponents
            exp_field = big[30:23];
            exp_field_b = small[30:23];

            exp_big = (exp_field == 0) ? 1 : exp_field;
            exp_small = (exp_field_b == 0) ? 1 : exp_field_b;

            // Extract mantissas and hidden bits
            big_ext = {
                (exp_field != 0),
                big[22:0],
                3'b000
            };

            small_ext = {
                (exp_field_b != 0),
                small[22:0],
                3'b000
            };

            // Align exponents
            d = exp_big - exp_small;

            if (d >= 27)
                small_shifted = 27'd0;
            else
                small_shifted = small_ext >> d;

            // Calculate sticky bit
            sticky = 1'b0;

            for (i = 0; i < 27; i = i + 1) begin
                if ((i < d) && small_ext[i])
                    sticky = 1'b1;
            end

            small_shifted[0] =
                small_shifted[0] | sticky;

            // Add or subtract mantissas
            if (big[31] == small[31]) begin
                sum = {1'b0, big_ext} +
                      {1'b0, small_shifted};
            end
            else begin
                sum = {1'b0, big_ext} -
                      {1'b0, small_shifted};
            end

            exp_work = exp_big;

            // Check zero result
            if (sum == 28'd0) begin

                if (big[31] != small[31])
                    sign_result = 1'b0;
                else
                    sign_result = big[31];

                result = {sign_result, 31'd0};

            end

            else begin

                // Normalization
                if (sum[27]) begin

                    mant_ext = {
                        sum[27:2],
                        (sum[1] | sum[0])
                    };

                    exp_work = exp_work + 1;

                end
                else begin

                    mant_ext = sum[26:0];

                    // Shift left until normalized
                    for (i = 0; i < 26; i = i + 1) begin

                        if ((mant_ext[26] == 1'b0) &&
                            (exp_work > 1)) begin

                            mant_ext = mant_ext << 1;
                            exp_work = exp_work - 1;

                        end

                    end

                end

                // Round to nearest even
                round_inc =
                    mant_ext[2] &
                    (mant_ext[1] |
                     mant_ext[0] |
                     mant_ext[3]);

                rounded =
                    {1'b0, mant_ext[26:3]} +
                    round_inc;

                // Handle rounding carry
                if (rounded[24]) begin

                    mant24 = rounded[24:1];
                    exp_work = exp_work + 1;

                end
                else begin

                    mant24 = rounded[23:0];

                end

                // Overflow
                if (exp_work >= 255) begin

                    result = {
                        sign_result,
                        8'hFF,
                        23'd0
                    };

                end

                // Normal result
                else if (mant24[23]) begin

                    result = {
                        sign_result,
                        exp_work[7:0],
                        mant24[22:0]
                    };

                end

                // Subnormal result
                else begin

                    result = {
                        sign_result,
                        8'd0,
                        mant24[22:0]
                    };

                end

            end

        end

    end

endmodule


module fp_addsub (
    input  logic        clk,
    input  logic        reset,
    input  logic        in_valid,
    input  logic        sub,
    input  logic [31:0] a,
    input  logic [31:0] b,

    output logic        out_valid,
    output logic [31:0] result
);

    logic [31:0] r;

    // Instantiate floating-point core
    fp_addsub_core u_core (
        .a(a),
        .b(b),
        .sub(sub),
        .result(r)
    );

    // Sequential output stage
    always_ff @(posedge clk) begin

        if (reset) begin

            out_valid <= 1'b0;
            result <= 32'd0;

        end

        else begin

            out_valid <= in_valid;

            if (in_valid)
                result <= r;

        end

    end

endmodule

