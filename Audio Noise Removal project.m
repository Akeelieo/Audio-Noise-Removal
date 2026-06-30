
% =====================================================================
% Audio signal processing
%   - load a raw audio clip
%   - add noise and inspect its frequency content
%   - design and apply a band-stop filter to remove a noise tone
%   - apply a chorus effect
% =====================================================================
function audio = process_audio()


  if exist('Audio.mat', 'file') == 2 ... 
        && exist('signals.mat', 'file') == 2 

        load('Audio.mat', 'audioRaw') 
        load('signals.mat', 'n1') 


        % raw input audio 
        audio.input = audioRaw;

        % Corrupting clean signal adding  noise vector
        audio.noisy = audioRaw + n1;

        % Transforming noisy signal into the frequency domain
        audio.noisyFFT = fft(audio.noisy);

        % Plot of magnitude spectrum across the audible band up to 22050 Hz
        figure;
        f = linspace(0, 22050, length(audio.noisyFFT));
        plot(f, abs(audio.noisyFFT));
        grid on;
        title('Magnitude Spectrum of Noisy Signal');
        xlabel('Frequency (Hz)');
        ylabel('|FFT(noisy)|');

        % The two largest spectral peaks (revealing the noise tone)
        [~, maxIdx] = maxk(abs(audio.noisyFFT), 2);

        % The frequency and magnitude at those peak locations
        maxFreq = f(maxIdx);
        maxMag  = abs(audio.noisyFFT(maxIdx));

        % label the peaks on the plot
        hold on;
        plot(maxFreq, maxMag, '.');
        text(maxFreq, maxMag, ...
            arrayfun(@(x) sprintf(' %.2f Hz', x), maxFreq, 'UniformOutput', false));
        legend('Magnitude Spectrum', 'Top Peaks');
        hold off;


        % ----- Band-stop FIR filter to remove the noise tone -----

        Fs      = 22050;   % Sampling frequency (Hz)
        fNoise  = 245;     % Centre frequency of the noise to remove (Hz)
        bw      = 25;      % Width of the stop band around the noise (Hz)

        % normalised to the Nyquist frequency (Fs/2).
        audio.filterCoeffs = fir1(50001, [(fNoise - bw/2), (fNoise + bw/2)] / (Fs/2), 'stop');

        % Filter's frequency response  
        figure;
        freqz(audio.filterCoeffs, 1, 4096, Fs);
        title('Magnitude of FIR Filter against Frequency');
        xlim([0.2 0.3]);   % Zoom in around the stop band for clarity

        % The stop-band edges
        xline(0.231, '--', 'Color', 'red', 'LineWidth', 1.5);
        xline(0.259, '--', 'Color', 'red', 'LineWidth', 1.5);
        text(0.262, -10, 'Stopband 231 Hz to 259 Hz');

        % The -3 dB cut-off points
        yline(-3, '--', 'Color', 'green', 'LineWidth', 1.5);
        xline(0.2318, '--', 'Color', 'green', 'LineWidth', 1.5);
        xline(0.258, '--', 'Color', 'green', 'LineWidth', 1.5);
        text(0.2, -15, 'Frequency Cut off at 232 Hz');
        text(0.2, -5,  'Frequency Cut off at -3 dB');
        text(0.262, -25, 'Frequency Cut off at 258 Hz');

        % Applying the filter to the noisy audio
        audio.filtered = filter(audio.filterCoeffs, 1, audio.noisy);

        % Overlay the noisy and filtered signals for comparison
        figure;
        plot(audio.noisy, 'b', 'DisplayName', 'Noisy Signal');
        hold on;
        plot(audio.filtered, 'r', 'DisplayName', 'Filtered Signal');
        hold off;
        title('Noisy and Filtered Signals');
        xlabel('Sample');
        ylabel('Amplitude');
        legend('Location', 'best');
        grid on;

        % ----- Applying a chorus effect -----
        
        % A chorus mixes the original signal with delayed copies of itself,
        % where the delays vary slowly over time to thicken the sound.

        gain1     = 0.51;  % Mix level of the first delayed copy
        gain2     = 0.3;   % Mix level of the second delayed copy
        baseDelay1 = 628;  % Base delay of the first copy (samples)
        baseDelay2 = 849;  % Base delay of the second copy (samples)
        modFreq   = 2.2;   % Rate at which the delays are modulated (Hz)

        % Input signal and its length
        x = audio.input;
        N = length(x);

        % Output buffer, same size as the input
        y = zeros(size(x));

        % Process the signal one sample at a time
        for n = 1:N
            % Slowly varying delays produce the characteristic chorus sweep
            delay1 = round(baseDelay1 + 5  * sin(2 * pi * modFreq * n));
            delay2 = round(baseDelay2 + 10 * sin(2 * pi * modFreq * n + pi/2));

            % Sample indices of the delayed copies
            idx1 = n - delay1;
            idx2 = n - delay2;

            % Start with the current (dry) sample
            y(n) = x(n);

            % Add each delayed copy only if its index is valid (>0)
            if idx1 > 0
                y(n) = y(n) + gain1 * x(idx1);
            end
            if idx2 > 0
                y(n) = y(n) + gain2 * x(idx2);
            end
        end

        % Store the chorus-processed audio
        audio.chorus = y;

        % Compare original vs processed signal on stacked subplots
        figure;
        subplot(2, 1, 1);
        plot(x);
        title('Original Signal');
        xlabel('Sample Index');
        ylabel('Amplitude');

        subplot(2, 1, 2);
        plot(y);
        title('Chorus Processed Signal');
        xlabel('Sample Index');
        ylabel('Amplitude');

        % Overlay both signals on one axis
        figure;
        hold on;
        grid on;
        plot(y);
        plot(x);
        title('Chorus Effect');
        legend('Chorus Processed Signal', 'Original Signal');
        xlabel('Sample Index');
        ylabel('Amplitude');

    end

