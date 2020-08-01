#!/bin/sh
for x in fonts/*.ttf; do
  mkdir "${x%.*}" && mv "$x" "${x%.*}"
done
