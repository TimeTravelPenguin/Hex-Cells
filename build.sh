#!/usr/bin/env sh

echo "Compiling main.pdf"
typst compile --root . main.typ main.pdf

echo "Compiling main.png"
typst compile --root . --ppi 1000 main.typ main.png

echo "Compiling main.svg"
typst compile --root . main.typ main.svg

echo "Done"
