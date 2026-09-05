#!/bin/bash
# Prohíbe que secrets.plain.yml esté en el repositorio
if [ -f secrets.plain.yml ]; then
    echo "❌ Error: secrets.plain.yml no debe estar en el repositorio. Elimínalo."
    exit 1
fi
exit 0