end


% =====================================================================
% Filter design
%   - Chebyshev Type II band-stop filter to reject interference tone
%   - Plot of filter's magnitude and phase responses
% =====================================================================

function filt = design_filter()

    % Pre-allocate outputs
    filt.order = [];
    filt.a = [];
    filt.b = [];

    % ----- Design the band-stop filter -----

    fo = 1850;  % Frequency of the interference to reject (Hz)
    fs = 7500;  % Sampling frequency (Hz)
    Rs = 35;    % Required stop-band attenuation (dB)
    Rp = 0.7;   % Allowed pass-band ripple (dB)
    bw = 100;   % Width of the stop band (Hz)

    % Derived frequency edges, normalised to the Nyquist frequency
    nyquist = fs / 2;                 % Highest representable frequency
    f1 = fo - bw/2;                   % Lower stop-band edge
    f2 = fo + bw/2;                   % Upper stop-band edge
    wp = [f1 - 5, f2 + 5] / nyquist;  % Pass-band edges (just outside stop band)
    ws = [f1, f2] / nyquist;          % Stop-band edges

    % Compute the minimum filter order that meets the specifications
    [N, Wn] = cheb2ord(wp, ws, Rp, Rs);
    filt.order = N;

    % Design the Chebyshev Type II band-stop filter coefficients
    [b, a] = cheby2((N+1)/2, Rs, Wn, 'stop');
    filt.a = a;
    filt.b = b;

    % ----- Plot the frequency response -----

    % Evaluate the response at 1024 points, scaled to real frequencies in Hz
    [H, f] = freqz(filt.b, filt.a, 1024, fs);

    figure;

    % Magnitude response (top)
    subplot(2, 1, 1);
    plot(f, 20*log10(abs(H)), 'b');   % Convert magnitude to dB
    title('Magnitude Response of Chebyshev Filter');
    xlabel('Frequency (Hz)');
    ylabel('Magnitude (dB)');
    grid on;
    xlim([1600, 2100]);
    ylim([-70, 5]);

    % Annotate the required stop-band attenuation level
    yline(-35, '--', 'Color', 'green');
    text(2000, -35, 'Frequency Attenuation at -35 dB');

    % Annotate the interference frequency
    xline(1850, '--', 'Color', 'black');
    text(1820, 2, 'fo = 1850 Hz');

    % Annotate the pass-band ripple limit
    yline(-0.7, '--', 'Color', 'green');
    text(500, -2, 'Maximum Pass Band at -0.7 dB');

    % Annotate the stop-band edges
    xline(1780, '--', 'Color', 'red');
    xline(1919, '--', 'Color', 'red');
    text(1900, -23, 'Stopbands at 1780 Hz and 1919 Hz');

    % Phase response (bottom)
    subplot(2, 1, 2);
    plot(f, angle(H) * (180 / pi), 'b');   % Convert phase from radians to degrees
    title('Phase Response of Chebyshev Filter');
    xlabel('Frequency (Hz)');
    ylabel('Phase (degrees)');
    grid on;
    xlim([0, fs/2]);

