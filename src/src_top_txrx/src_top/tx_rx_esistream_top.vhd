-------------------------------------------------------------------------------
-- This is free and unencumbered software released into the public domain.
--
-- Anyone is free to copy, modify, publish, use, compile, sell, or distribute
-- this software, either in source code form or as a compiled bitstream, for 
-- any purpose, commercial or non-commercial, and by any means.
--
-- In jurisdictions that recognize copyright laws, the author or authors of 
-- this software dedicate any and all copyright interest in the software to 
-- the public domain. We make this dedication for the benefit of the public at
-- large and to the detriment of our heirs and successors. We intend this 
-- dedication to be an overt act of relinquishment in perpetuity of all present
-- and future rights to this software under copyright law.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN 
-- ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- THIS DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES. 
-------------------------------------------------------------------------------
-- Version      Date            Author       Description
-- 1.0          2019            Teledyne e2v Creation
-- 1.1          2019            REFLEXCES    FPGA target migration, 64-bit data path
-- 2.0          2021            Teledyne e2v uart, regmap, frame checking, 16-bit/32-bit/64-bit
-------------------------------------------------------------------------------

library work;
use work.esistream_pkg.all;
use work.component_pkg.all;

library IEEE;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

library polarfire;
use polarfire.all;

entity tx_rx_esistream_top is
  generic(
    GEN_ESISTREAM          : boolean                       := true;
    GEN_GPIO               : boolean                       := false;
    NB_LANES               : integer                       := 8;
    RST_CNTR_INIT          : std_logic_vector(11 downto 0) := x"000";
    NB_CLK_CYC             : std_logic_vector(31 downto 0) := x"00000000";
    CLK_MHz                : real                          := 100.0;
    SPI_CLK_MHz            : real                          := 5.0;
    DEB_WIDTH              : integer                       := 25
    );
  port (
    sso_n          : in  std_logic;                                                 -- mgtrefclk from transceiver clock input
    sso_p          : in  std_logic;                                                 -- mgtrefclk from transceiver clock input
    sso_ref_n      : out std_logic;
    sso_ref_p      : out std_logic;
    CLK_50MHZ_I    : in  std_logic;                                                 -- sysclk
    rxp            : in  std_logic_vector(NB_LANES-1 downto 0) := (others => '0');  -- lane serial input p
    rxn            : in  std_logic_vector(NB_LANES-1 downto 0) := (others => '0');  -- lane Serial input n
    txp            : out std_logic_vector(NB_LANES-1 downto 0) := (others => '0');  -- lane serial input p
    txn            : out std_logic_vector(NB_LANES-1 downto 0) := (others => '0');  -- lane Serial input n
    SW1            : in  std_logic;
    SW2            : in  std_logic;
    DIP1           : in  std_logic;
    DIP2           : in  std_logic;
    DIP3           : in  std_logic;
    DIP4           : in  std_logic;
    LED            : out std_logic_vector(3 downto 0);
    FTDI_UART1_TXD : in  std_logic;                                                 -- CP2105 USB to UART output 
    FTDI_UART1_RXD : out std_logic                                                  --;                                                 -- CP2105 USB to UART input
    );
end entity tx_rx_esistream_top;

