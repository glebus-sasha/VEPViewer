# VEPViewer
A Shiny app for interactive visualization of VCF/VEP files, allowing users to upload, filter, and explore variant data.

## Installation

### Prerequisites
Make sure you have R and the required packages installed:

```r
install.packages(c("shiny", "dplyr", "tidyr", "DT", "vcfR"))
```

Clone the repository:

```sh
git clone https://github.com/glebus-sasha/VEPViewer.git
cd VEPViewer
```

## Running the Application

### Windows
Run the `run.bat` file:
```sh
run.bat
```
Alternatively, run from R:
```r
shiny::runApp("app.R", launch.browser = TRUE)
```

### Linux
Run the `run.sh` script:
```sh
./run.sh
```

Alternatively, run from R:
```r
shiny::runApp("app.R", launch.browser = TRUE)
```

## Usage
- Upload a `.vcf` or `.vep` file.
- Use the interactive table to filter and explore variants.
- Select which columns to display.

## License
This project is licensed under the MIT License.

