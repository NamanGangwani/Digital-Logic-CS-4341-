/*
	Cohort: The Waffle House
	Assignment: ALU.v
	Date: November 16, 2018
	Software: Icarus Verilog 10.1.1 for Windows; Notepad++ for source code editing
	Source: iVerilog retrieved from http://bleyer.org/icarus/
			Notepad++ retrieved from https://notepad-plus-plus.org/
*/


//=============================================
// ALU Opcodes
//=============================================
`define ADD 			3'b000
`define SUB 			3'b001
`define SHIFT_LEFT 		3'b010
`define SHIFT_RIGHT 	3'b011
`define AND 			3'b100
`define OR	 			3'b101
`define XOR		 		3'b110
`define NOT	 			3'b111

/*
	Takes input values of x and y
	to save xy into xandy
*/
module AndGate(input x,y, output reg xANDy);
	always @(*) begin
		xANDy <= x & y;
	end
endmodule

/*
	D Flip-Flop (1-bit)
		- Sets Q equal to D on the positive edge of clk
*/
module D_Flip_Flop_1(input clk, D, output reg Q);
	always @(posedge clk)
		Q <= D;
endmodule

/*
	D Flip-Flop (8-bit)
		- Sets Q equal to D on the positive edge of clk
*/
module D_Flip_Flop_8(input clk, input [7:0] D, output reg [7:0] Q);
	always @(posedge clk)
		Q <= D;
endmodule

/*
	Half-Adder
	XORs a and b int sum
	ANDs a and b into c_out
*/
module Add_half (input a, b, output c_out, sum);
   xor G1(sum, a, b);
   and G2(c_out, a, b);
endmodule

/*
	Full-Adder
	Insantiates half-adders
*/
module Add_full (input a, b, c_in, output c_out, sum);	// See Fig. 4.8
   wire w1, w2, w3;				// w1 is c_out; w2 is sum
   Add_half M1 (a, b, w1, w2);
   Add_half M0 (w2, c_in, w3, sum);
   or G1(c_out, w1, w3);
endmodule

/*
	Four Bit Adder-Subtractor
	Insantiates full-adders
*/
module Four_Bit_Adder_Subtractor (input [3:0] a, b, input c_in, output c_out, output [3:0] sum);
   wire c_in1, c_in2, c_in3; // Intermediate carries
   
   // Insantiate full adders
   Add_full M0 (a[0], b[0], c_in,  c_in1, sum[0]); 
   Add_full M1 (a[1], b[1], c_in1, c_in2, sum[1]);
   Add_full M2 (a[2], b[2], c_in2, c_in3, sum[2]);
   Add_full M3 (a[3], b[3], c_in3, c_out, sum[3]);
endmodule

/*
	Eight Bit Adder-Subtractor
	Complement B if M = 1
	Insantiates four bit adder-subtractors
*/
module Eight_Bit_Adder_Subtractor (input [7:0] a, b, input c_in, output wire c_out, output wire [7:0] sum);
	wire c_in4;
	wire unsigned [7:0] b2 = c_in == 1'b1 ? ~b: b; // Complements b if c_in = 1

   // Instantiate four bit adder-subtractors
   Four_Bit_Adder_Subtractor M0(a[3:0], b2[3:0], c_in, c_in4, sum[3:0]);
   Four_Bit_Adder_Subtractor M1(a[7:4], b2[7:4], c_in4, c_out, sum[7:4]);
endmodule

