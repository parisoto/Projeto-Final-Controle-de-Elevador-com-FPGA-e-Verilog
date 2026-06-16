module projeto_elevador_pitanga(
    input clk, 

    input btn_1, input btn_2, input btn_3,

    input fc_1, input fc_2, input fc_3,
    input sens_aberta_1, input sens_aberta_2, input sens_aberta_3,
    input sens_fechada_1, input sens_fechada_2, input sens_fechada_3,

    output motor_sobe, output motor_desce,
    output cmd_abre_1, output cmd_abre_2, output cmd_abre_3,
    output cmd_fecha_1, output cmd_fecha_2, output cmd_fecha_3,

    output [6:0] dp7_0, 
    output [6:0] dp7_1, 
    output [6:0] dp7_2, 
    output [6:0] dp7_3, 
    output blk
);

// ====================================================================
wire reset = 1'b0; 

wire porta_fechada_1 = sens_fechada_1;
wire porta_fechada_2 = sens_fechada_2;
wire porta_fechada_3 = sens_fechada_3;
wire porta_aberta_1  = sens_aberta_1;
wire porta_aberta_2  = sens_aberta_2;
wire porta_aberta_3  = sens_aberta_3;

// NOTA: Se os botões chamarem o elevador sozinhos sem você apertar, 
// mude estas 3 linhas para: wire btn_1_sync = ~btn_1; (inversão de sinal)
wire btn_1_sync = btn_1;
wire btn_2_sync = btn_2;
wire btn_3_sync = btn_3;

wire fc_1_sync  = fc_1;
wire fc_2_sync  = fc_2;
wire fc_3_sync  = fc_3;

// ====================================================================
// CORREÇÃO APLICADA AQUI: HOMING agora é 0. A placa sempre nascerá nele!
localparam HOMING       = 3'd0,
           IDLE         = 3'd1,
           MOVE_UP      = 3'd2,
           MOVE_DOWN    = 3'd3,
           DOOR_OPENING = 3'd4,
           DOOR_OPEN    = 3'd5,
           DOOR_CLOSING = 3'd6;

reg [2:0] estado = HOMING, prox_estado;
reg [31:0] timer = 0;
localparam TEMPO_PORTA = 32'd6; 

// ====================================================================
reg call_1 = 0, call_2 = 0, call_3 = 0;
reg [1:0] andar_atual = 2'd0; 

