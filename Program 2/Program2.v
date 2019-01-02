/*
	Cohort: The Waffle House
	Assignment: Program2.v
	Date: September 28, 2018
	Software: Icarus Verilog 10.1.1 for Windows; Notepad++ for source code editing
	Source: iVerilog retrieved from http://bleyer.org/icarus/
			Notepad++ retrieved from https://notepad-plus-plus.org/
			Add_half, Add_full, & parts of Four_Bit_Adder_Subtractor modules retrieved from HW2 Instructions on eLearning 
*/

/*
	Half-Adder
	XORs a and b int sum
	ANDs a and b into c_out
*/
module Add_half (input a, b,  output c_out, sum);
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
   or (c_out, w1, w3);
endmodule

/*
	Four Bit Adder-Subtractor
	XORs b to complement it if M = 1
	Insantiates full-adders
*/
module Four_Bit_Adder_Subtractor (input [3:0] a, b, input c_in, output c_out, output [3:0] sum);
   wire c_in1, c_in2, c_in3; // Intermediate carries
   wire unsigned [3:0] b2; // Soon to be complement of b (if necessary)
   
   // Complements b if c_in = 1
   xor G3(b2[0], c_in, b[0]);
   xor G4(b2[1], c_in, b[1]);
   xor G5(b2[2], c_in, b[2]);
   xor G6(b2[3], c_in, b[3]);
   
   // Insantiate full adders
   Add_full M0 (a[0], b2[0], c_in,  c_in1, sum[0]);
   Add_full M1 (a[1], b2[1], c_in1, c_in2, sum[1]);
   Add_full M2 (a[2], b2[2], c_in2, c_in3, sum[2]);
   Add_full M3 (a[3], b2[3], c_in3, c_out, sum[3]);
endmodule

/*
	Main Method
		- Initializes 4-Bit A, 4-Bit B, and Mode M
		- Insantiates 4-Bit Adder-Subtractor
		- Tests 4-Bit Adder-Subtractor with varying values of A, B, and M
*/
module Test_Bench;
	// Numbers to add or subtract
	reg unsigned [3:0] A;
	reg unsigned [3:0] B;
	reg M; // Mode (0 = Add, 1 = Subtract)
	
	wire c_out; // Carry bit
	wire unsigned [3:0] sum; // Answer
	
	// Instantiate the four bit adder-subtractor
	Four_Bit_Adder_Subtractor four_bit_adder_subtractor (A, B, M, c_out, sum);
	
	// Sample output
	initial begin
		#5;
		$display("000A  000B  M  000S  000C\n=========================\nBegin");
		$display("%b  %b  %b  %b  %b", A, B, M, sum, c_out);
		$display("=========================\nSet Addition");
		M = 0;
		#5;
		$display("%b  %b  %b  %b  %b", A, B, M, sum, c_out);
		#5;
		A = 10;
		$display("Set A = %d", A);
		$display("%b  %b  %b  %b  %b", A, B, M, sum, c_out);
		#5;
		B = 5;
		$display("Set B = %d", B);
		$display("%b  %b  %b  %b  %b", A, B, M, sum, c_out);
		#5;
		$display("A+B = %d", sum);
		$display("%b  %b  %b  %b  %b", A, B, M, sum, c_out);
		
		#5;
		$display("==========================\nSet Subtraction");
		M = 1;
		#5;
		$display("%b  %b  %b  %b  %b", A, B, M, sum, c_out);
		#5;
		A = 10;
		$display("Set A = %d", A);
		$display("%b  %b  %b  %b  %b", A, B, M, sum, c_out);
		#5;
		B = 3;
		$display("Set B = %d", B);
		$display("%b  %b  %b  %b  %b", A, B, M, sum, c_out);
		#5;
		$display("A-B = %d", sum);
		$display("%b  %b  %b  %b  %b", A, B, M, sum, c_out);
		$display("==========================");
		#5;
		
		$finish;
	end
endmodule