/*
	Mux (2:1)
		- Outputs the selected input based on the selector bit
*/
module Mux2(input [7:0] in0, in1, input s, output reg [7:0] out);
	always@(*) begin
		if (s == 1'b0)
			out <= in0;
		else
			out <= in1;
		//$display("%d", out);
	end
endmodule

/*
	Mux (10:1)
		- Outputs the selected input based on the selector bits
*/
module Mux10(input [7:0] in0, in1, in2, in3, in4, in5, in6, in7, in8, in9, input [9:0] s, output reg [7:0] out);
	parameter n = 10;
	always @(*) begin
		out <= (s[0] ? in1:
			   (s[1] ? in2: 
			   (s[2] ? in3:
			   (s[3] ? in4:
			   (s[4] ? in5: 
               (s[5] ? in6:
               (s[6] ? in7:
               (s[7] ? in8: 
			   (s[8] ? in0:
               (s[9] ? in9: 
					   8'b00000000))))))))));
		//$display("selected: %b", s);
	end
endmodule

/*
	Selector Unit
		- Selects the next state to go to based on the values of rst, error, and opcode
		- Returns a 1-hot value
*/
module Selector(input [2:0] opcode, input rst, error, output reg [9:0] out);
	always@(*) begin
			out <=  (rst 					? 10'b0100000000:
					(error 					? (opcode == `ADD ? 
											  10'b0000000001: 
											  10'b0000000010):
					(opcode == `ADD 		? 10'b0000000001:
					(opcode == `SUB 		? 10'b0000000010:
					(opcode == `SHIFT_LEFT  ? 10'b0000000100:
					(opcode == `SHIFT_RIGHT ? 10'b0000001000:
					(opcode == `AND			? 10'b0000010000:
					(opcode == `OR		    ? 10'b0000100000:
					(opcode == `XOR			? 10'b0001000000:
					(opcode == `NOT			? 10'b0010000000: 
											  10'b0000000000))))))))));
		//$display("selector: %b", out);
	end
endmodule

/*
	Arithmetic Logic Unit
		- Returns the result of the operations based on the values of the integers, 
		  accumulator register, and opcode
*/
module ALU(input clk, rst, input [7:0] int1, int2, input [2:0] opcode, output [7:0] out, output reg status);
	parameter l = 8;
	
	wire [l-1:0] next_state;
	wire first_operation_done, last_output, error;
	wire [l-1:0] one;
	
	// Checks to see if the first operation has been done after being reset
	D_Flip_Flop_1 dff_1(clk, ~rst, first_operation_done);
	// If last_output = 0, it will signal to select original input;
	// If last_output = 1, it will signal to select the last output
	AndGate and1((^first_operation_done === 1'bx ? 1'b0: first_operation_done), ~rst, last_output);
	// Sets the next state's value equal to the current state at the positive edge of clk
	D_Flip_Flop_8 dff_8(clk, next_state, out);
	
	// Decide between int1 and the last output based on whether there has been at least one operation done
	Mux2 in(int1, out, last_output, one);
	
	wire unsigned [l-1:0] add, sub;
	wire unsigned carry_out_add, carry_out_sub;
	reg M0 = 0;
	reg M1 = 1;
	
	// Sets the values of the add and subtract value based on the mode
	// Retrieves their carry-out values
	Eight_Bit_Adder_Subtractor adder(one, int2, M0, carry_out_add, add);
	Eight_Bit_Adder_Subtractor subtractor(one, int2, M1, carry_out_sub, sub);
	
	// Computes the values for the rest of the states
	wire [l-1:0] sl = one << 1;
	wire [l-1:0] sr = one >> 1;
	wire [l-1:0] _and = one & int2;
	wire [l-1:0] _or = one | int2;
	wire [l-1:0] _xor = one ^ int2;
	wire [l-1:0] _not = ~one;
	
	// Determines one hot select based on the values of the opcode, rst, and error state
	wire [9:0] s;
	Selector select(opcode, rst, error, s);
	
	// Selects the next state based on the value of the opcode
	Mux10 nextState(8'b00000000, add, sub, sl, sr, _and, _or, _xor, _not, out, s, next_state);
	
	assign error =  ((opcode == `ADD && carry_out_add == 1'b1) ? carry_out_add:
					 (opcode == `SUB && carry_out_sub == 1'b1) ? carry_out_sub: 1'b0);
	//assign status = ((opcode == `ADD || opcode == `SUB) ? error: 1'b0);
	
	//*
	always @(posedge clk) begin
		status <= error;
		//$monitor("%b %b %b %b %b %b %b", clk, rst, int1, int2, first_operation_done, last_output, opcode);
		//$monitor("%b one: %b two: %b %b %b", last_output, one, int2, sub, carry_out_sub);
		//$monitor("%b %b %b %b %b %b %b %b %b %b %b\n", add, sub, sl, sr, _and, _or, _xor, _not, out, s, out);
	end
	/**/
endmodule

/*
	Main Method
		- Initializes 8-Bit int1, 8-Bit int2, clk, rst
		- Tests major features of the ALU by sending in integers and an opcode and
		  receiving an output and status
*/
module Test_Bench;
	parameter l = 8;
	reg clk, rst;
	reg unsigned [l-1:0] int1, int2;
	reg [2:0] opcode;
	wire [l-1:0] out;
	wire status;
	
	// Instantiate the ALU
	ALU alu(clk, rst, int1, int2, opcode, out, status);
	
	initial begin
		$display("|   Integer1  |   Integer2  |   OpCode |    Output    |       Status       |");
		rst = 0; clk = 0;
		#5 rst = 1; #5 clk = 1; #5 clk = 0; rst = 0; $display(" ( RESET) Output: %b (%d)", out, out);
		#5 int1 = 10; int2 = 1; opcode = `ADD;
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "ADD", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "ADD", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "ADD", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "ADD", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		
		#5 rst = 1; #5 clk = 1; #5 clk = 0; rst = 0; $display(" ( RESET) Output: %b (%d)", out, out);
		#5 int1 = 20; int2 = 5; opcode = `SUB;
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "SUB", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "SUB", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "SUB", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "SUB", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		
		#5 rst = 1; #5 clk = 1; #5 clk = 0; rst = 0; $display(" ( RESET) Output: %b (%d)", out, out);
		#5; int1 = 10; int2 = 1; opcode = `SHIFT_LEFT;
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "SL", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "SL", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "SL", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "SL", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		
		#5 rst = 1; #5 clk = 1; #5 clk = 0; rst = 0; $display(" ( RESET) Output: %b (%d)", out, out);
		#5; int1 = 20; int2 = 1; opcode = `SHIFT_RIGHT;
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "SR", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "SR", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "SR", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "SR", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		
		#5 rst = 1; #5 clk = 1; #5 clk = 0; rst = 0; $display(" ( RESET) Output: %b (%d)", out, out);
		#5; int1 = 20; int2 = 15; opcode = `AND;
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "AND", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "AND", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "AND", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "AND", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		
		#5 rst = 1; #5 clk = 1; #5 clk = 0; rst = 0; $display(" ( RESET) Output: %b (%d)", out, out);
		#5; int1 = 20; int2 = 15; opcode = `OR;
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "OR", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "OR", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "OR", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "OR", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		
		#5 rst = 1; #5 clk = 1; #5 clk = 0; rst = 0; $display(" ( RESET) Output: %b (%d)", out, out);
		#5; int1 = 20; int2 = 15; opcode = `XOR;
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "XOR", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "XOR", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "XOR", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "XOR", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		
		rst = 0; clk = 0;
		#5 rst = 1; #5 clk = 1; #5 clk = 0; rst = 0; $display(" ( RESET) Output: %b (%d)", out, out);
		#5 int1 = 220; int2 = 10; opcode = `ADD;
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "ADD", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "ADD", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "ADD", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "ADD", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		
		$display(" WITHOUT RESETTING...");
		opcode = `SUB;
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "SUB", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "SUB", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "SUB", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		#5 clk = 1; #5; clk = 0; 
		$display("%b (%d)|%b (%d)|%b (%s)|%b (%d)| %0s", int1, int1, int2, int2, opcode, "SUB", out, out, status == 1'b0 ? "Done" : "Carry-Over Warning");
		$finish;
	end
endmodule