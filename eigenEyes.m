% *************************************************************************
% File Name      : eigenEyes.m
% Required by    : None
% Usage          : Direct
% Requires       : None
% Author         : Mohammed Shoaib/Shreshth Singhal @ 17:33:03 PM, TUE 12.27.11
%
% >> Princeton University
% >> Department of Electrical Engineering
% >> Princeton University, Princeton NJ 08544
%
% *************************************************************************
% This file does the following:
%
% 1). Reads images from a video directory (img/videoXXXX, etc) into a 
%     big matrix.
% 2). Applies PCA + whitening on the big matrix
% 3). Returns the top k principal components corresponding to the
%     eigeneyes with maximal variation
%
% *************************************************************************        
% Example usage:                                                                   
%                                                                                 
% function eigenEyes(filePath,noFrames,matchEye,noEEyes,noReconEyes,...
%                    debugMode, showPlot, savePlot, adjPlot)
%
%                
% matchEye    = 'L';             % Eye to match: left(L)/right(R)/both(B)
% filePath    = 'video0108';     % Dir. path containing images to load
% noFrames    = 50;              % Number of frames captured in video
% noEEyes     = 25;              % No. of eigenEyes to plot
% noReconEyes = 20;              % No. of eigenEyes for reconstruction
% debugMode   = 0;               % Debug results yes/no - control below
% showPlot    = 0;               % DEBUG: show plot or not
% savePlot    = 0;               % DEBUG: save plots or not
% adjPlot     = 0;               % DEBUG: adjacent plots or not
%
% *************************************************************************
% Program eigenEyes begins

function eigenEyes(filePath,noFrames,matchEye,noEEyes,noReconEyes,...
                   debugMode, showPlot, savePlot, adjPlot)

% -------------------------------------------------------------------------
% Parameter control - defaults                                                      
% -------------------------------------------------------------------------

if nargin < 9
    matchEye    = 'L';             % Eye to match: left(L)/right(R)/both(B)
    filePath    = 'video0108';     % Dir. path containing images to load
    noFrames    = 50;              % Number of frames captured in video
    noEEyes     = 30;              % No. of eigenEyes to plot
    noReconEyes = 20;              % No. of eigenEyes for reconstruction
    debugMode   = 0;               % Debug results yes/no - control below
    showPlot    = 0;               % DEBUG: show plot or not
    savePlot    = 0;               % DEBUG: save plots or not
    adjPlot     = 0;               % DEBUG: adjacent plots or not
end

noTrainImg = (noFrames-15)*9;                      % No. of training images
noTestImg  = noFrames-15;                          % No. of test images

% Preallocate train and test image buffers for speed

imgTrain(noTrainImg).base = 0; imgTest(noTestImg).base = 0;
imgTrain(noTrainImg).img  = 0; imgTest(noTestImg).img  = 0;
imgTrain(noTrainImg).name = 0; imgTest(noTestImg).name = 0;

% Preallocate row and column buffers for speed

imgRow(noTrainImg+noTestImg) = 0;
imgCol(noTrainImg+noTestImg) = 0;

% -------------------------------------------------------------------------
% Load the training images from the img directory for the matchEye process
% -------------------------------------------------------------------------

trainImgDir = dir(strcat('img/videoTraining/',matchEye,'*'));

for tIt = 1:size(trainImgDir,1)    
    load(strcat('img/videoTraining/',trainImgDir(tIt).name,'/eyeFramesL'));
    
    eyeFramesL(:,:,:,1:10) = [];              % Ignore the first ten frames
    
    for fIt = 1:size(eyeFramesL,4)
       imgTrain((tIt-1)*size(eyeFramesL,4) + fIt).base = rgb2gray(eyeFramesL(:,:,:,fIt));
       imgTrain((tIt-1)*size(eyeFramesL,4) + fIt).name = trainImgDir(tIt).name(3:end);
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
% Main code for the eigenEyes algorithm
% -------------------------------------------------------------------------

