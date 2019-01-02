/*
	Cohort: The Waffle House Group
	Assignment: Program1.v
	Date: September 7, 2018
	Software: Icarus Verilog 10.1.1 for Windows; Notepad++ for source code editing
	Source: iVerilog retrieved from http://bleyer.org/icarus/
			Notepad++ retrieved from https://notepad-plus-plus.org/
			SimpleOr, SimpleAnd, and SimpleNot modules retrieved from funXOR.v file example on eLearning
*/

/*
	Takes input values of x and y
	to save (x + y) into xory
*/
module SimpleOr(x,y,xory);
	input x;
	input y;
	output xory;
	reg xory;
	always @(*) 
	begin
		xory= x | y ;
	end
endmodule

/*
	Takes input values of x and y
	to save xy into xandy
*/
module SimpleAnd(x,y,xandy);
	input x;
	input y;
	output xandy;
	reg xandy;
	always @(*) begin
	xandy= x & y;
	end
endmodule

/*
	Takes input value of x
	to save x' into notx
*/
module SimpleNot(x,notx);
	input x;
	output notx;
	reg notx;
	
	always @(*) begin
	notx= !x;
	end
endmodule

/*
	Simulates circuit: 
		Out_1=(A+B’)C’(C+D)
*/
module Out_1(A, B, C, D, out);
	// Inputs and output
	input A;
	input B;
	input C;
	input D;
	output out;
	reg out;
	
	// Appropriate wires
	wire bNot;
	wire cNot;
	wire aOrBnot;
	wire cOrD;
	wire t1;
	wire t2;
	
	// Not values
	SimpleNot not1(B, bNot);
	SimpleNot not2(C, cNot);
	
	// Ors
	SimpleOr or1(A, bNot, aOrBnot);
	SimpleOr or2(C, D, cOrD);
	
	// Ands
	SimpleAnd and1(aOrBnot, cNot, t1);
	SimpleAnd and2(t1, cOrD, t2);
	
	// Time condition
	always @(*) begin
	out = t2;
	end
endmodule

/*
	Simulates circuit: 
		Out_2=(C’D+BCD+CD’)(A’+B)
*/
module Out_2(A, B, C, D, out);
	// Inputs and output
	input A;
	input B;
	input C;
	input D;
	output out;
	reg out;
	
	// Appropriate wires
	wire aNot;
	wire cNot;
	wire dNot;
	wire cnotD;
	wire bc;
	wire bcd;
	wire cDnot;
	wire firstOr;
	wire t1;
	wire t2;
	wire finalWire;
	
	// Nots
	SimpleNot not1(A, aNot);
	SimpleNot not2(C, cNot);
	SimpleNot not3(D, dNot);
	
	// Ands
	SimpleAnd and1(cNot, D, cnotD);
	SimpleAnd and2(B, C, bc);
	SimpleAnd and3(bc, D, bcd);
	SimpleAnd and4(C, dNot, cDnot);
	
	// Ors
	SimpleOr or1(cnotD, bcd, firstOr);
	SimpleOr or2(firstOr, cDnot, t1);
	SimpleOr or3(aNot, B, t2);
	
	// Final and
	SimpleAnd and5(t1, t2, finalWire);
	
	// Time condition
	always @(*) begin
	out = finalWire;
	end
endmodule

/*
	Simulates circuit: 
		Out_3=(AB+C)D+B’C
*/
module Out_3(A, B, C, D, out);
	// Inputs and output
	input A;
	input B;
	input C;
	input D;
	output out;
	reg out;
	
	// Appropriate wire
	wire bNot;
	wire ab;
	wire abPlusC;
	wire abPlusCAndD;
	wire bnotC;
	wire finalWire;
	
	// Not
	SimpleNot not1(B, bNot);
	
	// Ands
	SimpleAnd and1(A, B, ab);
	SimpleAnd and2(bNot, C, bnotC);
	
	// Or
	SimpleOr or1(ab, C, abPlusC);
	
	// First and
	SimpleAnd and3(abPlusC, D, abPlusCAndD);
	
	// Final or
	SimpleOr or2(abPlusCAndD, bnotC, finalWire);
	
	// Time conditions
	always @(*) begin
	out = finalWire;
	end
endmodule

/*
	Main method
		- Creates bits A, B, C, and D
		- Creates and 3 inititializes
		- Outputs the results of the circuits in the form of a truth table
*/
module Test_Bench;
	// Create counter and bits
	reg signed [31:0] num;
	reg A;
	reg B;
	reg C;
	reg D;
	
	// Create wires for circuits
	wire circuit1;
	wire circuit2;
	wire circuit3;
	
	// Start the circuits
	Out_1 out_1(A, B, C, D, circuit1);
	Out_2 out_2(A, B, C, D, circuit2);
	Out_3 out_3(A, B, C, D, circuit3);
	
	// Clock with period of 1 units and input stimuli
	// in the order of a truth table
	initial begin
		forever
		  begin
			#0 num = 0 ; A = 0; B = 0; C = 0; D = 0;
			#1 num = 1 ; A = 0; B = 0; C = 0; D = 1;       
			#1 num = 2 ; A = 0; B = 0; C = 1; D = 0;
			#1 num = 3 ; A = 0; B = 0; C = 1; D = 1;
			#1 num = 4 ; A = 0; B = 1; C = 0; D = 0;
			#1 num = 5 ; A = 0; B = 1; C = 0; D = 1;
			#1 num = 6 ; A = 0; B = 1; C = 1; D = 0;
			#1 num = 7 ; A = 0; B = 1; C = 1; D = 1;
			#1 num = 8 ; A = 1; B = 0; C = 0; D = 0;
			#1 num = 9 ; A = 1; B = 0; C = 0; D = 1;
			#1 num = 10; A = 1; B = 0; C = 1; D = 0;       
			#1 num = 11; A = 1; B = 0; C = 1; D = 1;
			#1 num = 12; A = 1; B = 1; C = 0; D = 0;
			#1 num = 13; A = 1; B = 1; C = 0; D = 1;
			#1 num = 14; A = 1; B = 1; C = 1; D = 0;
			#1 num = 15; A = 1; B = 1; C = 1; D = 1; 
			#1;
		end
	end

	initial begin
		#1
		$display("\t  #|A|B|C|D|1|2|3|");
		$display("==========+=+=+=+=++=+=+=+");
		$display("\t %2d|%b|%b|%b|%b|%b|%b|%b|", num, A, B, C, D, circuit1, circuit2, circuit3);
		//Display the results forever
		forever
		  begin
			#1 $display("\t %2d|%b|%b|%b|%b|%b|%b|%b|", num, A, B, C, D, circuit1, circuit2, circuit3);		
		end
	end
	
	///Shutoff after 16 time units (since 2^4 = 16)
	initial begin
	#16
	$finish;
	end
endmodule