architecture rtl of tx_rx_esistream_top is

  --------------------------------------------------------------------------------------------------------------------
  --! signal name description:
  -- _sr = _shift_register
  -- _re = _rising_edge (one clk period pulse generated on the rising edge of the initial signal)
  -- _fe = _falling_edge (one clk period pulse generated on the falling edge of the initial signal)
  -- _d  = _delay
  -- _2d = _delay x2
  -- _ba = _bitwise_and
  -- _sw = _slide_window
  -- _o  = _output
  -- _i  = _input
  -- _t  = _temporary or _tristate pin (OBUFT)
  -- _a  = _asychronous (fsm output decode signal)
  -- _s  = _synchronous (fsm synchronous output signal)
  -- _rs = _resynchronized (when there is a clock domain crossing)
  --------------------------------------------------------------------------------------------------------------------
  attribute keep                         : string;
  constant ALL_LANES_ON                  : std_logic_vector(NB_LANES-1 downto 0) := (others => '1');
  constant ALL_LANES_OFF                 : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');
  signal sysrstn                          : std_logic                             := '0';
  signal sysclk                          : std_logic                             := '0';
  signal sysclk2                         : std_logic                             := '0';
  signal sysclk3                         : std_logic                             := '0';
  signal syslock                         : std_logic                             := '0';
  signal rx_clk                          : std_logic                             := '0';
  attribute keep of rx_clk               : signal is "true";
  signal tx_clk                          : std_logic                             := '0';
  attribute keep of tx_clk               : signal is "true";
  signal reg_rst                         : std_logic                             := '0';
  signal reg_rst_check                   : std_logic                             := '0';
  signal sw_rst                          : std_logic                             := '0';
  signal sw_rst_check                    : std_logic                             := '0';
  signal rst_in                          : std_logic                             := '0';
  signal rst_deb                         : std_logic                             := '0';
  signal rst_t                           : std_logic                             := '0';
  signal rst_re                          : std_logic                             := '0';
  signal rst_check                       : std_logic                             := '0';
  signal rst_check_rs                    : std_logic                             := '0';
  signal rst_check_re                    : std_logic                             := '0';
  signal sync_in                         : std_logic                             := '0';
  signal sync_deb                        : std_logic                             := '0';
  signal sync_meta                       : std_logic                             := '0';
  signal sync_reg                        : std_logic;
  signal rx_sync_in                      : std_logic                             := '0';
  signal rx_ip_ready                     : std_logic                             := '0';
  signal rx_lanes_on                     : std_logic_vector(NB_LANES-1 downto 0) := (others => '1');
  signal rx_lanes_ready                  : std_logic                             := '0';
  signal rx_release_data                 : std_logic                             := '0';
  signal rx_prbs_en                      : std_logic                             := '1';
  signal tx_sync_in                      : std_logic                             := '0';
  signal tx_prbs_en                      : std_logic                             := '1';
  signal tx_disp_en                      : std_logic                             := '1';
  signal tx_lfsr_init                    : slv_17_array_n(NB_LANES-1 downto 0)   := (others => (others => '1'));
  signal tx_data_in                      : tx_data_array(NB_LANES-1 downto 0)    := (others => (others => (others => '0')));
  signal tx_ip_ready                     : std_logic                             := '0';
  signal tx_emu_d_ctrl                   : std_logic_vector(1 downto 0)          := "00";
  signal dsw_tx_emu_d_ctrl               : std_logic_vector(1 downto 0)          := "00";
  signal dsw_prbs_en                     : std_logic                             := '1';
  signal dsw_disp_en                     : std_logic                             := '1';
  --
  signal fifo_dout                       : data_array(NB_LANES-1 downto 0);
  signal fifo_rd_en                      : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');
  signal fifo_empty                      : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');
  --
  signal be_status                       : std_logic                             := '0';
  signal cb_status                       : std_logic                             := '0';
  signal valid_status                    : std_logic                             := '0';
  --
  signal aq600_prbs_en                   : std_logic                             := '1';
  signal clk_acq                         : std_logic                             := '0';
  signal s_reset_i                       : std_logic                             := '0';
  signal s_resetn_i                      : std_logic                             := '0';
  signal s_resetn_re                     : std_logic                             := '0';
  signal rx_rst                          : std_logic                             := '0';
  signal rx_nrst                         : std_logic                             := '1';
  signal fb_clk                          : std_logic                             := '0';
  --
  type rx_data_array_12b is array (natural range <>) of slv_12_array_n(DESER_WIDTH/16-1 downto 0);
  signal data_out_12b                    : rx_data_array_12b(NB_LANES-1 downto 0);
  --
  signal frame_out                       : rx_frame_array(NB_LANES-1 downto 0);
  signal frame_out_d                     : rx_frame_array(NB_LANES-1 downto 0);
  signal valid_out                       : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');
  --
  signal m_axi_addr                      : std_logic_vector(3 downto 0)          := (others => '0');
  signal m_axi_strb                      : std_logic_vector(3 downto 0)          := (others => '0');
  signal m_axi_wdata                     : std_logic_vector(31 downto 0)         := (others => '0');
  signal m_axi_rdata                     : std_logic_vector(31 downto 0)         := (others => '0');
  signal m_axi_wen                       : std_logic                             := '0';
  signal m_axi_ren                       : std_logic                             := '0';
  signal m_axi_busy                      : std_logic                             := '0';
  signal s_interrupt                     : std_logic                             := '0';
  --
  signal reg_0                           : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_1                           : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_2                           : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_3                           : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_4                           : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_5                           : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_6                           : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_7                           : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_8                           : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_9                           : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_10                          : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_11                          : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_12                          : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_13                          : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_14                          : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_15                          : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_16                          : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_17                          : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_18                          : std_logic_vector(31 downto 0)         := (others => '0');
  signal reg_19                          : std_logic_vector(31 downto 0)         := (others => '0');
  --
  signal uart_ready                      : std_logic                             := '0';
  --
  signal reg_4_os                        : std_logic                             := '0';
  signal reg_5_os                        : std_logic                             := '0';
  signal reg_6_os                        : std_logic                             := '0';
  signal reg_7_os                        : std_logic                             := '0';
  signal reg_10_os                       : std_logic                             := '0';
  signal reg_12_os                       : std_logic                             := '0';
  --
  attribute MARK_DEBUG                   : string;
  attribute MARK_DEBUG of rx_sync_in     : signal is "true";
  attribute MARK_DEBUG of rx_ip_ready    : signal is "true";
  attribute MARK_DEBUG of rx_lanes_ready : signal is "true";
  attribute MARK_DEBUG of cb_status      : signal is "true";
  attribute MARK_DEBUG of be_status      : signal is "true";
  attribute MARK_DEBUG of data_out_12b   : signal is "true";
  attribute MARK_DEBUG of valid_out      : signal is "true";
  --
  component OUTBUF_DIFF
    port (
      -- Inputs
      D    : in  std_logic;
      -- Outputs
      PADP : out std_logic;
      PADN : out std_logic
      );
  end component;