always @(posedge clk) begin
    if (fc_1_sync)      andar_atual <= 2'd1;
    else if (fc_2_sync) andar_atual <= 2'd2;
    else if (fc_3_sync) andar_atual <= 2'd3;

    if (btn_1_sync) call_1 <= 1;
    if (btn_2_sync) call_2 <= 1;
    if (btn_3_sync) call_3 <= 1;
    
    if (andar_atual == 2'd1 && estado == DOOR_OPEN) call_1 <= 0;
    if (andar_atual == 2'd2 && estado == DOOR_OPEN) call_2 <= 0;
    if (andar_atual == 2'd3 && estado == DOOR_OPEN) call_3 <= 0;
end

// ====================================================================
reg r_motor_sobe, r_motor_desce;
reg r_porta_abre_1, r_porta_fecha_1;
reg r_porta_abre_2, r_porta_fecha_2;
reg r_porta_abre_3, r_porta_fecha_3;

always @(posedge clk) begin
    estado <= prox_estado;
    if (estado == DOOR_OPEN) begin
        if (estado == prox_estado) 
            timer <= timer + 1; 
        else
            timer <= 0;         
    end else begin
        timer <= 0;
    end
end

wire todas_portas_fechadas = porta_fechada_1 & porta_fechada_2 & porta_fechada_3;

always @(*) begin
    prox_estado = estado;
    r_motor_sobe = 0; r_motor_desce = 0;
    r_porta_abre_1 = 0; r_porta_fecha_1 = 0;
    r_porta_abre_2 = 0; r_porta_fecha_2 = 0;
    r_porta_abre_3 = 0; r_porta_fecha_3 = 0;

    case (estado)
        HOMING: begin
            if (!todas_portas_fechadas) begin
                if (!porta_fechada_1) r_porta_fecha_1 = 1;
                if (!porta_fechada_2) r_porta_fecha_2 = 1;
                if (!porta_fechada_3) r_porta_fecha_3 = 1;
            end 
            else begin
                if (fc_1_sync || fc_2_sync || fc_3_sync) begin
                    prox_estado = IDLE; 
                end else begin
                    r_motor_desce = 1;
                end
            end
        end

        IDLE: begin
            if (andar_atual != 2'd0) begin
                if ((call_1 && andar_atual == 2'd1) || 
                    (call_2 && andar_atual == 2'd2) || 
                    (call_3 && andar_atual == 2'd3)) begin
                    prox_estado = DOOR_OPENING;
                end
                else if (todas_portas_fechadas) begin
                    if ((call_3 && andar_atual < 2'd3) || (call_2 && andar_atual == 2'd1)) 
                        prox_estado = MOVE_UP;
                    else if ((call_1 && andar_atual > 2'd1) || (call_2 && andar_atual == 2'd3)) 
                        prox_estado = MOVE_DOWN;
                end
            end
        end

        MOVE_UP: begin
            r_motor_sobe = 1;
            if ((fc_2_sync && call_2) || fc_3_sync) begin
                prox_estado = DOOR_OPENING;
            end
        end

        MOVE_DOWN: begin
            r_motor_desce = 1;
            if ((fc_2_sync && call_2) || fc_1_sync) begin
                prox_estado = DOOR_OPENING;
            end
        end

        DOOR_OPENING: begin
            if (andar_atual == 2'd1) begin
                r_porta_abre_1 = 1;
                if (porta_aberta_1) prox_estado = DOOR_OPEN;
            end
            else if (andar_atual == 2'd2) begin
                r_porta_abre_2 = 1;
                if (porta_aberta_2) prox_estado = DOOR_OPEN;
            end
            else if (andar_atual == 2'd3) begin
                r_porta_abre_3 = 1;
                if (porta_aberta_3) prox_estado = DOOR_OPEN;
            end
        end

        DOOR_OPEN: begin
            if (andar_atual == 2'd1) r_porta_abre_1 = 1;
            if (andar_atual == 2'd2) r_porta_abre_2 = 1;
            if (andar_atual == 2'd3) r_porta_abre_3 = 1;

            if (timer >= TEMPO_PORTA || 
               (andar_atual == 2'd1 && !porta_aberta_1) || 
               (andar_atual == 2'd2 && !porta_aberta_2) || 
               (andar_atual == 2'd3 && !porta_aberta_3)) begin
                prox_estado = DOOR_CLOSING;
            end
        end

        DOOR_CLOSING: begin
            if (andar_atual == 2'd1) begin
                r_porta_fecha_1 = 1;
                if (porta_fechada_1) prox_estado = IDLE;
            end
            else if (andar_atual == 2'd2) begin
                r_porta_fecha_2 = 1;
                if (porta_fechada_2) prox_estado = IDLE;
            end
            else if (andar_atual == 2'd3) begin
                r_porta_fecha_3 = 1;
                if (porta_fechada_3) prox_estado = IDLE;
            end
        end
        
        default: prox_estado = HOMING;
    endcase
end

// ====================================================================
wire safe_sobe = r_motor_sobe && !r_motor_desce;
wire safe_desce = r_motor_desce && !r_motor_sobe;

assign motor_sobe  = safe_sobe && todas_portas_fechadas;
assign motor_desce = safe_desce && todas_portas_fechadas;
assign cmd_abre_1  = r_porta_abre_1;
assign cmd_abre_2  = r_porta_abre_2;
assign cmd_abre_3  = r_porta_abre_3;
assign cmd_fecha_1 = r_porta_fecha_1;
assign cmd_fecha_2 = r_porta_fecha_2;
assign cmd_fecha_3 = r_porta_fecha_3;

// ====================================================================
reg [6:0] r_dp7_0;
always @(*) begin
    case(andar_atual)
        2'd1: r_dp7_0 = 7'b0110000; 
        2'd2: r_dp7_0 = 7'b1101101; 
        2'd3: r_dp7_0 = 7'b1111001; 
        default: r_dp7_0 = 7'b0000000; 
    endcase
end

wire porta_visualmente_aberta = (estado == DOOR_OPENING || estado == DOOR_OPEN);

assign dp7_3 = porta_visualmente_aberta ? 7'b1100111 : 7'b0000000;
assign dp7_2 = porta_visualmente_aberta ? 7'b1110111 : 7'b0000000;
assign dp7_1 = (andar_atual != 2'd0) ? 7'b1110111 : 7'b0000000;
assign dp7_0 = r_dp7_0;
assign blk = 1'b0; 

endmodule
