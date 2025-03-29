# bln_multicoords

<img src="./.github/assets/banner.png" style="width:100%" alt="bln multicoords redm script - standalone - bln studio" />

A simple developer resource for RedM that allows you to collect coordinates with heading (vector4) by walking around the map. Perfect for creating locations, spawn points, or any other position-based data for your RedM scripts.

[![](https://img.shields.io/badge/YouTube-FF0000?style=flat&logo=youtube&logoColor=white)](https://youtu.be/QSGFewxUQ60)
[![Discord](https://img.shields.io/badge/Discord-1111?style=flat&logo=discord&logoColor=white&color=7289da)](https://discord.bln-studio.com/)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/blnStudio/bln_multicoords)
![License](https://img.shields.io/github/license/blnStudio/bln_multicoords)

## Features

🎯 Collect coordinates (vector4) by walking and pressing keys  
🎨 Visual markers showing collected points  
🧭 Direction indicators showing heading  
🚫 Prevents duplicate/too close positions  
📋 Automatically copies coordinates to clipboard in Lua table format  
💬 On-screen notifications for actions  
⚡ Simple to use with basic commands  
🔄 Clean and optimized code

## Installation

1. Download the resource
2. Place `bln_multicoords` folder in your resources directory
3. Add `ensure bln_multicoords` to your server.cfg

## Usage

1. Start collecting coordinates:
   ```
   /mcoords
   ```

2. Controls:
   - `ENTER` - Add current position and heading to the list
   - `BACKSPACE` - Finish collecting and copy coordinates to clipboard

3. Visual Feedback:
   - `Yellow markers` show collected positions
   - `Red markers` indicate heading direction of a coord.
   - Text notifications appear for actions

## Example Output

```lua
{
    vector4(-1245.12, 2687.32, 62.94, 175.45),
    vector4(-1267.89, 2699.54, 63.12, 89.67),
    vector4(-1289.34, 2701.87, 63.45, 265.89),
}
```

## Notes
- The resource prevents collecting duplicate points that are too close to each other (within 1.0 units)
- Coordinates are automatically copied to clipboard when finished
- Visual markers remain visible while collecting to help visualize the path
- Heading is shown with a red marker pointing in the facing direction

## Support
Join our Discord for support and updates:
https://discord.com/invite/MEZRYQVpnt

## License
Free to use and modify. Please retain credits if redistributing.
