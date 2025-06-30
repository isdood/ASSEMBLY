#!/bin/bash

# Save terminal settings
original_settings=$(stty -g)

# Set terminal to raw mode
stty raw -echo -icanon -isig

# Run the test game
./test_game

# Restore terminal settings
stty "$original_settings"

# Clear screen and show cursor
echo -e "\033[2J\033[H\033[?25h"

exit 0
