/*
	Cohort: The Waffle House
	Assignment: Program3.v
	Date: October 19, 2018
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
	D Flip-Flop
		- Sets Q equal to D on the positive edge of clk
*/
module D_Flip_Flop(input D, clk, output reg Q);
	always @(posedge clk)
		Q <= D;
endmodule

/*
	Follows the circuit of the following criteria
		- A(t+1)=xy’+xB
		  B(t+1)=xA+xB’
		  z=A
		- Utilizes D Flip-Flops to get the next state of
		  A and B
		- Sets z to the current state of A on the positive
		  edge of clk
		  
*/
module Program_1(input x, y, clk, output A, B, output reg z);
	wire yNot, Bnot;
	wire xyNot, xB, xA, xBnot;
	wire d1, d2;

	SimpleNot notY(y, yNot);
	SimpleNot notB(B, Bnot);
	
	SimpleAnd and1(x, yNot, xyNot);
	SimpleAnd and2(x, B, xB);
	SimpleAnd and3(x, A, xA);
	SimpleAnd and4(x, Bnot, xBnot);
	
	SimpleOr  or1 (xyNot, xB, d1);
	SimpleOr  or2 (xA, xBnot, d2);
	
	D_Flip_Flop nextStateA(d1, clk, A);
	D_Flip_Flop nextStateB(d2, clk, B);
	
	always @(posedge clk)
		z <= A;
endmodule

/*
	T Flip-Flop
		- Clears Q on negative edge of reset
		- Inverts value of Q if T is 1 on positive edge of clk
*/
module T_Flip_Flop(input T, clk, reset, output reg Q);
	always @(posedge clk, negedge reset) begin
		if (reset == 0) 
			Q <= 1'b0;
		else if (T)
			begin
				Q <= ~Q;
			end
	end	
endmodule

/*
	Structurally builds the up-down counter with 
	nots, ands, ors, and T Flip-Flops
*/
module Program_2_Structural(input clear_b, clk, up, down, output [3:0] A);
	wire notUp, w1, w2, w3, w4, w5, w6, w7, T0, T1, T2, T3;
	
	SimpleNot notup(up, notUp);
	
	SimpleAnd w_1(notUp, down, w1);
	SimpleOr  T_0(up, w1, T0);
	T_Flip_Flop tff0(T0, clk, clear_b, A[0]);
	
	SimpleAnd w_2(w1, ~A[0], w2);
	SimpleAnd w_3(up, A[0], w3);
	SimpleOr  T_1(w2, w3, T1);
	T_Flip_Flop tff1(T1, clk, clear_b, A[1]);
	
	SimpleAnd w_4(w2, ~A[1], w4);
	SimpleAnd w_5(w3, A[1], w5);
	SimpleOr  T_2(w4, w5, T2);
	T_Flip_Flop tff2(T2, clk, clear_b, A[2]);
	
	SimpleAnd w_6(w4, ~A[2], w6);
	SimpleAnd w_7(w5, A[2], w7);
	SimpleOr  T_3(w6, w7, T3);
	T_Flip_Flop tff3(T3, clk, clear_b, A[3]);
endmodule

/*
	Behaviorlly builds the up-down counter with 
	explicit four-bit additions and subtractions
*/
module Program_2_Behavioral(input reset, clk, up, down, output reg [3:0] A);
	always @(posedge clk, negedge reset) begin
		if (reset == 0)
			A <= 4'b0000;
		else 
			begin
				if (up)
					A <= A + 4'b0001;
				else
					A <= A - 4'b0001;
			end
	end
endmodule

/*
	Main Method
		- Starts up circuits for Programs 1 and 2
			- Behavioral and Structural versions for Program 2
		- Initializes the CLKs for the time circuits
		- Prints sample output values
*/
module Test_Bench;
	// Start circuit for Program 1
	reg x = 0, y = 0, clk = 1;
	Program_1 program_1(x, y, clk, A, B, z);
	
	// Start structural circuit for Program 2
	reg clear_b, clk1, up, down;
	wire unsigned [3:0] a;
	Program_2_Structural program_2_structural(clear_b, clk1, up, down, a);
	
	// Start behavioral circuit for Program 2
	reg clear_b2, clk2, up2, down2;
	wire unsigned [3:0] a2;
	Program_2_Behavioral program_2_behavioral(clear_b2, clk2, up2, down2, a2);
	
	// Initialize the CLKs
	initial begin 
		clk = 0;
		clk1 = 0;
		clk2 = 0;
		forever begin
			#5; //Wavelength is 10
			clk = ~clk;
			clk1 = ~clk1;
			clk2 = ~clk2;
		end
	end
	
	// Print statements for outputs of the different circuits
	integer i;
	initial begin
		// Program 1 outputs
		for (i = 0; i < 18; i = i + 1) begin
			#10;
			$display("  %0t \t%b\t%b\t%b", $time, A, B, z);
		end
		
		// Program 2 outputs (behavioral)
		#10;
		for (i = 0; i < 64; i = i + 1) begin
			$display("   %0t\t       %b", $time, a2);
			#10;
		end
		
		// Program 2 outputs (structural)
		for (i = 0; i < 64; i = i + 1) begin
			$display("   %0t\t       %b", $time, a);
			#10;
		end
	end
	
	// Sample Output
	initial begin
		$display("--Programming Assignment 1 Output-- \n");
		
		$display("Set CLK Wavelength to 10 (alternates every 5 time units)");
		$display("==========================\n Time\tA(t+1) \tB(t+1) \tz\n==========================");
		$display("  %0t  (Set x = 0, y = 0)", $time);
		#10;
		x = 0; y = 0;
		#21;
		$display("  %0t (Set x = 1, y = 1)", $time);
		x = 1; y = 1;
		#50;
		$display("  %0t (Set x = 1, y = 0)", $time);
		x = 1; y = 0;
		#50;
		$display("  %0t (Set x = 0, y = 1)", $time);
		x = 0; y = 1;
		#50;
		
		$display("\n--Programming Assignment 2 Output (Behavioral)--\n");
		$display("Set CLK Wavelength to 10 (alternates every 5 time units)");
		$display("==========================\n   Time\t\tA\n==========================");
		#5; $display(" (Set clear_b = 1)"); clear_b2 = 1;
		#5; $display(" (Set clear_b = 0)"); clear_b2 = 0;
		#10; $display(" (Set Clear_b = 1)\n (Set up = 1, down = 0)"); clear_b2 = 1; up2 = 1; down2 = 0;
		#310; $display(" (Set up = 0, down = 1)"); up2 = 0; down2 = 1;
		#310;
		
		$display("\n--Programming Assignment 2 Output (Structural)--\n");
		$display("Set CLK Wavelength to 10 (alternates every 5 time units)");
		$display("==========================\n   Time\t\tA\n==========================");
		#5; $display(" (Set clear_b = 1)"); clear_b = 1;
		#5; $display(" (Set clear_b = 0)"); clear_b = 0;
		#10; $display(" (Set Clear_b = 1)\n (Set up = 1, down = 0)"); clear_b = 1; up = 1; down = 0;
		#310; $display(" (Set up = 0, down = 1)"); up = 0; down = 1;
		#310;
		$finish;
	end
endmodule