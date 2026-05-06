# ==============================================================================
# BLOK 1: Penentuan Lokasi File Library Binary (Pathing)
# ==============================================================================
# Tujuan: Menentukan path absolut ke file library (.lib/.so/.dylib) secara dinamis
# agar skrip build Anda bersifat portable (bisa jalan di Windows, Linux, atau macOS).
#
# WIN32: Variabel internal CMake yang bernilai TRUE jika target sistem adalah Windows.
#
# CMAKE_IMPORT_LIBRARY_PREFIX/SUFFIX:
#   Di Windows, linker membutuhkan "Import Library" (.lib) sebagai perantara untuk
#   menghubungkan program Anda dengan file .dll pada saat runtime.
#
# CMAKE_SHARED_LIBRARY_PREFIX/SUFFIX:
#   Di sistem Unix-like (Linux/macOS), linker langsung menautkan program Anda ke
#   Shared Object (.so) atau Dynamic Library (.dylib).
# ==============================================================================
if(WIN32)
  # Jika Windows, cari file import library (.lib)
  set(TORCH_PYTHON_IMPORTED_LOCATION "${PYTORCH_INSTALL_DIR}/lib/${CMAKE_IMPORT_LIBRARY_PREFIX}torch_python${CMAKE_IMPORT_LIBRARY_SUFFIX}")
else()
  # Jika bukan Windows, cari file shared library (.so / .dylib)
  set(TORCH_PYTHON_IMPORTED_LOCATION "${PYTORCH_INSTALL_DIR}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}torch_python${CMAKE_SHARED_LIBRARY_SUFFIX}")
endif()

# ==============================================================================
# BLOK 2: Mendefinisikan Target "torch_python" sebagai Import Library
# ==============================================================================
# add_library(nama_target TIPE IMPORTED):
#   - Nama target: 'torch_python'.
#   - Tipe 'SHARED': Memberitahu CMake bahwa ini adalah file library dinamis (runtime link).
#   - Tipe 'IMPORTED': Memberitahu CMake bahwa ini BUKAN target yang dibangun dari 
#     source code (bukan hasil kompilasi lokal), melainkan file yang sudah ada 
#     (pre-built) di sistem Anda.
# ==============================================================================
add_library(torch_python SHARED IMPORTED)

# set_target_properties: Mengatur metadata agar CMake tahu cara menggunakan target ini.
set_target_properties(torch_python PROPERTIES
  # INTERFACE_INCLUDE_DIRECTORIES: Lokasi file header (.h/.hpp) yang harus 
  # disertakan (include) oleh target lain yang menggunakan torch_python.
  INTERFACE_INCLUDE_DIRECTORIES "${PYTORCH_INSTALL_DIR}/include"
  
  # INTERFACE_LINK_LIBRARIES: Daftar library lain yang wajib di-link bersama 
  # torch_python agar program tidak error "undefined symbol" (dependensi transitif).
  # Di sini: c10 dan torch_cpu harus ikut disertakan.
  INTERFACE_LINK_LIBRARIES "c10;torch_cpu"
  
  # IMPORTED_LOCATION: Path file fisik (binary) yang digunakan linker untuk 
  # menautkan program Anda saat build time.
  IMPORTED_LOCATION "${TORCH_PYTHON_IMPORTED_LOCATION}"
)

# ==============================================================================
# BLOK 3: Mendefinisikan Interface Alias "torch_python_library"
# ==============================================================================
# Kenapa ada interface? 
# Seringkali, library pihak ketiga memerlukan pengaturan yang panjang. Kita membuat
# "Interface Library" agar user cukup memanggil satu nama target: "torch_python_library".
# Interface library tidak memiliki file output sendiri; ia hanya "pembungkus" 
# properti untuk diteruskan ke target lain.
# ==============================================================================
add_library(torch_python_library INTERFACE IMPORTED)

# Generator Expressions ($<...>):
# Ini adalah logika "If" di dalam proses build CMake.
#
# $<TARGET_PROPERTY:target,prop>: Mengambil properti dari target lain.
#   Artinya: "Ambil settingan INTERFACE_INCLUDE_DIRECTORIES dari torch_python".
#
# $<TARGET_FILE:target>: 
#   Mengambil path absolut ke file binary target tersebut.
#
# Mengapa menggunakan generator expressions?
# Agar jika properti torch_python berubah di masa depan, torch_python_library 
# akan otomatis terupdate tanpa perlu mengubah baris kode di blok ini.
# ==============================================================================
set_target_properties(torch_python_library PROPERTIES
  # Menyebarkan lokasi header file ke target yang menggunakan interface ini.
  INTERFACE_INCLUDE_DIRECTORIES "$<TARGET_PROPERTY:torch_python,INTERFACE_INCLUDE_DIRECTORIES>"
  
  # Menggabungkan binary file utama dan semua dependensi library lainnya menjadi satu paket.
  INTERFACE_LINK_LIBRARIES "$<TARGET_FILE:torch_python>;$<TARGET_PROPERTY:torch_python,INTERFACE_LINK_LIBRARIES>"
)
