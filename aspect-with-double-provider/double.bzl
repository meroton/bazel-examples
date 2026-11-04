Provider = provider(
    fields = ["data"],
)

def impl():
    return [
        Provider(data = "1"),
        Provider(data = "2"),
    ]

double_a = aspect(
    implementation = lambda _, __: impl(),
)

double_r = rule(
    implementation = lambda _: impl(),
)
