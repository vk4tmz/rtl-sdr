# 92.7 MIX FM / 93.3 SBS interference — investigation baseline

## Reproduction (18 October 2026, devlap200 RTL2832U/R820T)

Audio of **93.3 MHz SBS Radio** is dominant while tuning `rtl_fm` to **92.7 MHz MIX FM**, despite separate saved NooElec CU8 recordings successfully recovering MIX FM audio and its RDS (`7718`, `927mixfm`) using the independent `fm-measure` demodulator. Another receiver (RX888 SDDC) also recovers MIX FM with independent demodulation. Hardware differences therefore are not isolated as a cause. Gain reduction does not eliminate SBS audio. Different `-s`, `-o` and `-F` settings change the mixture.

Original command:

```bash
rtl_fm -f 92.7M -M fm -s 240k -o 4 -A fast -r 48000 -g 19.7 -p 44 -E deemp | aplay -t raw -f S16_LE -r 48000 -c 1
```

Observed startup:

```text
Warning: -o is very buggy
Tuned to 93180000 Hz.
Oversampling input by: 2x.
Oversampling output by: 4x.
Sampling at 1920000 S/s.
Output at 240000 Hz.
```

Hardware tuning +480 kHz is intentional in `optimal_settings`: capture sample rate / 4, compensated by `rotate_90` in the callback. It must not be interpreted on its own as mistuning.

## Source audit starting points

- `optimal_settings`: computes capture centre and sample rate; default `capture_rate/4` offset
- `rtlsdr_callback`: `rotate_90` mixer and conversion to signed 16-bit interleaved IQ
- `full_demod`: `low_pass` default boxcar decimation, optional multi-stage fifth-order filters; FM discriminator; `low_pass_simple` post-downsample; optional `low_pass_real` experimental resampling
- `controller_thread_fn`: `Output at` is `rate_in / post_downsample` and does not necessarily describe final resampled PCM when `-r` is present

**Hypothesis:** insufficient stopband attenuation in one or more decimation paths may alias very strong SBS into MIX FM output. This has not been demonstrated with matched IQ or controlled DSP measurements, and cannot yet be called a confirmed software bug.

## Required diagnosis before changing DSP

1. Reproduce with fixed/nooelec-recorded input samples, or add optional intermediate IQ capture tap and compare with an independent channel-selecting FM decoder. Baseline includes 92.7 target and 93.3 strong adjacent (600 kHz higher).
2. Measure spectral energy at receiver input, after the 90-degree shift, after IQ decimation, and after output decimation. Log exact rates and sample counts without introducing persistent blocking in the capture thread.
3. Build a synthetic deterministic 2-channel IQ regression (weaker desired + strong interferer) with different FM audio tones, at realistic input rates. Test listening output rate and demodulated content, not merely radio setup.
4. Implement minimal anti-alias fix based on measurements; ensure other modes and supported sample rates still work.
5. On real hardware, require 92.7 MIX FM music rather than SBS; separately verify 93.3 SBS and normal 104.5 broadcast mono and basic narrowband FM, plus PCM byte rate.

Tracking companion: `vk4tmz/fm-measure` notes/FM-011-rtl-fm-adjacent-station-audio-2026-10-18.md. No code change has been validated at this checkpoint.
