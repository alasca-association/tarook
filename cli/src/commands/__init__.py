import os


def exec_script(working_dir, script_path, args=[]):
    """Exec a script from the given working directory"""
    os.chdir(working_dir)
    os.execvpe(script_path, [str(script_path)] + args, None)
