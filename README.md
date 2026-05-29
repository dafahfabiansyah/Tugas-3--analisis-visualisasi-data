# Visualisasi Data Cuaca Interaktif - Shiny App
**STSI 4204 | Tugas Tutorial 3**

Aplikasi visualisasi data interaktif berbasis R Shiny menggunakan dataset cuaca Australia (366 observasi, 22 variabel).

---

## Prasyarat

Pastikan sudah terinstall:
- **R** versi 4.0 atau lebih baru → https://cran.r-project.org
- **RStudio** → https://posit.co/download/rstudio-desktop

---

## Cara Menjalankan

### 1. Download / Clone project ini

Pastikan dua file berikut berada dalam **satu folder yang sama**:
```
📁 Tugas 3/
 ├── app.R
 └── Data set Tugas tutorial 3 STSI 4204.xlsx
```

### 2. Install package yang dibutuhkan

Buka RStudio, lalu jalankan perintah berikut di **Console** (cukup sekali):

```r
install.packages(c("shiny", "readxl", "ggplot2", "dplyr", "plotly", "DT"))
```

### 3. Jalankan aplikasi

**Cara A — Buka file di RStudio:**
1. Buka file `app.R` di RStudio
2. Klik tombol **▶ Run App** di pojok kanan atas editor

**Cara B — Via Console:**
```r
shiny::runApp("path/ke/folder/Tugas 3")
```
Ganti `path/ke/folder/` dengan lokasi folder di komputer Anda.

---

## Fitur Aplikasi

| Jenis Visualisasi | Keterangan |
|---|---|
| **Scatter Plot** | Pilih 2 variabel numerik, warna berdasarkan kategori, garis trend LOESS opsional |
| **Line Plot** | Visualisasi hubungan dua variabel dalam bentuk garis |
| **Bar Plot** | Distribusi variabel kategorikal (Count atau Rata-rata nilai numerik) |
| **Tabel Data** | Tampilkan & filter data mentah, ekspor ke CSV/Excel |

Semua plot bersifat **interaktif** (zoom, hover, pan) menggunakan library `plotly`.

---

## Dataset

Dataset cuaca harian dari stasiun **Canberra, Australia** (2008–2009).

| Kolom | Deskripsi |
|---|---|
| MinTemp / MaxTemp | Suhu minimum & maksimum (°C) |
| Rainfall | Curah hujan (mm) |
| Evaporation | Evaporasi (mm) |
| Sunshine | Durasi sinar matahari (jam) |
| WindGustSpeed | Kecepatan angin kencang (km/h) |
| Humidity9am / Humidity3pm | Kelembaban pukul 9 pagi & 3 sore (%) |
| Pressure9am / Pressure3pm | Tekanan udara (hPa) |
| Cloud9am / Cloud3pm | Tutupan awan (oktas) |
| Temp9am / Temp3pm | Suhu pukul 9 pagi & 3 sore (°C) |
| RainToday / RainTomorrow | Apakah hujan hari ini/besok (Yes/No) |

---

## Troubleshooting

**Error: `there is no package called 'shiny'`**
→ Jalankan ulang perintah install di langkah 2.

**Error: file Excel tidak ditemukan**
→ Pastikan file `.xlsx` berada di **folder yang sama** dengan `app.R`, dan nama filenya tidak berubah.

**Port sudah dipakai**
→ Di Console jalankan: `shiny::runApp(port = 3839)`
