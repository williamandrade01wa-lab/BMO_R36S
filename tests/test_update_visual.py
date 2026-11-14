import hashlib
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec=importlib.util.spec_from_file_location('update_visual',Path(__file__).parents[1]/'scripts/update-visual.py')
u=importlib.util.module_from_spec(spec);spec.loader.exec_module(u)
DATA=('<html>'+''.join(u.MARKERS)+'</html>').encode()
SHA=hashlib.sha256(DATA).hexdigest()
BACKUP='20261025-120000'

class FakeDevice:
    options=[]
    target='r36s@192.168.1.65'
    def __init__(self,fail_health=False,upload_hash=SHA):
        self.calls=[];self.entry='index.html';self.sha=SHA;self.fail_health=fail_health;self.upload_hash=upload_hash
    def helper(self,*args):
        self.calls.append(args)
        action=args[0]
        if action=='install-candidate':return 'BACKUP_ID='+BACKUP
        if action=='promote-production':self.entry='index.html';return 'BACKUP_ID='+BACKUP
        if action=='use-candidate':self.entry='index.bmo-next.html'
        if action=='rollback-frontend':self.entry='index.html'
        if action=='kiosk-entry':return self.entry
        return ''
    def ssh(self,cmd):self.calls.append(('ssh',cmd));return ''
    def digest(self,path):return self.upload_hash if path.startswith(u.INCOMING) else self.sha
    def health(self,entry):
        self.calls.append(('health',entry))
        if self.fail_health:
            self.fail_health=False;raise ValueError('HTTP failure')

class UpdateTests(unittest.TestCase):
    def test_frontend_contract(self):self.assertEqual(u.frontend(DATA),SHA)
    def test_incomplete_frontend_rejected(self):
        with self.assertRaises(ValueError):u.frontend(b'<html>broken</html>')
    def test_backup_id_rejects_shell(self):
        with self.assertRaises(ValueError):u.backup_id('BACKUP_ID=foo;whoami')
    def test_target_rejects_shell(self):
        with self.assertRaises(ValueError):u.Device('r36s@host;id','missing')
    def test_branch_rejected_before_git(self):
        with patch.object(u,'run') as run:
            with self.assertRaises(ValueError):u.git_source(Path('.'),'--upload-pack=evil')
            run.assert_not_called()
    def test_source_uses_fetched_commit_without_checkout(self):
        values=[b'',b'https://github.com/williamandrade01wa-lab/BMO_R36S.git\n',b'',b'a'*40+b'\n',DATA]
        with patch.object(u,'run',side_effect=values) as run:
            commit,data,sha=u.git_source(Path('.'),'main')
            self.assertEqual((commit,data,sha),('a'*40,DATA,SHA))
            self.assertFalse(any('pull' in c.args[0] or 'reset' in c.args[0] for c in run.call_args_list))
    def test_candidate_retains_test_mode(self):
        d=FakeDevice()
        with patch.object(u,'run',return_value=b''):
            self.assertEqual(u.candidate(d,DATA,SHA),BACKUP)
        self.assertEqual(d.entry,'index.bmo-next.html')
        self.assertNotIn(('promote-production',),d.calls)
    def test_bad_upload_stops_before_install(self):
        d=FakeDevice(upload_hash='0'*64)
        with patch.object(u,'run',return_value=b''):
            with self.assertRaises(ValueError):u.candidate(d,DATA,SHA)
        self.assertFalse(any(c[0]=='install-candidate' for c in d.calls))
    def test_candidate_health_failure_restores_backup(self):
        d=FakeDevice(fail_health=True)
        with patch.object(u,'run',return_value=b''):
            with self.assertRaises(ValueError):u.candidate(d,DATA,SHA)
        self.assertIn(('rollback-frontend',BACKUP),d.calls)
        self.assertEqual(d.entry,'index.html')
    def test_promote_requires_active_tested_candidate(self):
        d=FakeDevice()
        with self.assertRaises(ValueError):u.promote(d,SHA)
        self.assertNotIn(('promote-production',),d.calls)
    def test_promote_rejects_changed_candidate(self):
        d=FakeDevice();d.entry='index.bmo-next.html';d.sha='0'*64
        with self.assertRaises(ValueError):u.promote(d,SHA)
        self.assertNotIn(('promote-production',),d.calls)
    def test_promote_success(self):
        d=FakeDevice();d.entry='index.bmo-next.html'
        self.assertEqual(u.promote(d,SHA),BACKUP)
        self.assertEqual(d.entry,'index.html')
    def test_failed_promotion_rolls_back(self):
        d=FakeDevice(fail_health=True);d.entry='index.bmo-next.html'
        with self.assertRaises(ValueError):u.promote(d,SHA)
        self.assertIn(('rollback-frontend',BACKUP),d.calls)

if __name__=='__main__':unittest.main()
