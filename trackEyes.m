% *************************************************************************
% File Name      : trackEyes.m
% Required by    : None
% Usage          : Direct
% Requires       : image processing toolbox, imaq toolbox
% Author         : Mohammed Shoaib/ Shresth Singhal @ 18:20:01 PM, SUN 12.25.11
%
% >> Princeton University
% >> Department of Electrical Engineering
% >> Princeton University, Princeton NJ 08544
%
% *************************************************************************
% This file does the following:
% 1). Capture live video feed from the webcam
% 2). Performs fast correlation based template matching to segment the eyes
%     (the user can choose to segment the left, right or bot the eyes)
% 3). Run the eigenEyes Algorithm to track the eyes and display the
%     gaze direction (control parameter)
% 4). Run the SVM Algorithm to track the eyes and display the
%     gaze direction (control parameter)
% *************************************************************************
% Example usage:
%
% function trackEyes(capData,noFrames,sampleInterval,filePath,matchEye,...
%                    noEEyes, noReconEyes, debugMode, showPlot, savePlot,...
%                    adjPlot, noClass, lagrangeLim, lambda, multiClassMethod,...
%                    kernel,classMode);
% 
% Generic parameters
% --------------------
% capData             = 'yes';       % Capture data from video or preload
% noFrames            = 50;          % Number of frames to capture from video 
% sampleInterval      = 1;           % Inter frame interval for video
% filePath            = 'video0108'; % Dir. path containing images to load
% matchEye            = 'L';         % Eye to match: left(L)/right(R)/both(B)
% 
% classMode           = 'eigenEyes'; % Classification mode: eigenEyes/svm
%
% EigenEyes parameters
% ---------------------
% noEEyes             = 25;          % No. of eigenEyes to plot
% noReconEyes         = 20;          % No. of eigenEyes for reconstruction
% debugMode           = 0;           % Debug results yes/no - control below
% showPlot            = 0;           % DEBUG: show plot or not
% savePlot            = 0;           % DEBUG: save plots or not
% adjPlot             = 0;           % DEBUG: adjacent plots or not
% 
% SVM parameters
% ---------------
% noClass             = 10;          % Number of classes for the SVM
% lagrangeLim         = 10000;       % Bound on lagrange multipliers
% lambda              = 1e-7;        % Conditioning parameter for QP optimizer   
% multiClassMethod    = 'one';       % How to perform multi-class SVM 
%                                    % 'one' = one versus one
%                                    % 'all' = one versus all
% kernel              = 'polyhomog'; % Kernel function to use for SVM
%                                    % (poly, polyhomog, htrbf, wavelet,
%                                    % frame, gaussian)
%
% *************************************************************************
% Program main trackEyes begins

function trackEyes(capData,noFrames,sampleInterval,filePath,matchEye,...
                   noEEyes, noReconEyes, debugMode, showPlot, savePlot,...
                   adjPlot, noClass, lagrangeLim, lambda, multiClassMethod,...
                   kernel,classMode)

% -------------------------------------------------------------------------
% STEP A: Set default arguments if less than required are specified
% -------------------------------------------------------------------------

if nargin < 17
    % Generic parameters
    % --------------------
    capData             = 'no';        % Capture data from video or preload
    noFrames            = 50;          % Number of frames to capture from video 
    sampleInterval      = 1;           % Inter frame interval for video
    filePath            = 'video0108'; % Dir. path containing images to load
    matchEye            = 'L';         % Eye to match: left(L)/right(R)/both(B)

    classMode           = 'eigenEyes'; % Classification mode: eigenEyes/svm

    % EigenEyes parameters
    % ---------------------
    noEEyes             = 30;          % No. of eigenEyes to plot
    noReconEyes         = 20;          % No. of eigenEyes for reconstruction
    debugMode           = 1;           % Debug results yes/no - control below
    showPlot            = 1;           % DEBUG: show plot or not
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
end

% -------------------------------------------------------------------------
% STEP B: Capture data from video or load previous video from a file
% -------------------------------------------------------------------------

switch capData    
    case 'yes'
        
        fprintf('----------------------------------------------------\n');
        fprintf('Capturing video from webcam. Stay still and move eyes.\n');
        fprintf('----------------------------------------------------\n');
        
        if ~exist(strcat('img/',filePath),'dir')      % Make data directory
            mkdir(strcat('img/',filePath)); 
        end
        
        capFrames = getVideoImages(noFrames, sampleInterval);

        vIt       = 1;                 % Remove initial (zero) frames
        for cIt = 1:size(capFrames,4)
            if(capFrames(:,:,:,cIt) == 0); else  
                vidFrames(:,:,:,vIt) = capFrames(:,:,:,cIt);
                vIt = vIt + 1;        
            end
        end

        eyeTemplateL = imcrop(vidFrames(:,:,:,8));  % Template for left eye
        eyeTemplateR = imcrop(vidFrames(:,:,:,8));  % Template for right eye
        
        save(strcat('img/',filePath,'/vidFrames'), 'vidFrames');
        save(strcat('img/',filePath,'/eyeTemplateL'),'eyeTemplateL');
        save(strcat('img/',filePath,'/eyeTemplateR'),'eyeTemplateR');
       
    case 'no'
        
        fprintf('----------------------------------------------------\n');
        fprintf('Loading pre-recorded video from file img/%s.\n',filePath);
        fprintf('----------------------------------------------------\n');
        
        load(strcat('img/',filePath,'/vidFrames'));      % load vidFrames
        load(strcat('img/',filePath,'/eyeTemplateL'));   % load eyeTemplate
        load(strcat('img/',filePath,'/eyeTemplateR'));   % load eyeTemplate    
        load(strcat('img/',filePath,'/eyeFramesL'));     % load eyeFrames
        load(strcat('img/',filePath,'/eyeFramesR'));     % load eyeFrames
end

% -------------------------------------------------------------------------
% STEP C: Detect eye region by template matching (correlation thresholding)
% -------------------------------------------------------------------------

switch capData
    case 'yes'
        [eyeFramesL,eyeFramesR] = segmentEyes(vidFrames,eyeTemplateL,...
                                              eyeTemplateR,matchEye,0);

        save(strcat('img/',filePath,'/eyeFramesL'), 'eyeFramesL');
        save(strcat('img/',filePath,'/eyeFramesR'), 'eyeFramesR');
end

% -------------------------------------------------------------------------
% Show the segmented eyes from each video frame
% -------------------------------------------------------------------------

if showPlot
    figure;
    xlabel('Segmented Eye Frames','FontSize', 24)
    for fIt = 2:size(vidFrames,4)
        imshow(eyeFramesL(:,:,:,fIt)); hold on;
        pause(0.1);
    end
end

% -------------------------------------------------------------------------
% STEP D: Perform gaze detection - through eigenEyes or SVM classification
% -------------------------------------------------------------------------

switch classMode
    case 'eigenEyes'

        % -----------------------------------------------------------------
        % Eigen eyes algorithm to detect the view locus
        % -----------------------------------------------------------------
 
        eigenEyes(filePath,noFrames,matchEye,noEEyes,noReconEyes,...
                  debugMode, showPlot, savePlot, adjPlot);     

    case 'svm'
        % -----------------------------------------------------------------
        % SVM algorithm to detect the view locus
        % -----------------------------------------------------------------

        svmRecognition(filePath,noFrames,matchEye,noClass,lagrangeLim,...
                       lambda, kernel, multiClassMethod, debugMode);
end