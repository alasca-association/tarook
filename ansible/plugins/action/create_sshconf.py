import subprocess

from ansible.plugins.action import ActionBase
from ansible.errors import AnsibleError


"""
Wrapper module for the utils/create_ssh_conf.py. Offers an action to re-generate
the custom ssh-config for the dynamic cloud inventory.
"""

class ActionModule(ActionBase):
    special_args = frozenset(('filename'))
    def run(self, tmp=None, task_vars=None):
        try:
            filename = self._task.args['filename']
        except KeyError:
            raise AnsibleError("'filename' must be set")

        # Translate the JSON hosts file into an ssh-config
        cmd = f"python3 {task_vars['playbook_dir']}/utils/create_ssh_conf.py {task_vars['hosts_file']}".split(" ")
        ssh_config = subprocess.check_output(cmd, universal_newlines=True)

        # Write the ssh-config to disk
        with open(filename, "w") as f:
            f.write(ssh_config)

        return dict(changed=True)
