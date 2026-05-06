 set_property IOSTANDARD LVCMOS33 [get_ports {RxD TxD rst}]
--   set_property PACKAGE_PIN W11 [get_ports RxD]
--   set_property PACKAGE_PIN V10 [get_ports TxD]
--   # TODO: set BTNU pin for 'rst' per ZedBoard manual
--   create_clock -period 10.000 [get_ports clk_100MHz]
