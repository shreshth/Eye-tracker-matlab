% *************************************************************************
% File Name      : svmRecognition.m
% Required by    : None
% Usage          : Direct
% Requires       : SVM-KM toolbox (INSA de Rouen, Rouen, France
% Author         : Mohammed Shoaib/Shreshth Singhal @ 13:16:19 PM, THU 01.12.11
%
% *************************************************************************
% This file does the following:
%
% 1). Reads training images from a video directory (img/videoXXXX, etc)
%     and trains multi-class SVM on it.
% 2). Applies learned SVM on test images and returns the best match class
%
% *************************************************************************        
% Example usage:                                                                   
%                                                                                 
% function svmRecognition(filePath,noFrames,matchEye, noClass, lagrangeLim, ...
%                         lambda, kernel, multiClassMethod)
%
%                
% matchEye         = 'L';          % Eye to match: left(L)/right(R)/both(B)
% filePath         = 'video0108';  % Dir. path containing images to load
% noFrames         = 50;           % Number of frames captured in video
% lagrangeLim      = 10000;        % Bound on lagrange multipliers
% lambda           = 1e-7;         % Conditioning parameter for QP optimizer
% noClass          = 10;           % Number of classes
% multiClassMethod = 'all';        % Method to do multi-class SVM (one versus one or all)
% kernel           = 'polyhomog';  % Kernel function to use for SVM
%
% *************************************************************************
% Program svmRecognition begins

function svmRecognition(filePath,noFrames,matchEye, noClass, lagrangeLim, ...
                        lambda, kernel, multiClassMethod)

% -------------------------------------------------------------------------
% Parameter control - defaults                                                      
% -------------------------------------------------------------------------

if nargin < 8
    matchEye         = 'L';             % Eye to match: left(L)/right(R)/both(B)
    filePath         = 'video0108';     % Dir. path containing images to load
    noFrames         = 50;              % Number of frames captured in video
    lagrangeLim      = 10000;           % Bound on lagrange multipliers
    lambda           = 1e-7;            % Conditioning parameter for QP optimizer
    noClass          = 10;              % Number of classes
    multiClassMethod = 'one';           % Method to do multi-class SVM (one versus one or all)
    if strcmp(multiClassMethod, 'all')
        kernel       = 'poly';          
    else
        kernel       = 'polyhomog';
    end                                 % Kernel function to use for SVM
end

noTrainImg = (noFrames-15)*10;                     % No. of training images
noTestImg  = noFrames-15;                          % No. of test images

% Preallocate train and test image buffers for speed

imgTrain(noTrainImg).base   = 0; imgTest(noTestImg).base   = 0;
imgTrain(noTrainImg).img    = 0; imgTest(noTestImg).img    = 0;
imgTrain(noTrainImg).name   = 0; imgTest(noTestImg).name   = 0;
imgTrain(noTrainImg).class  = 0; imgTest(noTestImg).imgRow = 0;

% Preallocate row and column buffers for speed

imgRow(noTrainImg+noTestImg) = 0;
imgCol(noTrainImg+noTestImg) = 0;

% -------------------------------------------------------------------------
% Load the training images from the img directory for the matchEye process
% -------------------------------------------------------------------------

trainImgDir = dir(strcat('img//videoTraining/',matchEye,'*'));

for tIt = 1:size(trainImgDir,1)    
    load(strcat('img/videoTraining/',trainImgDir(tIt).name,'/eyeFramesL'));
    
    eyeFramesL(:,:,:,1:10) = [];              % Ignore the first ten frames
    
    for fIt = 1:size(eyeFramesL,4)
       imgTrain((tIt-1)*size(eyeFramesL,4) + fIt).base = rgb2gray(eyeFramesL(:,:,:,fIt));
       imgTrain((tIt-1)*size(eyeFramesL,4) + fIt).name = trainImgDir(tIt).name(3:end);
       imgTrain((tIt-1)*size(eyeFramesL,4) + fIt).class = tIt;
       imgRow((tIt-1)*size(eyeFramesL,4) + fIt) = size(imgTrain((tIt-1)*size(eyeFramesL,4) + fIt).base,1);
       imgCol((tIt-1)*size(eyeFramesL,4) + fIt) = size(imgTrain((tIt-1)*size(eyeFramesL,4) + fIt).base,2);       
    end
