function [eyeFramesL,eyeFramesR] = segmentEyes(vidFrames,eyeTemplateL,eyeTemplateR,matchEye,DEBUG)

eyeFramesL = zeros(size(eyeTemplateL,1)+1,size(eyeTemplateL,2)+1,3,size(vidFrames,4));
eyeFramesR = zeros(size(eyeTemplateR,1)+1,size(eyeTemplateR,2)+1,3,size(vidFrames,4));

bBoxL = [size(vidFrames(:,:,:,1),1)/2,size(vidFrames(:,:,:,1),2)/2,size(eyeFramesL,2)-1,size(eyeFramesL,1)-1];        
bBoxR = [size(vidFrames(:,:,:,1),1)/2,size(vidFrames(:,:,:,1),2)/2,size(eyeFramesR,2)-1,size(eyeFramesR,1)-1];

% -------------------------------------------------------------------------

for cIt = 1:size(vidFrames,4)            
    
    vidFrame = im2double(vidFrames(:,:,:,cIt));    

    switch matchEye  
        case 'B'
            [~, boundBoxL] = templMatching(vidFrame,eyeTemplateL);
            [~, boundBoxR] = templMatching(vidFrame,eyeTemplateR);

            if ~isempty(boundBoxL), bBoxL = boundBoxL; end
            if ~isempty(boundBoxR), bBoxR = boundBoxR; end          
           
            eyeFramesL(:,:,:,cIt) = imcrop(vidFrame,bBoxL); 
            eyeFramesR(:,:,:,cIt) = imcrop(vidFrame,bBoxR); 

            % -------------------------------------------------------------
            % DEBUG
            % -------------------------------------------------------------
            if DEBUG
                imshow(vidFrame);
                rectangle('Position',boundBoxL,'EdgeColor','g','LineWidth',2)
                rectangle('Position',boundBoxR,'EdgeColor','g','LineWidth',2)
                pause(0.01);
            end
            
        case 'L'
            [~, boundBoxL] = templMatching(vidFrame,eyeTemplateL);
            if ~isempty(boundBoxL), bBoxL = boundBoxL; end
 
            eyeFramesL(:,:,:,cIt) = imcrop(vidFrame,bBoxL);
            
            % -------------------------------------------------------------
            % DEBUG
            % -------------------------------------------------------------            
            
            if DEBUG
                imshow(vidFrame);
                rectangle('Position',boundBoxL,'EdgeColor','g','LineWidth',2)
                pause(0.01);
            end
            
        case 'R'
            [~, boundBoxR] = templMatching(vidFrame,eyeTemplateR);
            if ~isempty(boundBoxR), bBoxR = boundBoxR; end
           
            eyeFramesR(:,:,:,cIt) = imcrop(vidFrame,bBoxR); 
            
            % -------------------------------------------------------------
            % DEBUG
            % -------------------------------------------------------------            

            if DEBUG
                imshow(vidFrame);
                rectangle('Position',boundBoxR,'EdgeColor','g','LineWidth',2)
                pause(0.01);
            end
    end
end