# Credit: heavily borrowed from @meisterT's work.
DEPTH_LIMIT = 3000
WIDTH_LIMIT = 300
LONGWIDE_DEPTH=500
LONGWIDE_WIDTH=500


# A flat base.
[genrule(
    name = "bar_%s_0" % x,
    outs = ["bar_%s_0.txt" % x],
    cmd = "touch $@",
) for x in range(0, WIDTH_LIMIT)]

# bar_x_y depends on bar_x_(y-1)
[
    [genrule(
        name = "bar_%s_%s" % (x, y),
        srcs = ["bar_%s_%s.txt" % (
            x,
            y - 1,
        )],
        outs = ["bar_%s_%s.txt" % (x, y)],
        cmd = "touch $@",
    ) for y in range(1, LONGWIDE_DEPTH)]
    for x in range(1, LONGWIDE_WIDTH)
]

# A long tail 
[genrule(
    name = "bar_0_%s" % x,
    srcs = ["bar_0_%s.txt" % (
        x - 1,
    )],
    outs = ["bar_0_%x.txt" % x],
    cmd = "touch $@",
) for x in range(1, DEPTH_LIMIT)]


# Benchmark targets
genrule(
    name = "longwide",
    srcs = ["bar_%s_%s.txt" % (
        x,
        LONGWIDE_DEPTH - 1,
    ) for x in range(0, LONGWIDE_WIDTH)],
    outs = ["longwide.txt"],
    cmd = "touch $@",
)

genrule(
    name = "chain",
    srcs = ["bar_0_%s.txt" % (DEPTH_LIMIT - 1)],
    outs = ["chain.txt"],
    cmd = "touch $@",
)

genrule(
    name = "flat",
    srcs = ["bar_%s_0.txt" % (
        x
    ) for x in range(0, WIDTH_LIMIT)],
    outs = ["flat.txt"],
    cmd = "touch $@",
)
