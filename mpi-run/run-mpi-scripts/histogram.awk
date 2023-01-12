#!/usr/bin/awk -f

BEGIN{
    bin_width=5;
    
}
{
    bin=int(($1-0.0001)/bin_width);
    if( bin in hist){
        hist[bin]+=1
    }else{
        hist[bin]=1
    }
}
END{
	count=0
	for (h in hist)
		count=((count + hist[h]))
	printf "Total Pairs: %i \n", count
	printf "B/W (GB/s) \t\t Count \t\t Percentage\n"
    for (h in hist)
        printf "%2.2f \t\t %i \t\t  %2.2f\n", h*bin_width, hist[h], (hist[h] * 100)/count
}
