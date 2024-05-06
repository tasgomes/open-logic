------------------------------------------------------------------------------
--  Copyright (c) 2024 by Oliver Bründler
--  All rights reserved.
--  Authors: Benoit Stef, Oliver Bründler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a very basic strobe divider. It forwards only every Nth single
-- cycle pulse to the output.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.olo_base_pkg_math.all;

------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity olo_base_strobe_divider is
    generic (
        MaxRatio_g  : positive;
        Latency_g   : natural range 0 to 1  := 1       
    ); 
    port (   
        Clk         : in  std_logic;  
        Rst         : in  std_logic;  
        In_Ratio    : in  std_logic_vector(log2ceil(MaxRatio_g)-1 downto 0)   := toUslv(MaxRatio_g-1, log2ceil(MaxRatio_g));
        In_Valid    : in  std_logic;
        Out_Valid   : out std_logic;
        Out_Ready   : in  std_logic                                             := '1'
    );      
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of olo_base_strobe_divider is

    -- *** Two Process Method ***
    type two_process_r is record
        Count       : natural range 0 to MaxRatio_g-1;
        OutValid    : std_logic;
    end record;
    signal r, r_next : two_process_r;
begin

    p_comb : process(r, In_Valid, In_Ratio, Out_Ready)
        variable OutValid_v : std_logic;
        variable v : two_process_r;
    begin
        -- *** hold variables stable ***
        v := r;

        -- Ratio Counter
        if In_Valid = '1' then
            if r.Count >= unsigned(In_Ratio) or MaxRatio_g = 1 then
                v.Count := 0;
                v.OutValid := '1';
            else
                v.Count := r.Count + 1;
            end if;
        end if;

        -- Latency Handling
        if Latency_g = 0 then
            OutValid_v := v.OutValid;
        else
            OutValid_v := r.OutValid;
        end if;

        -- Generate output Latency 1
        if OutValid_v = '1' and Out_Ready = '1' then
            v.OutValid := '0';
        end if;

        -- Outputs
        Out_Valid <= OutValid_v;

        -- *** assign signal ***
        r_next <= v;
    end process;

    p_seq : process(Clk)
    begin
        if rising_edge(Clk) then
            r <= r_next;
            if Rst = '1' then
                r.Count <= 0;
                r.OutValid <= '0';
            end if;
        end if;
    end process;

end architecture;
