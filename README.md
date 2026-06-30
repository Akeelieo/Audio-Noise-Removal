# Signal Processing Project

A MATLAB signal-processing project: FIR audio denoising, IIR (Chebyshev) notch filter design, a time-varying chorus effect, and least-squares signal estimation.

## Run

```matlab
results = signal_processing_project();
```

Three stages run independently, storing results in `results.audio`, `results.filter`, and `results.estimate`.

## 1. Audio processing (`process_audio`)

Noise is added to the clean signal and its spectrum found with the discrete Fourier transform:

$$X[k] = \sum_{n=0}^{N-1} x[n]\, e^{-j 2\pi n k / N}, \qquad k = 0, 1, \dots, N-1$$

evaluated by the FFT. Each bin maps to a frequency $f_k = k f_s / N$, so the dominant noise tone is read off directly.

That tone is removed with an FIR (non-recursive) band-stop filter, whose output is

$$y[n] = \sum_{k=0}^{M} b[k]\, x[n-k]$$

![Noisy vs filtered audio](preview%20(1).webp)

Blue is the noisy signal, red the filtered result. The noise tone shows as a near-constant amplitude band; once filtered, only genuine audio remains. The red trace is offset by the filter's group delay of $M/2$ samples.

A chorus effect is then applied with two slowly modulated delays:

$$y[n] = x[n] + \alpha_1\, x\big[n - (D_1 + 5\sin(2\pi f n))\big] + \alpha_2\, x\big[n - (D_2 + 10\sin(2\pi f n + \tfrac{\pi}{2}))\big]$$

## 2. Filter design (`design_filter`)

A recursive (IIR) Chebyshev Type II band-stop filter rejects a narrowband tone at $f_o$. The general difference equation is

$$y[n] = \sum_{k=0}^{M} b[k]\, x[n-k] - \sum_{k=1}^{N} a[k]\, y[n-k]$$

with $a[0]=1$. The order is found with `cheb2ord`, the coefficients $b[k]$, $a[k]$ with `cheby2`, and the magnitude and phase responses are plotted with `freqz`.

## 3. Signal estimation (`estimate_signal`)

Noisy sensor data is written as a linear model

$$\vec{y} = \Theta\,\vec{\phi} + \vec{w}$$

where $\Theta$ is the observation matrix whose columns are the model's basis functions:

$$\Theta = \big[\; 1 - e^{-0.20t} \quad e^{-0.29t}\cos(32.72t) \quad \sin(81.16t) \;\big]$$

The ordinary least-squares estimate of the parameters is

$$\hat{\vec{\phi}} = (\Theta^{T}\Theta)^{-1}\Theta^{T}\vec{y}$$

computed in MATLAB with the backslash operator (`phi = Obs \ y`), which solves this without explicitly forming the inverse. The fitted signal and its accuracy are

$$\hat{\vec{y}} = \Theta\,\hat{\vec{\phi}}, \qquad \text{MSE} = \frac{1}{N}\sum_{n=0}^{N-1}\big(\hat{y}[n] - y[n]\big)^2$$

The spectra of $\vec{y}$ and $\hat{\vec{y}}$ are then compared, with the strongest peaks labelled.

## Requirements

MATLAB with the Signal Processing Toolbox (`fir1`, `freqz`, `cheb2ord`, `cheby2`, `findpeaks`).

Data files (`lab_Audio.mat`, `lab_signals.mat`) are loaded if present; stages are skipped cleanly if not.

## Structure

```
.
├── signal_processing_project.m
├── images/
│   └── noisy_vs_filtered.png
└── README.md
```