begin
  --
  --------------------------------------------------------------------------------------------
  -- User interface:
  --------------------------------------------------------------------------------------------
  --
  -------------------------
  -- push-buttons
  -------------------------
  rst_in               <= not SW1;
  sync_in              <= not SW2;  
  -------------------------
  -- SW2 switch
  -------------------------
  dsw_tx_emu_d_ctrl(0) <= DIP1;  
  dsw_tx_emu_d_ctrl(1) <= DIP2;  
  dsw_prbs_en          <= DIP3;  
  dsw_disp_en          <= DIP4;
  --
  -------------------------
  -- LEDs
  -------------------------
  LED(0)               <= uart_ready;
  LED(1)               <= rx_ip_ready and tx_ip_ready;
  LED(2)               <= rx_lanes_ready and valid_status;
  LED(3)               <= cb_status or be_status;
  --
  -------------------------
  -- reset
  -------------------------
  rst_t     <= sw_rst or reg_rst;
  rx_rst    <= rst_re or s_reset_i;
  rx_nrst   <= not rx_rst;
  rst_check <= sw_rst_check or reg_rst_check;
  --
  meta_1 : entity work.meta
    port map (
      clk       => rx_clk,
      reg_async => rst_check,
      reg_sync  => rst_check_rs);
  --
  debouncer_1 : entity work.debouncer
   generic map (
     WIDTH => DEB_WIDTH)
   port map (
     clk   => CLK_50MHZ_I,
     deb_i => rst_in,
     deb_o => rst_deb);
  --
  sw_rst               <= rst_deb;
  sw_rst_check         <= rst_deb;
  sysrstn              <= not rst_deb;
  --
  risingedge_1 : entity work.risingedge
    port map (
      rst => s_reset_i,
      clk => sysclk,
      d   => rst_t,
      re  => rst_re);

  risingedge_2 : entity work.risingedge
    port map (
      rst => s_reset_i,
      clk => sysclk,
      d   => s_resetn_i,
      re  => s_resetn_re);
  --
  sysreset_1 : entity work.sysreset_1
    generic map (
      RST_CNTR_INIT => RST_CNTR_INIT)
    port map (
      syslock => syslock,
      sysclk  => sysclk,
      reset   => s_reset_i,
      resetn  => s_resetn_i);
  --
  --------------------------------------------------------------------------------------------
  -- SYNC 
  --------------------------------------------------------------------------------------------
  debouncer_2 : entity work.debouncer
    generic map (
      WIDTH => DEB_WIDTH)
    port map (
      clk   => sysclk,
      deb_i => sync_in,
      deb_o => sync_deb);
  --
  sync_meta  <= sync_deb or sync_reg;
  rx_sync_in <= sync_meta;
  --
  meta_re_2 : entity work.meta_re
    port map (
      rst       => rst_t,
      pulse_in  => sync_meta,
      clk_out   => tx_clk,
      pulse_out => tx_sync_in);
  --------------------------------------------------------------------------------------------
  --  clk_out1 : 100.0MHz (must be consistent with C_SYS_CLK_PERIOD)
  --------------------------------------------------------------------------------------------
  i_pll_sys : PF_CCC_C0
    port map (
      -- Inputs
      FB_CLK_0          => fb_clk, -- 50 MHz
      PLL_POWERDOWN_N_0 => sysrstn,
      REF_CLK_0         => CLK_50MHZ_I,
      -- Outputs
      OUT0_FABCLK_0     => fb_clk,
      OUT1_FABCLK_0     => sysclk,
      OUT2_FABCLK_0     => sysclk2,
      OUT3_FABCLK_0     => sysclk3,
      PLL_LOCK_0        => syslock

      );
  
  outbuf_diff_1 : OUTBUF_DIFF
    port map (
      -- Inputs
      D    => sysclk2,
      -- Outputs
      PADP => sso_ref_p,
      PADN => sso_ref_n
      );
  --------------------------------------------------------------------------------------------
  -- ESIstream RX IP
  --------------------------------------------------------------------------------------------
  gen_esistream_hdl : if GEN_ESISTREAM = true generate
    tx_rx_esistream_with_xcvr_1 : entity work.tx_rx_esistream_with_xcvr
      generic map (
        NB_LANES => NB_LANES,
        COMMA    => x"FF0000FF")
      port map (
        rst            => rx_rst,
        sysclk         => sysclk,
        refclk_n       => sso_n,
        refclk_p       => sso_p,
        -- TX port
        txp            => txp,
        txn            => txn,
        tx_sync_in     => tx_sync_in,
        tx_prbs_en     => tx_prbs_en,
        tx_disp_en     => tx_disp_en,
        tx_lfsr_init   => tx_lfsr_init,
        data_in        => tx_data_in,
        tx_ip_ready    => tx_ip_ready,
        tx_frame_clk   => tx_clk,
        -- RX port
        rxp            => rxp,
        rxn            => rxn,
        rx_sync_in     => rx_sync_in,
        rx_prbs_en     => rx_prbs_en,
        rx_lanes_on    => rx_lanes_on,
        rx_data_en     => rx_lanes_ready, -- rx_release_data,
        clk_acq        => rx_clk,
        rx_frame_clk   => rx_clk,
        rx_sync_out    => open,
        frame_out      => frame_out,
        valid_out      => valid_out,
        rx_ip_ready    => rx_ip_ready,
        rx_lanes_ready => rx_lanes_ready);
  end generate gen_esistream_hdl;
  --------------------------------------------------------------------------------------------
  -- Received data check 
  --------------------------------------------------------------------------------------------
  tx_emu_data_gen_top_1 : entity work.tx_emu_data_gen_top
    generic map (
      NB_LANES => NB_LANES)
    port map (
      nrst    => rx_nrst,
      clk     => tx_clk,
      d_ctrl  => tx_emu_d_ctrl,                                  -- "00" all 0; "11" all 1; else ramp+
      tx_data => tx_data_in);
  --------------------------------------------------------------------------------------------
  -- Received data check 
  --------------------------------------------------------------------------------------------
  -- Used for ILA only to display the ramp waveform using analog view in vivado simulator:
  lanes_assign : for i in 0 to NB_LANES-1 generate
    channel_assign : for j in 0 to DESER_WIDTH/16-1 generate
      process(rx_clk)
      begin
        if rising_edge(rx_clk) then
          -- to Integrated Logic Analyzer (ILA)
          data_out_12b(i)(j) <= frame_out(i)(j)(12-1 downto 0);  -- add pipeline to meet timing constraints
          -- to txrx_frame_checking
          frame_out_d(i)(j)  <= frame_out(i)(j);                 -- add pipeline to meet timing constraints
        end if;
      end process;
    end generate channel_assign;
  end generate lanes_assign;

  txrx_frame_checking_1 : entity work.txrx_frame_checking
    generic map (
      NB_LANES => NB_LANES)
    port map (
      rst          => rst_check_rs,
      clk          => rx_clk,
      d_ctrl       => tx_emu_d_ctrl,
      lanes_on     => rx_lanes_on,
      frame_out    => frame_out,
      valid_out    => valid_out,
      be_status    => be_status,
      cb_status    => cb_status,
      valid_status => valid_status);

  --------------------------------------------------------------------------------------------
  -- UART 8 bit 115200 and Register map
  --------------------------------------------------------------------------------------------
  uart_wrapper_1 : entity work.uart_wrapper
    port map (
      clk         => sysclk,
      rstn        => s_resetn_i,
      m_axi_addr  => m_axi_addr,
      m_axi_strb  => m_axi_strb,
      m_axi_wdata => m_axi_wdata,
      m_axi_rdata => m_axi_rdata,
      m_axi_wen   => m_axi_wen,
      m_axi_ren   => m_axi_ren,
      m_axi_busy  => m_axi_busy,
      interrupt   => s_interrupt,
      tx          => FTDI_UART1_RXD,
      rx          => FTDI_UART1_TXD);

  register_map_1 : entity work.register_map
    generic map (
      CLK_FREQUENCY_HZ => 100000000,
      TIME_US          => 1000000)
    port map (
      clk          => sysclk,
      rstn         => s_resetn_i,
      interrupt_en => s_resetn_re,
      m_axi_addr   => m_axi_addr,
      m_axi_strb   => m_axi_strb,
      m_axi_wdata  => m_axi_wdata,
      m_axi_rdata  => m_axi_rdata,
      m_axi_wen    => m_axi_wen,
      m_axi_ren    => m_axi_ren,
      m_axi_busy   => m_axi_busy,
      interrupt    => s_interrupt,
      uart_ready   => uart_ready,
      reg_0        => reg_0,
      reg_1        => reg_1,
      reg_2        => reg_2,
      reg_3        => reg_3,
      reg_4        => reg_4,
      reg_5        => reg_5,
      reg_6        => reg_6,
      reg_7        => reg_7,
      reg_8        => reg_8,
      reg_9        => reg_9,
      reg_10       => reg_10,
      reg_11       => reg_11,
      reg_12       => reg_12,
      reg_13       => reg_13,
      reg_14       => reg_14,
      reg_15       => reg_15,
      reg_16       => reg_16,
      reg_17       => reg_17,
      reg_18       => reg_18,
      reg_19       => reg_19,
      reg_4_os     => reg_4_os,
      reg_5_os     => reg_5_os,
      reg_6_os     => reg_6_os,
      reg_7_os     => reg_7_os,
      reg_10_os    => reg_10_os,
      reg_12_os    => reg_12_os);
  --
  tx_emu_d_ctrl(0) <= reg_0(0) or dsw_tx_emu_d_ctrl(0);
  tx_emu_d_ctrl(1) <= reg_0(1) or dsw_tx_emu_d_ctrl(1);
  --
  rx_prbs_en       <= reg_1(0) or dsw_prbs_en;
  tx_prbs_en       <= reg_1(1) or dsw_prbs_en;
  tx_disp_en       <= reg_1(2) or dsw_disp_en;
  --
  reg_rst          <= reg_2(0);
  reg_rst_check    <= reg_2(1);
  --
  sync_reg <= reg_6(0);
  -- firmware version --
  reg_8    <= x"00000100";

end architecture rtl;
