import os


def exec_cmd(working_dir, cmd_path, args=[], env=[]):
    """Exec a script from the given working directory"""
    os.chdir(working_dir)
    os.execvpe(cmd_path, [str(cmd_path)] + args, env)
