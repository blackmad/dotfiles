#!/usr/bin/env python3
"""
monitor_position.py

A script to position a secondary monitor relative to the primary monitor
with better parsing of displayplacer output.

Usage: python3 monitor_position.py [up|down|left|right] [--debug]
"""

import subprocess
import re
import sys
import argparse
import os
from typing import Dict, List, Tuple, Optional


class Display:
    """Class to store display information"""
    def __init__(self, display_id: str, is_main: bool = False):
        self.id = display_id
        self.resolution = ""
        self.width = 0
        self.height = 0
        self.origin_x = 0
        self.origin_y = 0
        self.is_main = is_main
        self.hertz = 60
        self.color_depth = 8
        self.scaling = False
        self.enabled = True
        self.rotation = 0

    def __str__(self) -> str:
        return (f"Display(id={self.id}, res={self.resolution} ({self.width}x{self.height}), "
                f"origin=({self.origin_x},{self.origin_y}), main={self.is_main})")


def debug_print(message: str, debug_mode: bool = False) -> None:
    """Print debug messages if debug mode is enabled"""
    if debug_mode:
        print(f"[DEBUG] {message}")


def check_displayplacer_installed() -> bool:
    """Check if displayplacer is installed and install it if necessary"""
    try:
        subprocess.run(["which", "displayplacer"], check=True, stdout=subprocess.PIPE)
        return True
    except subprocess.CalledProcessError:
        print("displayplacer tool not found. Attempting to install...")
        try:
            # Check if Homebrew is installed
            subprocess.run(["which", "brew"], check=True, stdout=subprocess.PIPE)
            # Install displayplacer using Homebrew
            subprocess.run(["brew", "install", "jakehilborn/jakehilborn/displayplacer"], check=True)
            return True
        except subprocess.CalledProcessError:
            print("Homebrew not found. Please install displayplacer manually:")
            print("1. Install Homebrew: /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"")
            print("2. Install displayplacer: brew install jakehilborn/jakehilborn/displayplacer")
            return False


def parse_displayplacer_output(output: str, debug_mode: bool = False) -> List[Display]:
    """Parse the output of displayplacer list and return a list of Display objects"""
    displays = []
    current_display = None
    
    # Split output by display sections
    display_sections = re.split(r'Persistent screen id:', output)[1:]
    
    debug_print(f"Found {len(display_sections)} display sections", debug_mode)
    
    for section in display_sections:
        # Get the display ID
        display_id = section.strip().split('\n')[0].strip()
        debug_print(f"Processing display with ID: {display_id}", debug_mode)
        
        # Check if this is the main display
        is_main = "main display" in section
        
        # Create a new Display object
        current_display = Display(display_id, is_main)
        
        # Get the resolution
        resolution_match = re.search(r'Resolution: (\d+)x(\d+)', section)
        if resolution_match:
            width, height = resolution_match.groups()
            current_display.resolution = f"{width}x{height}"
            current_display.width = int(width)
            current_display.height = int(height)
            debug_print(f"Resolution: {current_display.resolution}", debug_mode)
        
        # Get the origin
        origin_match = re.search(r'Origin: \((-?\d+),(-?\d+)\)', section)
        if origin_match:
            origin_x, origin_y = origin_match.groups()
            current_display.origin_x = int(origin_x)
            current_display.origin_y = int(origin_y)
            debug_print(f"Origin: ({current_display.origin_x},{current_display.origin_y})", debug_mode)
        
        # Get scaling
        current_display.scaling = "Scaling: on" in section
        
        # Get hertz
        hertz_match = re.search(r'Hertz: (\d+)', section)
        if hertz_match:
            current_display.hertz = int(hertz_match.group(1))
        
        # Get color depth
        color_depth_match = re.search(r'Color Depth: (\d+)', section)
        if color_depth_match:
            current_display.color_depth = int(color_depth_match.group(1))
        
        # Get rotation
        rotation_match = re.search(r'Rotation: (\d+)', section)
        if rotation_match:
            current_display.rotation = int(rotation_match.group(1))
            
        # Get enabled status
        current_display.enabled = "Enabled: true" in section
        
        displays.append(current_display)
    
    # Sort displays so main display is first
    displays.sort(key=lambda x: 0 if x.is_main else 1)
    
    return displays


def get_displays(debug_mode: bool = False) -> List[Display]:
    """Get the current display arrangement"""
    try:
        result = subprocess.run(["displayplacer", "list"], 
                                check=True, 
                                stdout=subprocess.PIPE, 
                                stderr=subprocess.PIPE, 
                                text=True)
        output = result.stdout
        debug_print(f"Got displayplacer output of length {len(output)}", debug_mode)
        return parse_displayplacer_output(output, debug_mode)
    except subprocess.CalledProcessError as e:
        print(f"Error running displayplacer: {e}")
        print(f"Error output: {e.stderr}")
        sys.exit(1)


def position_secondary_monitor(position: str, debug_mode: bool = False) -> None:
    """Position the secondary monitor relative to the primary monitor"""
    displays = get_displays(debug_mode)
    
    if len(displays) < 2:
        print("Error: At least two displays are required.")
        sys.exit(1)
    
    primary = displays[0]  # First display (should be main)
    secondary = displays[1]  # Second display
    
    debug_print(f"Primary display: {primary}", debug_mode)
    debug_print(f"Secondary display: {secondary}", debug_mode)
    
    # Calculate new position based on direction
    if position == "up":
        new_x = 0
        new_y = -secondary.height
        position_str = "above primary display"
    elif position == "down":
        new_x = 0
        new_y = primary.height
        position_str = "below primary display"
    elif position == "left":
        new_x = -secondary.width
        new_y = 0
        position_str = "to the left of primary display"
    elif position == "right":
        new_x = primary.width
        new_y = 0
        position_str = "to the right of primary display"
    else:
        print(f"Invalid position: {position}")
        sys.exit(1)
    
    debug_print(f"New position: ({new_x},{new_y}) - {position_str}", debug_mode)
    
    # Build the displayplacer command
    primary_scaling = "on" if primary.scaling else "off"
    secondary_scaling = "on" if secondary.scaling else "off"
    
    command = [
        "displayplacer",
        f"id:{primary.id} res:{primary.resolution} enabled:{str(primary.enabled).lower()} scaling:{primary_scaling} origin:(0,0)",
        f"id:{secondary.id} res:{secondary.resolution} enabled:{str(secondary.enabled).lower()} scaling:{secondary_scaling} origin:({new_x},{new_y})",
    ]
    
    debug_print(f"Command: {' '.join(command)}", debug_mode)
    
    print(f"Positioning secondary monitor {position_str}...")
    
    try:
        if debug_mode:
            print(f"Executing: {' '.join(command)}")
            result = subprocess.run(command, check=True, text=True)
        else:
            result = subprocess.run(command, 
                                   check=True, 
                                   stdout=subprocess.DEVNULL, 
                                   stderr=subprocess.PIPE, 
                                   text=True)
        print("Display arrangement updated successfully!")
    except subprocess.CalledProcessError as e:
        print(f"Error updating display arrangement: {e}")
        if e.stderr:
            print(f"Error output: {e.stderr}")
        sys.exit(1)


def main():
    """Main function"""
    parser = argparse.ArgumentParser(description="Position a secondary monitor relative to the primary monitor.")
    parser.add_argument("position", choices=["up", "down", "left", "right"], 
                        help="Position of the secondary monitor relative to the primary monitor")
    parser.add_argument("--debug", action="store_true", help="Enable debug mode")
    
    args = parser.parse_args()
    
    if args.debug:
        print("Debug mode enabled")
    
    # Check if displayplacer is installed
    if not check_displayplacer_installed():
        sys.exit(1)
    
    # Position the secondary monitor
    position_secondary_monitor(args.position, args.debug)


if __name__ == "__main__":
    main()
