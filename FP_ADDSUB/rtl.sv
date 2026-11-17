
module fp_addsub_core (
    input      [31:0] a,
    input      [31:0] b,
    input             sub,
    output reg [31:0] result
);

    reg [31:0] b2, x, y;
    reg        a_nan, b_nan, a_inf, b_inf;
    reg        sx, sy, es, rsign, hid_n, ru, sticky;
    reg [26:0] mx, my, my_sh, mn;
    reg [27:0] sum;
    reg [24:0] rnd;
    reg [22:0] frac;
    integer    ex, ey, d, lz, sh, e_n, e_out, i;

    always @* begin
        b2 = {b[31] ^ sub, b[30:0]};

        a_nan = (a[30:23] == 8'hFF) && (a[22:0] != 23'd0);
        b_nan = (b2[30:23] == 8'hFF) && (b2[22:0] != 23'd0);

        a_inf = (a[30:23] == 8'hFF) && (a[22:0] == 23'd0);
        b_inf = (b2[30:23] == 8'hFF) && (b2[22:0] == 23'd0);

        if (a[30:0] >= b2[30:0]) begin
            x = a;
            y = b2;
        end else begin
            x = b2;
            y = a;
        end

        sx = x[31];
        sy = y[31];
        es = sx ^ sy;

        ex = (x[30:23] == 8'd0) ? 1 : x[30:23];
        ey = (y[30:23] == 8'd0) ? 1 : y[30:23];

        mx = {(x[30:23] != 8'd0), x[22:0], 3'b000};
        my = {(y[30:23] != 8'd0), y[22:0], 3'b000};

        d = ex - ey;

        my_sh = (d >= 27) ? 27'd0 : (my >> d);

        sticky = 1'b0;

        for (i = 0; i < 27; i = i + 1)
            if (i < d && my[i])
                sticky = 1'b1;

        my_sh[0] = my_sh[0] | sticky;

        sum = es ? ({1'b0, mx} - {1'b0, my_sh})
                 : ({1'b0, mx} + {1'b0, my_sh});

        lz = 0;
        sh = 0;
        e_n = 0;
        e_out = 0;

        mn = 27'd0;
        rnd = 25'd0;
        ru = 1'b0;
        hid_n = 1'b0;
        frac = 23'd0;
        rsign = sx;

        if (sum == 28'd0) begin
            rsign = es ? 1'b0 : sx;
            result = {rsign, 31'd0};
        end else begin

            if (sum[27]) begin
                mn = {sum[27:2], sum[1] | sum[0]};
                e_n = ex + 1;
            end else begin
                lz = 27;

                for (i = 0; i <= 26; i = i + 1)
                    if (sum[i])
                        lz = 26 - i;

                sh = lz;

                if (ex - 1 < lz)
                    sh = ex - 1;

                mn = sum[26:0] << sh;
                e_n = ex - sh;
            end

            hid_n = mn[26];

            ru = mn[2] & (mn[3] | mn[1] | mn[0]);

            rnd = {1'b0, mn[26:3]} + {24'd0, ru};

            if (hid_n)
                e_out = e_n + rnd[24];
            else
                e_out = rnd[23] ? 1 : 0;

            frac = rnd[22:0];

            if (e_out >= 255)
                result = {rsign, 8'hFF, 23'd0};
            else
                result = {rsign, e_out[7:0], frac};
        end

        if (a_nan || b_nan)
            result = 32'h7FC00000;
        else if (a_inf && b_inf)
            result = (a[31] != b2[31]) ?
                     32'h7FC00000 : {a[31], 31'h7F800000};
        else if (a_inf)
            result = {a[31], 31'h7F800000};
        else if (b_inf)
            result = {b2[31], 31'h7F800000};

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

    fp_addsub_core u_core (
        .a(a),
        .b(b),
        .sub(sub),
        .result(r)
    );

    always_ff @(posedge clk) begin
        if (reset) begin
            out_valid <= 1'b0;
            result <= 32'd0;
        end else begin
            out_valid <= in_valid;

            if (in_valid)
                result <= r;
        end
    end

endmodule
