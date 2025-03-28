import os
import tkinter as tk
from tkinter import filedialog

def split_vep_file(file_path):
    """Разбивает VEP-файл по хромосомам и сохраняет их в отдельные файлы."""
    
    # Получаем имя файла без расширения
    base_name, ext = os.path.splitext(file_path)
    
    # Открываем файл на чтение
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Отделяем заголовок (начинается с ## или #CHROM)
    header = []
    data_lines = []
    for line in lines:
        if line.startswith('#'):
            header.append(line)
        else:
            data_lines.append(line)
    
    # Группируем строки по хромосомам
    chrom_data = {}
    for line in data_lines:
        chrom = line.split("\t")[0]  # Первая колонка — хромосома
        if chrom not in chrom_data:
            chrom_data[chrom] = []
        chrom_data[chrom].append(line)
    
    # Записываем каждый хромосомный файл
    for chrom, chrom_lines in chrom_data.items():
        output_file = f"{base_name}_{chrom}.vep"
        with open(output_file, 'w', encoding='utf-8') as out_f:
            out_f.writelines(header)  # Записываем заголовок
            out_f.writelines(chrom_lines)  # Записываем данные
        print(f"Создан файл: {output_file}")

# Создаем окно выбора файла
root = tk.Tk()
root.withdraw()  # Скрываем главное окно

file_path = filedialog.askopenfilename(
    title="Выберите VEP-файл",
    filetypes=[("VEP файлы", "*.vep"), ("Все файлы", "*.*")]
)

if file_path:
    split_vep_file(file_path)
    print("Разделение завершено!")
else:
    print("Файл не выбран.")
