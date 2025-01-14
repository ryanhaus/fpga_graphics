// dual-port RAM
module dpram #(
	parameter DATA_WIDTH = 8, // width of the data in bits
	parameter DATA_N = 16, // number of data (i.e., bytes)
	parameter ADDR_BITS = $clog2(DATA_N), // number of bits needed to represent DATA_N addresses
	parameter RST_VAL = 0 // the value that entries will be set to upon reset
) (
	input rst,

	input rd_clk,
	input [ADDR_BITS-1 : 0] rd_addr,
	output bit [DATA_WIDTH-1 : 0] rd_out,

	input wr_clk,
	input wr_en,
	input [ADDR_BITS-1 : 0] wr_addr,
	input [DATA_WIDTH-1 : 0] wr_in
);

	// the actual stored data
	bit [DATA_WIDTH-1 : 0] data [DATA_N-1 : 0];

	// handle reads
	always_ff @(posedge rd_clk) begin
		// write the appropriate value to rd_out
		rd_out <= data[rd_addr];
	end

	// handle writes + reset
	integer rst_i;

	always_ff @(posedge wr_clk) begin
		if (rst) begin
			// set all values in data to 0
			for (rst_i = 0; rst_i < DATA_N; rst_i = rst_i + 1) begin
				data[rst_i] = RST_VAL;
			end
		end
		else begin
			// write the appropriate value to the appropriate address
			if (wr_en)
				data[wr_addr] <= wr_in;
		end
	end
	
endmodule
