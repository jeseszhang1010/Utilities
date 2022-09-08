grep "^ 17179869184" *.o* | awk '{print $12}' | sort -n  | ../histogram.awk
