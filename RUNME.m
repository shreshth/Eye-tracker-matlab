% *************************************************************************
% File Name      : RUNME.m
% Required by    : None
% Usage          : Direct
% Requires       : IMAQ, image processing, svm-km toolbox (in directory)
% Author         : Mohammed Shoaib/Shreshth Singhal @ 13:30:12 PM, TUE 01.17.11
%
% >> Princeton University
% >> Department of Electrical Engineering
% >> Princeton University, Princeton NJ 08544
%
% *************************************************************************
% This file does the following. It invokes the trackEyes algorithm, which
% 1). Capture live video feed from the webcam
% 2). Performs fast correlation based template matching to segment the eyes
%     (the user can choose to segment the left, right or bot the eyes)
% 3). Run the eigenEyes Algorithm to track the eyes and display the
%     gaze direction (control parameter)
% 4). Run the SVM Algorithm to track the eyes and display the
%     gaze direction (control parameter)
% *************************************************************************
%
% Type help function name to know more about arguments to each function
% *************************************************************************
% Program RUNME begins (UNCOMMENT ONLY THE FUNCTION YOU WANT TO EXECUTE)
 
% Clear environment

clear all; close all; clc;

% -------------------------------------------------------------------------
% OBJECTIVE: Gaze tracking for reading assistance
%
% Default case: No video capture. Load video from a file. Perform gaze
% detection using the eigenEyes algorithm.
% -------------------------------------------------------------------------
% (Uncomment)change what is (un)necessary
% -------------------------------------------------------------------------

% Generic parameters
% --------------------
capData             = 'no';        % Capture data from video or preload
noFrames            = 50;          % Number of frames to capture from video 
sampleInterval      = 1;           % Inter frame interval for video
filePath            = 'video0117'; % Dir. path containing images to load
matchEye            = 'L';         % Eye to match: left(L)/right(R)/both(B)

classMode           = 'eigenEyes'; % Classification mode: eigenEyes/svm

% EigenEyes parameters
% ---------------------
noEEyes             = 30;          % No. of eigenEyes to plot
noReconEyes         = 20;          % No. of eigenEyes for reconstruction

% Set debugMode and showPlot to 1 to see some interesting plots
% -------------------------------------------------------------------------
debugMode           = 0;           % Debug results yes/no - control below
showPlot            = 0;           % DEBUG: show plot or not
savePlot            = 0;           % DEBUG: save plots or not
adjPlot             = 0;           % DEBUG: adjacent plots or not

% SVM parameters
% ---------------
noClass             = 10;          % Number of classes for the SVM
lagrangeLim         = 10000;       % Bound on lagrange multipliers
lambda              = 1e-7;        % Conditioning parameter for QP optimizer
multiClassMethod    = 'one';       % How to perform multi-class SVM 
                                   % 'one' = one versus one
                                   % 'all' = one versus all
kernel              = 'polyhomog'; % Kernel function to use for SVM
                                   % (poly, polyhomog, htrbf, wavelet,
                                   % frame, gaussian)
% Track eyes algorithm
% ---------------------

trackEyes(capData,noFrames,sampleInterval,filePath,matchEye,...
                   noEEyes, noReconEyes, debugMode, showPlot, savePlot,...
                   adjPlot, noClass, lagrangeLim, lambda, multiClassMethod,...
                   kernel,classMode);