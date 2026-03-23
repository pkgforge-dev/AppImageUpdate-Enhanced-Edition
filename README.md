# ⚠️ DEPRECATED ⚠️

# Superseded by https://github.com/pkgforge-dev/AppImageUpdate

---


# AppImageUpdate Enhanced Edition 🐧

[![GitHub Downloads](https://img.shields.io/github/downloads/pkgforge-dev/AppImageUpdate-Enhanced-Edition/total?logo=github&label=GitHub%20Downloads)](https://github.com/pkgforge-dev/AppImageUpdate-Enhanced-Edition/releases/latest)
[![CI Build Status](https://github.com//pkgforge-dev/AppImageUpdate-Enhanced-Edition/actions/workflows/main.yml/badge.svg)](https://github.com/pkgforge-dev/AppImageUpdate-Enhanced-Edition/releases/latest)

* [Latest Stable Release](https://github.com/pkgforge-dev/AppImageUpdate-Enhanced-Edition/releases/latest)

---

Fork of AppImageUpdate with the following advantages: 

* **Unrestricted operation:** Efficiently bypasses rate limits for seamless updates.

* **Truly works everywhere:** Works on any linux distros, **be it musl distro or 10 year old distro** 

* **Debloated:** Optimized to significantly reduce file size **to half the original** without compromising functionality.

Additionally, this enhanced edition combines the `validate` and `appimageupdatetool` CLI into a single AppImage. Symlink the AppImage as `validate` for direct usage or give `validate` as the first argument to use it.
    
**Why use this application?**

Here is a simple demonstrartion with the CPU-X AppImage, where it used only **2.65 MiB** to update a 33 MIB application: 

![image](https://github.com/user-attachments/assets/b1a961c0-4796-4072-b97c-1b493e35fd98)


Also check [appimagetool-uruntime](https://github.com/pkgforge-dev/appimagetool-uruntime) for a better appimagetool
