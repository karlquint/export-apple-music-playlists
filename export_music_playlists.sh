#!/bin/bash
# export_music_playlists.sh — Export user playlists from Apple Music as M3U or TXT
#
# Usage:
#   ./export_music_playlists.sh [-txt] [output_dir]
#
# Options:
#   -txt        Export as plain text instead of M3U (default: M3U)
#   output_dir  Directory for exported files (default: current directory)
#
# Examples:
#   ./export_music_playlists.sh                    # M3U in current dir
#   ./export_music_playlists.sh ~/Music/Exports    # M3U in ~/Music/Exports
#   ./export_music_playlists.sh -txt               # TXT in current dir
#   ./export_music_playlists.sh -txt ~/Playlists   # TXT in ~/Playlists

set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    sed -n '2,/^$/s/^# \?//p' "$0"
    exit 0
fi

FORMAT="m3u"
OUTPUT_DIR="."

for arg in "$@"; do
    if [[ "$arg" == "-txt" ]]; then
        FORMAT="txt"
    else
        OUTPUT_DIR="$arg"
    fi
done

mkdir -p "$OUTPUT_DIR"

echo "Fetching playlist names from Music app..."

playlist_data=$(osascript <<'APPLESCRIPT'
tell application "Music"
    set output to ""
    repeat with p in (every user playlist)
        try
            if (class of p is not folder playlist) then
                set output to output & (name of p) & (ASCII character 10)
            end if
        end try
    end repeat
    return output
end tell
APPLESCRIPT
)

if [ -z "$playlist_data" ]; then
    echo "No user playlists found."
    exit 0
fi

count=0
while IFS= read -r name; do
    [ -z "$name" ] && continue
    count=$((count + 1))
done <<< "$playlist_data"

echo "Found $count playlist(s). Exporting as ${FORMAT}..."
echo ""

exported=0

while IFS= read -r playlist_name; do
    [ -z "$playlist_name" ] && continue

    safe_name=$(echo "$playlist_name" | tr '/:' '__')

    if [ "$FORMAT" = "m3u" ]; then
        outfile="$OUTPUT_DIR/${safe_name}.m3u"

        osascript - "$playlist_name" <<'APPLESCRIPT' > "$outfile"
on run argv
    set playlistName to item 1 of argv
    tell application "Music"
        set output to "#EXTM3U" & (ASCII character 10)
        try
            set p to user playlist playlistName
            repeat with t in (every track of p)
                try
                    set tName to name of t
                    set tArtist to ""
                    try
                        set tArtist to artist of t
                    end try
                    set durInt to 0
                    try
                        set durInt to round (duration of t) rounding down
                    end try
                    set output to output & "#EXTINF:" & durInt & "," & tArtist & " - " & tName & (ASCII character 10)
                    try
                        set tLoc to POSIX path of (location of t as alias)
                        set output to output & tLoc & (ASCII character 10)
                    on error
                        set output to output & "# No local file" & (ASCII character 10)
                    end try
                end try
            end repeat
        end try
        return output
    end tell
end run
APPLESCRIPT

    else
        outfile="$OUTPUT_DIR/${safe_name}.txt"

        osascript - "$playlist_name" <<'APPLESCRIPT' > "$outfile"
on run argv
    set playlistName to item 1 of argv
    tell application "Music"
        set output to "Playlist: " & playlistName & (ASCII character 10) & (ASCII character 10)
        try
            set p to user playlist playlistName
            set idx to 0
            repeat with t in (every track of p)
                set idx to idx + 1
                try
                    set tName to name of t
                    set tArtist to ""
                    set tAlbum to ""
                    try
                        set tArtist to artist of t
                    end try
                    try
                        set tAlbum to album of t
                    end try
                    set durStr to "0:00"
                    try
                        set tDur to duration of t
                        set mins to (round (tDur / 60) rounding down)
                        set secs to (round (tDur mod 60) rounding down)
                        if secs < 10 then
                            set secStr to "0" & secs
                        else
                            set secStr to secs as text
                        end if
                        set durStr to mins & ":" & secStr
                    end try
                    set line_ to idx & ". " & tArtist & " - " & tName
                    if tAlbum is not "" then
                        set line_ to line_ & " (" & tAlbum & ")"
                    end if
                    set line_ to line_ & " [" & durStr & "]"
                    set output to output & line_ & (ASCII character 10)
                end try
            end repeat
        end try
        return output
    end tell
end run
APPLESCRIPT

    fi

    exported=$((exported + 1))
    echo "  [$exported/$count] $playlist_name -> $(basename "$outfile")"

done <<< "$playlist_data"

echo ""
echo "Done. Exported $exported playlist(s) to: $OUTPUT_DIR"
