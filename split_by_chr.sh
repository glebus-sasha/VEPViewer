#!/bin/bash

# Проверяем, передан ли аргумент
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input.vep>"
    exit 1
fi

input_file="$1"
output_dir=$(dirname "$input_file")
base_name=$(basename "$input_file" .vep)

# Определяем номер столбца с хромосомой (обычно первый)
chrom_col=1

# Извлекаем заголовок (строки, начинающиеся с '#')
header=$(grep "^#" "$input_file")

# Получаем список всех уникальных хромосом (исключая заголовок)
chromosomes=$(grep -v "^##" "$input_file" | awk -v col="$chrom_col" 'NR > 1 {print $col}' | sort -u)

# Разбиваем по хромосомам
for chrom in $chromosomes; do
    # Пропускаем пустые строки
    if [[ -z "$chrom" || "$chrom" == "#CHROM" ]]; then
        continue
    fi

    output_file="${output_dir}/${base_name}_chr${chrom}.vep"
    
    # Записываем заголовок
    echo "$header" > "$output_file"
    
    # Фильтруем строки по хромосоме
    grep -v "^##" "$input_file" | awk -v col="$chrom_col" -v chr="$chrom" '$col == chr' >> "$output_file"
    
    echo "Created: $output_file"
done

echo "Splitting complete."
