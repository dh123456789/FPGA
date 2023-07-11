module uart_bsp_send(
	input    sys_clk 		,
	input    sys_rst_n		,
	input    uart_en 		,
	input  [7:0]  uart_din 		,
	input  [2:0]  bsp_set 		,
	
	output  reg   tx_flag		,   //���͹��̱�־�ź�
    output  reg   uart_txd
);



reg	 [15:0] BPS_CNT	;
wire       en_flag;
reg        uart_en_d0; 
reg        uart_en_d1;  
reg [15:0] clk_cnt;                         //ϵͳʱ�Ӽ�����   
reg [ 3:0] tx_cnt;                          //�������ݼ�����              
reg [ 7:0] tx_data;                         //�Ĵ淢������



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

//����uart_en�����أ��õ�һ��ʱ�����ڵ������ź�
assign en_flag = (~uart_en_d1) & uart_en_d0;
                                                 
//�Է���ʹ���ź�uart_en�ӳ�����ʱ������
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

//�������ź�en_flag����ʱ,�Ĵ�����͵����ݣ������뷢�͹���          
always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n) begin                                  
        tx_flag <= 1'b0;
        tx_data <= 8'd0;
    end 
    else if (en_flag) begin                 //��⵽����ʹ��������                      
            tx_flag <= 1'b1;                //���뷢�͹��̣���־λtx_flag����
            tx_data <= uart_din;            //�Ĵ�����͵�����
        end
        else if ((tx_cnt == 4'd9)&&(clk_cnt == BPS_CNT/2))begin    
            tx_flag <= 1'b0;  //������ֹͣλ�м�ʱ��ֹͣ���͹���              
            tx_data <= 8'd0;//���͹��̽�������־λtx_flag����
        end
        else begin
            tx_flag <= tx_flag;
            tx_data <= tx_data;
        end 
end

//���뷢�͹��̺�����ϵͳʱ�Ӽ������뷢�����ݼ�����
always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n) begin                             
        clk_cnt <= 16'd0;                                  
        tx_cnt  <= 4'd0;
    end                                                      
    else if (tx_flag) begin                 //���ڷ��͹���
        if (clk_cnt < BPS_CNT) begin
            clk_cnt <= clk_cnt + 1'b1;
            tx_cnt  <= tx_cnt;
        end
        else begin
            clk_cnt <= 16'd0;               //��ϵͳʱ�Ӽ�����һ�����������ں�����
            tx_cnt  <= tx_cnt + 1'b1;       //��ʱ�������ݼ�������1
        end
    end
    else begin                              //���͹��̽���
        clk_cnt <= 16'd0;
        tx_cnt  <= 4'd0;
    end
end

//���ݷ������ݼ���������uart���Ͷ˿ڸ�ֵ
always @(posedge sys_clk or negedge sys_rst_n) begin        
    if (!sys_rst_n)  
        uart_txd <= 1'b1;        
    else if (tx_flag)
        case(tx_cnt)
            4'd0: uart_txd <= 1'b0;         //��ʼλ 
            4'd1: uart_txd <= tx_data[0];   //����λ���λ
            4'd2: uart_txd <= tx_data[1];
            4'd3: uart_txd <= tx_data[2];
            4'd4: uart_txd <= tx_data[3];
            4'd5: uart_txd <= tx_data[4];
            4'd6: uart_txd <= tx_data[5];
            4'd7: uart_txd <= tx_data[6];
            4'd8: uart_txd <= tx_data[7];   //����λ���λ
            4'd9: uart_txd <= 1'b1;         //ֹͣλ
            default: ;
        endcase
    else 
        uart_txd <= 1'b1;                   //����ʱ���Ͷ˿�Ϊ�ߵ�ƽ
end



endmodule