% Compute the average eye

avgEye = meanEye(imgTrain);

% ---------------------------------------------------------------------
% Put all training eyes into one big matrix and do SVD
% ---------------------------------------------------------------------

vecTrain = zeros(size(avgEye,1)*size(avgEye,2),noTrainImg);

for iIt = 1:noTrainImg                          % Subtract average eye
    normTrainEye = double(imgTrain(iIt).img) - double(avgEye);
    vecTrain(:, iIt)  = normTrainEye(:);
end;

[U,S,V] = svd(vecTrain,0);                      % Economy size SVD

% ---------------------------------------------------------------------
% DEBUG: Plot the cummulative value of the EigenVectors - shows the
% variance in the data accounted by the first N EigenVectors
% ---------------------------------------------------------------------

if debugMode
    plotPCVariance(S,showPlot,savePlot,noEEyes);
end

% ---------------------------------------------------------------------
% DEBUG: Show the top noEEyes Eigen eyes
% ---------------------------------------------------------------------

if debugMode
    plotEigenEyes(U,noEEyes,avgEye,showPlot,savePlot);
end

% ---------------------------------------------------------------------
% DEBUG: Reconstruct a randomly chosen eye using noReconEyes
% ---------------------------------------------------------------------

if debugMode
    plotReconEye(U,S,V,noReconEyes,avgEye,showPlot,savePlot);
end

% ---------------------------------------------------------------------
% Put all test eyes into one big matrix and project onto eigenEyes
% ---------------------------------------------------------------------

vecTest = zeros(size(avgEye,1)*size(avgEye,2),noTestImg);

for iIt = 1:noTestImg                           % Subtract average eye
    normTestEye = double(imgTest(iIt).img) - double(avgEye);
    vecTest(:, iIt) = normTestEye(:);
end;    

% ---------------------------------------------------------------------
% Compute weights (essential projections) of training images
% ---------------------------------------------------------------------

trainWeights = zeros(noEEyes,noTrainImg);      % Training eye weights

for iIt = 1:size(vecTrain,2)
    trainWeights(:,iIt) = U(:,1:noEEyes)'*vecTrain(:,iIt);
end;

% ---------------------------------------------------------------------
% For each test example, find best match in training data
% ---------------------------------------------------------------------

eucDistance = zeros(1,noTrainImg);              % Initialize distance
bestDist    = zeros(1,noTestImg);               % Initialize best 
bestMatch   = zeros(1,noTestImg);               % match and distance

for iIt = 1:noTestImg

    testWeight = U(:,1:noEEyes)'*vecTest(:,iIt);   % Test eye weight

    for tIt = 1:noTrainImg     % Euclidean dist. from all training img.
        eucDistance(tIt) = sqrt(sum((trainWeights(:,tIt) ...
                           - testWeight(:)).^2));
    end;

    [bestDist(iIt), bestMatch(iIt)] = min(eucDistance);
end

% ---------------------------------------------------------------------
% DEBUG: Show the best matches found in the training database
% ---------------------------------------------------------------------

if debugMode
    plotEyeMatches(noTestImg,imgTest,imgTrain,bestMatch,showPlot,...
                    adjPlot,savePlot);
end

% ---------------------------------------------------------------------
% Plot the result of the eigenEyes algorithm
% ---------------------------------------------------------------------

fprintf('----------------------------------------------------\n');
fprintf('Viewing Direction (eigen eyes): \n');
fprintf('----------------------------------------------------\n');

for i=1:noTestImg
    
    % Show the segmented test eye from each video frame
    imshow(imgTest(i).img); hold on; pause(1.0);
    
    % Print the view locus
    
    fprintf('%s\t', imgTrain(bestMatch(i)).name);
    if ~mod(i,3), fprintf('\n'); end
end

fprintf('\n----------------------------------------------------\n');