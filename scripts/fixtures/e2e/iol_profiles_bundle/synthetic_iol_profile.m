%% Parameters
wavelength_um = 0.55;

%% Load data
profile = zeros(64, 64);

%% Compute
profile(32, :) = linspace(0, 1, 64);

%% Plot
fprintf('Peak height = %.2f\n', max(profile(:)));
