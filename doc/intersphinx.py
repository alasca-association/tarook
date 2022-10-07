import json
import os
import pathlib

basedir = pathlib.Path(__file__).parent.resolve()

try:
    mapping = json.loads(os.environ["YAOOK_INTERSPHINX"])
except KeyError:
    mapping = {
        "yaook_k8s_user_expl": (
            str(basedir / "user-expl" / "_build" / "html"), None,
        ),
        "yaook_k8s_user_ref": (
            str(basedir / "user-ref" / "_build" / "html"), None,
        ),
        "yaook_k8s_user_guide": (
            str(basedir / "user-guide" / "_build" / "html"), None,
        ),
    }
