import pathlib,runpy,unittest
parse=runpy.run_path(str(pathlib.Path(__file__).resolve().parents[1]/"bmo-wifi-diagnose"))["parse_bands"]
class WifiBands(unittest.TestCase):
 def test_disabled_channel_distinct_from_hardware_support(self):
  supported,enabled=parse("* 2412 MHz [1] (20.0 dBm)\n* 5180 MHz [36] (disabled)\n")
  self.assertEqual(supported,["2.4 GHz","5 GHz"]);self.assertEqual(enabled,["2.4 GHz"])
 def test_no_guess_without_frequency(self):
  self.assertEqual(parse("SSID: Rede-5G\n"),([],[]))
 def test_dual_and_6ghz(self):
  self.assertEqual(parse("* 2462 MHz [11]\n* 5500 MHz [100]\n* 5975 MHz [5]\n")[0],["2.4 GHz","5 GHz","6 GHz"])
if __name__=="__main__":unittest.main()
