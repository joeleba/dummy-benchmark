# Credit: heavily borrowed from @meisterT's work.
WIDTH_LIMIT = 150000


# A flat base.
[genrule(
    name = "bar_%s" % x,
    outs = ["bar_%s.txt" % x],
    cmd = "touch $@"
) for x in range(0, WIDTH_LIMIT)]

# Benchmark targets
genrule(
    name = "flatwide",
    srcs = ["bar_%s.txt" % (x) for x in range(0, WIDTH_LIMIT)],
    outs = ["flatwide.txt"],
    cmd = "touch $@",
)

