module master_fsm #(
    // szerokosc magistrali dla rejestrow pozycji
    parameter POS_RANGE = 16
)(
    input logic clk,
    input logic rst_n,

    // wyjscia sterujace
    output logic set_zero,              
    output logic dir,                   
    output logic callib_done,           
    output logic prescaler_enable,

    // wejscia sterujace
    input logic enable,                 
    input logic callib,                 
    input logic go_to,         

    //wejscia z czujnikow i licznikow
    input logic sensor_clean,
    input logic [POS_RANGE - 1:0] target_position,
    input logic [POS_RANGE - 1:0] current_position

);

    typedef enum logic [2:0] {
        IDLE,
        CALLIB_FIND,
        CALLIB_DONE,
        MOVE_EVALUATE,
        MOVE_RUN,
        MOVE_DONE
    } state_t;

    state_t state, state_nxt;
    logic dir_nxt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            dir <= 1'b0;
        end else begin
            state <= state_nxt;
            dir <= dir_nxt;
        end
    end

    always_comb begin
        state_nxt = state; 

        if (!enable) begin
            state_nxt = IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (callib) begin
                        state_nxt = CALLIB_FIND;
                    end else if (go_to) begin
                        state_nxt = MOVE_EVALUATE;
                    end
                end
                
                CALLIB_FIND: begin
                    if (sensor_clean) begin
                        state_nxt = CALLIB_DONE;
                    end
                end
                
                CALLIB_DONE: begin
                    // FSM czeka aż zostanie zdjety sygnal callib
                    // potwierdzajac odczytanie flagi
                    if (!callib) begin
                        state_nxt = IDLE;
                    end
                end
                
                MOVE_EVALUATE: begin
                    if (target_position == current_position) begin
                        state_nxt = IDLE;
                    end else begin
                        state_nxt = MOVE_RUN;
                    end
                end
                
                MOVE_RUN: begin
                    if (callib) begin
                        state_nxt = CALLIB_FIND;
                    end
                    else if (target_position == current_position) begin
                        state_nxt = MOVE_DONE;
                    end
                end
                
                MOVE_DONE: begin
                    state_nxt = IDLE;
                end
                
                default: begin
                    state_nxt = IDLE;
                end
            endcase
        end
    end

    always_comb begin
        set_zero = 1'b0;
        callib_done = 1'b0;
        prescaler_enable = 1'b0;
        dir_nxt = dir; 

        case (state)
            IDLE: begin
            end
            
            CALLIB_FIND: begin
                prescaler_enable = 1'b1;
                dir_nxt = 1'b0; 
            end
            
            CALLIB_DONE: begin
                set_zero = 1'b1;
                callib_done = 1'b1;
            end
            
            MOVE_EVALUATE: begin
                if (target_position > current_position) begin
                    dir_nxt = 1'b1;
                end else begin
                    dir_nxt = 1'b0;
                end
            end
            
            MOVE_RUN: begin
                prescaler_enable = 1'b1;
            end
            
            MOVE_DONE: begin
            end
            
            default: begin
            end
        endcase

        if (!enable) begin
            prescaler_enable = 1'b0;
        end
    end

endmodule