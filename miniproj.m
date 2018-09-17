v = vision.VideoFileReader('carfootage-short.mp4'); % read footage
detector = vision.ForegroundDetector('NumGaussians', 5, ...
    'NumTrainingFrames', 70); % creates foreground mask
blob = vision.BlobAnalysis('AreaOutputPort', false, ...
     'BoundingBoxOutputPort', true, 'CentroidOutputPort', false, ...
     'MinimumBlobArea', 3500); % analyzes connected regions in the mask 
carcandidates = struct('bboxes',{},'framespresent',{},'framesgone',{});
% each entry in this structure holds detections that are candidates to be
% legitimate car tracking
se = strel('square', 3);
numcars = 0;
videoPlayer = vision.VideoPlayer();
newtracks = [];
while ~isDone(v)
    frame = v();
    foreground = detector(frame);
    foreground1 = bwareaopen(foreground, 500); % noise filter based on size
    foregroundfilt = imopen(foreground1, se); % algorithm noise filter
    BBOX = step(blob, foregroundfilt); % Bounding box coords
    newdetects = BBOX; % We'll consider these bounding boxes new detections
    if isempty(carcandidates) == 1
        for m = 1:size(BBOX,1)
            carcandidates(m).bboxes = BBOX(m,:);
            carcandidates(m).framespresent = 1;
            carcandidates(m).framesgone = 0;
        end
    end % On the first frame of detections, we'll consider all of them
    % candidates -- need to adjust in case first frame has no detections
    % tracks (tracks that are onscreen) 
    for k = 1:numel(carcandidates) %check this part out
        for j = 1:size(newdetects,1)
            overlapRatio = bboxOverlapRatio(newdetects(j,:),carcandidates(k).bboxes(end,:));
            if (overlapRatio > 0.5) && carcandidates(k).framesgone < 20
                carcandidates(k).bboxes = [carcandidates(k).bboxes; newdetects(j,:)];
                carcandidates(k).framespresent = carcandidates(k).framespresent + 1;
                % new tracks are established if bounding boxes over 
                % consecutive frames overlap each other over a certain 
                % percentage.
            else
                if carcandidates(k).framespresent > 0
                    carcandidates(k).framesgone = carcandidates(k).framesgone + 1;
                end % If no new detections match up to an existing track,
                % a counter goes up for the number of consecutive frames it
                % also doesn't appear
            end
        end
    end
    for q = 1:size(newdetects,1)
        carcandidates(end + 1).bboxes = newdetects(q,:);
        carcandidates(end).framespresent = 1;
        carcandidates(end).framesgone = 0;
    end % If new detections don't match up to existing tracks, they start
    % new tracks
    shapeInserter = vision.ShapeInserter('BorderColor', 'White');
    out = shapeInserter(frame, BBOX); % adds bounding boxes to video
    videoPlayer(out);
end
    for n = 1:numel(carcandidates)
        if carcandidates(n).framespresent > 42
            numcars = numcars + 1;
        end
    end % We'll only consider a track a legitimate car candidate if it
% appears over a certain number of frames
% Will need to adjust for video inputs from Raspberry Pi Camera
% Runs slow after a little while, need to optimize looping
% Need to perfect a cleaning method, false detections high, cleaning noise
