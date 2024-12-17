`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/08/2024 02:51:58 PM
// Design Name: 
// Module Name: Final_AXI_to_APB_Bridge
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Final_AXI_to_APB_Bridge#(
    parameter AXI_ADDR_WIDTH   = 32,   // Address width (e.g., 32 bits)
    parameter AXI_DATA_WIDTH   = 32,   // Data width (e.g., 32, 64 bits)
    parameter AXI_MAX_BURST_LEN = 8,   // Maximum burst length (e.g., 16, 256 - requires 8 bits for AXI_MAX_BURST_LEN)
    parameter AXI_BURST_WIDTH  = 2,    // Burst type width (usually 2 bits)
    parameter AXI_SIZE_WIDTH   = 3,     // Size width (usually 3 bits: byte, half-word, word)
    // APB Interface Parameters
    parameter APB_ADDR_WIDTH   = 32,   // Address width for APB (e.g., 32 bits)
    parameter APB_DATA_WIDTH   = 32    // Data width for APB (e.g., 32 bits)
)(
    /***********************/
    // Write Address Channel (AW)
    /***********************/
    input [AXI_ADDR_WIDTH-1:0] AWADDR,        // Write address 
    input [AXI_BURST_WIDTH-1:0] AWBURST,       // Burst type (INCR, WRAP, FIXED)
    input [AXI_MAX_BURST_LEN-1:0] AWLEN,       // Burst length (number of beats - 1)
    input AWVALID,                             // Write address valid
    output logic AWREADY,                            // Write address ready
    /***********************/
    // Read Address Channel (AR)
    /***********************/
    input [AXI_ADDR_WIDTH-1:0] ARADDR,        // Read address
    input [AXI_BURST_WIDTH-1:0] ARBURST,       // Burst type (INCR, WRAP, FIXED)
    input [AXI_MAX_BURST_LEN-1:0] ARLEN,       // Burst length (number of beats - 1)
    input ARVALID,                             // Read address valid
    output logic ARREADY,                            // Read address ready
    /***********************/
    // Write Data Channel (W)
    /***********************/
    input [AXI_DATA_WIDTH-1:0] WDATA,          // Write data
    input WVALID,                             // Write data valid
    input WLAST,                               // Last Signal 
    input [AXI_DATA_WIDTH/8 - 1 :0] WSTRB,     // Strobe Signal 
    output logic WREADY,                            // Write data ready
    /***********************/
    // Read Data Channel (RD)
    /***********************/
    output logic [AXI_DATA_WIDTH-1:0] RDATA,         // Read data
    output logic [1:0] RRESP,                        // Read response (OKAY, SLVERR)
    output logic RVALID,                             // Read data valid
    output logic RLAST,
    input RREADY,                              // Read data ready
    /***********************/
    // Write Response Channel (B)
    /***********************/
    //output [AXI_ID_WIDTH-1:0] BID,             // Write response ID (matches slave ID width)
    output logic [1:0] BRESP,                        // Write response (OKAY, SLVERR)
    output logic BVALID,                             // Write response valid
    input BREADY,                              // Write response ready
    /***********************/
    // Control and Timing Signals
    /***********************/
    input ACLK,                                // Clock signal for AXI protocol
    input ARESETn,                              // Active-low reset signal
    /***********************/
    // APB Master interface signals
    /***********************/
    output logic [APB_ADDR_WIDTH-1:0] PADDR,         // APB address
    output logic PWRITE,                             // APB Write/Read control signal
    output logic PSEL1,PSEL2,PSEL3,PSEL4,                               // APB select signal
    output logic PENABLE,                            // APB enable signal
    output logic [APB_DATA_WIDTH-1:0] PWDATA,        // APB write data
    input [APB_DATA_WIDTH-1:0] PRDATA,         // APB read data
    input PREADY                              // APB ready signal
    
   // input PSLVERR,                             // APB slave error signal
);
    /***********************/
    // State machine states using typedef enum
    /***********************/
    typedef enum logic [12:0] {
        IDLE_WRITE                  = 13'b0000000000001,
        READ_SETUP_M                = 13'b0000000000010,
        READ_SETUP_S                = 13'b0000000000100,
        READ_ACCESS_S               = 13'b0000000001000,
        READ_PREACCESS_M            = 13'b0000000010000,
        READ_ACCESS_M               = 13'b0000000100000,
        WRITE_SETUP_M               = 13'b0000001000000,
        WRITE_PREACCESS_M           = 13'b0000010000000,
        WRITE_ACCESS_M              = 13'b0000100000000,
        WRITE_TERMINATE             = 13'b0001000000000,
        WRITE_SETUP_S               = 13'b0010000000000,
        WRITE_ACCESS_S              = 13'b0100000000000,
        IDLE_READ                   = 13'b1000000000000
    } state_t;
    
    state_t current_state_write;
    state_t next_state_write;
    state_t current_state_read;
    state_t next_state_read;
    
    
    /***************************************************************/
    // Local Variables For Storing the write transaction AXI-Master
    /***************************************************************/ 
    
    
    logic [AXI_MAX_BURST_LEN : 0] Length_Of_Burst_Subordinate_write_next;
    logic [AXI_MAX_BURST_LEN : 0] Length_Of_Burst_Subordinate_write;
    logic [AXI_MAX_BURST_LEN : 0] Length_Of_Burst_Manager_write_next;
    logic [AXI_MAX_BURST_LEN : 0] Length_Of_Burst_Manager_write;
    logic [AXI_ADDR_WIDTH -1:0] Address_Hold_Reg_write_next;
    logic [AXI_ADDR_WIDTH -1:0] Address_Hold_Reg_write;
    
    logic [AXI_ADDR_WIDTH - 1:0] Memory_Aligner_write_next;
    logic [AXI_ADDR_WIDTH - 1:0] Memory_Aligner_write;
    
    logic [1:0] Write_Enabler;
    
    /***************************************************************/
    // Local Variables For the read transaction APB-Slave
    /***************************************************************/ 
    
    
    logic [AXI_MAX_BURST_LEN : 0] Length_Of_Burst_Subordinate_read_next;
    logic [AXI_MAX_BURST_LEN : 0] Length_Of_Burst_Subordinate_read;
    logic [AXI_MAX_BURST_LEN : 0] Length_Of_Burst_Manager_read_next;
    logic [AXI_MAX_BURST_LEN : 0] Length_Of_Burst_Manager_read;
    logic [AXI_ADDR_WIDTH -1:0] Address_Hold_Reg_read_next;
    logic [AXI_ADDR_WIDTH -1:0] Address_Hold_Reg_read;
    
    logic [AXI_DATA_WIDTH - 1 :0] Memory [0:AXI_DATA_WIDTH - 1];
    
    logic [1:0] Read_Enabler;
    logic [AXI_DATA_WIDTH/8 - 1 :0] WSTRB_axi;
    logic [AXI_DATA_WIDTH/8 - 1 :0] WSTRB_apb;
    bit last;
    /***********************/
    // FIFOs Implementation
    /***********************/
    logic [AXI_DATA_WIDTH-1:0] write_fifo [0:127] = '{default: '0};  // FIFO for storing write data
    logic [AXI_DATA_WIDTH-1:0] read_fifo [0:127]  = '{default: '0};   // FIFO for storing read data
    integer write_fifo_ptr, read_fifo_ptr, burst_count,write_fifo_ptr_writing,read_fifo_ptr_write;
    integer write_fifo_ptr_next, read_fifo_ptr_next, burst_count_next,write_fifo_ptr_writing_next,read_fifo_ptr_write_next;    
    
        // Round-Robin Arbiter Control Logic
    typedef enum logic {
        READ_PRIORITY = 1'b0,
        WRITE_PRIORITY = 1'b1
    } arbiter_state_t;

    arbiter_state_t current_arbiter_state, next_arbiter_state;

    /***********************************************************************************/
    // Combinational Block For Arbiter State
    /**********************************************************************************/
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            current_arbiter_state <= WRITE_PRIORITY;
        end else 
        begin
            current_arbiter_state <= next_arbiter_state;
        end
    end

    always_comb begin
        next_arbiter_state = current_arbiter_state;
        
        case (current_arbiter_state)
            WRITE_PRIORITY: begin
                // Prioritize Write if Write is valid and AR is not valid
                if (AWVALID && !ARVALID) begin
                    next_arbiter_state = READ_PRIORITY; // Switch to read priority after write
                end
            end
            
            READ_PRIORITY: begin
                // Prioritize Read if Read is valid and AW is not valid
                if (ARVALID && !AWVALID) begin
                    next_arbiter_state = WRITE_PRIORITY; // Switch to write priority after read
                end
            end
        endcase
    end
    /***********************************************************************************/
    // Sequential Block For Write And Read States
    /**********************************************************************************/    
    
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            current_state_write <= IDLE_WRITE;
            current_state_read <= IDLE_READ;
            Length_Of_Burst_Manager_read <= 0;
            Length_Of_Burst_Subordinate_read <= 0;
            Length_Of_Burst_Manager_write <= 0;
            Length_Of_Burst_Subordinate_write <= 0;
            Address_Hold_Reg_write <= 0;
            Address_Hold_Reg_read <= 0;
            write_fifo_ptr <= 0;
            read_fifo_ptr <= 0; 
            burst_count <= 0;
            write_fifo_ptr_writing <= 0;
            read_fifo_ptr_write <= 0;
            Memory_Aligner_write <= 0;
        end else begin
            // Apply arbitration logic to decide which channel to process
            if (current_arbiter_state == READ_PRIORITY && (AWADDR == ARADDR) || (current_arbiter_state == READ_PRIORITY) && ((AWADDR >= 0 && ARADDR >= 0 && AWADDR <= 50 && ARADDR <= 50) || (AWADDR >= 51 && ARADDR >= 51 && AWADDR <= 10 && ARADDR <= 100) || (AWADDR >= 101 && ARADDR >= 101 && AWADDR <= 150 && ARADDR <= 150) || (AWADDR >= 151 && ARADDR >= 151 && AWADDR <= 200 && ARADDR <= 200) )) begin
                current_state_write <= next_state_write;
                current_state_read <= IDLE_READ; // Suspend read when write is in progress
            end
            else 
                begin
                   current_state_write <= next_state_write; 
                end
            if ((current_arbiter_state == WRITE_PRIORITY && (AWADDR == ARADDR)) || (current_arbiter_state == WRITE_PRIORITY && ((AWADDR >= 0 && ARADDR >= 0 && AWADDR <= 50 && ARADDR <= 50) || (AWADDR >= 51 && ARADDR >= 51 && AWADDR <= 10 && ARADDR <= 100) || (AWADDR >= 101 && ARADDR >= 101 && AWADDR <= 150 && ARADDR <= 150) || (AWADDR >= 151 && ARADDR >= 151 && AWADDR <= 200 && ARADDR <= 200)))) begin
                current_state_read <= next_state_read;
                current_state_write <= IDLE_WRITE; // Suspend write when read is in progress
            end
            else 
                begin
                 current_state_read <= next_state_read;   
                end
             Length_Of_Burst_Manager_read <= Length_Of_Burst_Manager_read_next;
             Length_Of_Burst_Subordinate_read <= Length_Of_Burst_Subordinate_read_next;
             Length_Of_Burst_Manager_write <= Length_Of_Burst_Manager_write_next;
             Length_Of_Burst_Subordinate_write <= Length_Of_Burst_Subordinate_write_next;
             Address_Hold_Reg_write <= Address_Hold_Reg_write_next;
             Address_Hold_Reg_read <= Address_Hold_Reg_read_next;
             write_fifo_ptr <= write_fifo_ptr_next;
             read_fifo_ptr <= read_fifo_ptr_next; 
             burst_count <= burst_count_next;
             write_fifo_ptr_writing <= write_fifo_ptr_writing_next;
             read_fifo_ptr_write <= read_fifo_ptr_write_next;   
             Memory_Aligner_write <= Memory_Aligner_write_next;             
        end
    end 
    
    /***********************************************************************************/
    // Sequential Block For Write And Read FIFOS
    /**********************************************************************************/      
    always_ff @(posedge ACLK /*or negedge ARESETn*/) 
        begin    
            if(current_state_write == WRITE_ACCESS_M && Length_Of_Burst_Manager_write != 8'd0)
                begin
                    write_fifo[write_fifo_ptr] <= WDATA;
                end
            else 
                begin
                    write_fifo <= write_fifo;
                end

            if(current_state_read == READ_ACCESS_S && Length_Of_Burst_Subordinate_read != 8'd0)
                begin
                    read_fifo[read_fifo_ptr] <= PRDATA;
                end
            else 
                begin
                    read_fifo <= read_fifo;
                end
                    
        end
    /********************************************/
    // Combinational Block For Write Transaction
    /*******************************************/     
    
    always@(AWVALID,current_state_write, PREADY ,WVALID)
        begin
            case(current_state_write)
                IDLE_WRITE : begin
                            PWDATA = 0;
                            Write_Enabler = 0;
                            write_fifo_ptr_next = 0;
                            Address_Hold_Reg_write_next = 0;
                            burst_count_next = 0;
                            Length_Of_Burst_Manager_write_next = 0;
                            Length_Of_Burst_Subordinate_write_next = 0;
                            write_fifo_ptr_writing_next = 0;
                            Memory_Aligner_write_next = 0;
                            WSTRB_axi = 0;
                            WSTRB_apb = 0;
                            if(AWVALID)
                                begin
                                    next_state_write = WRITE_SETUP_M;
                                end
                            else
                                    next_state_write =IDLE_WRITE;   
                       end
                WRITE_SETUP_M : begin
                                if(AWVALID)
                                    begin
                                        Address_Hold_Reg_write_next = AWADDR;
                                        Length_Of_Burst_Subordinate_write_next = AWLEN + 1;
                                        Length_Of_Burst_Manager_write_next = AWLEN + 1;
                                        Memory_Aligner_write_next = AWADDR; //Memory Alignment For 8 Bytes
                                        next_state_write = WRITE_PREACCESS_M;
                                    end
                                else 
                                        next_state_write = IDLE_WRITE;  
                           end
                WRITE_PREACCESS_M :  begin
                                    if(WVALID)
                                        next_state_write = WRITE_ACCESS_M;
                                    else 
                                        next_state_write = WRITE_PREACCESS_M;
                                end
                WRITE_ACCESS_M : 
                    begin
                                   if(Length_Of_Burst_Manager_write != 8'd0)
                                        begin
                                            if(WLAST || Length_Of_Burst_Manager_write == 8'd1)
                                                next_state_write = WRITE_TERMINATE;
                                            else 
                                              next_state_write = WRITE_SETUP_S;
                                            WSTRB_axi = WSTRB;
                                            write_fifo_ptr_next = write_fifo_ptr + 1;
                                            if(burst_count <= AWLEN)
                                                burst_count_next = burst_count + 1;
                                                
                                            else 
                                                burst_count_next = 0;  
                                            case(AWBURST)
                                                2'b00: Address_Hold_Reg_write_next = AWADDR;
                                                2'b01: Address_Hold_Reg_write_next = Address_Hold_Reg_write + 4;
                                                2'b10:
                                                    begin
                                                        Address_Hold_Reg_write_next = Address_Hold_Reg_write + 4;
                                                        if(Address_Hold_Reg_write >= AWADDR + AWLEN*4)
                                                            Address_Hold_Reg_write_next = AWADDR;
                                                    end
                                                default : Address_Hold_Reg_write_next = AWADDR;
                                            endcase
                                            Length_Of_Burst_Manager_write_next = Length_Of_Burst_Manager_write - 1; 
                                        end
                                    else 
                                        next_state_write = WRITE_TERMINATE;
                    end
                WRITE_TERMINATE : 
                    begin
                       if(BREADY)
                                begin
                                    write_fifo_ptr_next = 0;
                                    next_state_write = WRITE_SETUP_S;
                                    
                                end
                       else 
                                    next_state_write = WRITE_TERMINATE;
                       end
                WRITE_SETUP_S : begin
                         next_state_write = WRITE_ACCESS_S;
                         PWDATA = write_fifo[write_fifo_ptr_writing];
                         Write_Enabler = 2'b11;
                            end
                WRITE_ACCESS_S : begin
                          if(PREADY)
                            begin
                                    
                              if(Length_Of_Burst_Subordinate_write != 8'd0)
                                begin
                                    if(Length_Of_Burst_Subordinate_write == 8'd1)
                                        next_state_write = IDLE_WRITE;
                                    else 
                                        next_state_write = WRITE_ACCESS_M;
                                    case(AWBURST)
                                           2'b00: Memory_Aligner_write_next = Memory_Aligner_write;
                                           2'b01: Memory_Aligner_write_next = Memory_Aligner_write + 4;
                                           2'b10:
                                                    begin
                                                        Memory_Aligner_write_next = Memory_Aligner_write + 4;
                                                        if(Memory_Aligner_write >= AWADDR + AWLEN*2)
                                                            Memory_Aligner_write_next = AWADDR;
                                                    end                                           
                                        default : Memory_Aligner_write_next = Memory_Aligner_write;
                                    endcase    
                                    WSTRB_apb = WSTRB_axi;
                                    write_fifo_ptr_writing_next = write_fifo_ptr_writing + 1;
                                    Length_Of_Burst_Subordinate_write_next = Length_Of_Burst_Subordinate_write - 1;
                               
                                end
                        end
                      else 
                        next_state_write = WRITE_ACCESS_S;
                    end
                default : next_state_write = IDLE_WRITE;
                endcase
            end 
           
           
           
    always@(ARVALID,current_state_read,RREADY,PREADY)
        begin
            case(current_state_read)
                IDLE_READ : begin
                            RDATA = 0;
                            Read_Enabler = 0;
                            Address_Hold_Reg_read_next = 0;
                            read_fifo_ptr_next = 0;
                            read_fifo_ptr_write_next = 0;
                            Length_Of_Burst_Subordinate_read_next = 0; 
                            Length_Of_Burst_Manager_read_next = 0;                            
                            last = 0;
                            if(ARVALID)
                                begin
                                    next_state_read = READ_SETUP_M;
                                    Read_Enabler = 2'b01; 
                                end
                            else
                                    next_state_read =IDLE_READ;   
                       end                               
                READ_SETUP_M : begin
                        if(ARVALID)
                            begin
                                Address_Hold_Reg_read_next = ARADDR;
                                Length_Of_Burst_Subordinate_read_next = ARLEN + 1; 
                                Length_Of_Burst_Manager_read_next = ARLEN + 1;
                                next_state_read = READ_SETUP_S;
                            end 
                    else 
                      next_state_read = IDLE_READ;                  
                  end
                READ_SETUP_S : 
                    begin
                        if(PREADY)
                            begin

                                next_state_read = READ_ACCESS_S;
                            end 
                        else 
                                next_state_read = READ_SETUP_S;
                    end
                READ_ACCESS_S : 
                   begin
                         if(Length_Of_Burst_Subordinate_read != 8'd0)
                           begin
                            case(ARBURST)
                                    2'b00 : Address_Hold_Reg_read_next      = Address_Hold_Reg_read;
                                    2'b01 : Address_Hold_Reg_read_next      = Address_Hold_Reg_read + 4;
                                    2'b10:
                                        begin
                                              Address_Hold_Reg_read_next = Address_Hold_Reg_read + 4;
                                              if(Address_Hold_Reg_read >= ARADDR + ARLEN*2)
                                                   Address_Hold_Reg_read_next = ARADDR;
                                              end                                    
                                        default : Address_Hold_Reg_read_next    = Address_Hold_Reg_read;
                            endcase
                                   read_fifo_ptr_next = read_fifo_ptr + 1; 
                                Length_Of_Burst_Subordinate_read_next = Length_Of_Burst_Subordinate_read - 1;
                                
                                next_state_read = READ_PREACCESS_M; 
                        end
                     else 
                           next_state_read = READ_ACCESS_M;
                   end
                READ_PREACCESS_M : 
                    begin

                            if(RREADY)
                                begin
                                    next_state_read = READ_ACCESS_M;

                                end    
                            else 
                                begin
                                    next_state_read = READ_PREACCESS_M;
                                end     
                    end
                READ_ACCESS_M : 
                   begin
                         if(Length_Of_Burst_Manager_read != 0)
                            begin
                                if(Length_Of_Burst_Manager_read == 4'd1)
                                    begin
                                        last = 1;
                                        next_state_read = IDLE_READ;
                                    end
                                else 
                                        next_state_read = READ_ACCESS_S;
                                        RDATA = read_fifo[read_fifo_ptr_write];
                                        read_fifo_ptr_write_next = read_fifo_ptr_write + 1;

                                        Length_Of_Burst_Manager_read_next = Length_Of_Burst_Manager_read - 1;
                            end
                        else 
                            next_state_read = IDLE_READ;
                   end
        
                default : next_state_read = IDLE_READ;                                                                                                                                                                                                                                                                
            endcase
        end    
    assign ARREADY = (current_state_read == READ_SETUP_M);
    assign PADDR =  (Write_Enabler[0] || Read_Enabler[0] && (current_state_write == WRITE_ACCESS_S || current_state_write == WRITE_SETUP_S))&&(current_state_read != READ_ACCESS_M) ? Memory_Aligner_write : Address_Hold_Reg_read;
    assign PSEL1 = !last && ( current_state_read == READ_SETUP_S || current_state_read == READ_ACCESS_M || current_state_read == READ_ACCESS_M || current_state_read == READ_ACCESS_S || current_state_write == WRITE_SETUP_S || current_state_write == WRITE_ACCESS_S)?((Address_Hold_Reg_write >= 10'd0 && Address_Hold_Reg_write <= 10'd50) || (Address_Hold_Reg_read >= 10'd0 && Address_Hold_Reg_read <= 10'd50)  ? 1 : 0) : 0;
    assign PSEL2 = !last &&  ( current_state_read == READ_SETUP_S || current_state_read == READ_ACCESS_M || current_state_read == READ_ACCESS_M|| current_state_read == READ_ACCESS_S || current_state_write == WRITE_SETUP_S || current_state_write == WRITE_ACCESS_S)?((Address_Hold_Reg_write >= 10'd51 && Address_Hold_Reg_write <= 10'd100) || (Address_Hold_Reg_read >= 10'd51 && Address_Hold_Reg_read <= 10'd100) ? 1 : 0) : 0;
    assign PSEL3 = !last &&  ( current_state_read == READ_SETUP_S || current_state_read == READ_ACCESS_M || current_state_read == READ_ACCESS_M|| current_state_read == READ_ACCESS_S || current_state_write == WRITE_SETUP_S || current_state_write == WRITE_ACCESS_S)?((Address_Hold_Reg_write >= 10'd101 && Address_Hold_Reg_write <= 10'd150) ||( Address_Hold_Reg_read >= 10'd101 && Address_Hold_Reg_read <= 10'd150) ? 1 : 0) : 0;
    assign PSEL4 = !last &&  ( current_state_read == READ_SETUP_S || current_state_read == READ_ACCESS_M || current_state_read == READ_ACCESS_M|| current_state_read == READ_ACCESS_S || current_state_write == WRITE_SETUP_S || current_state_write == WRITE_ACCESS_S)?((Address_Hold_Reg_write >= 10'd151 && Address_Hold_Reg_write <= 10'd200) || (Address_Hold_Reg_read >= 10'd151 && Address_Hold_Reg_read <= 10'd200) ? 1 : 0) : 0;
    assign PWRITE = (current_state_write == WRITE_ACCESS_S || current_state_write == WRITE_SETUP_S) ? 1:0;
    assign PENABLE = ( current_state_read == READ_ACCESS_S || current_state_write == WRITE_ACCESS_S );
    assign RRESP = last ? 0 : 1;
    assign RLAST = (RRESP && last && RREADY);
    assign RVALID = (current_state_read == READ_ACCESS_M);
    assign AWREADY = (current_state_write == WRITE_SETUP_M);
    assign WREADY = (current_state_write == WRITE_ACCESS_M);
    assign BVALID = (current_state_write == WRITE_TERMINATE);
    assign BRESP = (current_state_write == WRITE_TERMINATE)? 0 : 2'b01;    
endmodule
