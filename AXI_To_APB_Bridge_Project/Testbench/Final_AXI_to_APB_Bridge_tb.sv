`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/14/2024 07:53:02 PM
// Design Name: 
// Module Name: Final_AXI_to_APB_Bridge_tb
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


module Final_AXI_to_APB_Bridge_tb();

  // Parameters for the AXI and APB interface
  parameter AXI_ADDR_WIDTH = 32;
  parameter AXI_DATA_WIDTH = 32;
  parameter AXI_MAX_BURST_LEN = 8;
  parameter AXI_BURST_WIDTH = 2;
  parameter AXI_SIZE_WIDTH = 2;
  parameter APB_ADDR_WIDTH = 32;
  parameter APB_DATA_WIDTH = 32;

  // AXI interface signals
  logic [AXI_ADDR_WIDTH-1:0] AWADDR;
  logic [AXI_BURST_WIDTH-1:0] AWBURST;
  logic [AXI_MAX_BURST_LEN-1:0] AWLEN;
  logic AWVALID;
  logic AWREADY;

  logic [AXI_ADDR_WIDTH-1:0] ARADDR;
  logic [AXI_BURST_WIDTH-1:0] ARBURST;
  logic [AXI_MAX_BURST_LEN-1:0] ARLEN;
  logic ARVALID;
  logic ARREADY;

  logic [AXI_DATA_WIDTH-1:0] WDATA;
  logic [AXI_DATA_WIDTH/8 - 1 :0] WSTRB;
  logic WVALID;
  logic WLAST;
  logic WREADY;

  logic [AXI_DATA_WIDTH-1:0] RDATA;
  logic [1:0] RRESP;
  logic RVALID;
  logic RLAST;
  logic RREADY;

  logic [1:0] BRESP;
  logic BVALID;
  logic BREADY;

  // APB interface signals
  logic [APB_ADDR_WIDTH-1:0] PADDR;
  logic PWRITE;
  logic PSEL1, PSEL2, PSEL3, PSEL4;
  logic PENABLE;
  logic [APB_DATA_WIDTH-1:0] PWDATA;
  logic [APB_DATA_WIDTH-1:0] PRDATA;
  logic PREADY;

  // Control signals
  logic ACLK;
  logic ARESETn;
  int j;  
  // Clock and Reset Generation
  always begin
    ACLK = ~ACLK;
    #5; // 10ns clock period
  end

  initial begin
    ACLK = 0;
    ARESETn = 0;
  end

  // Instantiate the AXI to APB Bridge
  Final_AXI_to_APB_Bridge #(
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .AXI_MAX_BURST_LEN(AXI_MAX_BURST_LEN),
    .AXI_BURST_WIDTH(AXI_BURST_WIDTH),
    .AXI_SIZE_WIDTH(AXI_SIZE_WIDTH),
    .APB_ADDR_WIDTH(APB_ADDR_WIDTH),
    .APB_DATA_WIDTH(APB_DATA_WIDTH)
  ) uut (
    // AXI interface
    .AWADDR(AWADDR),
    .AWBURST(AWBURST),
    .AWLEN(AWLEN),
    .AWVALID(AWVALID),
    .AWREADY(AWREADY),
    .ARADDR(ARADDR),
    .ARBURST(ARBURST),
    .ARLEN(ARLEN),
    .ARVALID(ARVALID),
    .ARREADY(ARREADY),
    .WDATA(WDATA),
    .WVALID(WVALID),
    .WLAST(WLAST),
    .WREADY(WREADY),
    .RDATA(RDATA),
    .RRESP(RRESP),
    .RVALID(RVALID),
    .RLAST(RLAST),
    .RREADY(RREADY),
    .BRESP(BRESP),
    .BVALID(BVALID),
    .WSTRB(WSTRB),
    .BREADY(BREADY),
    
    // APB interface
    .PADDR(PADDR),
    .PWRITE(PWRITE),
    .PSEL1(PSEL1),
    .PSEL2(PSEL2),
    .PSEL3(PSEL3),
    .PSEL4(PSEL4),
    .PENABLE(PENABLE),
    .PWDATA(PWDATA),
    .PRDATA(PRDATA),
    .PREADY(PREADY),

    // Control signals
    .ACLK(ACLK),
    .ARESETn(ARESETn)
  );     
    
initial 
  begin
    ARVALID = 0;
    ARBURST = 2'b00;
    ARLEN = 0;
    ARADDR = 0;
    RREADY = 0;
    PRDATA = 0; 
    PREADY = 0;
    AWVALID = 0;
    AWBURST = 2'b00; 
    AWLEN =8'b00000000; 
    AWADDR = 5'd0;
    WVALID = 0;
    WDATA = 0;
    WLAST = 0;
    WSTRB = 0;
    BREADY = 0; 
    #10 ARESETn = 1;
   
   // Add Monitor to Observe Key Signals
    $monitor("Time=%0t | ACLK=%b | AWADDR=%h | WDATA=%h | AWBURST=%b | AWLEN=%d | WLAST=%b | ARADDR=%h | RDATA=%h | PADDR=%h | PRDATA=%h | PWRITE=%b | PENABLE=%b | PREADY=%b", 
             $time, ACLK, AWADDR, WDATA, AWBURST, AWLEN, WLAST, ARADDR, RDATA, PADDR, PRDATA, PWRITE, PENABLE, PREADY);

    /*****************************************************************************************************/
    // Single Write Transaction 
    $display("Single Write Transaction Started");
    /*****************************************************************************************************/
    
    
    #10;
    #10 AWVALID = 1;AWBURST = 2'b00; AWLEN =8'd0; AWADDR = 5'd9; 
    #30  AWVALID = 0; 
  WVALID = 1; BREADY = 1; 
      //  WDATA = 32'd10;
    for (j = 0; j <= AWLEN; j++)
        begin
            WDATA = 32'hABABCDCD;
            #25 PREADY = 1;
            WVALID = 0;
        end
        WDATA = 0;
    //////Putting Response Channel
      #5 BREADY = 0;
    #15 PREADY = 0;
    $display("Single Write Transaction Ended");
    #10 ARESETn = 0;
    #10 ARESETn = 1;
    
    
        /*****************************************************************************************************/
    // Single Write Transaction 
    $display("Single Read Transaction Started");
    /*****************************************************************************************************/
    
    
    #10;
    #10 ARVALID = 1;ARBURST = 2'b00; ARLEN =8'd0; ARADDR = 5'd9; 
    #20  ARVALID = 0; 
      //  WDATA = 32'd10;
    #5;  
    for (j = 0; j <= ARLEN; j++)
        begin
            PRDATA = 32'hABABCDCD;  PREADY = 1;
            #20 RREADY = 1;
        end
    //////Putting Response Channel
    PREADY = 0;
    #10 RREADY = 0;
    $display("Single Read Transaction Ended");
     ARESETn = 0;
    #10 ARESETn = 1;
    
    
    $display("Fixed Burst Write Transaction Started");
    /*****************************************************************************************************/
    
    
    #10;
    #10 AWVALID = 1;AWBURST = 2'b00; AWLEN =8'd7; AWADDR = 5'd9; 
    #30  AWVALID = 0; 
  WVALID = 1; BREADY = 1; 
    for (j = 0; j <= AWLEN; j++)
        begin
            WDATA = j + 1;
            #30 PREADY = 1;
        if(j == AWLEN - 1)
            begin
                 WLAST =  1;
            end  
        end
        WDATA = 0; WVALID = 0; WLAST =  0;
  
    //////Putting Response Channel
      #5 BREADY = 0;
    #15 PREADY = 0;
    $display("Fixed Burst Write Transaction Ended");
     ARESETn = 0;
    #10 ARESETn = 1; 
    
    
        $display("Incrementing Burst Write Transaction Started");
    /*****************************************************************************************************/

    
    #10;
    #10 AWVALID = 1;AWBURST = 2'b01; AWLEN =8'd7; AWADDR = 5'd9; 
    #30  AWVALID = 0; 
  WVALID = 1; BREADY = 1; 
    for (j = 0; j <= AWLEN; j++)
        begin
            WDATA = j + 1;
            #30 PREADY = 1;
        if(j == AWLEN - 1)
            begin
                 WLAST =  1;
            end  
        end
        WDATA = 0; WVALID = 0; WLAST =  0;
  
    //////Putting Response Channel
      #5 BREADY = 0;
    #15 PREADY = 0;
    $display("Incrementing Burst Write Transaction Ended");
     ARESETn = 0;
    #10 ARESETn = 1;   
    
            $display("Wrapping Burst Write Transaction Started");
    /*****************************************************************************************************/
    
    
    #10;
    #10 AWVALID = 1;AWBURST = 2'b10; AWLEN =8'd10; AWADDR = 5'd9; 
    #30  AWVALID = 0; 
  WVALID = 1; BREADY = 1; 
    for (j = 0; j <= AWLEN; j++)
        begin
            WDATA = j + 1;
            #30 PREADY = 1;
        if(j == AWLEN - 1)
            begin
                 WLAST =  1;
            end  
        end
        WDATA = 0; WVALID = 0; WLAST =  0;
  
    //////Putting Response Channel
      #5 BREADY = 0;
    #15 PREADY = 0;
    $display("Wrapping Burst Write Transaction Ended");
     ARESETn = 0;
    #10 ARESETn = 1;  
    
     $display("Fixed Burst Read Transaction Started");
       #10;
    #10 ARVALID = 1;ARBURST = 2'b00; ARLEN =8'd7; ARADDR = 5'd9; 
    #20  ARVALID = 0; 
    #5;  
    for (j = 0; j <= ARLEN; j++)
        begin
            #10
            PRDATA = j + 1;   PREADY = 1;
            #20 RREADY = 1;
        end
    //////Putting Response Channel
    PREADY = 0;
    #10 RREADY = 0;
    $display("Fixed Burst Read Transaction Ended");
     ARESETn = 0;
    #10 ARESETn = 1; 
    
    
    
    $display("Incrementing Burst Read Transaction Started");
    #10;
    #10 ARVALID = 1;ARBURST = 2'b01; ARLEN =8'd7; ARADDR = 5'd9; 
    #20  ARVALID = 0; 
    #5;  
    for (j = 0; j <= ARLEN; j++)
        begin
            #10  PREADY = 1;
            PRDATA = j + 1;  
            #20 RREADY = 1;
        end
    //////Putting Response Channel
    PREADY = 0;
    #10 RREADY = 0;
    $display("Incrementing Burst Read Transaction Ended");
     ARESETn = 0;
    #10 ARESETn = 1; 
    
    
     $display("Wrapping Burst Read Transaction Started");
    #10;
    #10 ARVALID = 1;ARBURST = 2'b10; ARLEN =8'd11; ARADDR = 5'd9; 
    #20  ARVALID = 0; 
    #5;  
    for (j = 0; j <= ARLEN; j++)
        begin
            #10  PREADY = 1;
            PRDATA = j + 1;  
            #20 RREADY = 1;
        end
    //////Putting Response Channel
    PREADY = 0;
    #10 RREADY = 0;
    $display("Wrapping Burst Read Transaction Ended");
     ARESETn = 0;
    #10 ARESETn = 1; 
    
    $display("Corner Cases : Simultaneous Read and Write by Providing the different address for Both Read and Write (That is different slaves): So it Shoud read and write independently");
    
    /////// Putting the Address and Burst Configuration in AWChannel
    #10 AWVALID = 1;AWBURST = 2'b01; AWLEN =8'd6; AWADDR = 5'd9; BREADY = 1; ARVALID = 1;ARBURST = 2'b01; ARLEN =8'd6; ARADDR = 8'd58; //RREADY = 1; 
    #10  
    #30  AWVALID = 0; ARVALID = 0;
    #5 
    //////Putting the Data Configuration for writing
    #5 WVALID = 1; //PREADY = 1;
    for (j = 0; j <= AWLEN; j++)
        begin
            WDATA = j + 1; PREADY = 1;
            PRDATA = j + 2;
            WSTRB = j;
            #30 PREADY = 1; RREADY = 1;
        end
    if(j == AWLEN + 1)
        begin
             WLAST =  1;
        end 
        WSTRB = 0;
            
    #20 WLAST = 1'd0;
    
    //////Putting Response Channel
     #5 BREADY = 0;

    /////////////////////////Its Time to put Burst Data into APB Master Interace
    

  PREADY = 0;
    ARESETn = 0;
    #10 ARESETn = 1;  
    
    
    
    $display("Corner Cases : Sequentially Write and Read by Providing the different address for Both Read and Write and providing the AWVALID and ARVALID at the same time: So it Shoud write first and then read based on arbiter state logic");

    #10 AWVALID = 1;AWBURST = 2'b01; AWLEN =8'd6; AWADDR = 5'd9; BREADY = 1; ARVALID = 1;ARBURST = 2'b01; ARLEN =8'd6; ARADDR = 8'd38; //RREADY = 1; 
    #10  ARVALID = 0;
    #30  AWVALID = 0; 
    #5 
    //////Putting the Data Configuration for writing
    #5 WVALID = 1; 
    for (j = 0; j <= AWLEN; j++)
        begin
            WDATA = j + 1; PREADY = 1;
            PRDATA = j + 2;
            WSTRB = j;
            #30 PREADY = 1; RREADY = 1;
        end
    if(j == AWLEN + 1)
        begin
             WLAST =  1;
        end 
        WSTRB = 0;
            
    #20 WLAST = 1'd0;
    
    //////Putting Response Channel
     #5 BREADY = 0;

    /////////////////////////Its Time to put Burst Data into APB Master Interace
    

  PREADY = 0;
  
  
  
  #35
      #10 AWVALID = 1;AWBURST = 2'b01; AWLEN =8'd6; AWADDR = 5'd9; BREADY = 1; ARVALID = 1;ARBURST = 2'b01; ARLEN =8'd6; ARADDR = 8'd47; //RREADY = 1; 
    #10  AWVALID = 0;
    #30  ARVALID = 0; 
    #5 
    //////Putting the Data Configuration for writing
    #5 WVALID = 1; //PREADY = 1;
    for (j = 0; j <= AWLEN; j++)
        begin
            WDATA = j + 1; PREADY = 1;
            PRDATA = j + 2;
            WSTRB = j;
            #30 PREADY = 1; RREADY = 1;
        end
    if(j == AWLEN + 1)
        begin
             WLAST =  1;
        end 
        WSTRB = 0;
            
    #20 WLAST = 1'd0;
    
    //////Putting Response Channel
     #5 BREADY = 0;

    /////////////////////////Its Time to put Burst Data into APB Master Interace
    

  PREADY = 0;
    ARESETn = 0;
    #10 ARESETn = 1;     
    
    
    $display("Corner Cases : Sequentially Write and Read by Providing the same address for Both Read and Write and providing the AWVALID and ARVALID at the same time: So it Shoud write first and then read based on arbiter state logic");
    #10 AWVALID = 1;AWBURST = 2'b01; AWLEN =8'd6; AWADDR = 5'd9; BREADY = 1; ARVALID = 1;ARBURST = 2'b01; ARLEN =8'd6; ARADDR = 8'd9; //RREADY = 1; 
    #10  ARVALID = 0;
    #30  AWVALID = 0; 
    #5 
    //////Putting the Data Configuration for writing
    #5 WVALID = 1; //PREADY = 1;
    for (j = 0; j <= AWLEN; j++)
        begin
            WDATA = j + 1; PREADY = 1;
            PRDATA = j + 2;
            WSTRB = j;
            #30 PREADY = 1; RREADY = 1;
        end
    if(j == AWLEN + 1)
        begin
             WLAST =  1;
        end 
        WSTRB = 0;
            
    #20 WLAST = 1'd0;
    
    //////Putting Response Channel
     #5 BREADY = 0;

    /////////////////////////Its Time to put Burst Data into APB Master Interace
    

  PREADY = 0;
  
  #20
      #10 AWVALID = 1;AWBURST = 2'b01; AWLEN =8'd6; AWADDR = 5'd9; BREADY = 1; ARVALID = 1;ARBURST = 2'b01; ARLEN =8'd6; ARADDR = 8'd9; //RREADY = 1; 
    #10  AWVALID = 0;
    #30  ARVALID = 0; 
    #5 
    //////Putting the Data Configuration for writing
    #5 WVALID = 1; //PREADY = 1;
    for (j = 0; j <= AWLEN; j++)
        begin
            WDATA = j + 1; PREADY = 1;
            PRDATA = j + 2;
            WSTRB = j;
            #30 PREADY = 1; RREADY = 1;
        end
    if(j == AWLEN + 1)
        begin
             WLAST =  1;
        end 
        WSTRB = 0;
            
    #20 WLAST = 1'd0;
    
    //////Putting Response Channel
     #5 BREADY = 0;

    /////////////////////////Its Time to put Burst Data into APB Master Interace
    

  PREADY = 0;
  RREADY = 0;
    ARESETn = 0;
    #10 ARESETn = 1; 
    $finish;
    
  end
endmodule