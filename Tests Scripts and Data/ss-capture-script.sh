#!/bin/bash

# Input file
cat "bbr -cubic vs cubic.csv" | grep 7575 > input.csv
input_file="input.csv"

# Output file
output_file="output.csv"
rm "$output_file"

# Loop through each line in input file
while IFS= read -r line; do
    # Extract fields using cut and grep
    timestamp=$(echo "$line" | cut -d ',' -f 1)
    portno=$(echo "$line" | cut -d ',' -f 8)
    bytes_sent=$(echo "$line" | grep -o 'bytes_sent=[0-9]\+' | cut -d '=' -f 2)
    delivered=$(echo "$line" | grep -o 'delivered=[0-9]\+' | cut -d '=' -f 2)
    lastack=$(echo "$line" | grep -o 'lastack=[0-9]\+' | cut -d '=' -f 2)
    rtt=$(echo "$line" | grep -o 'rtt=[0-9.]\+\/[0-9.]\+' | cut -d '=' -f 2 | cut -d '/' -f 1)
    rttvar=$(echo "$line" | grep -o 'rtt=[0-9.]\+\/[0-9.]\+' | cut -d '=' -f 2 | cut -d '/' -f 2)
    allrtt=$(echo "$line" | grep -o 'rtt=[0-9.]\+\/[0-9.]\+')
    

    # Format into CSV line
    csv_line="${timestamp},${portno},${bytes_sent},${delivered},${lastack},${rtt},${rttvar},${allrtt}"

    # Append to output file
    echo "$csv_line" >> "$output_file"
done < "$input_file"

rm "$input_file"
