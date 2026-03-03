# Computer Architecture I - Image Denoising in RISC-V

Project developed for the **Computer Architecture I** course at the **University of Évora**.

## Overview
This project involves developing a set of functions in **RISC-V Assembly** to perform noise removal (denoising) on grayscale images. The program handles low-level file operations and implements an algorithm to process and save the resulting image.

## Key Functionalities
* **File I/O:** Opening and reading image files directly in Assembly.
* **Denoising Algorithm:** Implementation of a noise reduction filter on grayscale pixels.
* **Output Management:** Saving the processed data into a new file, maintaining original format and dimensions.

## Technical Context
* **ISA:** RISC-V (32-bit).
* **Tools:** RARS Simulator.
* **Concepts:** Register management, memory addressing, and system calls for file manipulation.

## Project Structure
* [**/src**](./src) - Contains the RISC-V Assembly source code.
* [**/docs**](./docs) - Original assignment and technical report (in Portuguese).
* [**/assets**](./assets) - Input and output images used for testing.

---
*Note: The original assignment and detailed technical report (in Portuguese) can be found in the `/docs` folder.*