end

% -------------------------------------------------------------------------
% Load the test images from filePath
% -------------------------------------------------------------------------

load(strcat('img/',filePath,'/eyeFramesL'));
eyeFramesL(:,:,:,1:10) = [];                  % Ignore the first ten frames
    
for fIt = 1:size(eyeFramesL,4)
   imgTest(fIt).base  = rgb2gray(eyeFramesL(:,:,:,fIt));
   imgRow(noTrainImg+fIt) = size(imgTest(fIt).base,1);
   imgCol(noTrainImg+fIt) = size(imgTest(fIt).base,2);   
end

% -------------------------------------------------------------------------
% Crop/center the training and test images
% -------------------------------------------------------------------------

minRow = min(imgRow);
minCol = min(imgCol);

for iIt=1:noTrainImg
    [row, col] = size(imgTrain(iIt).base);
    bBox(1) = floor(col/2) - floor(minCol/2);
    bBox(2) = floor(row/2) - floor(minRow/2);
    bBox(3) = minCol-1;
    bBox(4) = minRow-1;
    
    if ~bBox(1), bBox(1) = 1; end               % Correct for minimum box
    if ~bBox(2), bBox(2) = 1; end    
       
    imgTrain(iIt).img = imcrop(imgTrain(iIt).base, bBox);
end

for iIt = 1:noTestImg
    [row, col] = size(imgTest(iIt).base);
    bBox(1) = floor(col/2) - floor(minCol/2);
    bBox(2) = floor(row/2) - floor(minRow/2);
    bBox(3) = minCol-1;
    bBox(4) = minRow-1;
    
    if ~bBox(1), bBox(1) = 1; end               % Correct for minimum box
    if ~bBox(2), bBox(2) = 1; end    
    
    imgTest(iIt).img = imcrop(imgTest(iIt).base, bBox);
end

% -------------------------------------------------------------------------
% Convert images into row vectors
% -------------------------------------------------------------------------

[rows cols] = size(imgTrain(1).img);
imgTrainRows = zeros(noTrainImg, rows*cols);
imgTrainClassRows = zeros(noTrainImg, 1);

for iIt=1:noTrainImg
    imgTrainRows(iIt, :) = reshape((imgTrain(iIt).img)', 1, rows*cols);
    imgTrainClassRows(iIt) = imgTrain(iIt).class;
end

for iIt=1:noTestImg
    imgTest(iIt).imgRow = reshape((imgTest(iIt).img)', 1, rows*cols);
end

% -------------------------------------------------------------------------
% Main code for the SVM recognition algorithm
% -------------------------------------------------------------------------

if strcmp(multiClassMethod, 'all')  % One versus all method
    % Find support vectors
    [SV, weights, bias, noSV, ~, ~] = svmmulticlass(imgTrainRows, imgTrainClassRows, noClass, lagrangeLim, lambda, kernel, 1, 0);
    
    % Classify test images accordingly
    for iIt = 1:noTestImg
        class = svmmultival(imgTest(iIt).imgRow, SV, weights, bias, noSV, kernel, 1);
        imgTest(iIt).name = trainImgDir(class).name(3:end);
    end 
else                                % One versus one method
    % Find support vectors
    [SV, weights, bias, noSV, ~, ~] = svmmulticlassoneagainstone(imgTrainRows, imgTrainClassRows, noClass, lagrangeLim, lambda, kernel, 1, 0);
    
    % Classify test images accordingly
    for iIt = 1:noTestImg
        [class, ~] = svmmultivaloneagainstone(imgTest(iIt).imgRow, SV, weights, bias, noSV, kernel, 1);
        imgTest(iIt).name = trainImgDir(class).name(3:end);
    end
end

% -------------------------------------------------------------------------
% Show results
% -------------------------------------------------------------------------

fprintf('----------------------------------------------------\n');
fprintf('Viewing Direction (SVM): \n');
fprintf('----------------------------------------------------\n');

for iIt = 1:noTestImg
    % Show the segmented test eye from each video frame
    figure;
    imshow(imgTest(iIt).img); hold on; pause(1.0);
    
    % Print the view locus
    fprintf('%s\t', imgTest(iIt).name);
    if ~mod(iIt,3), fprintf('\n'); end
end

fprintf('\n----------------------------------------------------\n');