# Filter comparison 2026-10-18: recorded PCM diagnostic review

Source archive: `rtl-fm-927-filter-comparison.tar.gz` uploaded by user. Capture host `devlap200`, local NooElec RTL2832U R820T, 92.7 MHz MIX FM near stronger 93.3 SBS Radio. The tested executable SHA256 was `716cb18da7ca68a4a0f401c5ad3b112022b9f5df4cbd3d4e26247c49290beada`. Linked library in isolated build tree, not `/usr/local`.

| Mode | tuner setting | recorded bytes | duration if 48 kHz mono S16 | wall time |
|---|---|---:|---:|---:|
| baseline (boxcar) | 93.180 MHz / 1.920 MS/s | 1,091,174 | 11.366 s | 12.048 s |
| FIR9 (with -o4) | 93.660 MHz / **invalid 3.840 MS/s** | 1,121,484 | 11.682 s | 24.062 s |
| sharp (-E sharp, -o4) | 93.180 MHz / 1.920 MS/s | 4,548,198 | **47.377 s** | **48.094 s** |

**Essential caveats:**

- FIR9 did **not** successfully set the intended sample rate. The driver reported `Invalid sample rate: 3840000 Hz` and `WARNING: Failed to set sample rate`. Its PCM is not a valid clean comparison or meaningful source for quality ranking. `-F 9` changes capture settings; choose a valid capture rate, e.g. try `-F 9 -o 1 -s 240k` (expected 1.92 MS/s by code calculation), and inspect the hardware log.
- Sharp output duration is **4x nominal**, accompanied by 48 s wall time rather than the requested 12 s. This must be investigated before claiming real-time throughput or correct PCM sample accounting. Causes such as computational backlog, thread shutdown timing or output-rate mismatch are hypotheses, not established.
- RMS and DC of PCM: baseline 14,772 / +13,838 (units int16); FIR9 14,495 / -461; sharp 1,088 / -128. These samples were recorded at different moments, so the amplitude and offset difference is **not** a calibrated RF quality comparison.
- User's live ear tests: `-E sharp` recovered audible MIX FM (some static); 93.3 SBS and 104.5 Triple M were clear. These are distinct from proving spectral selectivity, CPU headroom or PCM rate correctness.
- This experimental feature must remain opt-in, not upstreamed until deterministic same-IQ tests, actual-rate verification, 92.7/93.3 station rejection tests, and timing are demonstrated.

**Next:** reproduce each branch with a deterministic IQ test harness and instrument sample counts / callback timing; test FIR9 with hardware-valid rate; profile sharp CPU/processing; compare known signal audio strength and guard against output overruns. Retain original failure and successful station tests separately.
