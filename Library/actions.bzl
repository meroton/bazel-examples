"""
"""


LIST_SEP = "   - "
LINE_SEP = "\n" + LIST_SEP
_SEP = "\n   "

def mapPath(x):
    if x == None:
        return "None"
    else:
        return x.path

def header(x):
    return "\n" + x + ":\n"


def prettyAction(a):
    return """{{
        Mnemonic: {},
        Args: {},
        Argv: {},
        Content: {},
        Env: {},
        Outputs: {},
        Substitutions: {}
    }}""".format(
        a.mnemonic,
        a.args,
        a.argv,
        a.content,
        a.env,
        a.outputs,
        a.substitutions,
    )

def format(target):
    actions = getattr(target, "actions", [])
    res = ""
    for action in actions:
        if action.mnemonic == "CppCompile":
            res += prettyAction(action)

    # NB: `providers` is not a global Starlark function,
    # so if we use it for `cquery` it can no longer be loaded,
    # and share code with rules.
    #   ccinfo = providers(target).get("CcInfo")
    #   print(ccinfo)

    return res


