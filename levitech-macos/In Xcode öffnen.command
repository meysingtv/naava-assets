#!/bin/bash
#
# LEVITECH – öffnet das Projekt in Xcode.
# Doppelklick auf diese Datei im Finder.
#
cd "$(dirname "$0")" || exit 1
open LEVITECH.xcodeproj
