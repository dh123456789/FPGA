module uart_bsp_send(
	input    sys_clk 		,
	input    sys_rst_n		,
	input    uart_en 		,
	input  [7:0]  uart_din 		,
	input  [2:0]  bsp_set 		,
	
	output  reg   tx_flag		,   //发送过程标志信号
    output  reg   uart_txd
);



reg	 [15:0] BPS_CNT	;
wire       en_flag;
reg        uart_en_d0; 
reg        uart_en_d1;  
reg [15:0] clk_cnt;                         //系统时钟计数器   
reg [ 3:0] tx_cnt;                          //发送数据计数器              
reg [ 7:0] tx_data;                         //寄存发送数据



always@(posedge sys_clk or posedge sys_rst_n)
	if(!sys_rst_n)
		BPS_CNT <= 16'd5207;
	else begin
		case(bsp_set)
			0:BPS_CNT <= 16'd5207;		//9600    50000000/9600-1
			1:BPS_CNT <= 16'd2603;		//19200
			2:BPS_CNT <= 16'd1301;		//38400
			3:BPS_CNT <= 16'd867;		//57600
			4:BPS_CNT <= 16'd433;		//115200
			default:BPS_CNT <= 16'd5207;
		endcase
end

//捕获uart_en上升沿，得到一个时钟周期的脉冲信号
assign en_flag = (~uart_en_d1) & uart_en_d0;
                                                 
//对发送使能信号uart_en延迟两个时钟周期
always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n) begin
        uart_en_d0 <= 1'b0;                                  
        uart_en_d1 <= 1'b0;
    end                                                      
    else begin                                               
        uart_en_d0 <= uart_en;                               
        uart_en_d1 <= uart_en_d0;                            
    end
end

//当脉冲信号en_flag到达时,寄存待发送的数据，并进入发送过程          
always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n) begin                                  
        tx_flag <= 1'b0;
        tx_data <= 8'd0;
    end 
    else if (en_flag) begin                 //检测到发送使能上升沿                      
            tx_flag <= 1'b1;                //进入发送过程，标志位tx_flag拉高
            tx_data <= uart_din;            //寄存待发送的数据
        end
        else if ((tx_cnt == 4'd9)&&(clk_cnt == BPS_CNT/2))begin    
            tx_flag <= 1'b0;  //计数到停止位中间时，停止发送过程              
            tx_data <= 8'd0;//发送过程结束，标志位tx_flag拉低
        end
        else begin
            tx_flag <= tx_flag;
            tx_data <= tx_data;
        end 
end

//进入发送过程后，启动系统时钟计数器与发送数据计数器
always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n) begin                             
        clk_cnt <= 16'd0;                                  
        tx_cnt  <= 4'd0;
    end                                                      
    else if (tx_flag) begin                 //处于发送过程
        if (clk_cnt < BPS_CNT) begin
            clk_cnt <= clk_cnt + 1'b1;
            tx_cnt  <= tx_cnt;
        end
        else begin
            clk_cnt <= 16'd0;               //对系统时钟计数达一个波特率周期后清零
            tx_cnt  <= tx_cnt + 1'b1;       //此时发送数据计数器加1
        end
    end
    else begin                              //发送过程结束
        clk_cnt <= 16'd0;
        tx_cnt  <= 4'd0;
    end
end

//根据发送数据计数器来给uart发送端口赋值
always @(posedge sys_clk or negedge sys_rst_n) begin        
    if (!sys_rst_n)  
        uart_txd <= 1'b1;        
    else if (tx_flag)
        case(tx_cnt)
            4'd0: uart_txd <= 1'b0;         //起始位 
            4'd1: uart_txd <= tx_data[0];   //数据位最低位
            4'd2: uart_txd <= tx_data[1];
            4'd3: uart_txd <= tx_data[2];
            4'd4: uart_txd <= tx_data[3];
            4'd5: uart_txd <= tx_data[4];
            4'd6: uart_txd <= tx_data[5];
            4'd7: uart_txd <= tx_data[6];
            4'd8: uart_txd <= tx_data[7];   //数据位最高位
            4'd9: uart_txd <= 1'b1;         //停止位
            default: ;
        endcase
    else 
        uart_txd <= 1'b1;                   //空闲时发送端口为高电平
end



endmodule
