
function capFrames = getVideoImages(noFrames, sampleInterval)

% *************************************************************************
% This file records "noFrames" frames at a frame interval of
% "interSampleInterval". It returns an array of color images acquired from
% the webcam.
% *************************************************************************

% -------------------------------------------------------------------------
% Get camera info
% -------------------------------------------------------------------------

imaqreset;                                 % Reset the imaq state

hwInfo     = imaqhwinfo;
camName    = char(hwInfo.InstalledAdaptors(end));
camInfo    = imaqhwinfo(camName);
camID      = camInfo.DeviceInfo.DeviceID(end);
resolution = char(camInfo.DeviceInfo.SupportedFormats(end));

% -------------------------------------------------------------------------
% Start up video stream
% -------------------------------------------------------------------------

vid = videoinput(camName, camID, resolution);

% preview(vid);                            % DEBUG: video preview

set(vid, 'FramesPerTrigger', 120);
set(vid, 'ReturnedColorspace', 'rgb');     % color space to get snapshots
vid.FrameGrabInterval = sampleInterval;    % frame interval for snapshots

% -------------------------------------------------------------------------
% Data acquisition
% -------------------------------------------------------------------------

frameCntr     = 1;      % Initialize frame counter
arrayOfImages = zeros(str2double(resolution(10:end)),...
                      str2double(resolution(6:8)),3,noFrames);

start(vid);                                % Start video acquisition

while (vid.FramesAcquired+1 <= noFrames*sampleInterval)
     arrayOfImages(:,:,:,frameCntr) = getsnapshot(vid);
     frameCntr = frameCntr + 1;
end

stop(vid);                                 % Stop video acquisition
vid.TimerFcn = {'stop'};                  
delete(vid);                               % Delete video object

capFrames = uint8(arrayOfImages);          % Return captured frame in unit8