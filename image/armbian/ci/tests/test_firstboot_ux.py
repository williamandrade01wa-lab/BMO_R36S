#!/usr/bin/env python3
"""Isolated firstboot UX regression tests: no real system/network changes."""
import contextlib
import importlib.machinery
import importlib.util
import io
import pathlib
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

REPO=pathlib.Path(__file__).resolve().parents[4]
SOURCE=pathlib.Path(sys.argv[1]) if len(sys.argv)>1 else REPO/"image/armbian/userpatches/overlay/usr/local/sbin/bmo-firstboot"
TEMPLATE=pathlib.Path(sys.argv[2]) if len(sys.argv)>2 else REPO/"image/armbian/userpatches/overlay/usr/share/bmo/BMO-FIRSTBOOT.txt"
loader=importlib.machinery.SourceFileLoader("firstboot_ux",str(SOURCE))
spec=importlib.util.spec_from_loader(loader.name,loader)
b=importlib.util.module_from_spec(spec)
loader.exec_module(b)
sys.argv=sys.argv[:1]

class FirstbootUX(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory()
  self.root=pathlib.Path(self.tmp.name)
 def tearDown(self): self.tmp.cleanup()
 def config(self,text):
  p=self.root/"config.txt"; p.write_text(text,encoding="utf-8"); return b.parse_config(p)
 def test_simple_windows_file(self):
  c=self.config("\ufeffREDE_WIFI=Minha Rede\r\nSENHA_WIFI=teste#=$literal\r\nSENHA_USUARIO=senha teste\r\nACESSO_REMOTO=sim\r\n")
  self.assertEqual(c["WIFI_SSID"],"Minha Rede")
  self.assertEqual(c["WIFI_PASSWORD"],"teste#=$literal")
  self.assertEqual(c["USER_PASSWORD"],"senha teste")
  self.assertEqual(c["WIFI_ENABLED"],"yes")
  self.assertTrue(b.yes(c["SSH_ENABLED"]))
 def test_literal_shell_is_not_executed(self):
  c=self.config("REDE_WIFI=$(touch NEVER)\nSENHA_WIFI=abc$(id)\n")
  self.assertEqual(c["WIFI_SSID"],"$(touch NEVER)")
 def test_default_template(self):
  c=b.parse_config(TEMPLATE)
  self.assertFalse(b.yes(c["WIFI_ENABLED"]))
  self.assertFalse(b.yes(c["SSH_ENABLED"]))
  self.assertEqual(c["WIRED_IPV4_MODE"],"dhcp")
 def test_legacy_advanced(self):
  c=self.config("WIFI_SSID=Old\nWIFI_ENABLED=no\nWIFI_HIDDEN=yes\nSSH_PORT=2222\n")
  self.assertFalse(b.yes(c["WIFI_ENABLED"]))
  self.assertEqual(c["SSH_PORT"],"2222")
 def test_duplicate_alias_rejected(self):
  with self.assertRaisesRegex(ValueError,"repetida"):
   self.config("REDE_WIFI=One\nWIFI_SSID=Two\n")
 def test_unknown_key(self):
  with self.assertRaises(ValueError): self.config("BAD_SETTING=1\n")
 def test_sanitize_both_formats(self):
  p=self.root/"config.txt"
  p.write_text("SENHA_WIFI=secretwifi\nSENHA_USUARIO=secretuser\nWIFI_PASSWORD=oldsecret\nUSER_PASSWORD=olduser\nROOT_PASSWORD=rootsecret\nREDE_WIFI=Home\n")
  b.sanitize(p); text=p.read_text()
  self.assertEqual(text.count("__APPLIED__"),5)
  self.assertNotIn("secret",text)
  self.assertIn("REDE_WIFI=Home",text)
 def test_sanitize_windows_bom_first_secret(self):
  p=self.root/"config.txt"; p.write_text("\ufeffSENHA_WIFI=secretvalue\r\n",encoding="utf-8")
  b.sanitize(p)
  self.assertNotIn("secretvalue",p.read_text())
  self.assertIn("SENHA_WIFI=__APPLIED__",p.read_text())
 def test_connected_summary(self):
  c=dict(b.DEFAULTS); c["SSH_ENABLED"]="sim"; c["WIFI_PASSWORD"]="neverprint"
  text="\n".join(b.summary_lines(c,{},"enabled","OK",["192.168.1.123"]))
  self.assertIn("Rede local: CONECTADA",text)
  self.assertIn("IP: 192.168.1.123",text)
  self.assertIn("ssh -p 22 r36s@192.168.1.123",text)
  self.assertNotIn("neverprint",text)
  self.assertIn("Internet: nao testada",text)
 def test_no_ip_not_online(self):
  text="\n".join(b.summary_lines(dict(b.DEFAULTS),{"network":"online"},"disabled","OK",[]))
  self.assertIn("SEM CONEXAO",text)
  self.assertNotIn("Rede local: CONECTADA",text)
  self.assertNotIn("ssh -p",text)
 def test_ssh_failure_is_visible(self):
  text="\n".join(b.summary_lines(dict(b.DEFAULTS),{},"error","OK",["192.168.1.50"]))
  self.assertIn("SSH: FALHOU",text)
 def test_network_disabled(self):
  c=dict(b.DEFAULTS); c["NETWORK_ENABLED"]="no"
  self.assertIn("DESLIGADA na configuracao","\n".join(b.summary_lines(c,{},"disabled","OK",[])))
 def test_error_summary(self):
  text="\n".join(b.summary_lines(dict(b.DEFAULTS),{},"disabled","ERROR",[]))
  self.assertIn("PRECISA DE ATENCAO",text)
 def test_command_error_never_leaks_password(self):
  e=subprocess.CalledProcessError(1,["nmcli","modify","wifi","psk","SUPERSECRET"])
  self.assertNotIn("SUPERSECRET",b.safe_error(e))
  self.assertNotIn("psk",b.safe_error(e))
 def test_ips_filter(self):
  result=subprocess.CompletedProcess([],0,stdout="2: wlan0 inet 192.168.1.55/24 scope global wlan0\n3: tailscale0 inet 100.1.2.3/32 scope global tailscale0\n4: eth0 inet 169.254.1.1/16 scope global eth0\n",stderr="")
  with patch.object(b,"run",return_value=result): self.assertEqual(b.ips(),["192.168.1.55"])
 def test_status_files_and_console(self):
  boot=self.root/"boot"; boot.mkdir()
  with patch.object(b,"boot_dir",return_value=boot),patch.object(b,"ips",return_value=["192.168.1.60"]),patch.object(b,"LOG_FILE",self.root/"missinglog"),contextlib.redirect_stdout(io.StringIO()) as out:
   b.status(dict(b.DEFAULTS),{"network":"online"},"disabled","enabled","OK")
  self.assertIn("IP: 192.168.1.60",out.getvalue())
  self.assertIn("NETWORK=connected",(boot/"BMO-STATUS.txt").read_text())
  self.assertIn("SSH: DESLIGADO",(boot/"BMO-RESUMO.txt").read_text())
 def test_status_no_ip(self):
  boot=self.root/"boot"; boot.mkdir()
  with patch.object(b,"boot_dir",return_value=boot),patch.object(b,"ips",return_value=[]),patch.object(b,"LOG_FILE",self.root/"missinglog"),contextlib.redirect_stdout(io.StringIO()):
   b.status(dict(b.DEFAULTS),{"network":"online"},"enabled","enabled","OK")
  self.assertIn("NETWORK=disconnected",(boot/"BMO-STATUS.txt").read_text())
  self.assertNotIn("SSH=",(boot/"BMO-IP.txt").read_text())
 def test_summary_mode_does_not_apply(self):
  boot=self.root/"boot"; boot.mkdir(); (boot/"BMO-STATUS.txt").write_text("FIRSTBOOT=OK\n")
  (boot/"BMO-FIRSTBOOT.txt").write_text("REDE_WIFI=\n")
  with patch.object(b,"boot_dir",return_value=boot),patch.object(b,"ips",return_value=["192.168.1.61"]),patch.object(b,"run",return_value=subprocess.CompletedProcess([],3)),patch.object(b,"network",side_effect=AssertionError("must not apply")),patch.object(b,"ensure_user",side_effect=AssertionError("must not change users")),patch.object(b.sys,"argv",["bmo-firstboot","--summary"]),contextlib.redirect_stdout(io.StringIO()) as out:
   self.assertEqual(b.main(),0)
  self.assertIn("192.168.1.61",out.getvalue())
 def test_ssh_default_password_still_rejected(self):
  c=dict(b.DEFAULTS); c["SSH_ENABLED"]="sim"
  with self.assertRaisesRegex(RuntimeError,"SENHA_USUARIO"): b.ssh(c,{"USER_PASSWORD_DEFAULT":"yes"})

 def test_status_roundtrip_real_newlines(self):
  boot=self.root/"boot"; boot.mkdir()
  with patch.object(b,"boot_dir",return_value=boot),patch.object(b,"ips",return_value=["192.168.1.60"]),patch.object(b,"LOG_FILE",self.root/"missinglog"),contextlib.redirect_stdout(io.StringIO()) as output:
   b.status(dict(b.DEFAULTS),{},"disabled","enabled","OK")
  fields=dict(line.split("=",1) for line in (boot/"BMO-STATUS.txt").read_text().splitlines())
  self.assertEqual(fields["FIRSTBOOT"],"OK")
  self.assertEqual(fields["NETWORK"],"connected")
  self.assertEqual((boot/"BMO-IP.txt").read_text().splitlines(),["HOSTNAME=bmo-r36s","IPV4_1=192.168.1.60"])
  self.assertIn("IP: 192.168.1.60",output.getvalue().splitlines())
  self.assertNotIn(r"\n",(boot/"BMO-RESUMO.txt").read_text())
 def test_summary_has_real_lines(self):
  boot=self.root/"boot"; boot.mkdir(); (boot/"BMO-STATUS.txt").write_text("FIRSTBOOT=OK\n")
  (boot/"BMO-FIRSTBOOT.txt").write_text("REDE_WIFI=\n")
  with patch.object(b,"boot_dir",return_value=boot),patch.object(b,"ips",return_value=["192.168.1.61"]),patch.object(b,"run",return_value=subprocess.CompletedProcess([],3)),contextlib.redirect_stdout(io.StringIO()) as output:
   b.show_summary()
  self.assertIn("Configuracao: CONCLUIDA",output.getvalue().splitlines())
  self.assertIn("IP: 192.168.1.61",output.getvalue().splitlines())
 def test_build_marker_never_applies_firstboot(self):
  marker=self.root/"build-marker"; marker.touch()
  with patch.object(b,"BUILD_MARKER",marker),patch.object(b,"ensure_user",side_effect=AssertionError("must not change users")),patch.object(b,"network",side_effect=AssertionError("must not change network")),contextlib.redirect_stdout(io.StringIO()):
   self.assertEqual(b.main(),0)

unittest.main(verbosity=2)