end


% =====================================================================
% Estimating an unknown signal
%   Fit a known model (a sum of decaying/oscillating components) to noisy
%   sensor data using least squares, then compare the two in time and
%   frequency.
% =====================================================================
function est = estimate_signal()

    % Pre-allocate outputs
    est.model      = [];   % model/observation matrix
    est.params     = [];   % fitted parameters
    est.prediction = [];   % model prediction
    est.mse        = [];   % mean squared error
    est.dataFFT    = [];   % FFT of the measured data
    est.freqRange  = [];   % frequency axis
    est.predFFT    = [];   % FFT of the prediction

    % Only run if the signals data file is present
    if exist('lab_signals.mat', 'file') == 2
        load('lab_signals.mat', 'T')   % T = measured (noisy) data

        % ----- Build the model (observation) matrix -----

        Ts = 0.030;              % Time between samples (seconds)
        nSamples = length(T);    % Number of measurements

        % Time stamp for each sample, starting at t = 0
        t = (0:nSamples-1)' * Ts;

        % Each column is one basis function of the assumed signal model
        col1 = 1 - exp(-0.20 * t);                  % Rising exponential term
        col2 = exp(-0.29 * t) .* cos(32.72 * t);    % Decaying oscillation
        col3 = sin(81.16 * t);                      % Pure sinusoid

        % Stack the basis functions into the model matrix
        modelMatrix = [col1, col2, col3];
        est.model = modelMatrix;

        % ----- Fit the model parameters -----

        % Solve modelMatrix * params = T in the least-squares sense
        params = modelMatrix \ T;
        est.params = params;

        % ----- Reconstruct the signal from the fitted model -----
        prediction = modelMatrix * params;
        est.prediction = prediction;

        % ----- Measure the fit quality -----
        % Mean squared error between measured data and model prediction
        est.mse = mean((T - prediction).^2);

        % ----- Compare the spectra of data and prediction -----

        % FFT of the measured (noisy) data
        est.dataFFT = fft(T);

        % FFT of the reconstructed prediction
        est.predFFT = fft(prediction);

        % Build the frequency axis spanning [0, sample rate]
        Ts = 0.030;
        N = length(T);
        est.freqRange = linspace(0, 1/Ts, N);

        % Normalised magnitude spectra
        dataMag = abs(est.dataFFT) / N;
        predMag = abs(est.predFFT) / N;

        % Plot both magnitude spectra together
        figure;
        plot(est.freqRange, dataMag, 'b', 'LineWidth', 1.5, 'DisplayName', 'Noisy Sensor Data');
        hold on;
        plot(est.freqRange, predMag, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Predicted Temperatures');
        title('Magnitude Spectra: Data vs Prediction', 'FontSize', 14);
        xlabel('Frequency (Hz)', 'FontSize', 12);
        ylabel('Magnitude', 'FontSize', 12);
        legend show;
        grid on;

        % Locate the three strongest peaks in each spectrum
        [dataPeaks, dataLoc] = findpeaks(dataMag, est.freqRange, 'SortStr', 'descend', 'NPeaks', 3);
        [predPeaks, predLoc] = findpeaks(predMag, est.freqRange, 'SortStr', 'descend', 'NPeaks', 3);

        % Label the peaks of the measured data
        for i = 1:length(dataPeaks)
            text(dataLoc(i), dataPeaks(i), ...
                sprintf('(%.2f Hz, %.4f)', dataLoc(i), dataPeaks(i)), ...
                'VerticalAlignment', 'bottom', 'Color', 'blue');
        end

        % Label the peaks of the predicted data
        for i = 1:length(predPeaks)
            text(predLoc(i), predPeaks(i), ...
                sprintf('(%.2f Hz, %.4f)', predLoc(i), predPeaks(i)), ...
                'VerticalAlignment', 'top', 'Color', 'red');
        end

    end

end
