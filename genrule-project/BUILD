# Credit: heavily borrowed from @meisterT's work.
DEPTH = 100

WIDTH = 3000

# Base: depends on nothing.
[genrule(
    name = "bar_%s_0" % x,
    outs = ["bar_%s_0.txt" % x],
    cmd = "touch $@",
) for x in range(0, WIDTH)]

# bar_x_y depends on baz_x_(y-1)
[
    [genrule(
        name = "bar_%s_%s" % (x, y),
        srcs = ["bar_%s_%s.txt" % (
            x,
            y - 1,
        )],
        outs = ["bar_%s_%s.txt" % (x, y)],
        cmd = "touch $@",
    ) for y in range(1, DEPTH)]
    for x in range(0, WIDTH)
]

# Depends on all the top-level bar targets
genrule(
    name = "longwide",
    srcs = ["bar_%s_%s.txt" % (
        x,
        DEPTH - 1,
    ) for x in range(0, WIDTH)],
    outs = ["foo.txt"],
    cmd = "touch $@",
)

genrule(
    name = "longtail",
    srcs = ["bar_0_%s.txt" % (DEPTH - 1)] + ["baz_%s_0.txt" % (
        x
    ) for x in range(0, WIDTH)],
    outs = ["longtail.txt"],
    cmd = "touch $@",
)

genrule(
    name = "flat",
    srcs = ["bar_%s_0.txt" % (
        x
    ) for x in range(0, WIDTH)],
    outs = ["flat.txt"],
    cmd = "touch $@",
)