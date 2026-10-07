# UTS Biomedical IC Design — TM1638 LED & Key Display Module
**Nama:** Hanan Zhafirah Atsir
**NIM:** 23/522199/TK/57619 
Project ini dibuat untuk memenuhi tugas Ujian Tengah Semester (UTS) dengan menggunakan **FPGA iCESugar V1.5** dan **TM1638 LED & Key Display Module**.

Sistem membaca 8 push button pada modul TM1638 sebagai input biner 8-bit, kemudian menampilkan nilai tersebut dalam dua format:

- **Hexadecimal** pada sisi kiri display.
- **Decimal** pada sisi kanan display.

Contoh:

| Input switch | Hexadecimal | Decimal | Tampilan |
|---|---:|---:|---|
| `8'b10101010` | `AA` | `170` | `AA 170` |
| `8'b11111111` | `FF` | `255` | `FF 255` |
| `8'b00000000` | `00` | `0` | `00 0` |

## Hardware

- FPGA **iCESugar V1.5**
- TM1638 LED & Key Display Module
- Kabel jumper
- Catu daya modul TM1638

## Input Mapping

Delapan push button pada TM1638 dipetakan menjadi satu nilai biner 8-bit:

```text
S1  S2  S3  S4  S5  S6  S7  S8
│   │   │   │   │   │   │   │
b7  b6  b5  b4  b3  b2  b1  b0
```

Contoh (seperti yang akan terlihat di link video DIBAWAH):

- Jika input switch adalah 8’b11100011 maka display 7 segment sebelah kiri akan menampilkan E3 dan sebelah kanan akan menampilkan 227
- Jika input switch adalah 8’b11000111 maka display 7 segment sebelah kiri akan menampilkan C7 dan sebelah kanan akan menampilkan 199



### Hexadecimal

Nilai 8-bit dibagi menjadi dua nibble:

```verilog
switch_value[7:4]
switch_value[3:0]
```

Masing-masing nibble dikonversi menjadi pola seven-segment menggunakan fungsi `hex_to_seg()`.

### Decimal

Nilai decimal 0–255 dibagi menjadi:

- ratusan (`dec_hundreds`)
- puluhan (`dec_tens`)
- satuan (`dec_ones`)

Konversi menggunakan comparator dan subtraction agar implementasinya sederhana.

Contoh:

```text
170

170 >= 100
hundreds = 1
remainder = 70

70 >= 70
tens = 7
ones = 0

hasil = 170
```

## TM1638 Commands

Command yang digunakan:

```verilog
C_READ  = 8'h42;   // membaca push button
C_WRITE = 8'h40;   // write mode, auto address increment
C_ADDR  = 8'hC0;   // alamat awal display RAM
C_DISP  = 8'h8F;   // display ON
```

Urutan komunikasi utama:

```text
READ KEY (0x42)
      ↓
4 byte key data
      ↓
WRITE MODE (0x40)
      ↓
ADDRESS (0xC0)
      ↓
16 byte display/LED data
      ↓
DISPLAY ON (0x8F)
```

## Troubleshooting

Selama pengembangan ditemukan masalah berupa **glitch / blinking tidak diinginkan** pada seven-segment ketika pembacaan push button diaktifkan.

Beberapa pendekatan sempat diuji, seperti memperlambat komunikasi dan menambahkan filtering. Hasil pengujian menunjukkan bahwa parameter yang paling berpengaruh adalah clock divider pada driver TM1638.

Parameter final yang memberikan hasil stabil pada hardware yang digunakan:

```verilog
localparam CLK_DIV = 3;
```

Pada pengujian, nilai divider yang lebih besar justru tidak memberikan hasil sebaik `CLK_DIV = 3`.

Karena itu versi final mempertahankan:

```verilog
localparam CLK_DIV = 3;
```

Nilai ini dipilih berdasarkan pengujian langsung pada FPGA dan modul TM1638 yang digunakan.

## Demo Video

Video demonstrasi project dapat dilihat melalui link berikut:
https://drive.google.com/file/d/1MuL4PLD3AwQ6bDmN2Thw7C8IjkfEyAzu/view?usp=sharing 



