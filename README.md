# Signal Processing Project

A MATLAB signal-processing project covering several practical digital signal
processing tasks: removing tonal noise from an audio recording with an FIR
filter, designing a Chebyshev Type II notch filter to reject narrowband
interference, applying a time-varying chorus effect, and estimating the
parameters of a noisy sensor signal using least squares with time- and
frequency-domain analysis.

Originally developed for a university signal processing module.

## Overview

The project is organised as a single driver function that runs three
independent stages and collects their results into one output structure:

```matlab
results = signal_processing_project();
```

Each stage is self-contained and stores its outputs in a named field
(`results.audio`, `results.filter`, `results.estimate`).

## Stages

### 1. Audio processing (`process_audio`)

- Loads a raw audio clip and adds a noise vector to it.
- Computes the FFT of the noisy signal and plots its magnitude spectrum,
  identifying the dominant noise tone.
- Designs a high-order FIR band-stop filter centred on the noise frequency and
  applies it to clean the signal.
- Applies a chorus effect using a time-varying delay, mixing the original
  signal with two slowly modulated delayed copies.

The plot below compares the noisy signal (blue) with the filtered signal
(red). The noise tone produces a near-constant amplitude band across the whole
clip; after filtering, the signal collapses to near-zero in the quiet sections
and only the genuine audio content remains.

![Noisy vs filtered audio](preview(1).webp)

*(The filtered signal appears time-shifted relative to the noisy one — this is
the expected group delay introduced by the FIR filter.)*

### 2. Filter design (`design_filter`)

- Designs a Chebyshev Type II band-stop (notch) filter to reject a narrowband
  interference tone, given attenuation and ripple specifications.
- Uses `cheb2ord` to find the minimum filter order, then `cheby2` for the
  coefficients.
- Plots the magnitude and phase responses, annotated with the stop-band edges,
  attenuation level, and interference frequency.

### 3. Signal estimation (`estimate_signal`)

- Fits a known signal model (a sum of a rising exponential, a decaying
  oscillation, and a sinusoid) to noisy sensor data using least squares.
- Reconstructs the predicted signal and computes the mean squared error
  against the measured data.
- Compares the spectra of the measured and predicted signals, labelling the
  strongest peaks in each.

## Running the project

Open MATLAB in the project directory and run:

```matlab
results = signal_processing_project();
```

The function looks for two data files on the path:

- `lab_Audio.mat` — containing the raw audio vector (`audioRaw`)
- `lab_signals.mat` — containing the noise vector (`n1`) and sensor data (`T`)

If these files are not present, the corresponding stages are skipped and their
output fields are returned empty, so the function still runs cleanly.

### Listening to the audio (optional)

The audio is sampled at 22050 Hz. To play a processed signal:

```matlab
soundsc(results.audio.filtered, 22050);
```

`soundsc` is used in preference to `sound` because it auto-scales the signal,
avoiding clipping on signals whose amplitude exceeds the [-1, 1] range.

## Requirements

- MATLAB
- Signal Processing Toolbox (for `fir1`, `freqz`, `cheb2ord`, `cheby2`,
  `findpeaks`)

## Repository structure

```
.
├── signal_processing_project.m
├── images/
│   └── noisy_vs_filtered.png
└── README.md
```
