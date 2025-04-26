#!/bin/bash

set -e

echo "Stowing dotfiles..."

stow bash
stow nvim

echo "Done!"
