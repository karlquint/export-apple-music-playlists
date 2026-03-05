# Export Apple Music playlists

A simple shell script to export all user playlists from the macOS **Music** app as **M3U** or plain **text** files.

## Why?

Apple Music has no built-in way to export playlists as portable files. This script talks to the Music app via AppleScript and writes one file per playlist — ready to import into VLC, foobar2000, Plex, or any other player that understands M3U.

## Requirements

- macOS (tested on Tahoe)
- The **Music** app (will launch automatically if not running)

No dependencies, no installs — just a single bash script.

## Usage

```bash
chmod +x export_music_playlists.sh

# Export all playlists as M3U in the current directory
./export_music_playlists.sh

# Export to a specific folder
./export_music_playlists.sh ~/Music/Exports

# Export as plain text instead of M3U
./export_music_playlists.sh -txt

# Both options combined (order doesn't matter)
./export_music_playlists.sh -txt ~/Music/Exports
./export_music_playlists.sh ~/Music/Exports -txt
```

## Output formats

### M3U (default)

Standard extended M3U with duration, artist, title, and local file path:

```
#EXTM3U
#EXTINF:243,Radiohead - Everything In Its Right Place
/Users/you/Music/Music/Media/Radiohead/Kid A/01 Everything In Its Right Place.m4a
```

Tracks without a local file (Apple Music streaming only) are marked with a comment:

```
#EXTINF:195,Artist - Title
# No local file
```

### Text (`-txt`)

Human-readable numbered list with artist, title, album, and duration:

```
Playlist: My Favorites

1. Radiohead - Everything In Its Right Place (Kid A) [4:03]
2. Björk - Jóga (Homogenic) [5:05]
```

## What gets exported?

All **user-created playlists**, including smart playlists. Folder playlists (which are just containers) and built-in library views are skipped.

## Notes

- For large libraries the export can take a while — AppleScript track enumeration isn't fast. Progress is shown in the terminal.
- Filenames are sanitized (`:` and `/` are replaced with `_`).
- The script creates the output directory if it doesn't exist.

## License

MIT


