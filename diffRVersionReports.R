# diff two R_VERSION files

args = commandArgs(trailingOnly = TRUE)
print(args)

f1 = args[1]
f2 = args[2]

t1 = read.table(f1)
t2 = read.table(f2)

t3 = dplyr::full_join(t1, t2, by = c("V1"))
o = order(t3[, 1])
t3 = t3[o, ]

# which ones mismatch on version
t3[which(t3[, 2] != t3[, 3]), ]

# which ones are in f2 but not f1
t3[which(is.na(t3[, 2])), ]

## which ones are in f1 but not f2
t3[which(is.na(t3[, 3])), ]
