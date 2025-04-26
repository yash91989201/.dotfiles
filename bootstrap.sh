#!/bin/bash

set -e

echo "Stowing dotfiles..."

stow bash
stow nvim
stow git
stow profile

echo "Done!"
