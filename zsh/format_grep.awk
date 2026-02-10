BEGIN {
}

{
    # Find the first colon after .stats to split filename from content
    match($0, /\.stats:/)
    file = substr($0, 1, RSTART + 5)  # Include ".stats"
    line = substr($0, RSTART + 7)     # Skip ".stats: "
    
    # Extract key-value pairs from JSON-like format
    if (match(line, /"([^"]+)": "([^"]+)"/, arr)) {
        key = arr[1]
        value = arr[2]
        
        # Store value for this file and key
        data[file][key] = value
        
        # Track all keys we've seen (in order)
        if (!(key in keys)) {
            keys[key] = ++key_count
        }
    }
}

END {
    # Build header with all keys in order they were seen
    header = "File"
    n = asorti(keys, sorted_keys, "@val_num_asc")
    for (i = 1; i <= n; i++) {
        header = header "\t" sorted_keys[i]
    }
    print header
    
    # Print data for each file
    for (f in data) {
        row = f
        for (i = 1; i <= n; i++) {
            key = sorted_keys[i]
            row = row "\t" (key in data[f] ? data[f][key] : "")
        }
        print row
    }
}
