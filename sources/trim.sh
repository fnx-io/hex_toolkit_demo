#!/bin/bash

# Zkontroluje, zda je nainstalován ImageMagick
if ! command -v convert &> /dev/null
then
    echo "Chyba: ImageMagick (příkaz 'convert') není nainstalován."
    echo "Pro Ubuntu/Debian nainstalujte: sudo apt-get install imagemagick"
    echo "Pro Fedora/RHEL nainstalujte: sudo dnf install ImageMagick"
    echo "Pro macOS (s Homebrew) nainstalujte: brew install imagemagick"
    exit 1
fi

echo "Prohledávám PNG soubory v aktuálním adresáři, ořezávám průhledné okraje a měním velikost na 256x256..."

# Projde všechny PNG soubory v aktuálním adresáři
for file in *.png; do
    if [ -f "$file" ]; then
        filename=$(basename -- "$file")
        output_file="../assets/images/hex/${filename}"

        echo "Zpracovávám soubor: $file -> $output_file"
        # 1. Ořízne průhledné okraje (-trim)
        # 2. Změní velikost na 256x256, s tím, že se přizpůsobí delší strana a menší se doplní průhlednou plochou (-resize 256x256)
        # 3. Vycentruje obrázek v plátně 256x256 (-gravity Center -extent 256x256)
        convert "$file" \
                -trim \
                -resize 256x256 \
                -background none \
                -gravity Center \
                -extent 256x256 \
                "$output_file"

        if [ $? -eq 0 ]; then
            echo "Úspěšně zpracováno."
        else
            echo "Došlo k chybě při zpracování souboru: $file"
        fi
    fi
done

echo "Hotovo. Zpracované obrázky byly uloženy do ../assets/images/hex/"