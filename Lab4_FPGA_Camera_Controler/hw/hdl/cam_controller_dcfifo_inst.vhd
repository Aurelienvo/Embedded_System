cam_controller_dcfifo_inst : cam_controller_dcfifo PORT MAP (
		aclr	 => aclr_sig,
		data	 => data_sig,
		rdclk	 => rdclk_sig,
		rdreq	 => rdreq_sig,
		wrclk	 => wrclk_sig,
		wrreq	 => wrreq_sig,
		q	 => q_sig,
		rdusedw	 => rdusedw_sig
	);
