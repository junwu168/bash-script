#!/bin/awk

# {
#     freq[$10]++
# }
# END {
#     printf "%s\t%s\n", "Http Code", "Frequency"
#     for (k in freq)
#         printf "%s\t\t%d\n", k, freq[k]
# }

BEGIN {FS=":"}
{
    if ($3 >= 11 && $3 <= 13)
        print $0
}
END {

}

